import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:linkify/linkify.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/services/fileShare.dart';
import 'package:spidr_app/views/callScreen.dart';
import 'package:spidr_app/views/conversationScreen.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/views/mediaViewScreen.dart';
import 'package:spidr_app/views/personalChatScreen.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/dynamicStackItem.dart';
import 'package:spidr_app/widgets/mediaAndFilePicker.dart';
import 'package:spidr_app/widgets/staticStackItem.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:url_launcher/url_launcher.dart';

import 'globals.dart';

viewStoryOnNotif(BuildContext context, storyDS) {
  bool anon = storyDS.data()["anon"];
  List mediaGallery = storyDS.data()["mediaGallery"];
  Map mediaObj = storyDS.data()["mediaObj"];
  String storyId = storyDS.id;
  String senderId = storyDS.data()["senderId"];

  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MediaViewScreen(
                senderId: senderId,
                mediaId: storyId,
                mediaObj: mediaObj,
                showInfo: true,
                story: true,
                anon: anon,
                mediaGallery: mediaGallery,
                mediaIndex: 0,
              )));
}

notifOnClickHandler(BuildContext context, Map message) async {
  if (message = null) return;
  if (message["screen"] == "groupChat") {
    if (message["msgId"].isEmpty && message["data"] != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ConversationScreen(
                    groupChatId: message["data"]["groupId"],
                    uid: Constants.myUserId,
                    spectate: false,
                    preview: false,
                    initIndex: 0,
                    hideBackButton: false,
                  )));
    } else {
      DatabaseMethods()
          .getMsgIndex(message["data"]["groupId"], message["data"]["msgId"])
          .then((int msgIndex) {
        print(Constants.myUserId);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ConversationScreen(
                      groupChatId: message["data"]["groupId"],
                      uid: Constants.myUserId,
                      spectate: false,
                      preview: false,
                      initIndex: msgIndex,
                      hideBackButton: false,
                    )));
      });
    }
  } else if (message["screen"] == "groupProfile") {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GroupProfileScreen(
                groupId: message["groupId"],
                admin: message["adminId"],
                fromChat: false,
                preview: true)));
  } else if (message["screen"] == "personalChat") {
    print("testing${message["screen"]}");
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PersonalChatScreen(
                personalChatId: message["personalChatId"],
                contactId: message["contactId"],
                openByOther: true,
                friend: true)));
  } else if (message["screen"] == "snippet_comment") {
    String storyId = message["storyId"];

    DocumentSnapshot storyDS = await DatabaseMethods()
        .userCollection
        .doc(Constants.myUserId)
        .collection('stories')
        .doc(storyId)
        .get();

    viewStoryOnNotif(context, storyDS);
  }

  // else if(message["data"]["screen"] == "myFriends"){
  //   Navigator.push(context, MaterialPageRoute(
  //       builder: (context) => ChatsScreen(initialPage: 1)
  //   ));
  // }

  else if (message["screen"] == "groupSnippet") {
    String groupId = message["groupId"];
    String storyId = message["storyId"];

    DocumentSnapshot storyDS = await DatabaseMethods()
        .userCollection
        .doc(Constants.myUserId)
        .collection('groups')
        .doc(groupId)
        .collection('stories')
        .doc(storyId)
        .get();

    // DocumentSnapshot storyDS = await DatabaseMethods()
    //     .groupChatCollection
    //     .doc(groupId)
    //     .collection('stories')
    //     .doc(storyId)
    //     .get();

    viewStoryOnNotif(context, storyDS);
  } else if (message["screen"] == "friendSnippet") {
    String friendId = message["senderId"];
    String storyId = message["storyId"];
    DocumentSnapshot storyDS = await DatabaseMethods()
        .userCollection
        .doc(Constants.myUserId)
        .collection('friends')
        .doc(friendId)
        .collection('stories')
        .doc(storyId)
        .get();

    viewStoryOnNotif(context, storyDS);
  } else if (message["screen"] == "personalSnippet") {
    String storyId = message["storyId"];
    DocumentSnapshot storyDS = await DatabaseMethods()
        .userCollection
        .doc(Constants.myUserId)
        .collection('recStories')
        .doc(storyId)
        .get();

    viewStoryOnNotif(context, storyDS);
  } else if (message["screen"] == "callScreen") {
    String groupId = message["groupId"];
    String personalChatId = message["personalChatId"];
    bool anon = message["anon"] == 'false' ? false : true;
    final TargetPlatform platform = Theme.of(context).platform;

    bool ready = await checkCamPermission(platform) &&
        await checkMicPermission(platform);
    if (ready) {
      if (!Globals.inCall) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              groupId: groupId,
              personalChatId: personalChatId,
              anon: anon,
              role: ClientRole.Broadcaster,
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(
            msg: "Sorry, you are currently in call",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 14.0);
      }
    }
  }
}

