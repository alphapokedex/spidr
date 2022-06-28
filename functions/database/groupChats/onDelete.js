const helperFunctions = require('./helperFunctions.js');

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const mediaCollection = admin.firestore().collection('mediaItems');


exports.deleteGroup = functions.firestore.document('groupChats/{documentId}')
    .onUpdate(snap => {
      const doc = snap.after.data()
      const deleted = doc.deleted

      if(deleted === true){
        const groupId = snap.after.id
        const groupState = doc.chatRoomState
        const members = doc.members
        const waitList = doc.waitList

        members.forEach(userId => {
          userCollection.doc(userId).collection('groups').doc(groupId).delete()
          helperFunctions.delUserGroupStory(userId, groupId)
        })

        if(groupState !== "private"){
          for(var userId in waitList){
            userCollection.doc(userId).collection('groups').doc(groupId).delete()
            if(groupState === "public"){
              helperFunctions.delUserGroupStory(userId, groupId)
            }
          }
        }

        mediaCollection.where('groupId', "==", groupId)
          .get().then((mediaQS) => {
            mediaQS.forEach((mediaDS) => {
              mediaCollection.doc(mediaDS.id).delete()
            })
            return;
        }).catch(error => {
          console.log("mediaItems:", error)
        })

      }

      return;
    })
