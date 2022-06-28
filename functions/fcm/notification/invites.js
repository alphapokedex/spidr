const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendInviteNotification = functions
  .firestore.document('users/{userId}/invites/{inviteId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const toId = doc.toId

    if (toId !== null) {
      const invitor = doc.invitorName
      const hashTag = doc.hashTag

      admin.firestore()
        .collection('users')
        .doc(toId)
        .get()
        .then(userTo => {

          const hoppedOn = userTo.data().hoppedOn
          const notifOff = userTo.data().notifOff

          if(hoppedOn && (notifOff === undefined || !notifOff)){
            const payload = {
              notification: {
                title: invitor,
                body: "Invited you to " + hashTag,
                badge: '1',
                sound: 'default'
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

