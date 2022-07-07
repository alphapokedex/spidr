import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';

fileSend({
  String personalChatId,
  String contactId,
  bool friend,
  String groupChatId,
  String chatId,
  String storyId,
  Map imgObj,
  Map fileObj,
  List mediaGallery,
  int time,
  String storyType,
  bool anon,
  List tags,
  Map sendTo,
  AsyncSnapshot groupSnapshot,
  List rmvGroups,
  AsyncSnapshot userSnapshot,
  List rmvUsers,
}) {
  if (personalChatId != null) {
    DatabaseMethods(uid: Constants.myUserId).addPersonalMessage(
      personalChatId: personalChatId,
      text: '',
      userName: Constants.myName,
      sendTime: time,
      imgMap: imgObj,
      fileMap: fileObj,
      mediaGallery: mediaGallery,
      contactId: contactId,
      chatId: chatId,
      friend: friend,
    );
  } else if (groupChatId != null) {
    DatabaseMethods(uid: Constants.myUserId).addConversationMessages(
      groupChatId: groupChatId,
      message: '',
      username: Constants.myName,
      userId: Constants.myUserId,
      time: time,
      imgObj: imgObj,
      fileObj: fileObj,
      mediaGallery: mediaGallery,
      chatId: chatId,
    );
  } else {
    DatabaseMethods(uid: Constants.myUserId).createStory(
      mediaObj: imgObj,
      mediaGallery: mediaGallery,
      sendTime: time,
      anon: anon,
      storyId: storyId,
      searchKeys: tags,
      type: storyType,
      sendTo: sendTo,
      groupSnapshot: groupSnapshot,
      rmvGroups: rmvGroups,
      userSnapshot: userSnapshot,
      rmvUsers: rmvUsers,
    );
  }
}

getFileUrl(String type, File file) async {
  Reference ref;
  ref = FirebaseStorage.instance.ref().child(
      '$type/${Constants.myUserId}/${DateTime.now().microsecondsSinceEpoch}');
  TaskSnapshot task = await ref.putFile(file);
  String url = await task.ref.getDownloadURL();

  return url;
}

rplFileObjPath(String type, File file, Map fileObj) async {
  String url = await getFileUrl(type, file);

  fileObj.remove('filePath');
  fileObj['fileUrl'] = url;
}

rplImgObjPath(String type, File file, Map imgObj) async {
  String url = await getFileUrl(type, file);

  imgObj.remove('imgPath');
  imgObj['imgUrl'] = url;
}

fileUploadToChats({
  File file,
  String personalChatId,
  String contactId,
  bool friend,
  String groupChatId,
  Map imgObj,
  Map fileObj,
  List mediaGallery,
  int time,
  int numOfFiles,
}) async {
  String uploadType = personalChatId != null ? 'personalChats' : 'groupChats';

  String chatId;
  if (personalChatId != null) {
    chatId =
        await DatabaseMethods(uid: Constants.myUserId).uploadFileToPersonalChat(
      personalChatId: personalChatId,
      contactId: contactId,
      imgMap: imgObj,
      fileMap: fileObj,
      mediaGallery: mediaGallery,
      time: time,
      friend: friend,
      numOfFiles: numOfFiles,
    );
  } else if (groupChatId != null) {
    chatId = await DatabaseMethods(uid: Constants.myUserId).uploadFileToGroup(
      groupChatId: groupChatId,
      imgObj: imgObj,
      fileObj: fileObj,
      mediaGallery: mediaGallery,
      time: time,
      numOfFiles: numOfFiles,
    );
  }

  if (mediaGallery == null) {
    if (imgObj != null) {
      await rplImgObjPath(uploadType, file, imgObj);
    } else {
      await rplFileObjPath(uploadType, file, fileObj);
    }
  } else {
    for (Map imgObj in mediaGallery) {
      await rplImgObjPath(uploadType, File(imgObj['imgPath']), imgObj);
    }
  }

  fileSend(
    personalChatId: personalChatId,
    contactId: contactId,
    friend: friend,
    groupChatId: groupChatId,
    chatId: chatId,
    time: time,
    imgObj: imgObj,
    fileObj: fileObj,
    mediaGallery: mediaGallery,
  );
}

fileUploadToStory({
  File file,
  Map imgObj,
  List mediaGallery,
  int time,
  String storyType,
  bool anon,
  List tags,
  Map sendTo,
  AsyncSnapshot groupSnapshot,
  List rmvGroups,
  AsyncSnapshot userSnapshot,
  List rmvUsers,
  bool story,
}) async {
  String uploadType = 'stories';
  String storyId =
      await DatabaseMethods(uid: Constants.myUserId).uploadFileToStory(
    mediaObj: imgObj,
    mediaGallery: mediaGallery,
    sendTime: time,
    type: storyType,
  );

  if (mediaGallery == null) {
    await rplImgObjPath(uploadType, file, imgObj);
  } else {
    for (Map imgObj in mediaGallery) {
      await rplImgObjPath(uploadType, File(imgObj['imgPath']), imgObj);
    }
  }

  fileSend(
    time: time,
    imgObj: imgObj,
    mediaGallery: mediaGallery,
    storyId: storyId,
    storyType: storyType,
    anon: anon,
    tags: tags,
    sendTo: sendTo,
    groupSnapshot: groupSnapshot,
    rmvGroups: rmvGroups,
    userSnapshot: userSnapshot,
    rmvUsers: rmvUsers,
  );
}
