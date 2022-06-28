const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendPersonalSnippetNotif = functions
  .firestore.document('users/{userId}/recStories/{storyId}')
  .onCreate((snap, context) => {

    const doc = snap.data()

    const type = doc.type
    const storyId = doc.storyId
    const senderId = doc.senderId
    const anon = doc.anon
    const toId = doc.toId

    admin.firestore().collection('users').doc(senderId).get().then(sender => {
      var name = !anon ? sender.data().name : "Anonymous"

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
                title: type === "friends" ? name : "Hey!",
                body: type === "friends" ? "sent a broadcast to their friends" : "You just received a broadcast from "+name,
                badge: '1',
                sound: 'default'
              },
              data: {
                click_action: `FLUTTER_NOTIFICATION_CLICK`,
                sound: `default`,
                status: `done`,
                screen: `personalSnippet`,
                storyId: storyId,
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
