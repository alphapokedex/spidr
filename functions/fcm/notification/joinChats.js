const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendJoinNotification = functions
  .firestore.document('groupChats/{groupId}/users/{userId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const userId = doc.userId
    const hashTag = doc.hashTag

    admin.firestore().collection('users').doc(userId).get().then(user => {
        const hoppedOn = user.data().hoppedOn
        const notifOff = user.data().notifOff
        if(hoppedOn && (notifOff === undefined || !notifOff)){
          const payload = {
                notification: {
                  title: "Yay!",
                  body: "You are now a member of " + hashTag,
                  badge: '1',
                  sound: 'default'
                }
              }

              admin.messaging()
                .sendToDevice(user.data().pushToken, payload)
                .then(response => {
                  console.log('Successfully sent message:', response)
                  return;
                }).catch(error => {
                  console.log('Error sending message:', error)
                })

        }else{
          console.log("user is hopped off")
        }
      return;
      }).catch(error => {
        console.log('Error finding user:', error)
      })


    return null;
  })
