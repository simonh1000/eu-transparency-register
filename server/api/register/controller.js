/* globals require, console, setTimeout, exports */

"use strict";

var mongoClient = require('mongodb');
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";
var register,
	interests;

mongoClient.connect(mongoUrl, function(err, db) {
	if (err) throw err;

	console.log("Connected to database", mongoUrl);
	register = db.collection('lobby');
	interests = db.collection('interests');
});

// var delaySend = function(data, res) {
// 	setTimeout(() => res.send(data), 1000);
// };

exports.search = (req, res) => {
	let query = req.query;

	let queryObj = {};
	if (query.search)
		queryObj.orgName = {'$regex': query.search, $options: 'i'};
	if (query.section)
		queryObj.subsection = query.section;
	if (query.fte > 0)
		queryObj.noFTEs = { $gt : parseInt(query.fte) };
	if (query.budget > 0)
		queryObj.budget = { $gt : parseInt(query.budget) };

	console.log("Query:", query);
	console.log("QueryObj:", queryObj);

	register.find(queryObj, {'orgName': 1})
	.sort({'orgName' : 1 })
	.toArray( (err, data) => {
		if (err) throw err;

		// delaySend(data, res);
		res.send(data);
	});
};

exports.id = (req, res) => {
	let id = req.params.id;

	let myDoc =
		register.findOne({'_id': id})
		.then(data => {
			// console.log(data);
			// delaySend(data, res);
			res.send(data);
		});
};

exports.interests = (req, res) => {
	interests.find({}, {_id:0})
	.toArray( (err, data) => {
		if (err) return res.status(500).end();
		res.send(data);
	} );
};

// test route
// router.get('/', (req, res) => {
exports.test = (req, res) => {
	register.find({'orgName': {'$regex': 'goog', $options: 'i'}})
	.toArray( (err, data) => {
		if (err) throw err;
		// delaySend(data, res);
		res.send(data);
	});
};


/*
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
