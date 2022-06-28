const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendPersonalNotification = functions
  .firestore.document('personalChats/{personalChatId}/messages/{messageId}')
  .onCreate((snap, context) => {

    const doc = snap.data()

    const toId = doc.sendTo
    if (toId !== null) {
      const ogSenderId = doc.ogSenderId
      const personalChatId = doc.personalChatId


      admin.firestore()
        .collection('users')
        .doc(toId)
        .get()
        .then(userTo => {

          const hoppedOn = userTo.data().hoppedOn
          const notifOff = userTo.data().notifOff
          const blockList = userTo.data().blockList !== undefined ? userTo.data().blockList : []
          const mutedChats = userTo.data().mutedChats !== undefined ? userTo.data().mutedChats : []

          if(hoppedOn && (notifOff === undefined || !notifOff)){
            if(!mutedChats.includes(personalChatId) && !mutedChats.includes(groupId)){
              if(ogSenderId === null || !blockList.includes(ogSenderId)){
                const group = doc.group

                var groupId = ''
                var hashTag = ''

                if(group !== undefined){
                  groupId = group.substring(0, group.indexOf('_'))
                  hashTag = group.substring(group.indexOf('_') + 1)
                }

                  const msgId = doc.msgId
                  const text = doc.text
                  const imgMap = doc.imgMap
                  const fileMap = doc.fileMap
                  const mediaGallery = doc.mediaGallery
                  const sender = doc.sender
                  const senderId = doc.senderId

                  const payload = {
                    notification: {
                      title: group === undefined ? sender : hashTag,
                      body: group === undefined ? mediaGallery !== null ? "media gallery" : fileMap !== null ? fileMap.fileName : imgMap === null ? text : imgMap.imgName : sender + " replied to your message",
                      badge: '1',
                      sound: 'default'
                    },
                    data: {
                      click_action: `FLUTTER_NOTIFICATION_CLICK`,
                      sound: `default`,
                      status: `chat`,
                      screen: group === undefined ? `personalChat` : `groupChat`,
                      personalChatId: group === undefined ? personalChatId : '',
                      contactId: senderId,
                      contactName: sender,
                      groupId: groupId,
                      hashTag: hashTag,
                      msgId:msgId !== undefined ? msgId : ''
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

              }

            }

          }

        return;
      }).catch(error => {
        console.log('Error finding user:', error)
      })
    }
    return null
  })