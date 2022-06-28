const admin = require('firebase-admin');
admin.initializeApp()

//include algolia functions
exports.algolia = require('./algolia');

//include fcm functions
exports.fcm = require('./fcm');

//include database functions
exports.database = require('./database');


// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
