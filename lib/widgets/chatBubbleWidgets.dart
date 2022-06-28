import  'dart:async';
import  'dart:ui';

import  'package:carousel_slider/carousel_slider.dart';
import  'package:cloud_firestore/cloud_firestore.dart';
import  'package:dynamic_text_highlighting/dynamic_text_highlighting.dart';
import  'package:flutter/cupertino.dart';
import  'package:flutter/material.dart';
import  'package:fluttertoast/fluttertoast.dart';
import  'package:spidr_app/decorations/widgetDecorations.dart';
import  'package:spidr_app/helper/constants.dart';
import  "package:spidr_app/helper/functions.dart";
import  'package:spidr_app/services/database.dart';
import  'package:spidr_app/services/fileDownload.dart';
import  'package:spidr_app/views/userProfilePage.dart';
import  'package:spidr_app/widgets/mediaGalleryWidgets.dart';
import  "package:spidr_app/widgets/widget.dart";

class SharedChatBubble extends StatefulWidget {
  final Map fileObj;
  final Map imgObj;
  final List mediaGallery;
  final bool isSendByMe;
  final String mediaId;
  final bool reply;

  const SharedChatBubble(
      {this.fileObj,
      this.imgObj,
      this.mediaGallery,
      this.isSendByMe,
      this.mediaId,
      this.reply = false});
  @override
  _SharedChatBubbleState createState() => _SharedChatBubbleState();
}

class _SharedChatBubbleState extends State<SharedChatBubble> {
  String mediaId;
  String ogSenderId = '';
  String groupId;
  bool story = false;

  String ogSender = '';
  String profileImg;
  bool anon;

  getOgSenderInfo() async {
    DocumentSnapshot userDS =
        await DatabaseMethods(uid: ogSenderId).getUserById();
    if (mounted && userDS.exists) {
      setState(() {
        ogSender = userDS.get("name");
        profileImg = anon == null || !anon
            ? userDS.get("profileImg")
            : userMIYUs[userDS.get("anonImg")];
      });
    }
  }

