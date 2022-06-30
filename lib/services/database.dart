import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';

import './algolia_methods.dart';

class DatabaseMethods {
  final String uid;
  DatabaseMethods({this.uid});

  final CollectionReference groupChatCollection =
      FirebaseFirestore.instance.collection('groupChats');
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference mediaCollection =
      FirebaseFirestore.instance.collection('mediaItems');
  final CollectionReference personalChatCollection =
      FirebaseFirestore.instance.collection('personalChats');
  final CollectionReference storyCommentsCollection =
      FirebaseFirestore.instance.collection('story_comments');
  final CollectionReference fileCopiesCollection =
      FirebaseFirestore.instance.collection('files_copies');
  final CollectionReference reportedContentCollection =
      FirebaseFirestore.instance.collection('reported_content');
  final CollectionReference reportedUsersCollection =
      FirebaseFirestore.instance.collection('reported_users');
  final CollectionReference mediaCommentCollection =
      FirebaseFirestore.instance.collection('media_comments');
  final CollectionReference spidrTagsCollection =
      FirebaseFirestore.instance.collection('spidr_tags');

  // final CollectionReference nonSentFileCollection = FirebaseFirestore.instance.collection('nonSent_files');
  // final CollectionReference userContactsCollection = FirebaseFirestore.instance.collection('user_personalChats');
  // final CollectionReference userGroupsCollection = FirebaseFirestore.instance.collection('user_groupChats');
  // final CollectionReference groupUsersCollection = FirebaseFirestore.instance.collection('groupChat_users');
  // final CollectionReference userFeedsCollection = FirebaseFirestore.instance.collection('user_feeds');
  // final CollectionReference userGroupInvitesCollection = FirebaseFirestore.instance.collection('user_groupInvites');
  // final CollectionReference senderStoriesCollection = FirebaseFirestore.instance.collection('sender_stories');
  // final CollectionReference receiverStoriesCollection = FirebaseFirestore.instance.collection('receiver_stories');
  // final CollectionReference commentRepliesCollection = FirebaseFirestore.instance.collection('comment_replies');

  // cleanUpMedia404(){
  //   mediaCollection.get().then((QuerySnapshot mdQS) {
  //     mdQS.docs.forEach((DocumentSnapshot mdDS) async{
  //       Map imgObj = mdDS.data()['mediaObj'];
  //       final response = await http.get(imgObj["imgUrl"]);
  //       if(response.statusCode == 404){
  //         deleteMediaItem(mdDS.id);
  //       }
  //     });
  //   });
  // }

  Future<List> getHotTags() async {
    DocumentSnapshot hotTags = await spidrTagsCollection.doc("hotTags").get();
    print(hotTags.get("hotTags").toString());
    return hotTags.get("hotTags");
  }

  // Future<List> getGenreTags()async{
  //   DocumentSnapshot hotTags = await spidrTagsCollection.doc("genreTags").get();
  //   return hotTags.data()["genreTags"];
  // }

  getMyStream() {
    return userCollection.doc(uid).snapshots();
  }

  pinMyFriend(String friendId) {
    userCollection
        .doc(uid)
        .collection('friends')
        .doc(friendId)
        .update({"pinned": true});
  }

  unPinMyFriend(String friendId) {
    userCollection
        .doc(uid)
        .collection('friends')
        .doc(friendId)
        .update({"pinned": false});
  }

  muteMyFriend(String plChatId) {
    userCollection.doc(uid).update({
      "mutedChats": FieldValue.arrayUnion([plChatId])
    });
  }

  unMuteMyFriend(String plChatId) {
    userCollection.doc(uid).update({
      "mutedChats": FieldValue.arrayRemove([plChatId])
    });
  }

  getMyFriends() {
    return userCollection
        .doc(uid)
        .collection('friends')
        .orderBy('numOfNewMsg', descending: true)
        .snapshots();
  }

  sendFriendRequest(String friendId) {
    userCollection.doc(uid).update({
      'sentFdReq': FieldValue.arrayUnion([friendId])
    });
    userCollection
        .doc(uid)
        .collection('friendRequests')
        .doc(friendId)
        .set({'requester': Constants.myName, 'userId': friendId});
    userCollection.doc(friendId).update({
      'receivedFdReq': FieldValue.arrayUnion([uid])
    });
  }

  cancelFriendRequest(String friendId) {
    userCollection.doc(uid).update({
      'sentFdReq': FieldValue.arrayRemove([friendId])
    });
    userCollection.doc(uid).collection('friendRequests').doc(friendId).delete();
    userCollection.doc(friendId).update({
      'receivedFdReq': FieldValue.arrayRemove([uid])
    });
  }

  acceptFriendRequest(String friendId) {
    userCollection.doc(friendId).update({
      'sentFdReq': FieldValue.arrayRemove([uid])
    });
    userCollection.doc(friendId).collection('friendRequests').doc(uid).delete();

    userCollection.doc(uid).update({
      'receivedFdReq': FieldValue.arrayRemove([friendId])
    });

    userCollection.doc(friendId).update({
      'friends': FieldValue.arrayUnion([uid])
    });
    userCollection.doc(friendId).collection('friends').doc(uid).set({
      "friendId": uid,
    });
    userCollection.doc(uid).update({
      'friends': FieldValue.arrayUnion([friendId])
    });
    userCollection.doc(uid).collection('friends').doc(friendId).set({
      "acceptor": Constants.myName,
      "friendId": friendId,
    });
  }

  ignoreFriendRequest(String friendId) {
    userCollection.doc(friendId).update({
      'sentFdReq': FieldValue.arrayRemove([uid])
    });
    userCollection.doc(friendId).collection('collectionPath').doc(uid).delete();
    userCollection.doc(uid).update({
      'receivedFdReq': FieldValue.arrayRemove([friendId])
    });
  }

  hopOffNotifSetUp() {
    userCollection.doc(uid).update({"hoppedOn": false});
  }

  hopOnNotifSetUp() {
    userCollection.doc(uid).update({"hoppedOn": true});
  }

  // searchMediaStories(List<String> tags) async{
  //   return await AlgoliaMethods.searchStories(tags);
  // }

  // getMediaStories() async{
  //   return await AlgoliaMethods.getAllStories();
  // }

  getGCMedia({
    String type,
    String searchTxt,
    // List<DocumentSnapshot> mediaQS,
    // List mdIndices
  }) {
    switch (type) {
      case "Media":
        return AlgoliaMethods.getMedia(searchTxt);
      case "Audio":
        return AlgoliaMethods.getMediaAud(searchTxt);
      case "PDF":
        return AlgoliaMethods.getMediaPDF(searchTxt);
    }

    // // Random random = Random();
    // List<DocumentSnapshot> mediaDSList = [];
    // int range = mdIndices.length/Constants.maxMediaLoad >= 1 ? Constants.maxMediaLoad : mdIndices.length;
    // for(int i = 0; i < range; i+=1){
    //   // int randIndex = random.nextInt(mdIndices.length);
    //   mediaDSList.add(mediaQS[mdIndices[0]]);
    //   mdIndices.removeAt(0);
    // }
    //
    // return mediaDSList;
  }

  getUserByUserEmail(String userEmail) async {
    return await userCollection.where("email", isEqualTo: userEmail).get();
  }

  getUserById() async {
    return await userCollection.doc(uid).get();
  }

  uploadUserInfo(userMap) async {
    return await userCollection.doc(uid).set(userMap);
  }

  openChat(String groupId) async {
    DocumentReference groupDF =
        userCollection.doc(uid).collection('groups').doc(groupId);

    DocumentSnapshot groupDS = await groupDF.get();
    if (groupDS.exists) {
      groupDF.update({"inChat": true, "newMsg": [], "numOfNewMsg": 0});
    }
  }

  closeChat(String groupId) async {
    DocumentReference groupDF =
        userCollection.doc(uid).collection('groups').doc(groupId);

    DocumentSnapshot groupDS = await groupDF.get();

    if (groupDS.exists) groupDF.update({"inChat": false});
  }

  openSpecChat(String groupId) async {
    DocumentReference specDF =
        userCollection.doc(uid).collection('groups').doc(groupId);

    DocumentSnapshot specDS = await specDF.get();

    if (specDS.exists) {
      specDF.update({"inChat": true, "newMsg": [], 'numOfNewMsg': 0});
    }
  }

  closeSpecChat(String groupId) async {
    DocumentReference specDF =
        userCollection.doc(uid).collection('groups').doc(groupId);

    DocumentSnapshot specDS = await specDF.get();
    if (specDS.exists) specDF.update({"inChat": false});
  }

  openPersonalChat(String personalChatId, String friendId, bool friend) {
    if (friend) {
      userCollection
          .doc(uid)
          .collection('friends')
          .doc(friendId)
          .update({'inChat': true, 'newMsg': [], 'numOfNewMsg': 0});
    } else {
      userCollection
          .doc(uid)
          .collection('replies')
          .doc(personalChatId)
          .update({'inChat': true, 'newMsg': [], 'numOfNewMsg': 0});
    }
  }

  closePersonalChat(String personalChatId, String friendId, bool friend) {
    if (friend) {
      userCollection
          .doc(uid)
          .collection('friends')
          .doc(friendId)
          .update({'inChat': false});
    } else {
      userCollection
          .doc(uid)
          .collection('replies')
          .doc(personalChatId)
          .update({'inChat': false});
    }
  }

  removeSavedMedia(String messageId) async {
    DocumentReference itemDocRef =
        userCollection.doc(uid).collection('backpack').doc(messageId);

    DocumentSnapshot itemSnapshot = await itemDocRef.get();
    Map imgObj = itemSnapshot.get('imgObj');
    Map fileObj = itemSnapshot.get('fileObj');
    List mediaGallery = itemSnapshot.get('mediaGallery');

    delFileCopies(
        mediaId: messageId,
        imgObj: imgObj,
        fileObj: fileObj,
        mediaGallery: mediaGallery);

    await itemDocRef.delete();
  }

  saveMedia(Map imgObj, Map fileObj, List mediaGallery, String groupId,
      String senderId, String messageId, bool anon) async {
    await userCollection.doc(uid).collection('backpack').doc(messageId).set({
      'imgObj': imgObj,
      'fileObj': fileObj,
      'mediaGallery': mediaGallery,
      'groupId': groupId,
      'senderId': senderId,
      'saveTime': DateTime.now().microsecondsSinceEpoch,
      'media': imgObj != null || mediaGallery != null,
      'audio': fileObj != null && audioChecker(fileObj["fileName"]),
      'pdf': fileObj != null && pdfChecker(fileObj["fileName"]),
      'anon': anon
    });

    addFileCopies(mediaId: messageId);
  }

  delFileCopies(
      {String mediaId,
      Map imgObj,
      Map fileObj,
      List mediaGallery,
      int numOfFiles = 1}) async {
    DocumentReference fileDocRef = fileCopiesCollection.doc(mediaId);
    DocumentSnapshot fileSnapshot = await fileDocRef.get();

    if (fileSnapshot.exists) {
      int numOfCopies = fileSnapshot.data().toString().contains('numofCopies')
          ? fileSnapshot.get('numOfCopies')
          : 1;

      try {
        numOfCopies = fileSnapshot.get('numOfCopies');
      } on StateError {
        numOfCopies = 1;
      }

      numOfCopies = numOfCopies - numOfFiles;

      if (numOfCopies == 0) {
        fileDocRef.delete();
        delStory(mediaId);
        delMedia(mediaId);
        if (imgObj != null &&
            imgObj["gif"] == null &&
            imgObj["sticker"] == null) {
          rmvFileFromStorage(imgObj["imgUrl"]);
        } else if (fileObj != null) {
          rmvFileFromStorage(fileObj["fileUrl"]);
        } else if (mediaGallery != null) {
          for (Map m in mediaGallery) {
            rmvFileFromStorage(m["imgUrl"]);
          }
        }
      } else {
        await fileDocRef.update({'numOfCopies': numOfCopies});
      }
    }
  }

