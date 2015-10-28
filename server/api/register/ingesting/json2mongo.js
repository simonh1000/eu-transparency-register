/// <reference path="../../typings/node/node.d.ts"/>

"use strict";

var mongoClient = require('mongodb');
var getJson = require("./xls2json");

let mongoUrl = 'mongodb://localhost:27017/lobby';
let collName = 'lobby';

// Convert number fields to float, int
function mapper(entry) {
	function avg(str) {
		if (str == ">10000000") return 10000000;

		let rs = str.split("-").map(i=>parseInt(i));
		return Math.round((rs[0] + rs[1]) / 2);
	}

	let numbers = [
		"noPersons",
		"turnover"
	];
	numbers.forEach( num => entry[num] = parseInt(entry[num]) );

	entry.noFTEs = parseFloat(entry.noFTEs);

	if (entry.costsAbsolute) {
		entry.budget = entry.costsAbsolute = parseInt(entry.costsAbsolute);
	} else {
		entry.budget = avg(entry.costEst)
	}
	if (isNaN(entry.budget)) console.log("NaN", entry._id);

	return entry;
}

function replaceDB(json) {
	console.log(`Opening DB`);
	mongoClient.connect(mongoUrl, function(err, db) {
		if (err) throw err;

		let coll = db.collection(collName);

		coll.drop();

		coll.insertMany(json, (err, res) => {
			if (err) throw err;

			console.log(`Inserted ${res.insertedCount} entries into database`);
			console.log(`Closing DB connection`);
			return db.close();
		});
	});
}

// getJson.updateAll('tmp', json => {
// 	let json_conv = json.map(mapper);
// 	replaceDB(json_conv);
// });

getJson.test('tmp', json => {
	let json_conv = json.map(mapper);
	// console.log(json_conv[1]);

	replaceDB(json_conv);
});
