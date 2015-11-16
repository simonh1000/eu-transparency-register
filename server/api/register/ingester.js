"use strict";

var XLSX = require('xlsx');
var fs = require('fs');
var request = require("request");
var mongoClient = require('mongodb');
var moment = require("moment");
var Promise = require("bluebird");

var processor = require("./processor");

/* *NEEDS TO BE VAR ***************************** */
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

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
 * XLS download and pre-process
 */
// Downloads file to drive
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

// Takes output from xls2json and converts to DB
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

// Function that returns a Promise of a database connection
var mongoConnect = Promise.promisify(mongoClient.connect);

// Get existing data and return {db:db, data:json}
function getExistingData(db) {
	console.log('ingest: getExistingData starting');
	return db.collection(REGISTER)
	.find({})
	.toArray()
	.then( data => {
		let keyedData = {};
		data.forEach( entry => keyedData[entry._id] = entry );
		console.log('ingest: getExistingData returning keyedData');
		return {
			db: db,
			data: keyedData
		};
	}, err => console.error(err)
 	)
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

				// console.log(`new data for ${entry.orgName.substr(0,20)}, ${prop}: ${existing[prop]} -> ${entry[prop]}`);
				return true;
			}
		} else {
			return true;
		}
	}
	return false;
}

// iterate newData and add/replace new date, while making archive
function getNewOrUpdatedEntries(existing, newData, db) {
	let newEntries = [];
	let updates = [];

	newData.forEach(entry => {
		if (!existing.hasOwnProperty(entry._id)) {
			newEntries.push(entry);
			return;
		}

		if (isDifferrent(existing[entry._id], entry)) {
			updates.push(entry);
			return;
		}
	});
	console.log('ingest: newEntryCount', newEntries.length);
	console.log('ingest: newDataCount', updates.length);
	return {
		newEntries: newEntries,
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

function handleUpdate(fname, cb) {
	var db;

	return Promise.all([
		mongoConnect(mongoUrl).then(getExistingData),
		// getXls(fname).then( () => xls2Json(fname) )
		xls2Json(fname)
	])
	.then( results => {
		db = results[0].db;
		let existingKeyedData = results[0].data;
		// clean up newData
		let newData = results[1].map(rawMapper);

		// returns {newEntries: [Entry], updates: [Entry]}
		let newUpdated = getNewOrUpdatedEntries(existingKeyedData, newData);

		// Create new doc {_id: date, entries: [{_id, name}], updates:...}
		// store using _id in the array so that Elm can use same decoder for this as for search results
		let changesObj = {
			_id: moment().format(),
			entries: newUpdated.newEntries.map( e => ({_id:e._id, orgName:e.orgName}) ),
			updates: newUpdated.updates.map( e => ({_id:e._id, orgName:e.orgName}) )
		};
		let changesPromise =
			db.collection(CHANGES).insertOne(changesObj)
			.then(res => {changes: res.insertedCount});

		// New entries
		let newEntries = newUpdated.newEntries.map(addEntryDate);
		let entriesPromise =
			(newEntries.length) ? db.collection(REGISTER).insertMany(newEntries)
									.then(res => {newEntries: res.insertedCount}) : Promise.resolve("no new Entries");
		// let entriesPromise = Promise.resolve();
		console.log('ingest: inserted new entries');

		// Updates to existing entries
			// for each new entry
				// get previous entry from REGISTER, & tidy up
				// p1 = push to HISTORY
				// p2 = update REGISTER with new Information
				// return Promise.all[p1, p2]
		let updatePromises =
			newUpdated.updates
			.map(update => {
				let previous =
					addEntryDate( removeUnwantedFields( existingKeyedData[update._id] ) );

				let p1 = db.collection(HISTORY).updateOne({_id: update._id}, {$push: {history: previous}}, {upsert: true});

				let p2 = db.collection(REGISTER).replaceOne( {_id: update._id}, addEntryDate(update) );

				return Promise.all([p1, p2]);
				// return Promise.resolve();
			});
			console.log('ingest: replaced existing entries');

		return Promise.all(updatePromises.concat(changesPromise, entriesPromise));
	})
	.then( res => {
		// console.log(res);
		db.close();
		return res;
	})
	.catch( err => {
		console.error(err);
		if (db.close)
			db.close();

		return Promise.reject(err);
	} );
}
/*
 * Read file AND get existing data
 * then compare, and upload differences
 */
exports.index = function(req, res) {
	let fname = './reg'+moment().format('DD-MM');

	getXls(fname)
    .then( () => {
		return handleUpdate(fname)
	})
	// then use processor.js
	.then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData()]) )
	.then( results => {
		res.status(200).send(results);
	})
	.catch( err => res.status(500).send(err) );
};

/* ********************************** */

function insertLocal(fname, cb) {
	Promise.all([
		mongoConnect(mongoUrl),
		xls2Json(fname)
	])
	.then( results => {
		let db = results[0];
		let json = results[1];

		// **** set default 'lastUpdate'
		let defaultEntryDate = moment('28/10/2015', 'DD-MM-YYYY').format();

		let newJson = json.map(entry => {
			let newEntry = rawMapper(entry);
			newEntry['lastUpdate'] = defaultEntryDate;
			return newEntry;
		});

		let coll = db.collection(REGISTER);

		coll.drop();
		console.log('ingest: insertLocal - replacing DB');

		coll.insertMany(newJson, (err, res) => {
			if (err) throw err;

			console.log(`ingest: Inserted ${res.insertedCount} entries into ${REGISTER}. Closing DB connection`);
			db.close();
            cb();
		});
	} );
}

/* MANUAL TEST
*/
// download new data
// getXls('./' + moment().format(DDMM))
// 	.then( () => console.log('done') )
// 	.catch( err => console.error(err) );

// run update from local file
// handleUpdate('./reg16-11')
// 	.then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData()]) )
// 	.then( () => console.log('done') )
// 	.catch( err => console.error(err) );

// Re-initialise data from local file
// insertLocal('./oct28', () => console.log("done"))