  addFileCopies({String mediaId, int numC}) async {
    DocumentReference fileDocRef = fileCopiesCollection.doc(mediaId);
    DocumentSnapshot fileSnapshot = await fileDocRef.get();
    if (fileSnapshot.exists) {
      int numOfCopies = fileSnapshot.data().toString().contains('numofCopies')
          ? numC != null
              ? fileSnapshot.get('numOfCopies') + numC
              : fileSnapshot.get('numOfCopies') + 1
          : 0;

      try {
        numOfCopies = numC != null
            ? fileSnapshot.get('numOfCopies') + numC
            : fileSnapshot.get('numOfCopies') + 1;
      } on StateError {
        numOfCopies = 0;
      }

      fileDocRef.update({'numOfCopies': numOfCopies});
    }
  }

  Future<List<List<String>>> constructGroupIdLists() async {
    List<String> mdGroupIds = [];
    List<String> adGroupIds = [];
    List<String> pdfGroupIds = [];

    QuerySnapshot itemQS = await userCollection
        .doc(uid)
        .collection('backpack')
        .where('field')
        .get();

    for (var itemDS in itemQS.docs) {
      String groupId = itemDS.get("groupId");
      if (groupId != null) {
        if (itemDS.get("media") != null && itemDS.get("media")) {
          if (!mdGroupIds.contains(groupId)) {
            mdGroupIds.add(groupId);
          }
        } else if (itemDS.get("audio") != null && itemDS.get("audio")) {
          if (!adGroupIds.contains(groupId)) {
            adGroupIds.add(groupId);
          }
        } else if (itemDS.get("pdf") != null && itemDS.get("pdf")) {
          if (!pdfGroupIds.contains(groupId)) {
            pdfGroupIds.add(groupId);
          }
        }
      }
    }
    return [mdGroupIds, adGroupIds, pdfGroupIds];
  }

  filterSavedMedia(String groupId) {
    return userCollection
        .doc(uid)
        .collection('backpack')
        .where("media", isEqualTo: true)
        .where('groupId', isEqualTo: groupId)
        .snapshots();
  }

  getSavedMedia() {
    return userCollection
        .doc(uid)
        .collection('backpack')
        .where("media", isEqualTo: true)
        .orderBy('saveTime', descending: true)
        .snapshots();
  }

  filterSavedAudios(String groupId) {
    return userCollection
        .doc(uid)
        .collection('backpack')
        .where("audio", isEqualTo: true)
        .where('groupId', isEqualTo: groupId)
        .snapshots();
  }

  getSavedAudios() {
    return userCollection
        .doc(uid)
        .collection('backpack')
        .where("audio", isEqualTo: true)
        .orderBy('saveTime', descending: true)
        .snapshots();
  }

  filterSavedPDFs(String groupId) {
    return userCollection
        .doc(uid)
        .collection('backpack')
        .where("pdf", isEqualTo: true)
        .where('groupId', isEqualTo: groupId)
        .snapshots();
  }

  getSavedPDFs() {
    return userCollection
        .doc(uid)
        .collection('backpack')
        .where("pdf", isEqualTo: true)
        .orderBy('saveTime', descending: true)
        .snapshots();
  }

  handelPlChatUpload(String personalChatId, int numOfFiles) async {
    DocumentReference contactDF =
        userCollection.doc(uid).collection('replies').doc(personalChatId);
    DocumentSnapshot contactDS = await contactDF.get();
    int numOfUploads = contactDS.data().toString().contains('numofUploads')
        ? contactDS.get('numofUploads')
        : null;

    try {
      numOfUploads = contactDS.get('numofUploads');
    } on StateError {
      numOfUploads = null;
    }

    if (numOfUploads == null) {
      contactDF.update({"numOfUploads": numOfFiles ?? 1});
    } else {
      numOfUploads =
          numOfFiles != null ? numOfUploads + numOfFiles : numOfUploads + 1;
      contactDF.update({"numOfUploads": numOfUploads});
    }
  }

  handleFdChatUpload(String friendId, int numOfFiles) async {
    DocumentReference friendDF =
        userCollection.doc(uid).collection('friends').doc(friendId);
    DocumentSnapshot friendDS = await friendDF.get();
    int numOfUploads = friendDS.data().toString().contains('numofUploads')
        ? friendDS.get("numOfUploads")
        : null;

    try {
      numOfUploads = friendDS.get("numOfUploads");
    } on StateError {
      numOfUploads = null;
    }
    if (numOfUploads == null) {
      friendDF.update({"numOfUploads": numOfFiles ?? 1});
    } else {
      numOfUploads =
          numOfFiles != null ? numOfUploads + numOfFiles : numOfUploads + 1;
      friendDF.update({"numOfUploads": numOfUploads});
    }
  }

  Future<String> uploadFileToPersonalChat({
    String personalChatId,
    String contactId,
    Map imgMap,
    Map fileMap,
    List mediaGallery,
    int time,
    bool friend,
    int numOfFiles,
  }) async {
    if (friend) {
      handleFdChatUpload(contactId, numOfFiles);
    } else {
      handelPlChatUpload(personalChatId, numOfFiles);
    }

    DocumentSnapshot personalChatDS =
        await personalChatCollection.doc(personalChatId).get();
    bool anon = personalChatDS.data().toString().contains('anon')
        ? personalChatDS.get('anon')
        : false;

    try {
      anon = personalChatDS.get('anon');
    } on StateError {
      anon = false;
    }

    DocumentReference personalChatDF = await personalChatCollection
        .doc(personalChatId)
        .collection("messages")
        .add({
      'sendTo': contactId,
      'personalChatId': personalChatId,
      'text': '',
      'sender': anon == null || !anon ? Constants.myName : "Anonymous",
      'senderId': uid,
      'sendTime': time,
      'imgMap': imgMap,
      'fileMap': fileMap,
      'mediaGallery': mediaGallery,
    });

    return personalChatDF.id;
  }

  addPersonalMessage(
      {String personalChatId,
      String text,
      String userName,
      int sendTime,
      Map imgMap,
      Map fileMap,
      List mediaGallery,
      String contactId,
      String ogMediaId,
      String ogSenderId,
      String chatId,
      bool friend}) async {
    DocumentSnapshot personalChatDS =
        await personalChatCollection.doc(personalChatId).get();
    bool anon = personalChatDS.data().toString().contains('getStarted')
        ? personalChatDS.get('anon')
        : false;

    try {
      anon = personalChatDS.get('anon');
    } on StateError {
      anon = false;
    }

    if (chatId == null) {
      DocumentReference chatDF = await personalChatCollection
          .doc(personalChatId)
          .collection("messages")
          .add({
        'text': text,
        'sender': anon == null || !anon ? userName : "Anonymous",
        'senderId': uid,
        'sendTime': sendTime,
        'personalChatId': personalChatId,
        'sendTo': contactId,
        'imgMap': imgMap,
        'fileMap': fileMap,
        'mediaGallery': mediaGallery,
        'ogMediaId': ogMediaId,
        'ogSenderId': ogSenderId,
        'friend': friend
      });

      if (friend) {
        addFdChatNotif(
            friendId: contactId, chatId: chatDF.id, ogSenderId: ogSenderId);
      } else {
        addPerChatNotif(contactId, personalChatId, chatDF.id);
      }
    } else {
      personalChatCollection
          .doc(personalChatId)
          .collection('messages')
          .doc(chatId)
          .set({
        'text': text,
        'senderId': uid,
        'sendTime': sendTime,
        'imgMap': imgMap,
        'fileMap': fileMap,
        'mediaGallery': mediaGallery,
        'friend': friend
      });

      if (friend) {
        finishFdChatUpload(contactId);
        addFdChatNotif(friendId: contactId, chatId: chatId);
      } else {
        finishPlChatUpload(personalChatId);
        addPerChatNotif(contactId, personalChatId, chatId);
      }
    }
  }

  finishPlChatUpload(String personalChatId) async {
    DocumentReference contactDF =
        userCollection.doc(uid).collection('replies').doc(personalChatId);

    DocumentSnapshot contactDS = await contactDF.get();
    int numOfUploads = contactDS.data().toString().contains('numofUploads')
        ? contactDS.get('numofUploads')
        : 2;

    try {
      numOfUploads = contactDS.get('numofUploads');
    } on StateError {
      numOfUploads = 2;
    }
    if (numOfUploads > 0) {
      numOfUploads = numOfUploads - 1;
      contactDF.update({"numOfUploads": numOfUploads});
    }
  }

  finishFdChatUpload(String friendId) async {
    DocumentReference friendDF =
        userCollection.doc(uid).collection('friends').doc(friendId);

    DocumentSnapshot friendDS = await friendDF.get();
    int numOfUploads = friendDS.data().toString().contains('numofUploads')
        ? friendDS.get('numofUploads')
        : 2;

    try {
      numOfUploads = friendDS.get('numofUploads');
    } on StateError {
      numOfUploads = 2;
    }
    if (numOfUploads > 0) {
      numOfUploads = numOfUploads - 1;
      friendDF.update({"numOfUploads": numOfUploads});
    }
  }

  addPerChatNotif(
      String contactId, String personalChatId, String chatId) async {
    DocumentReference contactDocRef =
        userCollection.doc(contactId).collection('replies').doc(personalChatId);

    DocumentSnapshot contactSnapshot = await contactDocRef.get();

    if (contactSnapshot.exists && !contactSnapshot.get('inChat')) {
      int numOfNewMsg =
          contactSnapshot.data().toString().contains('numofUploads')
              ? contactSnapshot.get('numOfNewMsg')
              : null;
      try {
        numOfNewMsg = contactSnapshot.get('numOfNewMsg');
      } on StateError {
        numOfNewMsg = null;
      }
      numOfNewMsg = numOfNewMsg == null ? 1 : numOfNewMsg + 1;
      contactDocRef.update({
        'numOfNewMsg': numOfNewMsg,
        'newMsg': FieldValue.arrayUnion([chatId])
      });
    }
  }

  deletePerChatNotif(
      String contactId, String personalChatId, String chatId) async {
    DocumentReference contactDocRef =
        userCollection.doc(contactId).collection('replies').doc(personalChatId);

    DocumentSnapshot contactSnapshot = await contactDocRef.get();

    if (contactSnapshot.exists) {
      int numOfNewMsg =
          contactSnapshot.data().toString().contains('numofNewMsg')
              ? contactSnapshot.get('numOfNewMsg')
              : null;
      try {
        numOfNewMsg = contactSnapshot.get('numOfNewMsg');
      } on StateError {
        numOfNewMsg = null;
      }
      List newMsg = contactSnapshot.get('newMsg');
      if (newMsg.contains(chatId)) {
        if (numOfNewMsg > 0) {
          numOfNewMsg = numOfNewMsg - 1;
          contactDocRef.update({
            'numOfNewMsg': numOfNewMsg,
            'newMsg': FieldValue.arrayRemove([chatId])
          });
        }
      }
    }
  }

