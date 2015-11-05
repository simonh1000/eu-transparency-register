
"use strict";

var mongoClient = require('mongodb');
// var Promise = require("bluebird");

var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";
// var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

var registerCollection = 'lobby';
var interestsCollection = 'interests';
var sectionsCollection = 'sections';

var issues = require('./field_headers').issues;

function connectDB(cb) {
	console.log(`connectDB: ${mongoUrl}`);
	mongoClient.connect(mongoUrl, function(err, db) {
		console.log("Connected to database", err);
		cb(err, db);
	});
}

function countInterests(db) {
	let coll = db.collection(registerCollection);
	let interests = db.collection(interestsCollection);

	let promises =
		issues.map( issue => {
			return coll.find( { 'interests' : { $elemMatch: {$eq: issue} } } )
			.count()
			.then( c => {
				console.log(`${issue} ${c}`);
				return {
					issue: issue,
					count: c
				} 
			});
		});

	return Promise.all(promises)
	.then( results => {
		console.log("all promises returned")
		interests.drop();
		return interests.insert(results);
	} )
	.catch( Promise.reject("error simon") );
}

exports.index = (req, res) => {
	connectDB( (err, db) => {
		if (err) return res.status(500).send(err);

		countInterests(db)
		.then( response => res.send(response) );
	});
};

function countSpend(db) {
	let register = db.collection(registerCollection);
			
	let simpleCount = register.aggregate([
		{ "$group" : {_id : "$subsection", count: {$sum: 1} } }
	]);

	let budgetCount = register.aggregate([
		{ "$group" : {_id : "$subsection", total: {$sum: "$budget"} } }
	]);

	return Promise.all([simpleCount.toArray(), budgetCount.toArray()])
	.then(results => {
		let base = results[0];
		let merge = results[1];
		
		let mergedResults = base.map( elem => {
			let mergeVal = merge.find( e => e._id === elem._id );
			elem.total = mergeVal.total;
			return elem;
		})
		
		return db.collection(sectionsCollection)
		.insert(mergedResults);
	})
	.catch(err => Promise.reject("countSpend error: " + err));
}


/* LOCAL */
connectDB( (err, db) => {
	if (err) return console.log(err);

	// countInterests(db)
	// .then( response => {
	// 	console.log(response.result);
	// 	db.close();
	// });
	
	countSpend(db)
	.then( results => {
		console.log("countSpend", results.result)
		db.close()
	})
	.catch( err => {
		console.log(err)
		db.close()
	});
});
