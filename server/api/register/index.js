
"use strict";
var express = require('express');
var router = express.Router();

var mongoClient = require('mongodb');

let mongoUrl = 'mongodb://localhost:27017/lobby';

var delaySend = function(data, res) {
	setTimeout(() => res.send(data), 0);
}

mongoClient.connect(mongoUrl, function(err, db) {
	if (err) throw err;

	let coll = db.collection('lobby');

	console.log("Creating DB routes");

	router.get('/searchmore', (req, res) => {
		let query = req.query;

		let queryObj = {};
		if (query.search)
			queryObj.orgName = {'$regex': query.search, $options: 'i'};
		if (query.section)
			queryObj.subsection = query.section;
		if (query.fte)
			queryObj.noFTEs = { $gt : parseInt(query.fte) };
		if (query.budget)
			queryObj.budget = { $gt : parseInt(query.budget) };

		console.log("Query:", query);
		console.log("QueryObj:", queryObj);

		coll.find(queryObj, {'orgName': 1})
		.sort({'orgName' : 1 })
		.toArray( (err, data) => {
			if (err) throw err;

			delaySend(data, res);
			// res.send(data);
		});
	});

	router.get('/id/:id', (req, res) => {
		let id = req.params.id;

		let myDoc =
			coll.findOne({'_id': id})
			.then(data => {
				// console.log(data);
				delaySend(data, res);
				// res.send(data);
			});
	});

	// test route
	router.get('/', (req, res) => {
		coll.find({'orgName': {'$regex': 'goog', $options: 'i'}})
		.toArray( (err, data) => {
			if (err) throw err;

			delaySend(data, res);
			// res.send(data);
		});
	});

});

module.exports = router;
/*
{
router.get('/search/:orgname', (req, res) => {
	let orgname = req.params.orgname;
	console.log(orgname);

	coll.find(
		{'orgName': {'$regex': orgname, $options: 'i'}},
		{'orgName': 1}
	)
	.toArray( (err, data) => {
		if (err) throw err;
		// console.log(data);
		res.send(data);
	});
});

	"_id" : "917164011274-14",
	"regDate" : "06/06/2013",
	"section" : "I - Professional consultancies/law firms/self-employed consultants",
	"subsection" : "Professional consultancies",
	"orgName" : "1. Rozvojova s.r.o. (1RV)",
	"legalStatus" : "limited liability company",
	"website" : "http://www.rozvojova.eu/",
	"hqCountry" : "Czech Republic",
	"hqAddress" : "Trida Tomase Bati, 1547",
	"hqCity" : "Zlin",
	"hqPostCode" : "760 01",
	"hqPhone" : "(+420)776766390",
	"legalPerson" : "Vasicek Petr",
	"position" : "executive head",
	"euPerson" : "Vasicek Petr",
	"euPersonPosition" : "executive head",
	"goals" : "Project Coordination \nProject Finance \nEU Projects \nInternational Trade Projects \nManaging Technology Development Projects \nInternational Cooperation and Development Projects \nExport Promotion \nManaging the Tender Process",
	"level" : "regional/local, national",
	"initiatives" : "Horizont2020 \nEurostars \nEureka",
	"noPersons" : 1,
	"noFTEs" : 0.25,
	"interests" : "Agriculture and Rural Development, Education, Research and Technology",
	"Financial year: Start Date" : "01/01/2013",
	"Financial year: End Date" : "01/12/2013",
	"costsAbsolute" : 10000,
	"turnoverRange" : "0-99999",
	"clients" : "Kloboucka lesni s.r.o., Municipality Vizovice",
	"turnover" : NaN
}
*/
