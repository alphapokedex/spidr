const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendFriendSnippetNotif = functions
  .firestore.document('users/{userId}/friends/{friendId}/stories/{storyId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const senderId = doc.senderId
    const friendId = doc.friendId
    const storyId = doc.storyId

    admin.firestore()
      .collection('users')
      .doc(senderId)
      .get()
      .then(sender => {
        const name = sender.data().name

        admin.firestore().collection('users').doc(friendId).get().then(userTo => {
          const hoppedOn = userTo.data().hoppedOn
          const notifOff = userTo.data().notifOff

          if(hoppedOn && (notifOff === undefined || !notifOff)){
            const payload = {
              notification: {
                title: "HEY!",
                body: "You received a broadcast from" +name,
                badge: '1',
                sound: 'default'
              },
              data: {
                click_action: `FLUTTER_NOTIFICATION_CLICK`,
                sound: `default`,
                status: `done`,
                screen: `friendSnippet`,
                senderId: senderId,
                storyId: storyId
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

        return;
      }).catch(error => {
        console.log('Error finding user:', error)
      })

    return;
  })