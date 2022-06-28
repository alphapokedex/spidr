const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendFriendRequestNotification = functions
  .firestore.document('users/{userId}/friendRequests/{friendId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const userId = doc.userId

    if (userId !== null) {
      const requester = doc.requester

      admin.firestore()
        .collection('users')
        .doc(userId)
        .get()
        .then(userTo => {

          const hoppedOn = userTo.data().hoppedOn
          const notifOff = userTo.data().notifOff

          if(hoppedOn && (notifOff === undefined || !notifOff)){
            const payload = {
              notification: {
                title: requester,
                body: "just sent you a friend request",
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