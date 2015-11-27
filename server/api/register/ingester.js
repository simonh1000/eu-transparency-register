"use strict";

var XLSX = require('xlsx');
var fs = require('fs');
var request = require("request");
var mongoClient = require('mongodb');
var moment = require("moment");
var Promise = require("bluebird");

var processor = require("./processor");

/* *NEEDS TO BE VAR ***************************** */
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby"

// Collection names
const REGISTER = 'register';
const HISTORY = 'history';
const CHANGES = 'changes';
// Name of sheet in XLS file
const SHEET_NAME = 'LIST_REGISTRED_ORGANISATION';

var headers = require('./field_headers').headers;
var reqoptions = {
	url: "http://ec.europa.eu/transparencyregister/public/consultation/statistics.do?action=getLobbyistsExcel&fileType=XLS_NEW",
	headers: {
		'User-Agent': 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13'
	}
};

/*
 * XLS download and read
 * Downloads file to drive
 */
function getXls(fname) {
	return new Promise(function(resolve, reject) {
		request(reqoptions)
			.on('response', response => console.log("Downloading...") )
			.on('end', msg => {
				console.log(`ingester: Downloading finished. Saved to ${fname}.xls`)
				resolve(fname);
			})
			.on('close', msg => {
				console.log("Close??", msg);
			})
			.pipe(fs.createWriteStream(fname + '.xls'));
	});
}

// Reads xls file from disk and returns as json
function xls2Json(fname) {
	return new Promise( (resolve, reject) => {
		console.log(`ingest: Reading ${fname}.xls, for insertion in ${mongoUrl}`);
		var wbook = XLSX.readFile(fname+'.xls');
		console.log("ingest: Converting to json...");

		var worksheet = wbook.Sheets[SHEET_NAME];

		let json = XLSX.utils.sheet_to_json(worksheet, {header:headers, range:1});

		resolve(json);
	});
}

/*
 * Pure processing functions
 * Takes output from xls2json and converts to DB
 */
function rawMapper(entry) {

	function avg(str) {
		// console.log(str);
		if (str == ">10000000") return 10000000;
		let rs = str.split("-").map( i=> parseInt(i) );
		return Math.round((rs[0] + rs[1]) / 2);
	}

	function caseMapper(prop, val) {
		switch (prop) {
			case 'entryDate':  	// convert date into Mongo usable format
				return moment(val, 'D-M-YYYY').format();
			case 'interests':
				return val.split(', ');
			case 'noPersons':
				return parseInt(val);
			case 'turnover':
				return parseInt(val);
			case 'costsAbsolute':
				return parseInt(val);
			case 'noEP':
				return parseInt(val);
			case 'noFTEs':
				return parseFloat(val);
			default: return val
		}
	}

	var newEntry = {}
	for (var prop in entry) {
		if (entry[prop] !== "") {
			newEntry[prop] = caseMapper(prop, entry[prop]);
		}
	}
	// Budget / costs ... (costsAbsolute === 0 is a possibility)
	newEntry.budget = (typeof newEntry.costsAbsolute != 'undefined') ? newEntry.costsAbsolute : avg(newEntry.costEst);
	if (isNaN(newEntry.budget)) console.log("NaN", newEntry._id);

	return newEntry;
}

// Helper: arraysEqual
function arraysEqual(a, b) {
	if (a === b) return true;
	if (a == null || b == null) return false;
	if (a.length != b.length) return false;

	// If you don't care about the order of the elements inside
	// the array, you should sort both arrays here.

	for (var i = 0; i < a.length; ++i) {
		if (a[i] !== b[i]) return false;
	}
	return true;
}

// returns true if newEntry has new info or different data
function isDifferrent(existing, entry) {
	for (var prop in entry) {
		if (existing.hasOwnProperty(prop)) {
			// comparing array of interests otherwise suggests new data present
			if ((typeof entry[prop] !== 'object' && existing[prop] !== entry[prop])
				|| (typeof entry[prop] == 'object' && !arraysEqual(existing[prop], entry[prop]))) {

				// ****ideally want this logged to a temp file
				// console.log(`updated ${prop}: ${entry.orgName.substr(0,20)}: ${existing[prop]} -> ${entry[prop]}`);
				return true;
			}
		} else {
			// new data field supplied, also considered an update
			return true;
		}
	}
	return false;
}

// iterate over newData to identify new entries or updates
// return { _id: date,  newEntries: [{_id: , orgName}], updates: ...}
function getChanges(existing, newData) {
	function idAndName(e) {
		// store using _id to match search results
		return {_id: e._id, orgName: e.orgName}
	}

	let newEntries = [];
	let updates = [];

	newData.forEach(entry => {
		if (!existing.hasOwnProperty(entry._id)) {
			newEntries.push(idAndName(entry));
			return;
		}

		if (isDifferrent(existing[entry._id], entry)) {
			updates.push(idAndName(entry));
			return;
		}
	});
	return {
		_id: moment().format(),
		entries: newEntries,
		updates: updates
	}
}

function removeUnwantedFields(entry) {
	var cleanedEntry = {}
	let fields = [ "regDate", "legalPerson", "euPerson", "goals", "noPersons", "noFTEs", "noEP",
	  "epAccrdited", "memberships", "organisations", "Financial Start", "Financial End", "costsAbsolute",
	  "costEst" ];

	fields.forEach(fieldName => {
		  if (entry[fieldName])
		  	cleanedEntry[fieldName] = entry[fieldName]
		});
	return cleanedEntry;
}

function addEntryDate(entry) {
	entry['entryDate'] = moment().format();
	return entry;
}

/* ****************************************************************
 * Database functions
 * Function that returns a Promise of a database connection
 */
