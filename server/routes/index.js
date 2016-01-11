var express = require('express');
var router = express.Router();
var path = require('path');

var apiregister = require('../api/register');
var comments = require('../api/comments');

module.exports = function (app) {
    app.use('/api/register', apiregister);
    app.use('/api/comments', comments);

    app.use(express.static(path.join(__dirname, '../../dist')));

    app.route('/*').get(function(req, res, next) {
        res.sendFile(path.join(__dirname, '../../dist/index.html'));
    });
}

// module.exports = router;
