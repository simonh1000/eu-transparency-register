/// <reference path="../../typings/node/node.d.ts"/>

"use strict";

var XLSX = require('xlsx');
var fs = require('fs');
var request = require("request");

var headers =
[ "_id"
, "regDate"
, "section"
, "subsection"
, "orgName"
, "legalStatus"
, "website"
, "hqCountry"
, "hqAddress"
, "hqCity"
, "hqPostCode"
, "hqBox"
, "hqPhone"
, "belAddress"
, "belCity"
, "belPostCode"
, "belBox"
, "belPhone"
, "legalPerson"
, "position"
, "euPerson"
, "euPersonPosition"
, "goals"
, "level"
, "initiatives"
, "Relevant communication"
, "High level groups"
, "Consultative committees"
, "Expert groups"
, "Intergroups"
, "forums"
, "noPersons"
, "noFTEs"
, "noEP"
, "epAccrdited"
, "interests"
, "memberships"
, "organisations"
, "Financial Start"
, "Financial End"
, "costsAbsolute"
, "costEst"
, "turnover"
, "turnoverRange"
, "clients"
, "procurement"
, "source"
, "grants"
, "grantsSource"];

var reqoptions = {
	url: "http://ec.europa.eu/transparencyregister/public/consultation/statistics.do?action=getLobbyistsExcel&fileType=XLS_NEW",
	headers: {
		'User-Agent': 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13'
	}
};

const SHEET_NAME = 'LIST_REGISTRED_ORGANISATION';

// Downloads file to drive
function download(fname, cb) {
	return request(reqoptions)
		.on('response', function(response) {
			console.log("Downloading...") // 200
		})
		.on('end', msg => {
			console.log(`Downloading finished. Saved to ${fname}.xls`)
			cb();
		})
		.on('close', msg => {
			console.log("Close", msg);
			cb();
		})
		.pipe(fs.createWriteStream(fname + '.xls'));
}

function writeJson(fname, cb) {
	console.log("Reading data");
	var wbook = XLSX.readFile(fname+'.xls');
	console.log("Converting to json...");

	var worksheet = wbook.Sheets[SHEET_NAME];

	let json = XLSX.utils.sheet_to_json(worksheet, {header:headers, range:1});

	return cb(json);
}

function getJson(fname, cb) {
	download(fname, () => writeJson(fname, cb) );
};

// download(writeJson);
// writeJson(fname, cb);

exports.updateAll = getJson;
exports.test = writeJson;




// function rewriteHeaders(sheet) {
//
// 	headers.forEach( (newHeader, col) => {
// 		/* Find desired cell */
// 		/* find the cell object */
// 		let cellId = {c:col, r:0}
// 		let cellref = XLSX.utils.encode_cell(cellId); // construct reference for cell
// 		if(!sheet[cellref])
// 			throw "cell doesn't exist";
//
// 		let cell = sheet[cellref];
//
// 		/* if the cell is a text cell with the old string, change it */
// 		// if(!(cell.t == 's' || cell.t == 'str')) continue; // skip if cell is not text
// 		// if(cell.v === oldtext) cell.v = newtext; // change the cell value
// 		console.log(`Set ${JSON.stringify(cellId)} to ${newHeader}`);
// 		cell.v = newHeader; // change the cell value
// 	});
// 	return sheet;
// }
// request(reqoptions, function (error, response, body) {
// 	if (error) throw error;
// 	// console.log(response);
//
// 	if (response.statusCode == 200) {
// 		// console.log(body) //
//
// 		var data = new Uint8Array(body);
// 	    var arr = new Array();
// 	    for(var i = 0; i != data.length; ++i) arr[i] = String.fromCharCode(data[i]);
// 	    var bstr = arr.join("");
// 		console.log(bstr);
// 		var workbook = XLSX.read(body, {type:"binary"});
// 		// let json = writeJson(workbook);
// 		// console.log(json[1]);
// 	}
// });
// setTimeout(function() {
// 	console.log("I waited");
// }, 100000);

// let json = writeJson(workbook);
// fs.writeFileSync(fname+'_out.json', JSON.stringify(json));

/*
*  // node_modules/xlsx/bin/xlsx.njs -j parser/export.xls -o parser/output.json
*/
