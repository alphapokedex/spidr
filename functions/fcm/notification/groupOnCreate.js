const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');

exports.sendGroupCreateNotification = functions
  .firestore.document('groupChats/{groupId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const groupState = doc.chatRoomState

    if(groupState !== "invisible"){
      const groupId = snap.id
      const hashTag = doc.hashTag
      const oneDay = doc.oneDay

      const anon = doc.anon

      const adminId = doc.admin
      const adminName = doc.adminName

      userCollection.doc(adminId).get().then(adminUser => {

        const friends = adminUser.data().friends

        if(friends !== undefined){
          friends.forEach(friendId => {
            userCollection.doc(friendId).get().then(user => {

              const hoppedOn = user.data().hoppedOn
              const notifOff = user.data().notifOff

              const blockList = user.data().blockList !== undefined ? user.data().blockList : []

              if(hoppedOn && (notifOff === undefined || !notifOff)){
                if(!blockList.includes(adminId)){

                  const payload = {
                        notification: {
                          title: !anon ? adminName : "One of your friends",
                          body: !oneDay ?
                          !anon ? "just created a circle" : "just created an anonymous circle" :
                          !anon ? "just started a 24hr conversation " : "just started an anonymous 24hr conversation ",
                          badge: '1',
                          sound: 'default'
                        },
                        data: {
                          click_action: `FLUTTER_NOTIFICATION_CLICK`,
                          sound: `default`,
                          status: `done`,
                          screen: `groupProfile`,
                          groupId: groupId,
                          adminId: adminId,
                        }
                      }

                      admin.messaging()
                        .sendToDevice(user.data().pushToken, payload)
                        .then(response => {
                          console.log('Successfully sent notification to ' + user.data().name, response)
                          return;
                        }).catch(error => {
                          console.log('Error sending message:', error)
                        }
                      )

                }
              }

              return;
            }).catch(error => {
              console.log("friend:", error)
            })

          })
        }

        return;
      }).catch(error => {
        console.log("admin:", error)
      })

    }
    return;
  })