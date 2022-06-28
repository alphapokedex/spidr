const functions = require('firebase-functions');
const algoliasearch = require('algoliasearch');

const APP_ID = functions.config().algolia.app_id;
const ADMIN_KEY = functions.config().algolia.admin_api_key;

const client = algoliasearch(APP_ID, ADMIN_KEY);
const index = client.initIndex('groupChats');

//functions to update the algolia index 'groupChats', triggered by updates in the firestore collection 'groupChats'

/*
    NOTE: content in algolia indices are exposed client-side
    if data contains sensitive data, exclude it from being sent
*/

exports.addToIndex = functions.firestore.document('groupChats/{documentId}')
    .onCreate(snapshot => {
        const data = snapshot.data();
        const objectID = snapshot.id;
        return index.saveObject({ ...data, objectID });
    });

exports.updateIndex = functions.firestore.document('groupChats/{documentId}')
    .onUpdate(change => {
        const newData = change.after.data();
        const objectID = change.after.id;
        return index.saveObject({ ...newData, objectID });
    })

exports.deleteFromIndex = functions.firestore.document('groupChats/{documentId}')
    .onDelete(snapshot => index.deleteObject(snapshot.id));