Future<void> registerNotification(BuildContext context, String userId) async {
  DatabaseMethods(uid: userId).hopOnNotifSetUp();

  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  await firebaseMessaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // onLaunch: When the app is completely closed (not in the background) and opened directly from the push notification
  FirebaseMessaging.instance
      .getInitialMessage()
      .then((RemoteMessage message) async {
    DatabaseMethods(uid: userId).hopOnNotifSetUp();
    if (message != null) {
      await notifOnClickHandler(context, message.data);
    }
    print('onLaunch: $message');
    return;
  });

  // onMessage: When the app is open and it receives a push notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    DatabaseMethods(uid: userId).hopOnNotifSetUp();
    if (message != null) {
      await notifOnClickHandler(context, message.data);
    }
    print('onMessage $message');
    return;
  });

  // onResume: When the app is in the background and opened directly from the push notification.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    DatabaseMethods(uid: userId).hopOnNotifSetUp();
    print('onResume: ${message.data}');
    if (message != null) {
      await notifOnClickHandler(context, message.data);
    }
    return;
  });

  firebaseMessaging.getToken().then((token) async {
    Constants.myPushToken = token;
    DocumentReference userDocRef = DatabaseMethods().userCollection.doc(userId);
    userDocRef.update({'pushToken': token});
  }).catchError((err) {
    print(err.message.toString());
  });
}

bool isNewDay(String sendDateTime, String prevSendDateTime) {
  String datetime = sendDateTime.substring(0, sendDateTime.indexOf(' '));
  String prevDatetime =
      prevSendDateTime.substring(0, prevSendDateTime.indexOf(' '));

  return datetime != prevDatetime;
}

rmvFileFromStorage(String url) {
  Reference mediaRef = FirebaseStorage.instance.refFromURL(url);
  mediaRef.delete();
}

double getFileSize(File file) {
  int sizeInBytes = file.lengthSync();
  return sizeInBytes / (1024 * 1024);
}

List conGifMap(List gifyStickers) {
  List gifs = [];
  for (DynamicStackItem gs in gifyStickers) {
    if (!gs.deleted) {
      gifs.add({
        "gifUrl": gs.gifUrl,
        "xPos": gs.xPos,
        "yPos": gs.yPos,
        "scale": gs.scale
      });
    }
  }
  return gifs;
}

// List<Map> conMdListPreview(List<SelectedFile> selMedia){
//   List<Map> mediaList = [];
//   for(SelectedFile sm in selMedia){
//     List gifs = [];
//     if(sm.gifs != null)
//       gifs = conGifMap(sm.gifs);
//     mediaList.add({"imgUrl":sm.fileUrl, "imgName":sm.fileName, "caption":sm.caption, "gifs":gifs});
//   }
//   return mediaList;
// }

List<Map> conMediaList(List<SelectedFile> rdyMedia) {
  List<Map> mediaList = [];
  // for(SelectedFile sm in rdyMedia){
  //   sm.sent = true;
  //   DatabaseMethods().clearNonSentFiles(sm.fileId);
  //   List gifs = [];
  //   if(sm.gifs != null)
  //     gifs = conGifMap(sm.gifs);
  //   mediaList.add({"imgUrl":sm.fileUrl, "imgName":sm.fileName, "caption":sm.caption, "gifs":gifs});
  // }

  for (SelectedFile sm in rdyMedia) {
    mediaList.add({
      "imgPath": sm.filePath,
      "imgName": sm.fileName,
      "caption": sm.caption,
      "link": sm.link,
      "gifs": sm.gifs != null ? conGifMap(sm.gifs) : [],
      "mature": sm.mature
    });
  }
  return mediaList;
}

// List<SelectedFile> disposeMFPicker(List<SelectedFile> selFiles, List<SelectedFile> delFiles){
//   List<SelectedFile> nonSentFile = [];
//
//   for(SelectedFile sf in selFiles){
//     if(!sf.deleted && !sf.sent){
//       if(sf.fileUrl != null){
//         rmvFileFromStorage(sf.fileUrl);
//         sf.fileUrl = null;
//       }
//       nonSentFile.add(sf);
//     }
//   }
//
//   for(SelectedFile df in delFiles){
//     if(df.fileUrl != null)
//       rmvFileFromStorage(df.fileUrl);
//   }
//
//   return nonSentFile;
// }

conGifWidgets(List gifs) {
  List gifsWidgetList = [];
  if (gifsWidgetList != null) {
    for (Map g in gifs) {
      double scale = g["scale"] ??= g["scale"].toDouble();
      gifsWidgetList.add(
        StaticStackItem(
          g["gifUrl"],
          g["xPos"].toDouble(),
          g["yPos"].toDouble(),
          scale,
        ),
      );
    }
  }
  return gifs;
}

checkRepliedMsg(List replies) {
  if (replies != null) {
    for (var reply in replies) {
      if (reply['userId'] == Constants.myUserId) {
        return true;
      }
    }
  }
  return false;
}

getNumOfReplies(List replies) {
  int numOfReplies = 0;
  if (replies != null) {
    for (var reply in replies) {
      if (!reply["open"]) {
        numOfReplies++;
      }
    }
  }
  return numOfReplies;
}

final urlRegExp = RegExp(
    r"((https?:www\.)|(https?://)|(www\.))[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(/[-a-zA-Z0-9()@:%_+.~#?&/=]*)?");

