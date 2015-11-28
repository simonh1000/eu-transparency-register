'use strict';

var mongoClient = require('mongodb');
var Promise = require("bluebird");
var moment = require("moment");

var xls = require('./xls');
var ingester = require('./ingester');
var processor = require('./processor');
var config = require('../../../ignore/settings.js');

// var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby"
let fname = './reg' + moment().format('DD-MM');

// Function that returns a Promise of a database connection
var mongoConnect = Promise.promisify(mongoClient.connect);

let local = config.LOCAL;
let remote = config.REMOTE;

// DOWNLOAD NEW FILE
// ingester.getXls(fname)
// 	.then( () => console.log('done') )
// 	.catch( err => console.error(err) );

// RUN COMPLETE UPDATE
// 1) Download data and // Read data file
// ingester.getXls(fname)
// .then( () => xls.xls2Json(fname) )
xls.xls2Json(fname)
// // 2) update DB
.then( newJson => {
	let promises =
		[local]
		// [local, remote]
		.map( uri => updateOneDb(uri, newJson) );

	return Promise.all(promises);
})
// updateOneDb(remote)
.then( res => {
	console.log(res);
	res.forEach(r => {
		console.log(`Database ${r.mongoUrl} returned`);
		console.log(r.results);
	});
})
.catch( console.error.bind(this) );

function updateOneDb(uri, newJson) {
	var db;
	console.log("updateOneDb", uri);

	return mongoConnect(uri)
	// ingest data
	.then( _db => {
		db = _db;
		return ingester.handleUpdate(fname, newJson, db);
	})
	// make summary data
	.then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData(db)]) )
	// close connection
	.then( res => {
		console.log("updateOneDb, final then", res);
		db.close();
		return {
			mongoUrl: uri,
			results: [...res[0], ...res[1]]
		}
	})
	.catch( err => {
		if (db.close)
			db.close();
		Promise.reject(err);
	});
}

/* MANUAL TEST */
// exports.makeSummaryData()
// .then( responses => console.log(responses) )
// .catch( err => console.error(err) );
