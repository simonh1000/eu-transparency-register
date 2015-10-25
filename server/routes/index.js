var express = require('express');
var router = express.Router();
var path = require('path');

var apidefault = require('../api/default');

module.exports = function (app) {
    app.use('/api/default', apidefault);

    app.use(express.static(path.join(__dirname, '../public')));

    app.route('/*').get(function(req, res, next) {
        res.sendFile(path.join(__dirname, '../public/index.html'));
    });
}

// module.exports = router;
