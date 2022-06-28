const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');


exports.sendGroupSnippetNotif= functions
  .firestore.document('users/{userId}/groups/{groupId}/stories/{storyId}')
  .onCreate((snap, context) => {

    const doc = snap.data()

    const senderId = doc.senderId
    const anon = doc.anon
    const storyId = doc.storyId
    const toId = doc.toId
    const groupId = doc.groupId

    if(senderId !== toId){
        userCollection.doc(senderId).get().then(sender => {
          var name = !anon ? sender.data().name : "Anonymous"

          admin.firestore().collection('groupChats').doc(groupId).get().then(group => {
            const hashTag = group.data().hashTag

            userCollection.doc(toId).get().then(user => {
              const hoppedOn = user.data().hoppedOn
              const notifOff = user.data().notifOff

              if(hoppedOn && (notifOff === undefined || !notifOff)){
                const payload = {
                      notification: {
                        title: "Your Circle" +hashTag,
                        body: "just received a broadcast from " + name,
                        badge: '1',
                        sound: 'default'
                      },
                      data: {
                        click_action: `FLUTTER_NOTIFICATION_CLICK`,
                        sound: `default`,
                        status: `done`,
                        screen: `groupSnippet`,
                        groupId: groupId,
                        storyId: storyId,
                      }
                    }

                    admin.messaging()
                      .sendToDevice(user.data().pushToken, payload)
                      .then(response => {
                        console.log('Successfully sent message:', response)
                        return;
                      }).catch(error => {
                        console.log('Error sending message:', error)
                      }
                    )
              }else{
                console.log("user is hopped off")
              }
              return;
            }).catch(error => {
              console.log("users:", error)
            })
            return;
          }).catch(error => {
            console.log('groupChats:', error)
          })
          return;
        }).catch(error => {
          console.log('groupChats:', error)
        })
    }


    return null
  })

//exports.sendGroupSnippetNotif= functions
//  .firestore.document('groupChats/{groupId}/stories/{storyId}')
//  .onCreate((snap, context) => {
//
//    const doc = snap.data()
//
//    const groupId = doc.groupId
//    const senderId = doc.senderId
//    const anon = doc.anon
//    const type = doc.type
//    const storyId = doc.storyId
//
//    admin.firestore().collection('users').doc(senderId).get().then(sender => {
//      var name = !anon ? sender.data().name : "Anonymous"
//      const blockList = sender.data().blockList
//      const blockedBy = sender.data().blockedBy
//
//      admin.firestore().collection('groupChats').doc(groupId).get().then(group => {
//        const hashTag = group.data().hashTag
//        const members = group.data().members
//
//        members.forEach(userId => {
//          if (userId !== senderId && blockList.includes(userId) === false && blockedBy.includes(userId) === false) {
//
//            admin.firestore().collection('users').doc(userId).get().then(user => {
//              const hoppedOn = user.data().hoppedOn
//              if(hoppedOn){
//                const payload = {
//                      notification: {
//                        title: type === "regular" ? name : hashTag,
//                        body: type === "regular" ? "sent a snippet to " + hashTag : "received a snippet from " + name,
//                        badge: '1',
//                        sound: 'default'
//                      },
//                      data: {
//                        click_action: `FLUTTER_NOTIFICATION_CLICK`,
//                        sound: `default`,
//                        status: `done`,
//                        screen: `groupSnippet`,
//                        groupId: groupId,
//                        storyId: storyId,
//                      }
//                    }
//
//                    admin.messaging()
//                      .sendToDevice(user.data().pushToken, payload)
//                      .then(response => {
//                        console.log('Successfully sent message:', response)
//                        return;
//                      }).catch(error => {
//                        console.log('Error sending message:', error)
//                      }
//                    )
//              }else{
//                console.log("user is hopped off")
//              }
//              return;
//            }).catch(error => {
//              console.log("users:", error)
//            })
//            return;
//          } else {
//            console.log('can not send to msg sender')
//          }
//        })
//        return;
//
//      }).catch(error => {
//        console.log('groupChats:', error)
//      })
//      return;
//    }).catch(error => {
//      console.log('groupChats:', error)
//    })
//    return null
//  })
