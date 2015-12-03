"use strict";

var fs = require('fs');
var request = require("request");
var mongoClient = require('mongodb');
var moment = require("moment");
var Promise = require("bluebird");

var processor = require("./processor");

/* *NEEDS TO BE VAR ***************************** */
// var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby"

// Collection names
const REGISTER = 'register';
const HISTORY = 'history';
const CHANGES = 'changes';

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
function downloadXls(fname) {
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

/* ***********************************************
 * PURE PROCESSING FUNCTIONS
*/
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
// var mongoConnect = Promise.promisify(mongoClient.connect);

// Get existing data and returns as an object with key = _id
function getExistingData(db) {
	// console.log('ingest: getExistingData starting');
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

function handleUpdate(fname, newData, db) {
	// return Promise.all([getExistingData(db), xls2Json(fname)])
	// .then( results => {
	return getExistingData(db)
	.then( existingKeyedData => {
		// let existingKeyedData = results[0];
		//
		// let newData = results[1];

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

function replaceDb(newData, db) {
	return db.collection(REGISTER)
		.drop()
		.then( () => db.collection(REGISTER).insertMany(newData) )
		.then( result => ({'registerSize': result.insertedCount}));
}

exports.downloadXls = downloadXls;
exports.handleUpdate = handleUpdate;
exports.replaceDb = replaceDb;
