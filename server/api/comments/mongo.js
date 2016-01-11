var moment = require('moment');
var mongoClient = require('mongodb');
var mongoUrl = process.env.MONGO_URI || "mongodb://localhost:27017/lobby";

exports.index = function(collName) {
    return new Promise(function(resolve, reject) {
        mongoClient.connect(mongoUrl, (err, db) => {
        	if (err) reject(new Error(err));

        	resolve(db.collection(collName));
        });
    });
}
