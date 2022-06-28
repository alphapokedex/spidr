//This is a script to index all exisiting firestore collection data into the respective algolia index.
//This should only be done once per collection


/*
script requires the following available environemnt variables:

INDEXING - set to 1 to allow script to run
COLLECTION_NAME - the name of the firestore collection to import to algolia
INDEX_NAME - the name of the algolia index to upload to

run `firebase functions:config:get > .runtimeconfig.json` to make config variable available in local environment
*/

const algoliasearch = require('algoliasearch');
const firebase = require('firebase');
const functions = require('firebase-functions');
const firestore = require('firebase/firestore');

if (!process.env.INDEXING) {// protect from accidental use, must set INDEXING environment variable to true
    console.log("Script did not execute: must set environment variable INDEXING=true");
    process.exit(0);
}

const APP_ID = functions.config().algolia.app_id;
const ADMIN_KEY = functions.config().algolia.admin_api_key;

const COLLECTION_NAME = process.env.COLLECTION_NAME;  //set to the collections you want to send to algolia
const FIREBASE_PROJECT_ID = "spidr-release";

firebase.initializeApp({
    projectId: FIREBASE_PROJECT_ID,
    databaseURL: `https://${FIREBASE_PROJECT_ID}.firebaseio.com`,
});

const db = firebase.firestore();

const algolia = algoliasearch(APP_ID, ADMIN_KEY);
const index = algolia.initIndex(process.env.INDEX_NAME);

const records = [];
db.collection(COLLECTION_NAME).get().then(snapshot => {
    snapshot.forEach(doc => {
        const docData = doc.data();
        docData.objectID = doc.id;

        records.push(docData);
        console.log(`document ${doc.id} fetched`);
    });
    return Promise.resolve();
}).then(() => {
    index.saveObjects(records).then(() => {
        console.log('\nDocuments imported to Algolia');
        return Promise.resolve();
    }).catch(error => {
        console.error('Error importing documents into Algolia', error);
        process.exit(1);
    });
    return Promise.resolve();
}).catch(error => {
    console.error("Error getting documents", error);
    process.exit(1);
})


