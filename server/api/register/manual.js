'use strict';

var mongoClient = require('mongodb');
var Promise = require("bluebird");
var moment = require("moment");

var ingester = require('./ingester');
var processor = require('./processor');

let fname = './reg' + moment().format('DD-MM');

// Function that returns a Promise of a database connection
var mongoConnect = Promise.promisify(mongoClient.connect);


// DOWNLOAD NEW FILE
// ingester.getXls('./reg' + moment().format('DD-MM'))
// 	.then( () => console.log('done') )
// 	.catch( err => console.error(err) );

// RUN COMPLETE UPDATE
ingester.handleUpdate(fname)
	.then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData()]) )
	.then( console.log.bind(this) )
	.catch( err => console.error(err) );

//
// MONGO_URI=mongodb://hotbelgo:ber3la6mo6nT@ds047114.mongolab.com:47114/euregister node manual
// MONGO_URI=mongodb://localhost:27017/lobby node manual


// RUN SUMMARY UPDATER ONLY
// processor.makeSummaryData()
// 	.then( console.log.bind(this) )
// 	.catch( err => console.error(err) );

/* ********************************** */
// Re-initialise data from local file
// insertLocal('./reg17-11', () => console.log("done"))


// function insertLocal(fname, cb) {
// 	Promise.all([
// 		mongoConnect(mongoUrl),
// 		xls2Json(fname)
// 	])
// 	.then( results => {
// 		let db = results[0];
// 		let json = results[1];
//
// 		// **** set default 'lastUpdate'
// 		let defaultEntryDate = moment('28/10/2015', 'DD-MM-YYYY').format();
//
// 		let newJson = json.map(entry => {
// 			let newEntry = rawMapper(entry);
// 			newEntry['lastUpdate'] = defaultEntryDate;
// 			return newEntry;
// 		});
//
// 		let coll = db.collection(REGISTER);
//
// 		coll.drop();
// 		console.log('ingest: insertLocal - replacing DB');
//
// 		coll.insertMany(newJson, (err, res) => {
// 			if (err) throw err;
//
// 			console.log(`ingest: Inserted ${res.insertedCount} entries into ${REGISTER}. Closing DB connection`);
// 			db.close();
//             cb();
// 		});
// 	} );
// }


/* MANUAL TEST */
// exports.makeSummaryData()
// .then( responses => console.log(responses) )
// .catch( err => console.error(err) );