  setUp() {
    if (widget.imgObj != null || widget.mediaGallery != null) {
      Map imgObj =
          widget.imgObj ?? widget.mediaGallery[0];
      setState(() {
        anon = imgObj['anon'];
        ogSenderId = imgObj["ogSenderId"];
      });
      if (imgObj["ogStoryId"] != null) {
        setState(() {
          mediaId = imgObj["ogStoryId"];
          story = true;
        });
        DatabaseMethods(uid: Constants.myUserId)
            .markSeenStory(ogSenderId, mediaId);
      } else {
        setState(() {
          mediaId = imgObj["ogChatId"];
          groupId = imgObj["ogGroupId"];
        });
      }
    } else {
      setState(() {
        ogSenderId = widget.fileObj["ogSenderId"];
        anon = widget.fileObj["anon"];
        mediaId = widget.fileObj["ogChatId"];
        groupId = widget.fileObj["ogGroupId"];
      });
    }
    getOgSenderInfo();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    if (mediaId != widget.mediaId) setUp();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    setUp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: shadowEffect(30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: !widget.reply
              ? MediaQuery.of(context).size.height * 0.45
              : MediaQuery.of(context).size.height * 0.35,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              SizedBox.expand(
                child: widget.mediaGallery == null
                    ? mediaAndFileDisplay(
                        context: context,
                        imgObj: widget.imgObj,
                        fileObj: widget.fileObj,
                        mediaId: mediaId,
                        senderId: ogSenderId,
                        groupChatId: groupId,
                        play: false,
                        showInfo: true,
                        story: story,
                        anon: anon,
                        div: 1.25,
                        numOfLines: 1,
                      )
                    : MediaGalleryTile(
                        startIndex: 0,
                        mediaGallery: widget.mediaGallery,
                        groupId: groupId,
                        messageId: !story ? mediaId : null,
                        senderId: ogSenderId,
                        sendBy: ogSender,
                        storyId: story ? mediaId : null,
                        story: story,
                        anon: anon,
                        height: MediaQuery.of(context).size.height / 2.25,
                        div: 1.25,
                      ),
              ),
              mediaCommentList(context: context, mediaId: mediaId, anon: anon),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: profileImg != null
                        ? GestureDetector(
                            onTap: () {
                              if (anon == null || !anon) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => UserProfileScreen(
                                              userId: ogSenderId,
                                            )));
                              }
                            },
                            child: avatarImg(profileImg, 24, false),
                          )
                        : const SizedBox.shrink(),
                    title: Text(
                        ogSenderId == Constants.myUserId
                            ? "Me"
                            : anon == null || !anon
                                ? ogSender
                                : "Anonymous",
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class UrlChatBubble extends StatefulWidget {
  final String urlText;
  const UrlChatBubble(this.urlText);
  @override
  _UrlChatBubbleState createState() => _UrlChatBubbleState();
}

class _UrlChatBubbleState extends State<UrlChatBubble> {
  String url = "";

  @override
  void didUpdateWidget(covariant UrlChatBubble oldWidget) {
    // TODO: implement didUpdateWidget
    String newUrl = extractUrl(widget.urlText);

    if (url != newUrl) {
      setState(() {
        url = "";
      });
      Timer(
          const Duration(milliseconds: 1),
          () => setState(() {
                url = newUrl;
              }));
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    setState(() {
      url = extractUrl(widget.urlText);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return urlPreviewWrapper(context: context, text: widget.urlText, url: url);
  }
}

Widget fileChatDisplay(
    {BuildContext context,
    String messageId,
    Map fileObj,
    String senderId,
    String groupId,
    String hashTag,
    bool anon,
    bool toPageView = true
    // String personalChatId,
    }) {
  return Stack(
    alignment: Alignment.bottomLeft,
    children: [
      SizedBox.expand(
        child: mediaAndFileDisplay(
          fileObj: fileObj,
          senderId: senderId,
          groupChatId: groupId,
          context: context,
          hashTag: hashTag,
          anon: anon,
          // personalChatId: personalChatId,
          mediaId: messageId,
          play: false,
          showInfo: false,
          div: 1.25,
          numOfLines: 3,
          toPageView: toPageView,
        ),
      ),
      mediaCommentList(context: context, mediaId: messageId, anon: anon),
    ],
  );
}

Widget unknownFileBubble(Map fileObj, bool isSendByMe, platform) {
  return ListTile(
    leading: avatarImg("assets/images/unknownFile.png", 24, false),
    title: Text(fileObj["fileName"],
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    subtitle: Text("${fileObj["fileSize"]}",
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSendByMe ? Colors.black : Colors.orange)),
    dense: true,
    trailing: fileObj['fileUrl'] != null
        ? Icon(
            platform == TargetPlatform.android
                ? Icons.download_rounded
                : CupertinoIcons.download_circle,
            color: isSendByMe ? Colors.black54 : Colors.purple,
          )
        : SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    isSendByMe ? Colors.black54 : Colors.purple)),
          ),
    onTap: () async {
      if (fileObj['fileUrl'] != null) {
        bool ready = await checkStoragePermission(platform);
        if (ready) {
          String savedDir = await DownloadMethods.prepareSaveDir(platform);
          String taskId = await DownloadMethods.startDownload(
              fileObj['fileName'], fileObj['fileUrl'], savedDir);
          if (taskId != null) {
            Fluttertoast.showToast(
              msg: "Start download",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 3,
            );
          }
        }
      }
    },
  );
}

Widget fileChatBubble(
    {BuildContext context,
    Map fileObj,
    messageId,
    bool isSendByMe,
    TargetPlatform platform,
    bool audio,
    bool document,
    String senderId,
    String groupId,
    String hashTag,
    bool anon,
    // String personalChatId,
    bool toPageView = true}) {
  if (audio || document) {
    return Container(
      decoration: shadowEffect(30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: fileChatDisplay(
              context: context,
              messageId: messageId,
              fileObj: fileObj,
              senderId: senderId,
              groupId: groupId,
              hashTag: hashTag,
              anon: anon,
              toPageView: toPageView
              // personalChatId: personalChatId,
              ),
        ),
      ),
    );
  } else {
    return unknownFileBubble(fileObj, isSendByMe, platform);
  }
}

class MediaGalleryBubble extends StatefulWidget {
  final List mediaGallery;
  final String messageId;
  final bool isSendByMe;
  final bool reply;
  final String senderId;
  final String groupId;
  final String hashTag;
  final bool anon;
  final bool toPageView;
  // final String personalChatId;
  final double height;
  const MediaGalleryBubble({
    this.mediaGallery,
    this.messageId,
    this.isSendByMe,
    this.reply,
    this.senderId,
    this.groupId,
    this.hashTag,
    this.anon,
    this.toPageView = true,
    // this.personalChatId,
    this.height,
  });
  @override
  _MediaGalleryBubbleState createState() => _MediaGalleryBubbleState();
}