  addFdChatNotif({String friendId, String chatId, String ogSenderId}) async {
    DocumentReference friendDF =
        userCollection.doc(friendId).collection('friends').doc(uid);

    DocumentSnapshot userDS = await userCollection.doc(friendId).get();

    DocumentSnapshot friendDS = await friendDF.get();
    List blockList = userDS.data().toString().contains('blockList') != null
        ? userDS.get('blockList')
        : [];
    try {
      blockList = userDS.get('blockList');
    } on StateError {
      blockList = [];
    }

    if (ogSenderId == null || !blockList.contains(ogSenderId)) {
      if (friendDS.exists && !friendDS.get('inChat')) {
        int numOfNewMsg = friendDS.data().toString().contains('numofNewMsg')
            ? friendDS.get('numOfNewMsg')
            : null;
        try {
          numOfNewMsg = friendDS.get('numOfNewMsg');
        } on StateError {
          numOfNewMsg = null;
        }
        numOfNewMsg = numOfNewMsg == null ? 1 : numOfNewMsg + 1;
        friendDF.update({
          'newMsg': FieldValue.arrayUnion([chatId]),
          'numOfNewMsg': numOfNewMsg
        });
      }
    }
  }

  deleteFdChatNotif(String friendId, String chatId) async {
    DocumentReference friendDF =
        userCollection.doc(friendId).collection('friends').doc(uid);

    DocumentSnapshot friendDS = await friendDF.get();

    if (friendDS.exists) {
      int numOfNewMsg = friendDS.data().toString().contains('numofNewMsg')
          ? friendDS.get('numOfNewMsg')
          : 0;
      try {
        numOfNewMsg = friendDS.get('numOfNewMsg');
      } on StateError {
        numOfNewMsg = 0;
      }
      List newMsg = friendDS.data().toString().contains('newMsg')
          ? friendDS.get('newMsg')
          : [];
      if (newMsg.contains(chatId)) {
        if (numOfNewMsg > 0) {
          numOfNewMsg = numOfNewMsg - 1;
          friendDF.update({
            'numOfNewMsg': numOfNewMsg,
            'newMsg': FieldValue.arrayRemove([chatId])
          });
        }
      }
    }
  }

  deletePersonalMessage(String personalChatId, String textId) async {
    DocumentReference textDocRef = personalChatCollection
        .doc(personalChatId)
        .collection("messages")
        .doc(textId);

    DocumentSnapshot textSnapshot = await textDocRef.get();
    await textDocRef.delete();

    Map<String, dynamic> imgMap =
        textSnapshot.data().toString().contains('imgMap')
            ? textSnapshot.get('imgMap')
            : null;
    Map<String, dynamic> fileMap =
        textSnapshot.data().toString().contains('fileMap')
            ? textSnapshot.get('fileMap')
            : null;
    List mediaGallery = textSnapshot.data().toString().contains('mediaGallery')
        ? textSnapshot.get('mediaGallery')
        : null;
    Map ogMediaId = textSnapshot.data().toString().contains('ogMediaId')
        ? textSnapshot.get('ogMediaId')
        : null;

    if (imgMap != null || fileMap != null || mediaGallery != null) {
      Map<String, dynamic> imgMap =
          textSnapshot.data().toString().contains('imgMap')
              ? textSnapshot.get('imgMap')
              : null;
      Map<String, dynamic> fileMap =
          textSnapshot.data().toString().contains('fileMap')
              ? textSnapshot.get('fileMap')
              : null;
      List mediaGallery =
          textSnapshot.data().toString().contains('mediaGallery')
              ? textSnapshot.get('mediaGallery')
              : null;

      if (ogMediaId != null) {
        String messageId = textSnapshot.get('ogMediaId');
        delFileCopies(
            mediaId: messageId,
            imgObj: imgMap,
            fileObj: fileMap,
            mediaGallery: mediaGallery);
      } else {
        if (imgMap != null) {
          FirebaseStorage.instance.refFromURL(imgMap['imgUrl']).delete();
        } else if (fileMap != null) {
          FirebaseStorage.instance.refFromURL(fileMap['fileUrl']).delete();
        } else {
          for (Map m in mediaGallery) {
            FirebaseStorage.instance.refFromURL(m['imgUrl']).delete();
          }
        }
      }
    }
  }

  deletePersonalChat(String personalChatId, String contactId) async {
    DocumentReference myPerChatDocRef =
        userCollection.doc(uid).collection('replies').doc(personalChatId);

    DocumentSnapshot myPerChatSnapshot = await myPerChatDocRef.get();
    myPerChatDocRef.delete();

    if (myPerChatSnapshot.exists && myPerChatSnapshot.get('openByOther')) {
      DocumentReference contactDocRef = userCollection
          .doc(contactId)
          .collection('replies')
          .doc(personalChatId);

      DocumentSnapshot contactSnapshot = await contactDocRef.get();

      if (!contactSnapshot.exists) {
        DocumentReference perChatDocRef =
            personalChatCollection.doc(personalChatId);

        DocumentSnapshot perChatSnapshot = await perChatDocRef.get();
        String groupId = perChatSnapshot.get('originalGroupId');
        String chatId = perChatSnapshot.get('originalChatId');

        updateConversationMessages(
            groupChatId: groupId,
            messageId: chatId,
            personalChatId: personalChatId,
            userId: contactId,
            actionType: "DELETE_REPLY");
      }
    }
  }

  createPersonalChat({
    String userId,
    String text,
    String dateTime,
    int sendTime,
    Map imgMap,
    Map fileMap,
    List mediaGallery,
    Map myReply,
    String groupId,
    String hashTag,
    bool anon,
    String messageId,
    String actionType,
    String ogMediaId,
  }) async {
    DocumentReference perChatDocRef;
    int replyTime = DateTime.now().microsecondsSinceEpoch;

    if (actionType == "REPLY_CHAT") {
      bool audio = fileMap != null && audioChecker(fileMap["fileName"]);
      bool pdf = fileMap != null && pdfChecker(fileMap["fileName"]);
      bool media = imgMap != null || mediaGallery != null;

      perChatDocRef = await personalChatCollection.add({
        'to': userId,
        'from': uid,
        'originalChatId': messageId,
        'originalGroupId': groupId,
        'originalGroupHashTag': hashTag,
        'anon': anon,
      });

      if (audio || pdf || media) {
        addFileCopies(mediaId: ogMediaId ?? messageId);
      }

      await perChatDocRef.collection("messages").add({
        'text': text,
        'senderId': userId,
        'formattedDateTime': dateTime,
        'sendTime': sendTime,
        'sendTo': null,
        'ogMediaId': ogMediaId ?? messageId,
        'imgMap': imgMap,
        'fileMap': fileMap,
        'mediaGallery': mediaGallery,
      }).catchError((e) {
        print(e.toString());
      });

      if (myReply != null) {
        await perChatDocRef.collection("messages").add(myReply);
      }

      DocumentReference userGroupDocRef =
          userCollection.doc(userId).collection('groups').doc(groupId);

      DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
      Map replies = userGroupSnapshot.get('replies');
      replies[perChatDocRef.id] = uid;

      userGroupDocRef.update({'replies': replies});
      userCollection.doc(uid).collection('replies').doc(perChatDocRef.id).set({
        "contactId": userId,
        "newMsg": [],
        "numOfNewMsg": 0,
        "openByOther": false,
        "inChat": true,
        "replyTime": replyTime,
      });
    } else if (actionType == "START_CONVO") {
      perChatDocRef = await personalChatCollection
          .add({'to': userId, 'from': uid, 'anon': anon});

      userCollection.doc(uid).collection('replies').doc(perChatDocRef.id).set({
        "contactId": userId,
        "newMsg": [],
        "numOfNewMsg": 0,
        "openByOther": true,
        "inChat": true,
        "replyTime": replyTime,
        'chatStartTime': replyTime,
      });

      userCollection
          .doc(userId)
          .collection('replies')
          .doc(perChatDocRef.id)
          .set({
        "contactId": uid,
        "newMsg": [],
        "numOfNewMsg": 0,
        "openByOther": true,
        "inChat": false,
        "replyTime": replyTime,
        'chatStartTime': replyTime,
      });
    } else if (actionType == "FRIEND_CHAT") {
      perChatDocRef = await personalChatCollection.add({
        'to': userId,
        'from': uid,
      });

      userCollection.doc(uid).collection('friends').doc(userId).update({
        "personalChatId": perChatDocRef.id,
        "newMsg": [],
        "numOfNewMsg": 0,
        "inChat": false
      });
      userCollection.doc(userId).collection('friends').doc(uid).update({
        "personalChatId": perChatDocRef.id,
        "newMsg": [],
        "numOfNewMsg": 0,
        "inChat": true
      });
    }
    return perChatDocRef.id;
  }

  cleanUpDeletedGroups() {
    groupChatCollection
        .where('deleted', isEqualTo: true)
        .get()
        .then((QuerySnapshot groupQS) {
      for (var groupDS in groupQS.docs) {
        DocumentReference groupDF = groupChatCollection.doc(groupDS.id);
        String profileImg = groupDS.get('profileImg');

        if (!profileImg.startsWith('assets', 0)) {
          rmvFileFromStorage(profileImg);
        }

        groupDF
            .collection('chats')
            .orderBy("time")
            .get()
            .then((QuerySnapshot chatQS) {
          Future.forEach(chatQS.docs, (chatDS) async {
            await deleteConversationMessage(
              groupChatId: groupDS.id,
              chatId: chatDS.id,
              delGroup: true,
            );
          });
        });

        groupDF.collection('users').get().then((QuerySnapshot userQS) {
          for (var userDS in userQS.docs) {
            groupDF.collection('users').doc(userDS.id).delete();
          }
        });

        groupDF.collection('stories').get().then((QuerySnapshot storyQS) {
          for (var storyDS in storyQS.docs) {
            groupDF.collection('stories').doc(storyDS.id).delete();
          }
        });

        groupDF.delete();
      }
    });
  }

  deleteMyGroup(String groupId) {
    userCollection.doc(uid).collection('groups').doc(groupId).delete();
    // userCollection.doc(uid).collection('spectating').doc(groupId).delete();
  }

  deleteGroupChat(String groupId) {
    deleteMyGroup(groupId);
    DocumentReference groupDF = groupChatCollection.doc(groupId);
    groupDF.update({"deleted": true});
  }

  Future<String> createGroupChat(
      {String hashTag,
      String username,
      String chatRoomState,
      int time,
      double groupCapacity,
      String groupPic,
      String program,
      String school,
      bool anon,
      List tags,
      bool oneDay}) async {
    DocumentReference groupChatDocRef = await groupChatCollection.add({
      'hashTag': hashTag,
      'program': program,
      'school': school,
      'profileImg': groupPic,
      'admin': uid,
      'adminName': username,
      'members': [uid],
      'leftUsers': [],
      'bannedUsers': [],
      'chatRoomState': chatRoomState,
      'createdAt': time,
      'joinRequests': {},
      'waitList': {},
      'groupCapacity': groupCapacity,
      'tags': tags,
      'about': "",
      'anon': anon,
      'oneDay': oneDay,
      'deleted': false
    });

    groupChatCollection
        .doc(groupChatDocRef.id)
        .update({'groupId': groupChatDocRef.id});

    userCollection.doc(uid).collection("groups").doc(groupChatDocRef.id).set({
      'groupId': groupChatDocRef.id,
      'joinRequests': {},
      'replies': {},
      'inChat': true,
      'spectating': false,
      'newMsg': [],
      'numOfNewMsg': 0,
      'createdAt': oneDay ? time : null,
      'pinned': false
    });

    groupChatCollection
        .doc(groupChatDocRef.id)
        .collection("users")
        .doc(uid)
        .set({'userId': uid, 'hashTag': hashTag});

    return groupChatDocRef.id;
  }

