const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const groupChatCollection = admin.firestore().collection('groupChats');

updateNewMsg = function(userId, groupId, chatId){

  userCollection.doc(userId).collection('groups').doc(groupId).get().then(userGroup => {

    if(!userGroup.data().inChat){
      var numOfNewMsg = userGroup.data().numOfNewMsg
      var newMsg =  userGroup.data().newMsg !== undefined ? userGroup.data().newMsg : []

      numOfNewMsg = numOfNewMsg !== undefined ? numOfNewMsg + 1 : 1
      newMsg.push(chatId)

      userCollection.doc(userId)
        .collection('groups')
        .doc(groupId)
        .update({'numOfNewMsg':numOfNewMsg,'newMsg':newMsg})
    }

    return;
  }).catch(error => {
    console.log('userGroup:', error)
  })
}

exports.sendGroupChat = functions.firestore.document('groupChats/{groupId}/chats/{chatId}')
    .onCreate(snap => {

      const chatId = snap.id

      const doc = snap.data()
      const senderId = doc.userId
      const group = doc.group

      const groupId = group.substring(0, group.indexOf('_'))

      groupChatCollection.doc(groupId).get().then(group => {
        const members = group.data().members
        const spectators = group.data().waitList
        const groupState = group.data().chatRoomState

        userCollection.doc(senderId).get().then(user => {
          const blockedBy = user.data().blockedBy !== undefined ? user.data().blockedBy : []

          members.forEach(memberId => {
            if(memberId !== senderId && !blockedBy.includes(memberId)){
              updateNewMsg(memberId, groupId, chatId)
            }
          })

          if(groupState !== "private"){
            for(var spectatorId in spectators){
              if(!blockedBy.includes(spectatorId)){
                updateNewMsg(spectatorId, groupId, chatId)
              }
            }
          }
          return;
        }).catch(error => {
          console.log('user:', error)
        })
        return;
      }).catch(error => {
        console.log('groupChat:', error)
      })

      return;
    })