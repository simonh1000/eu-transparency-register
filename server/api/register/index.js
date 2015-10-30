var express = require('express');
var router = express.Router();
var controller = require('./controller');
// var ingester = require("./ingester");

router.get('/id/:id', controller.id);
router.get('/search', controller.search);
router.get('/interests', controller.interests);
// router.get('/ingest',	ingester.index); 		// copies into database

module.exports = router;
