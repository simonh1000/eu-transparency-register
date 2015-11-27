'use strict';

var mongoClient = require('mongodb');
var Promise = require("bluebird");
var moment = require("moment");

var ingester = require('./ingester');
var processor = require('./processor');

var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby"
let fname = './reg' + moment().format('DD-MM');

// Function that returns a Promise of a database connection
var mongoConnect = Promise.promisify(mongoClient.connect);

// DOWNLOAD NEW FILE
// ingester.getXls(fname)
// 	.then( () => console.log('done') )
// 	.catch( err => console.error(err) );

// RUN COMPLETE UPDATE
// 1) Download data
ingester.getXls(fname)
// 2) update DB
.then( () => updateOneDb(mongoUrl) )
.then( res => {
	console.log(`Database ${res.mongoUrl} returned`);
	console.log(res.results);
})
.catch( console.error.bind(this) );

function updateOneDb(uri) {
	var db;

	return mongoConnect(uri)
	// ingest data
	.then( _db => {
		db = _db;
		return ingester.handleUpdate(fname, db);
	})
	// make summary data
	.then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData(db)]) )
	// close connection
	.then( res => {
		db.close();
		return {
			mongoUrl: mongoUrl,
			results: res
		}
	})
	.catch( err => {
		if (db.close)
			db.close();
		Promise.reject(err);
	});
}

// updateOneDb(mongoUrl);
// MONGO_URI=mongodb://hotbelgo:ber3la6mo6nT@ds047114.mongolab.com:47114/euregister node manual
// MONGO_URI=mongodb://localhost:27017/lobby node manual


// RUN SUMMARY UPDATER ONLY
// processor.makeSummaryData()
// 	.then( console.log.bind(this) )
// 	.catch( err => console.error(err) );

/* ********************************** */
// ingester.getXls('./reg' + moment().format('DD-MM'))
// // 2) get a mongoConnection
// .then( () => mongoConnect(mongoUrl) )
// // mongoConnect(mongoUrl)
// // ingest data
// .then( _db => {
// 	db = _db;
// 	return ingester.handleUpdate(fname, db);
// })
// // make summary data
// .then( ingestRes => Promise.all([Promise.resolve(ingestRes), processor.makeSummaryData(db)]) )
// // close connection
// .then( res => {
// 	console.log(res);
// 	db.close()
// })
// .catch( err => {
// 	console.error(err);
// 	if (db.close)
// 		db.close();
// });
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