  updateConversationMessages({
    String groupChatId,
    String messageId,
    String personalChatId,
    String userId,
    String username,
    String actionType,
  }) async {
    DocumentReference chatDocRef =
        groupChatCollection.doc(groupChatId).collection("chats").doc(messageId);

    switch (actionType) {
      case "ADD_REPLY":
        {
          await chatDocRef.update({
            "replies": FieldValue.arrayUnion([
              {
                "userId": uid,
                "personalChatId": personalChatId,
                "open": false,
                "username": username
              }
            ])
          });
        }
        break;
      case "OPEN_REPLY":
        {
          int openTime = DateTime.now().microsecondsSinceEpoch;

          DocumentReference contactDocRef = userCollection
              .doc(userId)
              .collection('replies')
              .doc(personalChatId);

          DocumentSnapshot contactSnapshot = await contactDocRef.get();
          if (contactSnapshot.exists) {
            contactDocRef
                .update({'openByOther': true, 'chatStartTime': openTime});
          }

          userCollection
              .doc(uid)
              .collection('replies')
              .doc(personalChatId)
              .set({
            "contactId": userId,
            "newMsg": [],
            "numOfNewMsg": 0,
            "openByOther": true,
            "inChat": true,
            "replyTime": openTime,
            'chatStartTime': openTime,
          });

          DocumentReference userGroupDocRef =
              userCollection.doc(uid).collection('groups').doc(groupChatId);

          DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
          if (userGroupSnapshot.exists) {
            Map initReplies = userGroupSnapshot.get('replies');
            initReplies.remove(personalChatId);
            userGroupDocRef.update({'replies': initReplies});
          }

          DocumentSnapshot chatSnapshot = await chatDocRef.get();
          List replies = chatSnapshot.get("replies");

          for (Map reply in replies) {
            if (reply["userId"] == userId) {
              reply["open"] = true;
              break;
            }
          }
          await chatDocRef.update({"replies": replies});
        }
        break;
      case "DELETE_REPLY":
        {
          DocumentSnapshot chatSnapshot = await chatDocRef.get();
          if (chatSnapshot.exists) {
            List replies = chatSnapshot.get('replies');
            int index;
            bool opened = true;
            for (int i = 0; i < replies.length; i++) {
              if (replies[i]["personalChatId"] == personalChatId) {
                opened = replies[i]['open'];
                index = opened ? i : -1;
                break;
              }
            }

            if (opened) {
              replies.removeAt(index);
              chatDocRef.update({'replies': replies});
              personalChatCollection
                  .doc(personalChatId)
                  .collection('messages')
                  .get()
                  .then((QuerySnapshot msgQS) {
                for (var msgDS in msgQS.docs) {
                  deletePersonalMessage(personalChatId, msgDS.id);
                }
              });
              await personalChatCollection.doc(personalChatId).delete();
            }
          }
        }
        break;
    }
  }

  Future<int> getNumOfFiles(String groupId, String mediaId) async {
    QuerySnapshot chatQS = await groupChatCollection
        .doc(groupId)
        .collection("chats")
        .where('ogMediaId', isEqualTo: mediaId)
        .get();

    return chatQS.docs.length;
  }

  deleteConversationMessage(
      {String groupChatId, String chatId, bool delGroup = false}) async {
    DocumentReference chatDocRef =
        groupChatCollection.doc(groupChatId).collection("chats").doc(chatId);

    DocumentSnapshot chatSnapshot = await chatDocRef.get();
    chatDocRef.delete();

    Map<String, dynamic> imgObj =
        chatSnapshot.data().toString().contains('imgObj')
            ? chatSnapshot.get('imgObj')
            : null;
    Map<String, dynamic> fileObj =
        chatSnapshot.data().toString().contains('fileObj')
            ? chatSnapshot.get('fileObj')
            : null;
    List mediaGallery = chatSnapshot.data().toString().contains('mediaGallery')
        ? chatSnapshot.get('mediaGallery')
        : null;
    int numOfFiles = 1;
    String mediaId = chatSnapshot.data().toString().contains('ogMediaId')
        ? chatSnapshot.get('ogMediaId')
        : chatId;

    if (imgObj != null || fileObj != null || mediaGallery != null) {
      mediaCollection.doc(mediaId).delete();

      if (delGroup) numOfFiles = await getNumOfFiles(groupChatId, mediaId);

      await delFileCopies(
          mediaId: mediaId,
          imgObj: imgObj,
          fileObj: fileObj,
          mediaGallery: mediaGallery,
          numOfFiles: numOfFiles);
    } else if (chatSnapshot.get('inChatReply') != null &&
        chatSnapshot.get('inChatReply' "msgReplyTo") is! String) {
      var msgReplyTo = chatSnapshot.get('inChatReply' "msgReplyTo");
      if (chatSnapshot.get('inChatReply' "msgReplyTo") is Map) {
        imgObj = msgReplyTo['imgName'] != null ? msgReplyTo : null;
        fileObj = msgReplyTo['fileName'] != null ? msgReplyTo : null;
      } else if (chatSnapshot.get('inChatReply' "msgReplyTo") is List) {
        mediaGallery = chatSnapshot.get('inChatReply' "msgReplyTo");
      }

      await delFileCopies(
          mediaId: mediaId,
          imgObj: imgObj,
          fileObj: fileObj,
          mediaGallery: mediaGallery);
    }
  }

  // deleteNotification(String groupChatId, String hashTag, String chatId) async{
  //   DocumentSnapshot groupSnapshot = await groupChatCollection.doc(groupChatId).get();
  //
  //   List members = groupSnapshot.data()['members'];
  //
  //   for(String member in members){
  //     DocumentReference userGroupDocRef = userCollection
  //         .doc(member)
  //         .collection('groups')
  //         .doc(groupChatId);
  //
  //     DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
  //     int numOfNewMsg = userGroupSnapshot.data()['numOfNewMsg'];
  //     List newMsg = userGroupSnapshot.data()['newMsg'];
  //     if(newMsg.contains(chatId)){
  //       if(numOfNewMsg > 0){
  //         numOfNewMsg = numOfNewMsg - 1;
  //         userGroupDocRef.update({'numOfNewMsg':numOfNewMsg, 'newMsg':FieldValue.arrayRemove([chatId])});
  //       }
  //     }
  //
  //   }
  //
  //   Map spectators = groupSnapshot.data()['waitList'];
  //   String groupState = groupSnapshot.data()['chatRoomState'];
  //   if( groupState != 'private'){
  //     for(String spectatorId in spectators.keys){
  //       DocumentReference userGroupDocRef = userCollection
  //           .doc(spectatorId)
  //           .collection('groups')
  //           .doc(groupChatId);
  //
  //       DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
  //       int numOfNewMsg = userGroupSnapshot.data()['numOfNewMsg'];
  //       List newMsg = userGroupSnapshot.data()['newMsg'];
  //       if(newMsg.contains(chatId)){
  //         if(numOfNewMsg > 0){
  //           numOfNewMsg = numOfNewMsg - 1;
  //           userGroupDocRef.update({'numOfNewMsg':numOfNewMsg, 'newMsg':FieldValue.arrayRemove([chatId])});
  //         }
  //       }
  //
  //     }
  //   }
  // }

  getMyFeeds(String groupId) {
    return userCollection
        .doc(uid)
        .collection('groups')
        .doc(groupId)
        .collection('feeds')
        .orderBy('sendTime', descending: true)
        .snapshots();
  }

  Future<String> uploadFileToGroup({
    String groupChatId,
    Map imgObj,
    Map fileObj,
    List mediaGallery,
    int time,
    int numOfFiles,
  }) async {
    DocumentReference userGroupDF =
        userCollection.doc(uid).collection('groups').doc(groupChatId);

    DocumentSnapshot userGroupDS = await userGroupDF.get();

    int numOfUploads = userGroupDS.data().toString().contains('numofUploads')
        ? userGroupDS.get('numofUploads')
        : null;

    try {
      numOfUploads = userGroupDS.get('numofUploads');
    } on StateError {
      numOfUploads = null;
    }

    if (numOfUploads == null) {
      userGroupDF.update({"numOfUploads": numOfFiles ?? 1});
    } else {
      numOfUploads =
          numOfFiles == null ? numOfUploads + 1 : numOfUploads + numOfFiles;
      userGroupDF.update({"numOfUploads": numOfUploads});
    }

    DocumentSnapshot groupDS = await groupChatCollection.doc(groupChatId).get();
    String hashTag = groupDS.get('hashTag');

    DocumentReference chatDocRef =
        await groupChatCollection.doc(groupChatId).collection("chats").add({
      'message': '',
      'sendBy': Constants.myName,
      'userId': uid,
      'time': time,
      'imgObj': imgObj,
      'fileObj': fileObj,
      'mediaGallery': mediaGallery,
      'group': '${groupChatId}_$hashTag',
    });

    return chatDocRef.id;
  }

  handleGroupChatMedia(
    String chatId,
    Map imgObj,
    Map fileObj,
    List mediaGallery,
    String groupChatId,
    String groupState,
    bool anon,
    String username,
    String userId,
    int time,
  ) {
    fileCopiesCollection.doc(chatId).set({'numOfCopies': 1});

    if (groupState == "public") {
      Map mediaObj = imgObj ?? fileObj;
      addMediaItem(
        groupChatId,
        anon,
        username,
        userId,
        chatId,
        time,
        mediaObj,
        mediaGallery,
      );
    }
  }

  addConversationMessages(
      {String groupChatId,
      String message,
      String username,
      String userId,
      int time,
      List mediaGallery,
      Map imgObj,
      Map fileObj,
      Map inChatReply,
      String ogMediaId,
      String ogSenderId,
      String chatId}) async {
    DocumentSnapshot groupDS = await groupChatCollection.doc(groupChatId).get();
    String hashTag = groupDS.get('hashTag');
    String groupState = groupDS.get('chatRoomState');
    bool anon = groupDS.get('anon') != null && groupDS.get('anon');

    bool audio = fileObj != null &&
        audioChecker(fileObj["fileName"]) &&
        ogMediaId == null;
    bool pdf =
        fileObj != null && pdfChecker(fileObj["fileName"]) && ogMediaId == null;
    bool media = (imgObj != null || mediaGallery != null) && ogMediaId == null;
    bool url = urlRegExp.hasMatch(message);

    if (chatId == null) {
      DocumentReference chatDocRef =
          await groupChatCollection.doc(groupChatId).collection("chats").add({
        'message': message,
        'sendBy': username,
        'userId': userId,
        'time': time,
        'imgObj': imgObj,
        'fileObj': fileObj,
        'mediaGallery': mediaGallery,
        'replies': [],
        'group': '${groupChatId}_$hashTag',
        'inChatReply': inChatReply,
        'ogSenderId': ogSenderId,
        'ogMediaId': ogMediaId,
        'audio': audio,
        'pdf': pdf,
        'media': media,
        'feed': audio || pdf || media,
        'url': url,
      });

      // addNotification(
      //     groupChatId:groupChatId,
      //     chatId:chatDocRef.id,
      //     senderId:userId,
      //     ogSenderId: ogSenderId != null ? ogSenderId : userId
      // );

      if (media || audio || pdf) {
        handleGroupChatMedia(chatDocRef.id, imgObj, fileObj, mediaGallery,
            groupChatId, groupState, anon, username, userId, time);
      }
    } else {
      groupChatCollection.doc(groupChatId).collection('chats').doc(chatId).set({
        'message': message,
        'sendBy': username,
        'userId': userId,
        'time': time,
        'imgObj': imgObj,
        'fileObj': fileObj,
        'mediaGallery': mediaGallery,
        'replies': [],
        'audio': audio,
        'pdf': pdf,
        'media': media,
        'feed': audio || pdf || media,
        'url': url,
      });

      // addNotification(groupChatId:groupChatId, chatId:chatId, senderId:userId, ogSenderId:userId);

      DocumentReference groupDF =
          userCollection.doc(userId).collection('groups').doc(groupChatId);
      DocumentSnapshot groupDS = await groupDF.get();
      int numOfUploads = groupDS.data().toString().contains('numOfUploads')
          ? groupDS.get('numOfUploads')
          : 0;
      if (numOfUploads > 0) {
        numOfUploads = numOfUploads - 1;
        groupDF.update({"numOfUploads": numOfUploads});
      }

      if (media || audio || pdf) {
        handleGroupChatMedia(chatId, imgObj, fileObj, mediaGallery, groupChatId,
            groupState, anon, username, userId, time);
      }
    }
  }

