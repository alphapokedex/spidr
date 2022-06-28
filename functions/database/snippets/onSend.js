const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const groupChatCollection = admin.firestore().collection('groupChats');

exports.sendSenderStory = functions.firestore.document('users/{userId}/stories/{storyId}')
    .onUpdate(snap => {
      const doc = snap.after.data()
      const storyId = snap.after.id

      const senderId = doc.senderId
      const recGroups = doc.recGroups
      const recUsers = doc.recUsers
      delete doc.recGroups
      delete doc.recUsers
      delete doc.seenList

      doc.storyId = storyId

      userCollection.doc(senderId).get().then(sender => {
        const blockedBy = sender.data().blockedBy !== undefined ? sender.data().blockedBy : []
        const blockList = sender.data().blockList !== undefined ? sender.data().blockList : []

        if(recUsers !== undefined){
          recUsers.forEach(userId => {
            if(userId !== senderId && !blockedBy.includes(userId) && !blockList.includes(userId)){
              var storyInfo = Object.assign({}, doc)
              storyInfo.toId = userId
              userCollection.doc(userId).collection('recStories')
                .doc(storyId)
                .set(storyInfo)
            }
          })
        }

        if(recGroups !== undefined){
          recGroups.forEach(groupId => {
            groupChatCollection.doc(groupId).get().then(group => {
              const groupDoc = group.data()
              const members = groupDoc.members
              const groupState = groupDoc.chatRoomState

              doc.groupId = groupId

              members.forEach(memberId => {
                if(!blockedBy.includes(memberId) && !blockList.includes(memberId)){
                  var storyInfo = Object.assign({}, doc)
                  storyInfo.toId = memberId
                  userCollection.doc(memberId).collection('groups')
                    .doc(groupId)
                    .collection("stories")
                    .doc(storyId)
                    .set(storyInfo)
                }
              })

              if(groupState === "public"){
                const waitList = groupDoc.waitList
                for(var spectator in waitList){
                  if(blockedBy.includes(spectator) === false && blockList.includes(spectator) === false){
                    userCollection.doc(spectator).collection('groups')
                      .doc(groupId)
                      .collection("stories")
                      .doc(storyId)
                      .set(doc)
                  }
                }
              }
              return;
            }).catch(error => {
              console.log('recGroups:', error)
            })
          })
        }

        return;
      }).catch(error => {
        console.log('sender:', error)
      })

      return;
    })