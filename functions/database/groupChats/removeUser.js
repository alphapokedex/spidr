const helperFunctions = require('./helperFunctions.js')

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');

exports.removeMember = functions.firestore.document('groupChats/{groupId}/users/{userId}')
    .onDelete(snap => {
      const doc = snap.data()
      const userId = snap.id
      const groupId = doc.groupId

//      helperFunctions.delUserGroupFeed(userId, groupId, 'groups')
      helperFunctions.delUserGroupStory(userId, groupId)
      return;
    })

exports.removeSpectator = functions.firestore.document('groupChats/{groupId}/spectators/{spectatorId}')
    .onDelete(snap => {
      const doc = snap.data()
      const userId = snap.id
      const groupId = doc.groupId

//      helperFunctions.delUserGroupFeed(userId, groupId, 'spectating')
      helperFunctions.delUserGroupStory(userId, groupId)
      return;
    })
