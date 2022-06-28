const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendSnippetCommentNotif = functions
  .firestore.document('story_comments/{storyId}/comments/{commentId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const storySenderId = doc.storySenderId
    const sender = doc.sender
    const storyId = doc.storyId

    admin.firestore().collection('users').doc(storySenderId).get().then(user => {
      const hoppedOn = user.data().hoppedOn
      const notifOff = user.data().notifOff

      if(hoppedOn && (notifOff === undefined || !notifOff)){
        const payload = {
            notification: {
              title: sender,
              body: 'just commented on your broadcast',
              badge: '1',
              sound: 'default'
            },
            data: {
              click_action: `FLUTTER_NOTIFICATION_CLICK`,
              sound: `default`,
              status: `chat`,
              screen: `snippet_comment`,
              storyId: storyId
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
      }
      return;
    }).catch(error => {
      console.log("users:", error)
    })

    return;
  })