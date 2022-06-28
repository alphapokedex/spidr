const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const groupChatCollection = admin.firestore().collection('groupChats');

removeNewMsg = function(userId, groupId, chatId){

  userCollection.doc(userId).collection('groups').doc(groupId).get().then(userGroup => {

    var numOfNewMsg = userGroup.data().numOfNewMsg
    var newMsg = userGroup.data().newMsg !== undefined ? userGroup.data().newMsg : []
    if(newMsg.includes(chatId)){
        numOfNewMsg = numOfNewMsg !== undefined ? numOfNewMsg - 1 : 0
        newMsg = newMsg.filter(id => id !== chatId)
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

exports.deleteGroupChat = functions.firestore.document('groupChats/{groupId}/chats/{chatId}')
    .onDelete(snap => {

      const chatId = snap.id

      const doc = snap.data()
      const senderId = doc.userId
      const group = doc.group

      const groupId = group.substring(0, group.indexOf('_'))

      groupChatCollection.doc(groupId).get().then(group => {
        const members = group.data().members
        const spectators = group.data().waitList
        const groupState = group.data().chatRoomState

        members.forEach(memberId => {
          if(memberId !== senderId){
            removeNewMsg(memberId, groupId, chatId)
          }
        })

        if(groupState !== "private"){
          for(var spectatorId in spectators){
            removeNewMsg(spectatorId, groupId, chatId)
          }
        }

        return;
      }).catch(error => {
        console.log('groupChat:', error)
      })

      return;
    })