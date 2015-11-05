var express = require('express');
var router = express.Router();
var controller = require('./controller');
// var ingester = require("./ingester");
// var processor = require("./processor");

router.get('/id/:id', controller.id);
router.get('/search', controller.search);
router.get('/interests', controller.interests);
router.get('/sections', controller.sections);
// router.get('/ingest',	ingester.index);            // copies into database
// router.get('/countinterests', processor.index);     // calculates data for summary table

module.exports = router;
