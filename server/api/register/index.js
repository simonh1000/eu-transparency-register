/*
 * 'register' = all current data _id = EU Id
 * 'history' = previous data _id = EU Id
 * 'changes' = [{_id, orgName}] _id = date
 * 'summary' = .... _id = ['interests', 'sections']
 */

var express = require('express');
var router = express.Router();
var controller = require('./controller');
var ingester = require("./ingester");
// var processor = require("./processor");

router.get('/meta', controller.meta);           // returns count of register
router.get('/summary', controller.summary);
router.get('/recents', controller.newentries);

router.get('/id/:id', controller.id);
router.get('/search', controller.search);

// router.get('/ingest',	ingester.index);            // copies into database, and then runs post-processors

module.exports = router;