  // addNotification({String groupChatId, String chatId, String senderId, String ogSenderId}) async{
  //   DocumentSnapshot groupSnapshot = await groupChatCollection.doc(groupChatId).get();
  //   DocumentSnapshot senderSnapshot = await userCollection.doc(ogSenderId).get();
  //
  //   List members = groupSnapshot.data()['members'];
  //   List blockedBy = senderSnapshot.data()['blockedBy'] != null ? senderSnapshot.data()['blockedBy'] : [];
  //
  //   for(String member in members){
  //     if(member != senderId && !blockedBy.contains(member)){
  //       DocumentReference userGroupDocRef = userCollection.doc(member)
  //           .collection('groups')
  //           .doc(groupChatId);
  //
  //       DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
  //       if(!userGroupSnapshot.data()['inChat']){
  //         int numOfNewMsg = userGroupSnapshot.data()['numOfNewMsg'];
  //         numOfNewMsg = numOfNewMsg == null ? 1 : numOfNewMsg + 1;
  //         userGroupDocRef.update({
  //           'numOfNewMsg':numOfNewMsg,
  //           'newMsg':FieldValue.arrayUnion([chatId])
  //         });
  //       }
  //     }
  //   }
  //
  //   Map spectators = groupSnapshot.data()['waitList'];
  //   String groupState = groupSnapshot.data()['chatRoomState'];
  //
  //   if(groupState != "private"){
  //     for(String spectator in spectators.keys){
  //       if(!blockedBy.contains(spectator)){
  //         DocumentReference userGroupDocRef = userCollection
  //             .doc(spectator)
  //             .collection('groups')
  //             .doc(groupChatId);
  //
  //         DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
  //
  //         if(!userGroupSnapshot.data()['inChat']){
  //           int numOfNewMsg = userGroupSnapshot.data()['numOfNewMsg'];
  //           numOfNewMsg = numOfNewMsg == null ? 1 : numOfNewMsg + 1;
  //           userGroupDocRef.update({
  //             'numOfNewMsg':numOfNewMsg,
  //             'newMsg':FieldValue.arrayUnion([chatId])
  //           });
  //         }
  //       }
  //
  //     }
  //   }
  // }

  Future<int> getMsgIndex(String groupId, String chatId) async {
    DocumentReference chatDocRef =
        groupChatCollection.doc(groupId).collection('chats').doc(chatId);
    DocumentSnapshot chatSnapshot = await chatDocRef.get();
    int chatIndex = -1;

    if (chatSnapshot.exists) {
      await groupChatCollection
          .doc(groupId)
          .collection('chats')
          .orderBy("time", descending: true)
          .endAtDocument(chatSnapshot)
          .get()
          .then((value) => chatIndex = value.docs.length - 1);
    }
    return chatIndex;
  }

