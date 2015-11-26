/*
 * CALCULATE SUMMARY INFORMATION
 */

"use strict";

var mongoClient = require('mongodb');
var Promise = require("bluebird");

var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

const REGISTER = 'register';
const SUMMARY = 'summary';
// document _id's
const INTERESTS = 'interests';
const SECTIONS = 'sections';
const COUNTRIES = 'countries';

var interests = require('./field_headers').interests;

// Function that returns a Promise of a database connection
var mongoConnect = Promise.promisify(mongoClient.connect);

/*
 * Iterates across list of interests
 * Counts number of registrees citging that interest
 * Puts summary totals in 'interest' collection
 */
function countInterests(db) {
	let coll = db.collection(REGISTER);

	let promises =
		interests.map( interest => {
			return coll.find( { 'interests' : { $elemMatch: {$eq: interest} } } )
			.count()
			.then( c => {
				// console.log(`${interest} ${c}`);
				return {
					interest: interest,
					count: c
				}
			});
		});

	return Promise.all(promises)
	.then( results => {
		console.log(`processor: ${results.length} Interest promises returned`);
		// interests.drop();
		return db.collection(SUMMARY).replaceOne({_id:INTERESTS}, {_id:INTERESTS, data: results}, {upsert:true});
	} )
	.catch( err => {
		console.error(err);
		return err;
		// Promise.reject("countInterests error");
	} );
}

/*
 * Calculates numbers and spend per 'sub-section'
 * stores results in 'sections' collection
 */
function countSections(db) {
	let register = db.collection(REGISTER);

	let simpleCount = register.aggregate([
		// { "$group" : {_id : "$subsection", count: {$sum: 1} } }
		{ "$group" : {_id : "$subsection", count: {$sum: 1}, total: {$sum: "$budget"} } }
	]);

	// let budgetCount = register.aggregate([
	// 	{ "$group" : {_id : "$subsection", total: {$sum: "$budget"} } }
	// ]);

	// return Promise.all([simpleCount.toArray(), budgetCount.toArray()])
	return simpleCount.toArray()
	.then(results => {
		console.log(`processor: ${results.length} Sections promises resolved`);
		let base = results; 			// count data
		// let base = results[0]; 			// count data
		// let merge = results[1]; 		// spend data

		// for each element in base (count) add the spend figure
		let mergedResults = base;
		// let mergedResults = base.map( elem => {
		// 	let mergeVal = merge.find( e => e._id === elem._id );
		// 	elem.total = mergeVal.total;
		// 	return elem;
		// })

		// db.collection(SECTIONS).drop();
		return db.collection(SUMMARY).replaceOne(
					{_id: SECTIONS},
					{_id: SECTIONS, 'data': mergedResults},
					{upsert: true}
				).then(res => ({'sections': results.length}));
	})
	// .catch( err => Promise.reject(err) );
}

/*
 * Calculates numbers and spend per 'sub-section'
 * stores results as {_id: 'sections', ...}
 */
function countCountries(db) {
	let register = db.collection(REGISTER);

	let countries = register.aggregate([
	// db.register.aggregate([
		{ "$match" : {subsection: "Companies & groups"} },
		// { "$group" : {_id : "$hqCountry", count: {$sum: 1} } },
		{ "$group" : {_id : "$hqCountry", count: {$sum: 1}, eppass: {$sum: "$noEP"} } },
		{ "$sort" : {"count": -1} }
	]);

	return countries.toArray()
		.then( results => {
			console.log(`processor: ${results.length} countries`);
			return db.collection(SUMMARY).replaceOne(
					{_id: COUNTRIES},
					{_id: COUNTRIES, 'data': results},
					{upsert: true}
				);
		} );
}

exports.makeSummaryData = function(db) {
	console.log("makeSummaryData starting");
	return Promise.all([
		// countSections(db).then( res => ({"sections": !!res.result.ok}) ),
		countSections(db),
		countInterests(db).then( res => ({"interests": !!res.result.ok}) ),
		countCountries(db).then( res => ({"countries": !!res.result.ok}) )
	]);
};
// exports.makeSummaryData = function() {
// 	var db;
// 	return mongoConnect(mongoUrl)
// 	.then( _db => {
// 		db = _db;
// 		return Promise.all([
// 			countSections(db).then( res => ({"sections": !!res.result.ok}) ),
// 			countInterests(db).then( res => ({"interests": !!res.result.ok}) ),
// 			countCountries(db).then( res => ({"countries": !!res.result.ok}) )
// 		  ]);
// 	})
// 	.then( results => {
// 		console.log('makeSummaryData success');
// 		db.close();    // db.close
// 		return results; //.map( r => r.result );
// 	} )
// 	.catch ( err => {
// 		db.close();    // db.close
// 		// Promise.reject(err);
// 		return err
// 	} );
// }

/* A P I */
// exports.index = (req, res) => {
// 	exports.makeSummaryData()
// 	.then( responses => res.send(responses) )
// 	.catch( err => res.status(500).send(err) );
// };