var mongoConnect = Promise.promisify(mongoClient.connect);

// Get existing data and returns as an object with key = _id
function getExistingData(db) {
	console.log('ingest: getExistingData starting');
	return db.collection(REGISTER)
		.find({})
		.toArray()
		.then( data => {
			let keyedData = {};
			data.forEach( entry => keyedData[entry._id] = entry );
			console.log('ingest: getExistingData returning keyedData');
			return keyedData;
			// return {
			// 	db: db,
			// 	data: keyedData
			// };
		}, err => console.error(err)
	);
}

function handleUpdate(fname, db) {
	return Promise.all([getExistingData(db), xls2Json(fname)])
	.then( results => {
		let existingKeyedData = results[0];

		// convert numbers in newData
		let newData = results[1].map(rawMapper);

		// RECORD SUMMARY LIST OF ENTRIES / UPDATES
		let newUpdated = getChanges(existingKeyedData, newData);
		//  * !!!!!!!!!!!!!!!!!!!!only add non-empty lists
		let changesPromise =
			db.collection(CHANGES)
			.insertOne(newUpdated)
			.then(res => ({
				'newEntries': newUpdated.entries.length,
				'updates': newUpdated.updates.length
			}));

		// FOR ALL UPDATES, MAKE A COPY OF CURRENT DATA
		let historyPromises =
			newUpdated.updates
			.map(update => {
				// for each _id that is changed
					// use data from existingKeyedData
					// remove unwanted fields
					// add the date
				let previous =
					addEntryDate( removeUnwantedFields( existingKeyedData[update._id] ) );

				// add this information to the hitory about this _id
				return db.collection(HISTORY)
						.updateOne({_id: update._id}, {$push: {history: previous}}, {upsert: true});
			});

		// REPLACE MAIN REGISTER DATABASE
		let registerPromise =
			db.collection(REGISTER)
			.drop()
			.then( () => db.collection(REGISTER).insertMany(newData) )
			.then( result => ({'registerSize': result.insertedCount}));

		return Promise.all([registerPromise, changesPromise].concat(historyPromises))
			.then( res => [res[0], res[1], {'historyUpdates': (res.length-2)}] );
	});
}

// function handleUpdate(fname) {
// 	var db;
//
// 	return Promise.all([
// 		mongoConnect(mongoUrl)
// 			.then(_db => {
// 				db = _db;
// 				return getExistingData(db);
// 			}), 					    // database data
// 		xls2Json(fname) 				// new data
// 	])
// 	.then( results => {
// 		// let existingKeyedData = results[0].data;
// 		let existingKeyedData = results[0];
// 		// convert numbers to Int/Float ....
// 		let newData = results[1].map(rawMapper);
//
// 		// RECORD SUMMARY LIST OF ENTRIES / UPDATES
// 		let newUpdated = getChanges(existingKeyedData, newData);
// 		/* *******
// 		 * !!!!!!!!!!!!!!!!!!!!only add non-empty lists
// 		 */
// 		let changesPromise =
// 			db.collection(CHANGES)
// 			.insertOne(newUpdated)
// 			.then(res => ({
// 				'newEntries': newUpdated.entries.length,
// 				'updates': newUpdated.updates.length
// 			}));
// 			// console.log('ingest: newEntryCount', newEntries.length);
// 			// console.log('ingest: newDataCount', updates.length);
//
// 		// FOR ALL UPDATES, MAKE A COPY OF CURRENT DATA
// 		// Updates to existing entries
// 			// for each new entry
// 				// get previous entry from REGISTER, & tidy up
// 				// p1 = push to HISTORY
// 				// p2 = update REGISTER with new Information
// 				// return Promise.all[p1, p2]
// 		let historyPromises =
// 			newUpdated.updates
// 			.map(update => {
// 				// get and clean up existing entry
// 				let previous =
// 					addEntryDate( removeUnwantedFields( existingKeyedData[update._id] ) );
//
// 				return db.collection(HISTORY)
// 						.updateOne({_id: update._id}, {$push: {history: previous}}, {upsert: true});
// 				// let p2 = db.collection(REGISTER).replaceOne( {_id: update._id}, addEntryDate(update) );
// 				// return Promise.all([p1, p2]);
// 				// return Promise.resolve();
// 			});
//
// 		console.log('ingest: Created update history promises');
//
// 		// REPLACE MAIN REGISTER DATABASE
// 		let registerPromise =
// 			db.collection(REGISTER)
// 			.drop()
// 			.then( () => db.collection(REGISTER).insertMany(newData) )
// 			.then( result => ({'registerSize': result.insertedCount}));
//
// 		return Promise.all([registerPromise, changesPromise].concat(historyPromises));
// 	})
// 	.then( res => {
// 		// console.log(res);
// 		db.close();
// 		// return [ ...res, {'updates': (res.length-2)} ];
// 		return [ res[0], res[1], {'updates': (res.length-2)} ];
// 	})
// 	.catch( err => {
// 		console.error(err);
// 		if (db.close)
// 			db.close();
//
// 		return Promise.reject(err);
// 	} );
// }
/*
 * Read file AND get existing data
 * then compare, and upload differences
 */
// exports.index = function(req, res) {
// 	let fname = './server/api/register/reg'+moment().format('DD-MM');
//
// 	getXls(fname)
//     .then( () => {
// 		return handleUpdate(fname)
// 	})
// 	// then use processor.js
// 	.then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData()]) )
// 	.then( results => {
// 		res.status(200).send(results);
// 	})
// 	.catch( err => res.status(500).send(err) );
// };

exports.getXls = getXls;
exports.handleUpdate = handleUpdate;