  getConversationMessages(String groupChatId) {
    return groupChatCollection
        .doc(groupChatId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  getPersonalChatMedia(String personalChatId) {
    return personalChatCollection
        .doc(personalChatId)
        .collection("messages")
        .orderBy('sendTime', descending: true)
        .where("media", isEqualTo: true)
        .snapshots();
  }

  pinMyGroup(String groupId) {
    userCollection
        .doc(uid)
        .collection('groups')
        .doc(groupId)
        .update({"pinned": true});
  }

  unPinMyGroup(String groupId) {
    userCollection
        .doc(uid)
        .collection('groups')
        .doc(groupId)
        .update({"pinned": false});
  }

  getGroupStory(String groupId) {
    return userCollection
        .doc(uid)
        .collection('groups')
        .doc(groupId)
        .collection('stories')
        .orderBy('sendTime', descending: true)
        .snapshots();
  }

  getGroupFeed(String groupChatId) async {
    return await groupChatCollection
        .doc(groupChatId)
        .collection("chats")
        .orderBy('time', descending: true)
        .where("feed", isEqualTo: true)
        .get();
  }

  getGroupMedia(String groupChatId) async {
    return await groupChatCollection
        .doc(groupChatId)
        .collection("chats")
        .orderBy('time', descending: true)
        .where("media", isEqualTo: true)
        .get();
  }

  getGroupAudio(String groupChatId) async {
    return await groupChatCollection
        .doc(groupChatId)
        .collection("chats")
        .orderBy('time', descending: true)
        .where("audio", isEqualTo: true)
        .get();
  }

  getGroupPDF(String groupChatId) async {
    return await groupChatCollection
        .doc(groupChatId)
        .collection("chats")
        .orderBy('time', descending: true)
        .where("pdf", isEqualTo: true)
        .get();
  }

  getGroupURL(String groupChatId) async {
    return await groupChatCollection
        .doc(groupChatId)
        .collection("chats")
        .orderBy('time', descending: true)
        .where("url", isEqualTo: true)
        .get();
  }

  getPersonalMessages(String personalChatId) {
    return personalChatCollection
        .doc(personalChatId)
        .collection("messages")
        .orderBy("sendTime", descending: true)
        .snapshots();
  }

  getPersonalChats() {
    return userCollection
        .doc(uid)
        .collection('replies')
        .orderBy('replyTime', descending: true)
        .snapshots();
  }

  getUserChats() {
    return userCollection.doc(uid).collection('groups').snapshots();
  }

  muteMyGroup(String groupId) {
    userCollection.doc(uid).update({
      "mutedChats": FieldValue.arrayUnion([groupId])
    });
  }

  unMuteMyGroup(String groupId) {
    userCollection.doc(uid).update({
      "mutedChats": FieldValue.arrayRemove([groupId])
    });
  }

  getMyGroups() {
    return userCollection
        .doc(uid)
        .collection('groups')
        .where('spectating', isEqualTo: false)
        .orderBy('numOfNewMsg', descending: true)
        .snapshots();
  }

  getSpectatingChats() {
    return userCollection
        .doc(uid)
        .collection('groups')
        .where('spectating', isEqualTo: true)
        .snapshots();
  }

  suggestGroups() async {
    DocumentSnapshot userSnapshot = await userCollection.doc(uid).get();
    List tags = userSnapshot.data().toString().contains('tags')
        ? userSnapshot.get('tags')
        : [];
    return await AlgoliaMethods.getSuggestedGroups(tags);
  }

  suggestUsers() async {
    DocumentSnapshot userSnapshot = await userCollection.doc(uid).get();
    List tags = userSnapshot.data().toString().contains('tags')
        ? userSnapshot.get('tags')
        : [];
    return await AlgoliaMethods.getSuggestedUsers(tags);
  }

  addMediaItem(
    String groupId,
    bool anon,
    String sendBy,
    String senderId,
    String chatId,
    int sendTime,
    Map mediaObj,
    List mediaGallery,
  ) async {
    DocumentSnapshot groupSnapshot =
        await groupChatCollection.doc(groupId).get();
    DocumentSnapshot userSnapshot = await userCollection.doc(senderId).get();
    List blockedBy = groupSnapshot.data().toString().contains('blockedBy')
        ? userSnapshot.get("blockedBy")
        : [];
    List tags = groupSnapshot.data().toString().contains('tags')
        ? groupSnapshot.get('tags')
        : [];
    String hashTag = groupSnapshot.data().toString().contains('hashTag')
        ? groupSnapshot.get("hashTag")
        : null;

    mediaCollection.doc(chatId).set({
      "sendBy": sendBy,
      "senderId": senderId,
      "sendTime": sendTime,
      "mediaObj": mediaObj,
      "mediaGallery": mediaGallery,
      "groupId": groupId,
      'hashTag': hashTag,
      "tags": tags,
      "anon": anon,
      'media': (mediaObj != null && mediaObj["imgName"] != null) ||
          mediaGallery != null,
      'audio': mediaObj != null &&
          mediaObj["fileName"] != null &&
          audioChecker(mediaObj["fileName"]),
      'pdf': mediaObj != null &&
          mediaObj["fileName"] != null &&
          pdfChecker(mediaObj["fileName"]),
      'notVisibleTo': blockedBy
    });
  }

  // deleteMediaItem(String mediaId) async{
  //   mediaCollection.doc(mediaId).delete();
  //   DocumentReference mediaDF = mediaCommentCollection.doc(mediaId);
  //   DocumentSnapshot mediaDS = await mediaDF.get();
  //   if(mediaDS.exists){
  //     mediaDF.collection("comments").get().then((QuerySnapshot commentQS) {
  //       commentQS.docs.forEach((DocumentSnapshot commentDS) {
  //         mediaDF.collection("comments").doc(commentDS.id).delete();
  //       });
  //     });
  //     await mediaDF.delete();
  //   }
  // }

  addMediaComment(String mediaId, String comment) async {
    DocumentReference mediaDF = mediaCommentCollection.doc(mediaId);

    DocumentSnapshot mediaDS = await mediaDF.get();
    if (!mediaDS.exists) await mediaDF.set({"mediaId": mediaId});

    mediaDF.collection('comments').add({
      "senderId": uid,
      "comment": comment,
      "sendTime": DateTime.now().microsecondsSinceEpoch
    });
  }

  delMedia(String mediaId) {
    DocumentReference mediaComDF = mediaCommentCollection.doc(mediaId);
    mediaComDF.collection('comments').get().then((QuerySnapshot comQS) {
      for (var comDS in comQS.docs) {
        delMediaComment(mediaId, comDS.id);
      }
    });
    mediaComDF.delete();
  }

  delMediaComment(String mediaId, String commentId) {
    mediaCommentCollection
        .doc(mediaId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  getMediaComments(String mediaId) {
    return mediaCommentCollection
        .doc(mediaId)
        .collection('comments')
        .orderBy("sendTime", descending: true)
        .snapshots();
  }

  updateUserSchoolInfo(String school) {
    userCollection.doc(uid).update({'school': school});
  }

  updateUserProgramInfo(String program) {
    userCollection.doc(uid).update({'program': program});
  }

  deleteUserQuote() {
    Constants.myQuote = '';
    userCollection.doc(uid).update({'quote': ''});
  }

  editUserQuote(String newQuote) {
    Constants.myQuote = newQuote;
    userCollection.doc(uid).update({'quote': newQuote});
  }

  deleteUserTag(String tag) async {
    DocumentReference userDocRef = userCollection.doc(uid);
    DocumentSnapshot userSnapshot = await userDocRef.get();
    List tags = userSnapshot.get('tags');
    tags.remove(tag);
    userDocRef.update({'tags': tags});
  }

  addUserTag(String tag, int index) async {
    DocumentReference userDocRef = userCollection.doc(uid);
    DocumentSnapshot userSnapshot = await userDocRef.get();

    List tags = userSnapshot.get('tags');
    if (tags.length - 1 < index) {
      tags.add(tag);
    } else {
      tags[index] = tag;
    }
    userDocRef.update({'tags': tags});
    return tags;
  }

  editGroupInfo(String newQuote, String groupId) {
    groupChatCollection.doc(groupId).update({'about': newQuote});
  }

  editGroupAnon(String groupId, bool anon) {
    groupChatCollection.doc(groupId).update({'anon': anon});
    mediaCollection
        .where('groupId', isEqualTo: groupId)
        .get()
        .then((QuerySnapshot mdQS) {
      for (var mdDS in mdQS.docs) {
        mediaCollection.doc(mdDS.id).update({'anon': anon});
      }
    });
  }

  delGroupTag(String tag, String groupId) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupSnapshot = await groupDocRef.get();

    List tags = groupSnapshot.get('tags');
    tags.remove(tag);

    groupDocRef.update({'tags': tags});
    // editMediaItemTag(groupId, tags);
  }

  addGroupTag(String tag, int index, String groupId) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupSnapshot = await groupDocRef.get();

    List tags = groupSnapshot.get('tags');
    if (tags.length - 1 < index) {
      tags.add(tag);
    } else {
      tags[index] = tag;
    }
    groupDocRef.update({'tags': tags});
    // editMediaItemTag(groupId, tags);
  }

  // editMediaItemTag(String groupId, List tags) async{
  //
  //   mediaCollection.where('groupId', isEqualTo: groupId).get().then((QuerySnapshot mdQS){
  //     mdQS.docs.forEach((DocumentSnapshot mdDS) {
  //       mediaCollection.doc(mdDS.id).update({'tags':tags});
  //     });
  //   });
  // }

  editGroupHashTag(String groupId, String hashTag) {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    groupDocRef.update({'hashTag': hashTag});

    // mediaCollection.where('groupId', isEqualTo: groupId).get().then((QuerySnapshot mdQS){
    //   mdQS.docs.forEach((DocumentSnapshot mdDS){
    //     mediaCollection.doc(mdDS.id).update({'hashTag':hashTag});
    //   });
    // });
  }

  updateGroupCapacity(String groupId, double groupCapacity) {
    groupChatCollection.doc(groupId).update({'groupCapacity': groupCapacity});
  }

  getGroupChatById(String groupId) async {
    return await groupChatCollection.doc(groupId).get();
  }

  getGroupMembers(String groupId) {
    return groupChatCollection.doc(groupId).collection('users').snapshots();
  }

  getAllUsers() {
    return userCollection
        .where('email', isNotEqualTo: Constants.myEmail)
        .snapshots();
  }

  getPublicGroup(String searchText, bool oneDay) {
    return AlgoliaMethods.getStreamGroups(searchText, oneDay);
  }

  getSugTags({max = 8}) async {
    List hotTags = await getHotTags();
    return await AlgoliaMethods.getSugTags(hotTags, max);
  }

  // converts format of AlgoliaQuerySnapshot to match that of QuerySnapshot as in firebase responses,
  // use when receiving result from algolia and not from firebase
  searchGroupChats(String searchText) {
    // return await groupChatCollection
    //     .where('searchKeys', arrayContains: searchText )
    //     .snapshots();
    return AlgoliaMethods.searchGroupChats(searchText);
  }

  searchUsers(String searchText) {
    return AlgoliaMethods.searchUsers(searchText);
  }

  getStoryComments(String storyId) {
    return storyCommentsCollection
        .doc(storyId)
        .collection('comments')
        .orderBy("sendTime")
        .snapshots();
  }

  getCommentReplies(String storyId, String commentId) {
    return storyCommentsCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('sendTime')
        .snapshots();
  }

  addStoryComment(String storyId, String storySenderId, String comment) async {
    DocumentReference storyDocRef = storyCommentsCollection.doc(storyId);
    await storyDocRef.collection('comments').add({
      "senderId": uid,
      "comment": comment,
      "storySenderId": storySenderId,
      "storyId": storyId,
      "sendTime": DateTime.now().microsecondsSinceEpoch
    });
  }

  addCommentReply(String storyId, String commentId, String reply) async {
    await storyCommentsCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .collection("replies")
        .add({
      "replierId": uid,
      "reply": reply,
      "sendTime": DateTime.now().microsecondsSinceEpoch
    });
  }

  delStoryComment(String storyId, String commentId) async {
    DocumentReference commentDF = storyCommentsCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId);

    commentDF.collection('replies').get().then((QuerySnapshot replyQS) {
      for (var replyDS in replyQS.docs) {
        commentDF.collection('replies').doc(replyDS.id).delete();
      }
    });

    await commentDF.delete();

    // await storyDocRef.collection('comments').doc(commentId).delete();
    //
    // commentRepliesCollection.doc(commentId).collection('replies').get().then((QuerySnapshot replyQS){
    //   replyQS.docs.forEach((DocumentSnapshot replyDS) {
    //     commentRepliesCollection.doc(commentId).collection('replies').doc(replyDS.id).delete();
    //   });
    // });
    //
    // commentRepliesCollection.doc(commentId).delete();
  }

  delCommentReply(String storyId, String commentId, String replyId) async {
    // DocumentReference commentDocRef = commentRepliesCollection.doc(commentId);
    // await commentDocRef.collection('replies').doc(replyId).delete();

    await storyCommentsCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .delete();

    // DocumentReference storyComDocRef = storyCommentsCollection.doc(storyId).collection('comments').doc(commentId);
    // DocumentSnapshot storyComSnapshot = await storyComDocRef.get();
    // int numOfReplies = storyComSnapshot.data()["numOfReplies"];
    // if(numOfReplies != null){
    //   numOfReplies = numOfReplies - 1;
    //   storyComDocRef.update({"numOfReplies":numOfReplies});
    // }
  }

  delStory(String storyId) async {
    DocumentReference storyDF = storyCommentsCollection.doc(storyId);
    DocumentSnapshot storyDS = await storyDF.get();
    if (storyDS.exists) {
      storyDF.collection('comments').get().then((QuerySnapshot comQS) {
        for (var comDS in comQS.docs) {
          storyCommentsCollection
              .doc(storyId)
              .collection('comments')
              .doc(comDS.id)
              .collection('replies')
              .get()
              .then((QuerySnapshot replyQS) {
            for (DocumentSnapshot replyDS in replyQS.docs) {
              storyCommentsCollection
                  .doc(storyId)
                  .collection('comments')
                  .doc(comDS.id)
                  .collection('replies')
                  .doc(replyDS.id)
                  .delete();
            }
          });
          storyCommentsCollection
              .doc(storyId)
              .collection('comments')
              .doc(comDS.id)
              .delete();
        }
      });
      storyDF.delete();
    }
  }

  Future<String> uploadFileToStory(
      {Map mediaObj, List mediaGallery, int sendTime, String type}) async {
    DocumentReference userDF = userCollection.doc(uid);
    DocumentSnapshot userDS = await userDF.get();
    int numOfUploads = userDS.data().toString().contains('numofUploads')
        ? userDS.get('numofUploads')
        : null;
    try {
      numOfUploads = userDS.get('numofUploads');
    } on StateError {
      numOfUploads = null;
    }
    if (numOfUploads == null) {
      await userDF.update({"numOfUploads": 1});
    } else {
      numOfUploads = numOfUploads + 1;
      await userDF.update({"numOfUploads": numOfUploads});
    }

    DocumentReference storyDF =
        await userCollection.doc(uid).collection('stories').add({
      "mediaObj": mediaObj,
      "mediaGallery": mediaGallery,
      "sendTime": sendTime,
      "type": type,
    });

    return storyDF.id;
  }

  createStory({
    Map mediaObj,
    List mediaGallery,
    List searchKeys,
    int sendTime,
    bool anon,
    String storyId,
    String type,
    Map sendTo,
    AsyncSnapshot groupSnapshot,
    List rmvGroups,
    AsyncSnapshot userSnapshot,
    List rmvUsers,
  }) async {
    // DocumentReference senderDS = senderStoriesCollection.doc(uid);
    DocumentReference senderDS = userCollection.doc(uid);

    Map<String, dynamic> storyInfo = {};

    if (storyId == null) {
      DocumentReference storyDS = await senderDS.collection('stories').add({
        "mediaObj": mediaObj,
        "mediaGallery": mediaGallery,
        "sendTime": sendTime,
        "senderId": uid,
        "seenList": [],
        "anon": anon,
        "type": type,
      });
      storyInfo = {
        "mediaObj": mediaObj,
        "mediaGallery": mediaGallery,
        "senderId": uid,
        "sender": Constants.myName,
        "sendTime": sendTime,
        "anon": anon,
        "type": type,
        "storyId": storyDS.id,
      };
      fileCopiesCollection.doc(storyDS.id).set({'numOfCopies': 1});
    } else {
      senderDS.collection('stories').doc(storyId).set({
        "mediaObj": mediaObj,
        "mediaGallery": mediaGallery,
        "sendTime": sendTime,
        "senderId": uid,
        "seenList": [],
        "anon": anon,
        "type": type,
      });
      storyInfo = {
        "mediaObj": mediaObj,
        "mediaGallery": mediaGallery,
        "senderId": uid,
        "sender": Constants.myName,
        "sendTime": sendTime,
        "anon": anon,
        "type": type,
        "storyId": storyId,
      };

      fileCopiesCollection.doc(storyId).set({'numOfCopies': 1});
      DocumentReference userDF = userCollection.doc(uid);
      DocumentSnapshot userDS = await userDF.get();
      int numOfUploads = userDS.data().toString().contains('numOfUploads')
          ? userDS.get('numOfUploads')
          : 0;
      if (numOfUploads > 0) {
        numOfUploads = numOfUploads - 1;
        await userDF.update({"numOfUploads": numOfUploads});
      }
    }

    if (type == "regular") {
      sendMediaReg(storyInfo, sendTo);
    } else if (type == "friends") {
      sendMediaFriends(storyInfo);
    } else {
      sendMediaSnippet(
          storyInfo, groupSnapshot, rmvGroups, userSnapshot, rmvUsers);
    }
  }

  sendMediaReg(Map<String, dynamic> storyInfo, Map sendTo) {
    String senderId = storyInfo["senderId"];
    String storyId = storyInfo["storyId"];
    storyInfo.remove('sender');
    List<String> friendIds = [];
    List<String> groupIds = [];

    for (String sendToId in sendTo.keys) {
      if (sendTo[sendToId]['type'] == "group") {
        groupIds.add(sendToId);
        storyInfo["anon"] = sendTo[sendToId]['anon'];
        storyInfo["groupId"] = sendToId;
        groupChatCollection
            .doc(sendToId)
            .collection('stories')
            .doc(storyId)
            .set(storyInfo);
      } else {
        friendIds.add(sendToId);
        storyInfo["anon"] = false;
        storyInfo["friendId"] = sendToId;
        userCollection
            .doc(sendToId)
            .collection('friends')
            .doc(uid)
            .collection('stories')
            .doc(storyId)
            .set(storyInfo);
      }
    }

    userCollection
        .doc(senderId)
        .collection('stories')
        .doc(storyId)
        .update({"recGroups": groupIds, "recFriends": friendIds});
  }

  sendMediaFriends(Map<String, dynamic> storyInfo) {
    String storyId = storyInfo["storyId"];
    storyInfo["anon"] = false;

    userCollection
        .doc(uid)
        .collection('friends')
        .get()
        .then((QuerySnapshot friendQS) {
      for (var friendDS in friendQS.docs) {
        storyInfo["toId"] = friendDS.id;
        userCollection
            .doc(friendDS.id)
            .collection('recStories')
            .doc(storyId)
            .set(storyInfo);
      }
    });
  }

  sendMediaSnippet(
    Map<String, dynamic> storyInfo,
    AsyncSnapshot groupSnapshot,
    List rmvGroups,
    AsyncSnapshot userSnapshot,
    List rmvUsers,
  ) {
    String storyId = storyInfo["storyId"];
    String senderId = storyInfo["senderId"];
    List groupIds = [];
    List userIds = [];

    storyInfo.remove("sender");
    for (int i = 0; i < (groupSnapshot.data.hits.length as int); i++) {
      if (!rmvGroups.contains(groupSnapshot.data.hits[i].objectID)) {
        groupIds.add(groupSnapshot.data.hits[i].objectID);
        // storyInfo['groupId'] = groupSnapshot.data.hits[i].objectID;
        // groupChatCollection.doc(groupSnapshot.data.hits[i].objectID).collection('stories').doc(storyId).set(storyInfo);
      }
    }

    for (int i = 0; i < (userSnapshot.data.hits.length as int); i++) {
      String userId = userSnapshot.data.hits[i].objectID;
      // List blockList = userSnapshot.data.hits[i].data["blockList"];
      // if((blockList == null || !blockList.contains(senderId)) && !Constants.myBlockList.contains(userId)){
      if (!rmvUsers.contains(userId) && userId != Constants.myUserId) {
        userIds.add(userId);
        // storyInfo["toId"] = userId;
        // userCollection.doc(userId).collection('recStories').doc(storyId).set(storyInfo);
      }
      // }
    }

    userCollection
        .doc(senderId)
        .collection('stories')
        .doc(storyId)
        .update({"recGroups": groupIds, "recUsers": userIds});
  }

  deleteSenderStory(String storyId, Map mediaObj, List mediaGallery) async {
    DocumentReference senderDF = userCollection.doc(uid);
    DocumentReference storyDF = senderDF.collection('stories').doc(storyId);
    DocumentSnapshot storyDS = await storyDF.get();

    if (storyDS.exists) {
      storyDF.delete();
    }

    delFileCopies(
        mediaId: storyId, imgObj: mediaObj, mediaGallery: mediaGallery);
  }

  getSenderStories(bool owner) {
    if (owner) {
      return userCollection
          .doc(uid)
          .collection('stories')
          .orderBy("sendTime", descending: true)
          .snapshots();
    } else {
      return userCollection
          .doc(uid)
          .collection('stories')
          .where('type', isEqualTo: "snippet")
          .orderBy("sendTime", descending: true)
          .snapshots();
    }
  }

  // addStoryToExplore(
  //     String storyId,
  //     String sendBy,
  //     String senderId,
  //     int sendTime,
  //     Map mediaObj,
  //     List mediaGallery,
  //     bool anon,
  //     List searchKeys,
  //     ){
  //
  //   mediaCollection.doc(storyId).set({
  //     "sendBy":sendBy,
  //     "senderId":senderId,
  //     "sendTime":sendTime,
  //     "mediaObj":mediaObj,
  //     "mediaGallery":mediaGallery,
  //     "anon":anon,
  //     "tags":searchKeys,
  //     "story":true,
  //   });
  //
  // }

  markSeenStory(String senderId, String storyId) async {
    if (senderId != uid) {
      userCollection.doc(senderId).collection('stories').doc(storyId).update({
        "seenList": FieldValue.arrayUnion([uid])
      });
    }
  }

  deleteReceiverStory(
      String storyId, String friendId, String groupId, String type) {
    if (type == "regular") {
      if (groupId != null) {
        groupChatCollection
            .doc(groupId)
            .collection('stories')
            .doc(storyId)
            .delete();
      }
      if (friendId != null) {
        userCollection
            .doc(uid)
            .collection('friends')
            .doc(friendId)
            .collection('stories')
            .doc(storyId)
            .delete();
      }
    } else if (type == "friends") {
      userCollection.doc(uid).collection('recStories').doc(storyId).delete();
    } else {
      if (groupId != null) {
        userCollection
            .doc(uid)
            .collection('groups')
            .doc(groupId)
            .collection('stories')
            .doc(storyId)
            .delete();
      } else {
        userCollection.doc(uid).collection('recStories').doc(storyId).delete();
      }
      // groupChatCollection.doc(groupId).collection('stories').doc(storyId).delete();
    }
  }

  getReceiverStories() {
    return userCollection
        .doc(uid)
        .collection('recStories')
        .orderBy("sendTime", descending: true)
        .snapshots();

    // return receiverStoriesCollection
    //     .doc(uid)
    //     .collection('stories')
    //     .orderBy("time", descending: true)
    //     .snapshots();
  }

  getMyInvites() {
    return userCollection
        .doc(uid)
        .collection('invites')
        .orderBy('inviteTime', descending: true)
        .snapshots();
  }

  removeInvite(String groupId) async {
    DocumentReference userInviteDocRef =
        userCollection.doc(uid).collection('invites').doc(groupId);
    DocumentSnapshot userInviteSnapshot = await userInviteDocRef.get();
    if (userInviteSnapshot.exists) {
      userInviteDocRef.delete();
    }

    groupChatCollection.doc(groupId).update({
      'invites': FieldValue.arrayRemove([uid])
    });
  }

  inviteUser(String groupId, String hashTag, String groupState) async {
    userCollection.doc(uid).collection('invites').doc(groupId).set({
      "invitorName": Constants.myName,
      "invitorId": Constants.myUserId,
      "groupState": groupState,
      "inviteTime": DateTime.now().microsecondsSinceEpoch,
      "toId": uid,
      "hashTag": hashTag
    });

    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupDocSnapshot = await groupDocRef.get();

    List invites = groupDocSnapshot.data().toString().contains('invites')
        ? groupDocSnapshot.get('invites')
        : null;
    if (invites != null) {
      groupDocRef.update({
        'invites': FieldValue.arrayUnion([uid])
      });
    } else {
      groupDocRef.update({
        'invites': [uid]
      });
    }
  }

  Future requestJoinGroup(String groupId, String username, String userId,
      String email, Map imgObj) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupDocSnapshot = await groupDocRef.get();

    Map joinRequests =
        groupDocSnapshot.data().toString().contains('joinRequests')
            ? groupDocSnapshot.get('joinRequests')
            : null;

    if (!joinRequests.containsKey(userId)) {
      joinRequests[userId] = {
        "username": username,
        "email": email,
        "imgObj": imgObj
      };
      await groupDocRef.update({'joinRequests': joinRequests});
    }

    String admin = groupDocSnapshot.get('admin');

    removeInvite(groupId);

    DocumentReference userGroupDocRef =
        userCollection.doc(admin).collection('groups').doc(groupId);

    DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();
    Map joinReq = userGroupSnapshot.get('joinRequests');

    if (!joinReq.containsKey(userId)) {
      joinReq[userId] = {
        "username": username,
        "email": email,
        "imgObj": imgObj
      };
      userGroupDocRef.update({'joinRequests': joinReq});
    }
  }

