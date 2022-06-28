const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const groupChatCollection = admin.firestore().collection('groupChats');

exports.deleteSenderStory = functions.firestore.document('users/{userId}/stories/{storyId}')
    .onDelete(snap => {
      const doc = snap.data()
      const storyId = snap.id
      const type = doc.type
      const senderId = doc.senderId

      if(type === "regular"){
        const recGroups = doc.recGroups
        const recFriends = doc.recFriends

        recGroups.forEach(groupId => {
          groupChatCollection.doc(groupId).collection('stories').doc(storyId).delete()
        })

        recFriends.forEach(friendId => {
          userCollection.doc(friendId)
              .collection('friends')
              .doc(senderId)
              .collection('stories')
              .doc(storyId)
              .delete();
        })
      }else if(type === "friends"){
        userCollection.doc(senderId).get().then(sender => {
          const friends = sender.data().friends
          friends.forEach(friendId => {
            userCollection.doc(friendId).collection('recStories').doc(storyId).delete()
          })
          return;
        }).catch(error => {
          console.log("mediaItems:", error)
        })

      }else{
        const recGroups = doc.recGroups
        const recUsers = doc.recUsers

        recGroups.forEach(groupId => {
//          groupChatCollection
//            .doc(groupId)
//            .collection('stories')
//            .doc(storyId)
//            .delete()

          groupChatCollection.doc(groupId).get().then(group =>{
            const groupDoc = group.data()

            const members = groupDoc.members
            const groupState = groupDoc.chatRoomState

            members.forEach(userId => {
              userCollection.doc(userId)
                .collection('groups')
                .doc(groupId)
                .collection('stories')
                .doc(storyId)
                .delete()
            })

            if(groupState === "public"){
              const waitList = groupDoc.waitList
              for(var userId in waitList){
                userCollection.doc(userId)
                  .collection('groups')
                  .doc(groupId)
                  .collection('stories')
                  .doc(storyId)
                  .delete()
              }
            }

            return;
          }).catch(error => {
            console.log("group:", error)
          })


        })

        recUsers.forEach(userId => {
          userCollection.doc(userId)
            .collection('recStories')
            .doc(storyId)
            .delete()
        })
      }
      return;
    })
