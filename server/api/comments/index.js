/*
 * 'register' = all current data _id = EU Id
 * 'history' = previous data _id = EU Id
 * 'changes' = [{_id, orgName}] _id = date
 * 'summary' = .... _id = ['interests', 'sections']
 */

var express = require('express');
var router = express.Router();

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
    coll.insertOne(req.body)
    .then(
        () => res.status(200).send({success:true}),
        e => res.status(500).send(e)
    );
});


module.exports = router;