void openUrl(String url) async {
  Uri uri = Uri.tryParse(url);
  if (uri != null) {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Fluttertoast.showToast(
        msg: 'Could not launch $url',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 3,
      );
    }
  }
}

String extractUrl(String text) {
  var elements = linkify(text,
      options: const LinkifyOptions(
        humanize: false,
      ));
  for (var e in elements) {
    if (e is LinkableElement) {
      return e.url;
    }
  }
  return "";
}

String extractSiteName(String text) {
  var elements = linkify(
    text,
  );
  for (var e in elements) {
    if (e is UrlElement) {
      return e.text;
    }
  }
  return "";
}

final empStrRegExp = RegExp(r"(^\s*$)");

final youTubeSURLRegExp = RegExp(r"^(https?://)?(www\.)?(youtu\.?be)/(.+$)");

String repYouTubeUrl(String url) {
  String regularUrl = url.replaceFirstMapped(youTubeSURLRegExp,
      (match) => 'https://www.youtube.com/watch?v=${match[4]}');
  return regularUrl;
}

String timeToString(int time) {
  return DateFormat('yyyy-MM-dd hh:mm a')
      .format(DateTime.fromMicrosecondsSinceEpoch(time));
}

int getTimeElapsed(int startTime) {
  DateTime now = DateTime.now();
  DateTime startDateTime = DateTime.fromMicrosecondsSinceEpoch(startTime);
  int timeElapsed = now.difference(startDateTime).inSeconds;

  return timeElapsed;
}

emptyStrChecker(String s) {
  return s.isEmpty || empStrRegExp.hasMatch(s);
}

videoChecker(String fileName) {
  return path.extension(fileName) == ".mp4";
}

audioChecker(String fileName) {
  bool audio = path.extension(fileName).contains(
        RegExp('[.mp3|.wav|.flac|.wma|.aac|.m4a]'),
      );
  return audio;
}

pdfChecker(String fileName) {
  bool document = path.extension(fileName) == ".pdf";
  return document;
}

addMediaItem(
    {BuildContext context,
    String groupId,
    bool anon,
    String sendBy,
    String senderId,
    String mediaId,
    int sendTime,
    Map mediaObj,
    List mediaGallery}) async {
  await DatabaseMethods().addMediaItem(
    groupId,
    anon,
    sendBy,
    senderId,
    mediaId,
    sendTime,
    mediaObj,
    mediaGallery,
  );

  showCenterFlash(
      alignment: Alignment.center,
      context: context,
      text: 'Posted to "Discover"');
}

removeMediaItem(BuildContext context, String mediaId) async {
  await DatabaseMethods().mediaCollection.doc(mediaId).delete();
  showCenterFlash(
      alignment: Alignment.center,
      context: context,
      text: 'Hidden from "Discover"');
}

shareMediaFile(
    {BuildContext context, List mediaGallery, Map imgObj, Map fileObj}) async {
  if (mediaGallery == null) {
    ShareMethods.shareFile(imgObj: imgObj, fileObj: fileObj, context: context);
  } else {
    Map selImg = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ShareMediaGalleryDialog(mediaGallery);
        });
    if (selImg != null) {
      ShareMethods.shareFile(imgObj: selImg, context: context);
    }
  }
}

// TODO  please make a model instead of passing a lot of varibales
reportContent({
  BuildContext context,
  String groupId,
  String personalChatId,
  String senderId,
  String contentId,
  String storyId,
  String commentId,
}) async {
  String reportReason = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportContentDialog();
      });
  if (reportReason != null) {
    DatabaseMethods(uid: Constants.myUserId).reportContent(
        groupId: groupId,
        personalChatId: personalChatId,
        senderId: senderId,
        contentId: contentId,
        reportReason: reportReason,
        storyId: storyId,
        commentId: commentId);

    showCenterFlash(
        alignment: Alignment.bottomCenter,
        context: context,
        text:
            'Reported. Content will be reviewed within 24 hours and will be removed if it is deemed to violate our policy');
    return true;
  }
}

reportUser({
  BuildContext context,
  String senderId,
  String userReportedId,
}) async {
  String reportReason = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportContentDialog();
      });
  if (reportReason != null) {
    DatabaseMethods(uid: Constants.myUserId).reportUser(
      senderId: senderId,
      userReportedId: userReportedId,
      reportReason: reportReason,
    );

    showCenterFlash(
        alignment: Alignment.bottomCenter,
        context: context,
        text:
            'Reported. User will be reviewed and removed within 24 hours if it violates Spidr Terms');
    return true;
  }
}

Future<bool> checkCamPermission(TargetPlatform platform) async {
  if (platform == TargetPlatform.android) {
    final status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.camera.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }
  } else {
    return true;
  }

  return false;
}

Future<bool> checkMicPermission(TargetPlatform platform) async {
  if (platform == TargetPlatform.android) {
    final status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }
  } else {
    return true;
  }

  return false;
}

Future<bool> checkStoragePermission(TargetPlatform platform) async {
  if (platform == TargetPlatform.android) {
    final status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }
  } else {
    return true;
  }
  return false;
}
