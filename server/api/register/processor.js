"use strict";

var mongoClient = require('mongodb');
var Promise = require("bluebird");

var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

var dataCollection = 'lobby';
var interestsCollection = 'interests';
var issues = require('./field_headers').issues;

function processDB(cb) {
	console.log(`Opening DB: ${mongoUrl}`);
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

processDB( (err, response) => {
	if (err) throw err;
	console.log("Done!");
})
