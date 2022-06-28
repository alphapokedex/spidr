const functions = require('firebase-functions');
const algoliasearch = require('algoliasearch');

const APP_ID = functions.config().algolia.app_id;
const ADMIN_KEY = functions.config().algolia.admin_api_key;

const client = algoliasearch(APP_ID, ADMIN_KEY);
const index = client.initIndex('mediaItems');

//functions to update the algolia index 'mediaItems', triggered by updates in the firestore collection 'mediaItems'

/*
    NOTE: content in algolia indices are exposed client-side
    if data contains sensative data, exclude it from being sent
*/


exports.addToIndex = functions.firestore.document('mediaItems/{documentId}')
    .onCreate(snapshot => {
        const mediaItem = snapshot.data();
        mediaItem.objectID = snapshot.id;
        index.saveObject(mediaItem);
        console.log('Finished');
    });

exports.updateIndex = functions.firestore.document('mediaItems/{documentId}')
    .onUpdate(change => {
        const newData = change.after.data();
        const objectID = change.after.id;
        return index.saveObject({ ...newData, objectID });
    })

exports.deleteFromIndex = functions.firestore.document('mediaItems/{documentId}')
    .onDelete(snapshot => index.deleteObject(snapshot.id));