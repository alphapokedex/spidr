const admin = require('firebase-admin');
const userCollection = admin.firestore().collection('users');

//exports.delUserGroupFeed = function(userId, groupId, type){
//  userCollection.doc(userId).collection(type)
//    .doc(groupId)
//    .collection("feeds")
//    .get().then((feedQS) => {
//
//      feedQS.forEach((feedDS) => {
//        userCollection.doc(userId).collection(type)
//        .doc(groupId)
//        .collection('feeds')
//        .doc(feedDS.id)
//        .delete()
//      })
//      return;
//
//  }).catch(error => {
//    console.log("feeds:", error)
//  })
//}

exports.delUserGroupStory = function(userId, groupId){
  userCollection.doc(userId).collection("groups")
    .doc(groupId)
    .collection("stories")
    .get().then((storyQS) => {

      storyQS.forEach((storyDS) => {
        userCollection.doc(userId).collection("groups")
        .doc(groupId)
        .collection('stories')
        .doc(storyDS.id)
        .delete()
      })
      return;

  }).catch(error => {
    console.log("stories:", error)
  })
}