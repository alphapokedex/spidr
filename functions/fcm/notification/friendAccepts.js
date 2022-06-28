const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendFriendAcceptNotification = functions
  .firestore.document('users/{userId}/friends/{friendId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const acceptor = doc.acceptor
    const friendId = doc.friendId

    if (acceptor !== undefined) {

      admin.firestore()
        .collection('users')
        .doc(friendId)
        .get()
        .then(userTo => {

          const hoppedOn = userTo.data().hoppedOn
          const notifOff = userTo.data().notifOff
          if(hoppedOn && (notifOff === undefined || !notifOff)){
            const payload = {
              notification: {
                title: acceptor,
                body: "has accepted your friend request",
                badge: '1',
                sound: 'default'
              },
              data: {
               click_action: `FLUTTER_NOTIFICATION_CLICK`,
               sound: `default`,
               status: `done`,
               screen: `myFriends`,
             }
            }

            admin.messaging()
              .sendToDevice(userTo.data().pushToken, payload)
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
    }
    return null
  })