/// <reference path="../../typings/node/node.d.ts"/>

"use strict";

var mongoClient = require('mongodb');
var getJson = require("./xls2json");

let mongoUrl = 'mongodb://localhost:27017/lobby';
let collName = 'lobby';

// Convert number fields to float, int
function mapper(entry) {
	let numbers = [
		"noPersons",
		"costsAbsolute",
		"turnover"
	];
	entry.noFTEs = parseFloat(entry.noFTEs);
	numbers.forEach( num => entry[num] = parseInt(entry[num]) );

	// return entry.initiatives.split(/[,\n]/)
	// 	.map(j => j.trim())
	// 	.filter(k => k.length);
	// dates.forEach( i => entry[i] = Date.parse(entry[i]));

	return entry;
}

function replaceDB(json) {
	console.log(`Opening DB`);
	mongoClient.connect(mongoUrl, function(err, db) {
		if (err) throw err;

		let coll = db.collection(collName);

		console.log(`Converting numerical data in Json`);
		let json_conv = json.map(mapper);
		// console.log(json_conv[0]);

		coll.drop();

		coll.insertMany(json_conv, (err, res) => {
			if (err) throw err;

			// returns _id ?
			console.log(`Inserted ${res.insertedCount} entries into database`);
			return db.close();
		});
	});
}

// getJson.updateAll('tmp', replaceDB);

getJson.test('tmp', json => {
	replaceDB(json);
});
