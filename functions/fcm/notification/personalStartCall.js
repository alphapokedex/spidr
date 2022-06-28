const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const personalChatCollection = admin.firestore().collection('personalChats');


exports.sendPersonalCallNotif = functions
  .firestore.document('personalChats/{personalChatId}')
  .onUpdate((snap, context) => {

    const docBefore = snap.before.data()
    const docAfter = snap.after.data()

    const personalChatId = snap.after.id

    const inCallUsersBe = docBefore.inCallUsers !== undefined ? docBefore.inCallUsers : {}
    const inCallUsersAf = docAfter.inCallUsers

    if(Object.keys(inCallUsersBe).length === 0 && Object.keys(inCallUsersAf).length > 0){

        personalChatCollection.doc(personalChatId).get().then(personalChat => {
          const anon = personalChat.data().anon !== undefined && personalChat.data().anon
          const from = personalChat.data().from
          const to  = personalChat.data().to
          const uid = Object.keys(inCallUsersAf)[0]

          const callerId = inCallUsersAf[uid]['userId']
          const receiverId = from === callerId ? to : from

          userCollection.doc(callerId).get().then(caller =>{
            const callerName = !anon ? caller.data().name : "Anonymous"

            userCollection.doc(receiverId).get().then(receiver =>{
              const hoppedOn = receiver.data().hoppedOn
              const notifOff = receiver.data().notifOff
              const blockList = receiver.data().blockList !== undefined ? receiver.data().blockList : []
              const mutedChats = receiver.data().mutedChats !== undefined ? receiver.data().mutedChats : []

             if(hoppedOn && (notifOff === undefined || !notifOff)){
                if(!mutedChats.includes(personalChatId)){

                  const payload = {
                    notification: {
                      title: callerName,
                      body: "started a call",
                      badge: '1',
                      sound: 'default'
                    },
                    data: {
                      click_action: `FLUTTER_NOTIFICATION_CLICK`,
                      sound: `default`,
                      status: `done`,
                      screen: `callScreen`,
                      personalChatId: personalChatId,
                      anon:!anon ? `false` : `true`
                    }
                  }

                  admin.messaging()
                    .sendToDevice(receiver.data().pushToken, payload)
                    .then(response => {
                      console.log('Successfully sent message:', response)
                      return;
                    }).catch(error => {
                      console.log('Error sending message:', error)
                    })

                }

              }

              return;
            }).catch(error => {
              console.log('receiver:', error)
            })

            return;
          }).catch(error => {
            console.log('caller:', error)
          })

          return;
        }).catch(error => {
          console.log('personalChat:', error)
        })
    }

    return null
  })