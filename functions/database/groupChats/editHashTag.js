const functions = require('firebase-functions');
const admin = require('firebase-admin');
const mediaCollection = admin.firestore().collection('mediaItems');

exports.editGroupHashTag = functions.firestore.document('groupChats/{documentId}')
    .onUpdate(snap => {
      const doc = snap.after.data()
      const groupId = snap.after.id
      const hashTag = doc.hashTag

      mediaCollection.where('groupId', "==", groupId)
        .get().then((mediaQS) => {
          mediaQS.forEach((mediaDS) => {
            mediaCollection.doc(mediaDS.id).update({'hashTag':hashTag})
          })
          return;
      }).catch(error => {
        console.log("mediaItems:", error)
      })

      return;
    })
