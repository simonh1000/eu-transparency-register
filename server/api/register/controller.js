/* globals require, console, setTimeout, exports */

"use strict";

var moment = require('moment');
var mongoClient = require('mongodb');
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

const CHANGES = 'changes';
const SUMMARY = 'summary';
const REGISTER = 'register';
// document IDs
const INTERESTS = 'interests';
const SECTIONS = 'sections';
const COUNTRIES	= 'countries';

// Create 3 global mongo collection variables
var register,
	summary,
	changes;

mongoClient.connect(mongoUrl, function(err, db) {
	if (err) throw err;

	console.log("Connected to database", mongoUrl);
	register = db.collection(REGISTER);
	changes = db.collection(CHANGES);
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

exports.countries = (req, res) => {
	summary.find({_id:COUNTRIES})
	.toArray( (err, data) => {
		if (err) return res.status(500).end();
		res.send(data[0].data);
	} );
};

exports.summary = (req, res) => {
	summary.find()
	.toArray( (err, data) => {
		if (err) return res.status(500).end();
		res.send(data);
	} );
};

exports.newentries = (req, res) => {
	// find all records with id < 14 days ago
	// concat results
	let minus7 = moment().subtract(7, 'days').format();

	changes.find({_id: {$gte: minus7}})
	.toArray( (err, data) => {
		if (err) return res.sendStatus(500).end();
		// results likely to be an array of several elements, so combine them
		let combined =
			data.reduce(
				(acc, dataset) => {
					// console.log("reduce", dataset.entries);
					return { entries: acc.entries.concat(dataset.entries),
					         updates: acc.updates.concat(dataset.updates) }
				 },
				{ entries: [], updates: [] }
			);
		// console.log(combined.entries);
		res.send(combined);
	} );
};

// provides total count
exports.meta = (req, res) => {
	register.find({})
	.count( (err, data) => {
		if (err) throw err;
		// delaySend(data, res);
		res.send({count:data});
	});
};
