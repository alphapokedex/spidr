const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const groupChatCollection = admin.firestore().collection('groupChats');

exports.sendGroupCallNotification = functions
  .firestore.document('groupChats/{groupId}')
  .onUpdate((snap, context) => {

    const docBefore = snap.before.data()
    const docAfter = snap.after.data()

    const groupId = snap.after.id

    const inCallUsersBe = docBefore.inCallUsers !== undefined ? docBefore.inCallUsers : {}
    const inCallUsersAf = docAfter.inCallUsers

    if(Object.keys(inCallUsersBe).length === 0 && Object.keys(inCallUsersAf).length > 0){

        groupChatCollection.doc(groupId).get().then(group => {
          const anon = group.data().anon
          const members = group.data().members
          const hashTag = group.data().hashTag
          const uid = Object.keys(inCallUsersAf)[0]
          const callerId = inCallUsersAf[uid]['userId']

          userCollection.doc(callerId).get().then(caller =>{
            const callerName = !anon ? caller.data().name : "Anonymous"

            members.forEach(memberId => {
              userCollection.doc(memberId).get().then(user => {
               const hoppedOn = user.data().hoppedOn
                const notifOff = user.data().notifOff

                const blockList = user.data().blockList !== undefined ? user.data().blockList : []
                const mutedChats = user.data().mutedChats !== undefined ? user.data().mutedChats : []

                if(hoppedOn && (notifOff === undefined || !notifOff)){
                      if(!blockList.includes(callerId)){
                        if(!mutedChats.includes(groupId)){
                            const payload = {
                                  notification: {
                                    title: callerName,
                                    body: 'started a call in '+hashTag,
                                    badge: '1',
                                    sound: 'default'
                                  },
                                  data: {
                                    click_action: `FLUTTER_NOTIFICATION_CLICK`,
                                    sound: `default`,
                                    status: `done`,
                                    screen: `callScreen`,
                                    groupId: groupId,
                                    anon:!anon ? `false` : `true`
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
                        }
                }
                return;
              }).catch(error => {
                console.log('user:', error)
              })
            })

            return;
          }).catch(error => {
            console.log('caller:', error)
          })

          return;
        }).catch(error => {
          console.log('groupChats:', error)
        })
    }

    return null
  })