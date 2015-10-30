"use strict";

var XLSX = require('xlsx');
var fs = require('fs');
var request = require("request");
var mongoClient = require('mongodb');

/* *NEEDS TO BE VAR ***************************** */
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

let collName = 'lobby';
var reqoptions = {
	url: "http://ec.europa.eu/transparencyregister/public/consultation/statistics.do?action=getLobbyistsExcel&fileType=XLS_NEW",
	headers: {
		'User-Agent': 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13'
	}
};

const SHEET_NAME = 'LIST_REGISTRED_ORGANISATION';

var headers = require('./field_headers').headers;

// Downloads file to drive
function getXls(fname, cb) {
	return request(reqoptions)
		.on('response', function(response) {
			console.log("Downloading...")
		})
		.on('end', msg => {
			console.log(`Downloading finished. Saved to ${fname}.xls`)
			cb();
		})
		.on('close', msg => {
			console.log("Close", msg);
			cb();
		})
		.pipe(fs.createWriteStream(fname + '.xls'));
}

function xls2Json(fname, cb) {
	console.log("Reading data");
	var wbook = XLSX.readFile(fname+'.xls');
	console.log("Converting to json...");

	var worksheet = wbook.Sheets[SHEET_NAME];

	let json = XLSX.utils.sheet_to_json(worksheet, {header:headers, range:1});

	return cb(json);
}

// Convert number fields to float, int
function jsonMapper(entry) {
	function avg(str) {
		if (str == ">10000000") return 10000000;

		let rs = str.split("-").map(i=>parseInt(i));
		return Math.round((rs[0] + rs[1]) / 2);
	}

	// interest areas
	entry.interests = entry.interests.split(', ');
	// numerical values
	["noPersons", "turnover"].forEach( num => entry[num] = parseInt(entry[num]) );
	entry.noFTEs = parseFloat(entry.noFTEs);

	if (entry.costsAbsolute) {
		entry.budget = entry.costsAbsolute = parseInt(entry.costsAbsolute);
	} else {
		entry.budget = avg(entry.costEst)
	}
	if (isNaN(entry.budget)) console.log("NaN", entry._id);

	return entry;
}

function replaceDB(json, cb) {
	console.log(`Opening DB: ${mongoUrl}`);
	mongoClient.connect(mongoUrl, function(err, db) {
		if (err) throw err;

		let coll = db.collection(collName);

		coll.drop();

		coll.insertMany(json, (err, res) => {
			if (err) throw err;

			console.log(`Inserted ${res.insertedCount} entries into database`);
			console.log(`Closing DB connection`);
			return db.close();
            cb();
		});
	});
}

function getNewData(fname, cb) {
	getXls(fname, () => xls2Json(fname, cb) );
};

// function updateLocal(fname, cb) {
// 	// Reads local file and puts in database
// 	xls2Json(fname, json => {
// 		let json_conv = json.map(jsonMapper);
// 		replaceDB(json_conv, cb);
// 	});
// }
// updateLocal('./tmp', () => console.log("done"))

exports.index = function(req, res) {
    getNewData('./tmp', json => {
    	let json_conv = json.map(jsonMapper);
    	replaceDB(json_conv, () => res.status(200).end());
    });
};
