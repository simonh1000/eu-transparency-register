/* globals require, console, setTimeout, exports */

"use strict";

var mongoClient = require('mongodb');
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

const SUMMARY = 'summary';
// document IDs
const INTERESTS = 'interests';
const SECTIONS = 'sections';

// Create 3 global mongo collection variables
var register,
	interests,
	summary;

mongoClient.connect(mongoUrl, function(err, db) {
	if (err) throw err;

	console.log("Connected to database", mongoUrl);
	register = db.collection('lobby');
	// interests = db.collection('interests');
	// sections = db.collection('sections');
	summary = db.collection(SUMMARY);
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
	// interests.find({}, {_id:0})
	summary.find({_id:INTERESTS})
	// .sort({'data.count' : -1 })
	.toArray( (err, data) => {
		if (err) return res.status(500).end();

		let sorted = data[0].data.sort( (r1,r2) => r2.count - r1.count );
		res.send(sorted);
	} );
};

exports.sections = (req, res) => {
	// sections.find({})
	summary.find({_id:SECTIONS})
	.toArray( (err, data) => {
		if (err) return res.status(500).end();
		res.send(data[0].data);
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
