const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');

exports.sendGroupTagCreateNotification = functions
  .firestore.document('groupChats/{groupId}')
  .onCreate((snap, context) => {

    const doc = snap.data()
    const groupState = doc.chatRoomState

      if(groupState !== "invisible"){
      const groupId = snap.id
      const hashTag = doc.hashTag
      const oneDay = doc.oneDay
      const groupTag = doc.tags
      const members = doc.members

      const anon = doc.anon

      const adminId = doc.admin
      const adminName = doc.adminName

      console.log('000000000000000000',groupTag);

      if(!groupTag.isEmpty){
      const userTagCollection = userCollection.where("tags", "array-contains-any", groupTag).get().then(querySnapshot => {

      const arrUsers = querySnapshot.docs.map(element => element.data());

      console.log('1111111111111111111111');

      arrUsers.forEach(user => {

          console.log('222222222222222222');

          if(adminId || members !== user){

              console.log('333333333333333333');

              const hoppedOn = user.hoppedOn
              const notifOff = user.notifOff
              const userName = user.name
              const blockList = user.blockList !== undefined ? user.blockList : []


              if(hoppedOn && (notifOff === undefined || !notifOff)){

               console.log('Data successful. Sending out users tag notification for group chat: ', hashTag);

                if(!blockList.includes(adminId)){

                  const payload = {
                        notification: {
                          title: "Check This Circle Out!",
                          body: !oneDay ?
                                    adminName + " just created a new circle under one of your SpidrTags. Check it out ! " :
                                    "Join " + adminName+"'s" + " conversation under one of your SpidrTags before it disappears ! ",
                          badge: '1',
                          sound: 'default'
                        },
                        data: {
                          click_action: `FLUTTER_NOTIFICATION_CLICK`,
                          sound: `default`,
                          status: `done`,
                          screen: `groupProfile`,
                          groupId: groupId,
                          adminId: adminId,
                        }
                      }

                      admin.messaging()
                        .sendToDevice(user.pushToken, payload)
                        .then(response => {
                          console.log('Successfully sent notification to ' + user.name, response)
                          return;
                        }).catch(error => {
                          console.log('Error sending message:', error)
                        }
                      )

                }
              }
        }
        return;
      }).catch(error => {
        console.log("userId:", error)
      })
    return;
    }).catch(error => {
      console.log(error);
    })
    }
    }
    return;
  })