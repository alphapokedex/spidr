const functions = require('firebase-functions');
const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');
const mediaCollection = admin.firestore().collection('mediaItems');


exports.onBlockUser = functions.firestore.document('users/{userId}')
    .onUpdate(snap => {
      const blockerId = snap.after.id
      const beforeDoc = snap.before.data()
      const afterDoc = snap.after.data()

      const beBList = beforeDoc.blockList !== undefined ? beforeDoc.blockList : []
      const afBList = afterDoc.blockList

      if(afBList.length > beBList.length){
        const diff = afBList.filter(x => !beBList.includes(x))

        diff.forEach(userId => {
            userCollection.doc(blockerId)
              .collection('recStories')
              .where("senderId", "==", userId)
              .get().then((storyQS) => {
                storyQS.forEach((storyDS) => {
                  userCollection.doc(blockerId)
                    .collection('recStories')
                    .doc(storyDS.id)
                    .delete()
                })
                return;
              }).catch(error => {
                console.log("recStories:", error)
              })

            userCollection.doc(blockerId).collection('groups').get().then((groupQS) => {
                groupQS.forEach((groupDS) => {
                  userCollection.doc(blockerId).collection('groups')
                    .doc(groupDS.id)
                    .collection('stories')
                    .where("senderId", "==", userId)
                    .get().then((storyQS) => {
                      storyQS.forEach((storyDS) => {
                        userCollection.doc(blockerId)
                          .collection('groups')
                          .doc(groupDS.id)
                          .collection('stories')
                          .doc(storyDS.id)
                          .delete()
                      })

                      return;
                    }).catch(error => {
                      console.log("stories:", error)
                    })
                })

                return;
              }).catch(error => {
                console.log("groups:", error)
              })

            mediaCollection.where("senderId", "==", userId).get().then((mediaQS) => {
              mediaQS.forEach((mediaDS) => {
                var notVisibleTo = mediaDS.data().notVisibleTo !== undefined ? mediaDS.data().notVisibleTo : []
                notVisibleTo.push(blockerId)
                mediaCollection.doc(mediaDS.id).update({"notVisibleTo":notVisibleTo})
              })

              return;
            }).catch(error => {
              console.log("mediaItems:", error)
            })
        })
      }
      return;
    })