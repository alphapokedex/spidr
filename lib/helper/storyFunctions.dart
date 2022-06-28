import  'dart:io';

import  'package:flutter/cupertino.dart';
import  'package:flutter/material.dart';
import  'package:spidr_app/helper/constants.dart';
import  'package:spidr_app/services/database.dart';
import  'package:spidr_app/services/newFileUpload.dart';

//TODO create  a story instead on pasing around variables
storyRemove({
  bool owner,
  String storyId,
  Map mediaObj,
  List mediaGallery,
  String friendId,
  String groupId,
  String type,
  bool seen
}){

  if(owner){
    DatabaseMethods(uid: Constants.myUserId).deleteSenderStory(storyId, mediaObj, mediaGallery);
  }else if(seen == null || seen){
    DatabaseMethods(uid: Constants.myUserId).deleteReceiverStory(storyId, friendId, groupId, type);
  }
}

storyUpload({
  String mediaPath,
  List mediaList,
  List tags,
  bool anon,
  String caption,
  String link,
  List gifs,
  bool mature,
  bool video,
  int sendTime,
  String type,
  Map sendTo,

  AsyncSnapshot groupSnapshot,
  List rmvGroups,
  AsyncSnapshot userSnapshot,
  List rmvUsers,
}) async{

  if(mediaList != null){
    mediaList[0]["tags"] = tags;
    fileUploadToStory(
      file: mediaList.length == 1 ? File(mediaList[0]["imgPath"]) : null,
      imgObj:mediaList.length == 1 ? mediaList[0] : null,
      mediaGallery: mediaList.length > 1 ? mediaList : null,
      time:sendTime,
      storyType:type,
      anon:anon,
      tags:tags,
      sendTo:sendTo,
      groupSnapshot: groupSnapshot,
      rmvGroups: rmvGroups,
      userSnapshot: userSnapshot,
      rmvUsers: rmvUsers,
    );
  }else{
    Map<String, dynamic> mediaObj = {
      "imgPath":mediaPath,
      "imgName": video ? "$sendTime.mp4" : "$sendTime.jpeg",
      "caption":caption,
      "link":link,
      "gifs":gifs,
      "tags":tags,
      "mature":mature
    };

    fileUploadToStory(
      file:File(mediaPath),
      imgObj:mediaObj,
      time:sendTime,
      storyType:type,
      anon:anon,
      tags:tags,
      sendTo:sendTo,
      groupSnapshot: groupSnapshot,
      rmvGroups: rmvGroups,
      userSnapshot: userSnapshot,
      rmvUsers: rmvUsers,
    );
  }
}

// TODO create a a comment model
addComment(formKey, TextEditingController commentEditingController, String storyId, String storySenderId) async{
  if(formKey.currentState.validate()){
    String comment = commentEditingController.text;
    await DatabaseMethods(uid: Constants.myUserId).addStoryComment(storyId, storySenderId, comment);
    commentEditingController.text = "";
  }
}

addReply(formKey, TextEditingController replyEditingController, String storyId, String commentId) async{
  if(formKey.currentState.validate()){
    String reply = replyEditingController.text;
    await DatabaseMethods(uid: Constants.myUserId).addCommentReply(storyId, commentId, reply);
    replyEditingController.text = "";
  }
}