/// <reference path="../../../typings/express/express.d.ts"/>
/// <reference path="../../../typings/express/express.d.ts"/>

"use strict";
var express = require('express');
var router = express.Router();

var mongoClient = require('mongodb');

let mongoUrl = 'mongodb://localhost:27017/lobby';

mongoClient.connect(mongoUrl, function(err, db) {
	if (err) throw err;

	let coll = db.collection('lobby');

	console.log("Creating DB routes");

	// test route
	router.get('/', (req, res) => {
		coll.find({'orgName': {'$regex': 'goog', $options: 'i'}})
		.toArray( (err, data) => {
			if (err) throw err;
			res.send(data);
		});
	});


	// router.get('/search', (req, res) => {
	// 	let query = req.query;
	// 	console.log(query);
	//
	// 	coll.find(
	// 		{'orgName': {'$regex': orgname, $options: 'i'}},
	// 		{'orgName': 1}
	// 	)
	// 	.toArray( (err, data) => {
	// 		if (err) throw err;
	// 		// console.log(data);
	// 		res.send(data);
	// 		// db.close();
	// 	});
	// });

	router.get('/search/:orgname', (req, res) => {
		let orgname = req.params.orgname;
		console.log(orgname);

		coll.find(
			{'orgName': {'$regex': orgname, $options: 'i'}},
			{'orgName': 1}
		)
		.toArray( (err, data) => {
			if (err) throw err;
			console.log(data);
			res.send(data);
		});
	});

	router.get('/id/:id', (req, res) => {
		let id = req.params.id;

		let myDoc = coll.findOne(
			{'_id': id},
			{}
		).then(data => {
			console.log(data);
			res.send(data);
		})
		// coll.find(
		// 	{'_id': id},
		// 	{}
		// )
		// .toArray( (err, data) => {
		// 	if (err) throw err;
		// 	res.send(data);
		// } );
	});
});

module.exports = router;