class _MediaGalleryBubbleState extends State<MediaGalleryBubble> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        galleryIndicator(widget.mediaGallery, current),
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            CarouselSlider(
              items: widget.mediaGallery.map((e) {
                int index = widget.mediaGallery.indexOf(e);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2.5),
                  child: widget.reply == null || !widget.reply
                      ? mediaChatBubble(
                          imgObj: e,
                          messageId: widget.messageId,
                          context: context,
                          mediaGallery: widget.mediaGallery,
                          mediaIndex: index,
                          senderId: widget.senderId,
                          groupId: widget.groupId,
                          hashTag: widget.hashTag,
                          anon: widget.anon,
                          toPageView: widget.toPageView
                          // personalChatId: widget.personalChatId,
                          )
                      : replyMediaBubble(
                          context: context,
                          imgObj: e,
                          senderId: widget.senderId,
                          messageId: widget.messageId,
                          isSendByMe: widget.isSendByMe,
                          mediaGallery: widget.mediaGallery,
                          mediaIndex: index,
                          anon: widget.anon),
                );
              }).toList(),
              options: CarouselOptions(
                  height: widget.height,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  initialPage: current,
                  onPageChanged: (index, reason) {
                    setState(() {
                      current = index;
                    });
                  }),
            ),
            mediaCommentList(context: context, mediaId: widget.messageId)
          ],
        ),
      ],
    );
  }
}

Widget mediaChatBubble(
    {Map imgObj,
    String messageId,
    BuildContext context,
    List mediaGallery,
    int mediaIndex,
    String senderId,
    String groupId,
    String hashTag,
    bool anon,
    // String personalChatId,
    bool toPageView = true}) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.45,
    decoration: imgObj["sticker"] == null ? shadowEffect(30) : null,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          SizedBox.expand(
            child: mediaAndFileDisplay(
              context: context,
              imgObj: imgObj,
              senderId: senderId,
              groupChatId: groupId,
              hashTag: hashTag,
              anon: anon,
              // personalChatId: personalChatId,
              mediaId: messageId,
              play: false,
              showInfo: false,
              mediaGallery: mediaGallery,
              mediaIndex: mediaIndex,
              div: 1.25,
              numOfLines: 3,
              toPageView: toPageView,
            ),
          ),
          mediaGallery == null
              ? mediaCommentList(
                  context: context, mediaId: messageId, anon: anon)
              : const SizedBox.shrink()
        ],
      ),
    ),
  );
}

Widget groupTextBubble(BuildContext context, String message,
    List highlightWords, bool isSendByMe) {
  return !urlRegExp.hasMatch(message)
      ? DynamicTextHighlighting(
          text: message,
          highlights: highlightWords,
          color: Colors.blueAccent,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          caseSensitive: false,
        )
      : UrlChatBubble(message);
}

Widget personalTextBubble(BuildContext context, String text, bool isSendByMe) {
  return !urlRegExp.hasMatch(text)
      ? Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        )
      : UrlChatBubble(text);
}

Widget replyTextBubble(BuildContext context, String text, bool isSendByMe) {
  return !urlRegExp.hasMatch(text)
      ? Text(
          text,
          style: TextStyle(
              color: isSendByMe ? Colors.black : Colors.orange,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.start,
        )
      : UrlChatBubble(text);
}

Widget replyMediaBubble(
    {BuildContext context,
    platform,
    Map imgObj,
    Map fileObj,
    String senderId,
    String messageId,
    bool isSendByMe,
    List mediaGallery,
    int mediaIndex,
    bool anon}) {
  return imgObj != null ||
          (fileObj != null &&
              (audioChecker(fileObj['fileName']) ||
                  pdfChecker(fileObj['fileName'])))
      ? Container(
          height: MediaQuery.of(context).size.height * 0.35,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                SizedBox.expand(
                  child: mediaAndFileDisplay(
                    context: context,
                    imgObj: imgObj,
                    fileObj: fileObj,
                    senderId: senderId,
                    mediaId: messageId,
                    play: false,
                    showInfo: false,
                    mediaGallery: mediaGallery,
                    mediaIndex: mediaIndex,
                    div: 1.25,
                    numOfLines: 3,
                  ),
                ),
                mediaGallery == null
                    ? mediaCommentList(
                        context: context, mediaId: messageId, anon: anon)
                    : const SizedBox.shrink()
              ],
            ),
          ))
      : unknownFileBubble(fileObj, isSendByMe, platform);
}