  Future declineJoinRequest(String groupId) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupDocSnapshot = await groupDocRef.get();

    Map joinRequests =
        groupDocSnapshot.data().toString().contains('joinRequests')
            ? groupDocSnapshot.get('joinRequests')
            : null;
    if (joinRequests.containsKey(uid)) {
      if (joinRequests[uid]['imgObj'] != null) {
        Reference imgRef = FirebaseStorage.instance
            .refFromURL(joinRequests[uid]['imgObj']['imgUrl']);
        await imgRef.delete();
      }

      joinRequests.remove(uid);
      groupDocRef.update({'joinRequests': joinRequests});
    }

    DocumentReference userGroupDocRef = userCollection
        .doc(Constants.myUserId)
        .collection('groups')
        .doc(groupId);

    DocumentSnapshot userGroupDocSnapshot = await userGroupDocRef.get();
    Map joinReq =
        userGroupDocSnapshot.data().toString().contains('joinRequests')
            ? userGroupDocSnapshot.get('joinRequests')
            : null;

    if (joinReq.containsKey(uid)) {
      joinReq.remove(uid);
      userGroupDocRef.update({'joinRequests': joinReq});
    }
  }

  Future putOnWaitList(
    String groupId,
    String username,
    String userId,
    String email,
    Map imgObj,
  ) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupDocSnapshot = await groupDocRef.get();

    removeInvite(groupId);

    Map waitList = groupDocSnapshot.data().toString().contains('waitList')
        ? groupDocSnapshot.get('waitList')
        : null;

    if (!waitList.containsKey(userId)) {
      waitList[userId] = {
        "username": username,
        "email": email,
        'imgObj': imgObj,
        'time': DateTime.now().microsecondsSinceEpoch
      };

      await groupDocRef.update({'waitList': waitList});
    }

    String chatRoomState = groupDocSnapshot.get('chatRoomState');
    bool oneDay = groupDocSnapshot.data().toString().contains('oneDay')
        ? groupDocSnapshot.get('oneDay')
        : false;
    int createdAt = groupDocSnapshot.data().toString().contains('createdAt')
        ? groupDocSnapshot.get('createdAt')
        : 0;
    if (chatRoomState != 'private') {
      await userCollection.doc(userId).collection('groups').doc(groupId).set({
        'groupId': groupId,
        'newMsg': [],
        'numOfNewMsg': 0,
        'inChat': true,
        'createdAt': oneDay ? createdAt : null,
        'spectating': true
      });
      groupChatCollection
          .doc(groupId)
          .collection('spectators')
          .doc(userId)
          .set({'userId': userId, "groupId": groupId});
    }
  }

  Future joinGroupChat(String groupId, String hashTag, String userId,
      String actionType, bool oneDay, int createdAt) async {
    bool inChat = actionType == "JOIN_PUB_GROUP_CHAT";

    removeInvite(groupId);

    await groupChatCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId])
    });

    await userCollection.doc(userId).collection('groups').doc(groupId).set({
      'groupId': groupId,
      'replies': {},
      'inChat': inChat,
      'newMsg': [],
      'numOfNewMsg': 0,
      'createdAt': oneDay ? createdAt : null,
      'pinned': false,
      'spectating': false
    });

    groupChatCollection
        .doc(groupId)
        .collection('users')
        .doc(userId)
        .set({'userId': userId, 'hashTag': hashTag, 'groupId': groupId});
  }

  Future toggleGroupMembership(String groupId, String actionType) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    DocumentSnapshot groupDocSnapshot = await groupDocRef.get();
    String hashTag = groupDocSnapshot.get('hashTag');
    String admin = groupDocSnapshot.get('admin');
    bool oneDay = groupDocSnapshot.data().toString().contains('oneDay')
        ? groupDocSnapshot.get('oneDay')
        : false;
    int createdAt = groupDocSnapshot.data().toString().contains('createdAt')
        ? groupDocSnapshot.get('createdAt')
        : 0;

    switch (actionType) {
      case "JOIN_PUB_GROUP_CHAT":
        {
          await joinGroupChat(
              groupId, hashTag, uid, actionType, oneDay, createdAt);
        }
        break;
      case "LEAVE_GROUP":
      case "BAN_USER":
        {
          Map waitList = groupDocSnapshot.get('waitList');
          String groupState = groupDocSnapshot.get('chatRoomState');

          await groupDocRef.update({
            'members': FieldValue.arrayRemove([uid])
          });

          if (actionType == "LEAVE_GROUP") {
            await groupDocRef.update({
              'leftUsers': FieldValue.arrayUnion([uid])
            });
          } else {
            await groupDocRef.update({
              'bannedUsers': FieldValue.arrayUnion([uid])
            });
          }

          if (waitList.isNotEmpty) {
            Map sortedWL = SplayTreeMap.from(waitList,
                (x, y) => waitList[x]['time'].compareTo(waitList[y]['time']));

            String userId = sortedWL.keys.elementAt(0);
            String username = waitList[userId]["username"];
            String email = waitList[userId]["email"];
            Map imgObj = waitList[userId]["imgObj"];

            if (groupState != "private") {
              await userCollection
                  .doc(userId)
                  .collection('groups')
                  .doc(groupId)
                  .delete();

              await joinGroupChat(
                  groupId, hashTag, userId, actionType, oneDay, createdAt);

              if (imgObj != null) {
                DateTime now = DateTime.now();
                addConversationMessages(
                  groupChatId: groupId,
                  message: '',
                  username: username,
                  userId: userId,
                  time: now.microsecondsSinceEpoch,
                  imgObj: imgObj,
                );
              }
            } else {
              requestJoinGroup(groupId, username, userId, email, imgObj);
            }

            waitList.remove(userId);
            await groupDocRef.update({'waitList': waitList});
          }

          await userCollection
              .doc(uid)
              .collection('groups')
              .doc(groupId)
              .delete();
          await groupChatCollection
              .doc(groupId)
              .collection('users')
              .doc(uid)
              .delete();
        }
        break;
      case "ACCEPT_JOIN_REQ":
        {
          Map joinRequests = groupDocSnapshot.get("joinRequests");
          Map imgObj = joinRequests[uid]["imgObj"];
          String username = joinRequests[uid]["username"];

          joinRequests.remove(uid);
          await groupDocRef.update({'joinRequests': joinRequests});

          DocumentReference userGroupDocRef = userCollection
              .doc(Constants.myUserId)
              .collection('groups')
              .doc(groupId);

          DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();

          Map joinReq = userGroupSnapshot.get('joinRequests');
          joinReq.remove(uid);
          await userGroupDocRef.update({'joinRequests': joinReq});

          joinGroupChat(groupId, hashTag, uid, actionType, oneDay, createdAt);

          if (imgObj != null) {
            DateTime now = DateTime.now();

            addConversationMessages(
              groupChatId: groupId,
              message: '',
              username: username,
              userId: uid,
              time: now.microsecondsSinceEpoch,
              imgObj: imgObj,
            );
          }
        }
        break;
      case "ACCEPT_REQ_BUT_FULL":
        {
          Map joinRequests = groupDocSnapshot.get("joinRequests");
          Map imgObj = joinRequests[uid]["imgObj"];
          String username = joinRequests[uid]["username"];
          String email = joinRequests[uid]["email"];

          joinRequests.remove(uid);
          await groupDocRef.update({'joinRequests': joinRequests});

          DocumentReference userGroupDocRef = userCollection
              .doc(Constants.myUserId)
              .collection('groups')
              .doc(groupId);

          DocumentSnapshot userGroupSnapshot = await userGroupDocRef.get();

          Map joinReq = userGroupSnapshot.get('joinRequests');
          joinReq.remove(uid);
          await userGroupDocRef.update({'joinRequests': joinReq});

          putOnWaitList(groupId, username, uid, email, imgObj);
        }
        break;
      case "ADD_USER":
        {
          await joinGroupChat(groupId, hashTag, uid, admin, oneDay, createdAt);
        }
        break;
      case "QUIT_SPECTATING":
        {
          userCollection.doc(uid).collection('groups').doc(groupId).delete();
          groupChatCollection
              .doc(groupId)
              .collection('spectators')
              .doc(uid)
              .delete();

          Map waitList = groupDocSnapshot.get('waitList');
          waitList.remove(uid);
          groupDocRef.update({'waitList': waitList});
        }
        break;
      default:
        {
          print('No such action');
        }
        break;
    }
  }

  setUpAnonImg() {
    Random random = Random();
    int randNum = random.nextInt(33);
    replaceUserAnonPic(randNum);
  }

  uploadUserBanner(String imgUrl) {
    userCollection.doc(uid).update({
      'banner': FieldValue.arrayUnion([imgUrl])
    });
  }

  removeUserBanner(String imgUrl) {
    rmvFileFromStorage(imgUrl);
    userCollection.doc(uid).update({
      'banner': FieldValue.arrayRemove([imgUrl])
    });
  }

  replaceUserAnonPic(int imgIndex) {
    Constants.myAnonImg = imgIndex;
    userCollection.doc(uid).update({'anonImg': imgIndex});
  }

  replaceUserPic(String imgUrl) {
    Constants.myProfileImg = imgUrl;
    userCollection.doc(uid).update({'profileImg': imgUrl});
  }

  replaceGroupPic(String imgUrl, String groupId) async {
    DocumentReference groupDocRef = groupChatCollection.doc(groupId);
    groupDocRef.update({'profileImg': imgUrl});
  }

  blockUser(String userId) async {
    Constants.myBlockList.add(userId);
    userCollection.doc(uid).update({
      "blockList": FieldValue.arrayUnion([userId]),
    });
    userCollection.doc(userId).update({
      "blockedBy": FieldValue.arrayUnion([uid])
    });
  }

  unBlockUser(String userId) async {
    Constants.myBlockList.remove(userId);
    userCollection.doc(uid).update({
      "blockList": FieldValue.arrayRemove([userId]),
    });
    userCollection.doc(userId).update({
      "blockedBy": FieldValue.arrayRemove([uid])
    });
  }

  reportContent(
      {String groupId,
      String personalChatId,
      String senderId,
      String contentId,
      String reportReason,
      String storyId,
      String commentId}) async {
    if (groupId != null) {
      groupChatCollection
          .doc(groupId)
          .collection('chats')
          .doc(contentId)
          .update({
        "reportedBy": FieldValue.arrayUnion([uid])
      });
    } else if (personalChatId != null) {
      personalChatCollection
          .doc(personalChatId)
          .collection('messages')
          .doc(contentId)
          .update({"reported": true});
    } else if (storyId != null) {
      if (commentId != null) {
        storyCommentsCollection
            .doc(storyId)
            .collection('comments')
            .doc(commentId)
            .collection('replies')
            .doc(contentId)
            .update({
          "reportedBy": FieldValue.arrayUnion([uid])
        });
      } else {
        storyCommentsCollection
            .doc(storyId)
            .collection('comments')
            .doc(contentId)
            .update({
          "reportedBy": FieldValue.arrayUnion([uid])
        });
      }
    }

    DocumentReference contentDF = reportedContentCollection.doc(contentId);
    await contentDF.set({
      "senderId": senderId,
      "groupId": groupId,
      "personalChatId": personalChatId,
      "storyId": storyId,
      "commentId": commentId
    });

    contentDF.collection("reporters").doc(uid).set({
      "reportReason": reportReason,
      "reportTime": DateTime.now().microsecondsSinceEpoch,
    });
  }

  reportUser({
    String senderId,
    String userReportedId,
    String reportReason,
  }) async {
    DocumentReference contentDF = reportedUsersCollection.doc(userReportedId);
    await contentDF.set({
      "senderId": senderId,
      "reportReason": reportReason,
      "reportTime": DateTime.now().microsecondsSinceEpoch,
      "userReportedId": userReportedId
    });
  }

  removeMedia(String mediaId) {
    // Constants.myRemovedMedia.add(mediaId);
    // userCollection.doc(uid).update({"removedMedia":FieldValue.arrayUnion([mediaId])});
    mediaCollection.doc(mediaId).update({
      "notVisibleTo": FieldValue.arrayUnion([uid])
    });
  }

  undoRemoveMedia(String mediaId) {
    // Constants.myRemovedMedia.remove(mediaId);
    // userCollection.doc(uid).update({"removedMedia":FieldValue.arrayRemove([mediaId])});
    mediaCollection.doc(mediaId).update({
      "notVisibleTo": FieldValue.arrayRemove([uid])
    });
  }

  addRecentSearch(String type, String docId) async {
    DocumentSnapshot myDS = await userCollection.doc(uid).get();
    List recentSearch = myDS.get(type) ?? [];
    recentSearch.remove(docId);
    recentSearch.insert(0, docId);

    if (recentSearch.length > 9) recentSearch.removeLast();
    userCollection.doc(uid).update({type: recentSearch});
  }

  removeRecentSearch(String type, String docId) {
    userCollection.doc(uid).update({
      type: FieldValue.arrayRemove([docId])
    });
  }

  clearRecentSearch() {
    userCollection.doc(uid).update({"reUserSearch": [], "reGroupSearch": []});
  }

  turnOffNotif() {
    userCollection.doc(uid).update({"notifOff": true});
  }

  turnOnNotif() {
    userCollection.doc(uid).update({"notifOff": false});
  }

  storyCleanUp() async {
    int counter = 0;
    return userCollection.doc(uid).collection('groups').get().then((groups) {
      if (groups.docs.isNotEmpty) {
        for (var group in groups.docs) {
          var stories = userCollection
              .doc(uid)
              .collection('groups')
              .doc(group.id)
              .collection('stories')
              .get();
          stories.then(
            (storySnap) async => await Future.forEach(
              storySnap.docs,
              (story) async {
                var storyId = story.id;
                var storyOwner = story.get('senderId');
                bool storyDs = await userCollection
                    .doc(storyOwner)
                    .collection('stories')
                    .doc(storyId)
                    .get()
                    .then((value) => value.exists);
                if (!storyDs) {
                  counter++;
                  userCollection
                      .doc(uid)
                      .collection('groups')
                      .doc(group.id)
                      .collection('stories')
                      .doc(story.id)
                      .delete();
                  print("$counter:$storyId");
                }
              },
            ),
          );
        }
      }
    });
  }

// constructKeyWordMap(String groupId){
//   Map<String, dynamic> keyWordMap = {};
//
//   int index = 0;
//
//   groupChatCollection.doc(groupId)
//       .collection('chats')
//       .orderBy("time", descending: true)
//       .get()
//       .then((QuerySnapshot chatQS) {
//         chatQS.docs.forEach((DocumentSnapshot chatDS) {
//
//           String message = chatDS.data()['message'];
//           List wordList = [];
//
//           if(message.isNotEmpty) wordList = message.split(' ');
//           else {
//             if(chatDS.data()['imgObj'] != null){
//               String caption = chatDS.data()['imgObj']['caption'];
//               if(caption != null && caption.isNotEmpty){
//                 wordList = caption.split(' ');
//               }
//             }
//           }
//
//           for(String word in wordList){
//             String lowerWord = word.toLowerCase();
//             if(!keyWordMap.containsKey(lowerWord)){
//               keyWordMap[lowerWord] = [index];
//             }else{
//               keyWordMap[lowerWord].add(index);
//             }
//           }
//
//           index ++;
//         });
//   });
//
//   return keyWordMap;
// }

}
