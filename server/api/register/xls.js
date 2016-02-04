'use strict';

var XLSX = require('xlsx');
var fs = require('fs');

var headers = require('./field_headers').headers;
// Name of sheet in XLS file
const SHEET_NAME = 'LIST_REGISTRED_ORGANISATION';

/* ******************************************
 * READ XLS DATA
 */
exports.xls2Json = function(fname) {
	return new Promise( (resolve, reject) => {
		console.log(`xls: Reading ${fname}.xls`);
		var wbook = XLSX.readFile(fname+'.xls');
		console.log("xls: Converting to json...");

		var worksheet = wbook.Sheets[SHEET_NAME];

		// clean data before returning
		let json =
            XLSX.utils
            .sheet_to_json(worksheet, {'header': headers, 'range':1})
            .map(rawMapper);

		resolve(json);
	});
}

function rawMapper(entry) {

	function avg(str) {
		// console.log(str);
		if (str == ">10000000") return 10000000;
		let rs = str.split("-").map( i => parseInt(i) );
		return Math.round((rs[0] + rs[1]) / 2);
	}

	function caseMapper(prop, val) {
		switch (prop) {
			case 'entryDate':  	// convert date into Mongo usable format
				return moment(val, 'D-M-YYYY').format();
			case 'Financial Start':
				return val.replace(/\//g,'-');
			case 'Financial End':
				return val.replace(/\//g,'-');
			case 'interests':
				return val.split(', ');
			case 'noPersons':
				return parseInt(val);
			case 'turnover':
				return parseInt(val);
			case 'costsAbsolute':
				return parseInt(val);
			case 'noEP':
				return parseInt(val);
			case 'noFTEs':
				return parseFloat(val);
			default: return val
		}
	}

	var newEntry = {}
	for (var prop in entry) {
		if (entry[prop] !== "") {
			newEntry[prop] = caseMapper(prop, entry[prop]);
		}
	}
	// Budget / costs ... (costsAbsolute === 0 is a possibility)
	newEntry.budget = (typeof newEntry.costsAbsolute != 'undefined') ? newEntry.costsAbsolute : avg(newEntry.costEst);
	if (isNaN(newEntry.budget)) {
		console.log(newEntry);
		throw new Error("Entry contains no cost data");
	}

	return newEntry;
}
