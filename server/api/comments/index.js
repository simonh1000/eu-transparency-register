/*
 */

'use strict';

var express = require('express');
var router = express.Router();
var mailgun = require('./mailgun')

var coll;

const COMMENTS = 'comments';

require('./mongo').index(COMMENTS)
.then( mongoCollection => coll = mongoCollection )
.catch( err => console.error("******", err) );

// var controller = require('./controller')(mongodb);

router.get('/', (req, res) => {
    // console.log("get");
    coll.find({}, {'_id':0, 'email':0})
    .toArray()
    .then(
        d => res.send(d),
        e => res.status(500).send(e)
    );
});

router.post('/', (req, res) => {
    console.log("post", req.body);
    let comment = req.body;
    coll.insertOne(comment)
    .then(
        () => {
            mailgun.sendEmail(comment.email, comment.comment)
            .catch( err => console.log(err) ); // don't need to wait for Promise
            
            res.status(200).send({success:true})
        },
        e => res.status(500).send(e)
    );
});


module.exports = router;
