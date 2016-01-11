'use strict';

let mailgunOptions = {
	apiKey: process.env.MAILGUN_KEY,
	domain: process.env.MAILGUN_DOMAIN
};
var mailgun = require('mailgun-js')(mailgunOptions);

// console.log(mailgunOptions);

exports.sendEmail = function(email, comment) {
    return new Promise(function(resolve, reject) {
        var data = {
            from: '<me@tcxeditor.mailgun.org>',
            to: 'hotbelgo@gmail.com',
            subject: 'EU Lobby Register comment',
            text: "From: " + email + " Message: "+ comment
        };

        mailgun.messages()
        .send(data, function (err, body) {
            if (err) return reject(err);
            return resolve(body);
        });
    });
};
