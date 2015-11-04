"use strict";

var mongoClient = require('mongodb');
var Promise = require("bluebird");

var mongoUrl = process.env.MONGO_URI || "mongodb://hotbelgo:ber3la6mo6nT@ds047114.mongolab.com:47114/euregister";

var dataCollection = 'lobby';
var interestsCollection = 'interests';
var issues = require('./field_headers').issues;

function processDB(cb) {
	console.log(`processDB: ${mongoUrl}`);
	mongoClient.connect(mongoUrl, function(err, db) {
		if (err) throw err;

		let coll = db.collection(dataCollection);
		let interests = db.collection(interestsCollection);

		// console.log(coll.find({'interests' : {$elemMatch: {$eq: 'Customs'}}}).count());

		// let countedIssues =
		// 	issues.map( issue => ({
		// 		issue: issue,
		// 		count: coll.find({'interests' : {$elemMatch: {$eq: issues}}}).count()
		// 	}));
		let promises =
			issues.map( issue => {
				return coll.find({'interests' : {$elemMatch: {$eq: issue}}})
				.count()
				.then( c => ({
					issue: issue,
					count: c
				}) );
			});

		Promise.all(promises)
		.then( results => {
			interests.drop();
			return interests.insert(results);
		} )
		.then( response => cb(null, response) )
		.finally( () => db.close() )
		.catch( cb );
	});
}

exports.index = (req, res) => {
	processDB( (err, response) => {
		if (err) return res.status(500).send(err);

		res.send(response);
	});
};

/* LOCAL */
// processDB( (err, response) => {
// 	if (err) throw err;
// 	console.log("Done!");
// })
