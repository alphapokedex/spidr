const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendGroupNotification = functions
  .firestore.document('groupChats/{groupId}/chats/{chatId}')
  .onCreate((snap, context) => {

    const doc = snap.data()

    const message = doc.message
    const senderId = doc.userId
    const group = doc.group
    var sender = doc.sendBy
    const imgObj = doc.imgObj
    const fileObj = doc.fileObj
    const mediaGallery = doc.mediaGallery

    const groupId = group.substring(0, group.indexOf('_'))
    const hashTag = group.substring(group.indexOf('_') + 1)

    const ogSenderId = doc.ogSenderId

    admin.firestore().collection('groupChats').doc(groupId).get().then(group => {
      const anon = group.data().anon
      const groupState = group.data().chatRoomState
      sender = anon === null || !anon ? sender : "Anonymous"
      const members = group.data().members
      const spectators = Object.keys(group.data().waitList)

      const allUsers = groupState !== "private" ? members.concat(spectators) : members

      allUsers.forEach(userId => {
        if (userId !== senderId) {
          admin.firestore().collection('users').doc(userId).get().then(user => {
            const hoppedOn = user.data().hoppedOn
            const notifOff = user.data().notifOff

            const blockList = user.data().blockList !== undefined ? user.data().blockList : []
            const mutedChats = user.data().mutedChats !== undefined ? user.data().mutedChats : []

            if(hoppedOn && (notifOff === undefined || !notifOff)){
              if(ogSenderId === null || !blockList.includes(ogSenderId)){
                  if(!blockList.includes(senderId)){
                    if(!mutedChats.includes(groupId)){
                        const payload = {
                              notification: {
                                title: hashTag,
                                body: mediaGallery !== null ? sender + " sent a media gallery" :
                                fileObj !== null ? sender + ": " + fileObj.fileName :
                                imgObj !== null ? sender + ": " + imgObj.imgName :
                                sender + ": " + message,
                                badge: '1',
                                sound: 'default'
                              },
                              data: {
                                click_action: `FLUTTER_NOTIFICATION_CLICK`,
                                sound: `default`,
                                status: `chat`,
                                screen: `groupChat`,
                                groupId: groupId,
                                hashTag: hashTag,
                                msgId:''
                              }
                            }

                            admin.messaging()
                              .sendToDevice(user.data().pushToken, payload)
                              .then(response => {
                                console.log('Successfully sent message to ' + user.data().name, response)
                                return;
                              }).catch(error => {
                                console.log('Error sending message:', error)
                              }
                            )
                      }else{
                        console.log(user.data().name + " muted " + hashTag)
                      }
                    }else{
                      console.log(sender + " blocked by " + user.data().name)
                    }

              }
            }

            return;
          }).catch(error => {
            console.log("users:", error)
          })
          return;
        } else {
          console.log('can not send to msg sender')
        }
      })
      return;

    }).catch(error => {
      console.log('groupChats:', error)
    })
    return null
  })