import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/services/fileDownload.dart';
import 'package:spidr_app/views/docViewScreen.dart';
import 'package:spidr_app/widgets/mediaGalleryWidgets.dart';
import 'package:spidr_app/widgets/mediaInfoWidgets.dart';
import 'package:spidr_app/widgets/storyCommentsWidgets.dart';
import 'package:spidr_app/widgets/storyFuncWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'mediaPreview.dart';

class MediaViewScreen extends StatefulWidget {
  final String senderId;
  final String groupId;
  final String mediaId;
  final Map mediaObj;
  final bool showInfo;
  final bool story;
  final bool anon;

  final int mediaIndex;
  final List mediaGallery;
  const MediaViewScreen(
      {this.senderId,
      this.groupId,
      this.mediaId,
      this.mediaObj,
      this.showInfo,
      this.story,
      this.anon,
      this.mediaIndex,
      this.mediaGallery});
  @override
  _MediaViewScreenState createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> {
  String sendBy;
  String profileImg;
  String anonImg;
  int sendTime;
  bool chatExist;

  bool blocked;

  // bool inExplore;
  bool storyExist;

  Stream comStream;
  final comFormKey = GlobalKey<FormState>();
  final reFormKey = GlobalKey<FormState>();

  TextEditingController commentEditingController;
  TextEditingController replyEditingController;

  bool showStoryRec = false;
  bool mature = false;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;
  String savedDir;
  ReceivePort port = ReceivePort();
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();
  GlobalKey key5 = GlobalKey();

  bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }

    port.listen((data) {
      setState(() {
        taskId = data[0];
        status = data[1];
        progress = data[2];
      });
    });
  }

  unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  startDownload(TargetPlatform platform, String url, String fileName) async {
    bool ready = await checkStoragePermission(platform);
    if (ready) {
      savedDir = await DownloadMethods.prepareSaveDir(platform);
      taskId = await DownloadMethods.startDownload(fileName, url, savedDir);
      // if(taskId != null)
      //   Fluttertoast.showToast(
      //     msg: "Start download",
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.SNACKBAR,
      //     timeInSecForIosWeb: 3,
      //   );
    }
  }

  cancelDownload() async {
    await DownloadMethods.cancelDownload(taskId);
  }

  retryDownload() async {
    taskId = await DownloadMethods.retryDownload(taskId);
  }

  openDownload() async {
    bool success = await DownloadMethods.openDownloadedFile(taskId);
    if (!success) {
      Fluttertoast.showToast(
          msg: "Sorry, please try again",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 3,
          fontSize: 14.0);
    }
  }

  checkChatExist() async {
    DocumentSnapshot chDS = await DatabaseMethods()
        .groupChatCollection
        .doc(widget.groupId)
        .collection('chats')
        .doc(widget.mediaId)
        .get();

    setState(() {
      chatExist = chDS.exists;
    });
  }

  checkStoryExist() async {
    DocumentSnapshot stDS = await DatabaseMethods()
        .userCollection
        .doc(widget.senderId)
        .collection('stories')
        .doc(widget.mediaId)
        .get();

    setState(() {
      storyExist = stDS.exists;
    });
  }

  Widget exploreMediaBtt() {
    return StreamBuilder(
        stream:
            DatabaseMethods().mediaCollection.doc(widget.mediaId).snapshots(),
        builder: (context, snapshot) {
          bool inDiscover = snapshot.hasData && snapshot.data.data() != null;
          return GestureDetector(
              onTap: () {
                if (inDiscover) {
                  removeMediaItem(context, widget.mediaId);
                } else {
                  addMediaItem(
                      context: context,
                      groupId: widget.groupId,
                      anon: widget.anon,
                      sendBy: sendBy,
                      senderId: widget.senderId,
                      mediaId: widget.mediaId,
                      sendTime: sendTime,
                      mediaObj:
                          widget.mediaGallery == null ? widget.mediaObj : null,
                      mediaGallery: widget.mediaGallery);
                }
              },
              child: mediaFuncBtt(inDiscover
                  ? Icons.explore_rounded
                  : Icons.explore_off_rounded));
        });
  }

  Widget gcInfoPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.325,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(15, 0, 0, 5),
      decoration: mediaViewDec(),
      child: mediaCommentSenderPanel(
          context: context,
          mediaId: widget.mediaId,
          senderId: widget.senderId,
          sendBy: sendBy,
          profileImg: profileImg,
          anonImg: anonImg,
          anon: widget.anon,
          blocked: blocked,
          heightDiv: 0.2),
    );
  }

  // Widget storyRecList(platform){
  //   return StreamBuilder(
  //     stream: DatabaseMethods().userCollection
  //         .doc(Constants.myUserId)
  //         .collection('stories')
  //         .doc(widget.mediaId)
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if(snapshot.hasData && snapshot.data != null && snapshot.data.data() != null){
  //         List recGroups = snapshot.data.data()["recGroups"];
  //         List recUsers = snapshot.data.data()["recFriends"] != null ? snapshot.data.data()["recFriends"] : snapshot.data.data()["recUsers"];
  //
  //         return Container(
  //           width: showStoryRec ? MediaQuery.of(context).size.width*0.65 : MediaQuery.of(context).size.width*0.15,
  //           height: 54,
  //           padding: const EdgeInsets.symmetric(vertical: 2.5),
  //
  //           decoration: BoxDecoration(
  //             color: Colors.black54,
  //             borderRadius: BorderRadius.horizontal(left: Radius.circular(30))
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //
  //               IconButton(
  //                 icon:Icon(showStoryRec ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_left_rounded),
  //                 color: Colors.white,
  //                 onPressed: (){
  //                   setState(() {
  //                     showStoryRec = !showStoryRec;
  //                   });
  //                 },
  //               ),
  //
  //               showStoryRec ? Expanded(
  //                 child: Center(
  //                   child: snapshot.data.data()["type"] == "regular" || snapshot.data.data()["type"] == "snippet" ?
  //                   ListView(
  //                     physics: BouncingScrollPhysics(),
  //                     shrinkWrap: true,
  //                     scrollDirection: Axis.horizontal,
  //                     children: recGroups.map((id) => profileIconWithId(groupId: id)).toList() +
  //                         recUsers.map((id) => profileIconWithId(userId: id)).toList(),
  //                   ) : Text(
  //                     "Friends Only",
  //                     style: TextStyle(fontWeight: FontWeight.bold, color:Colors.white, fontSize: 16)
  //                   ),
  //                 ),
  //               ) : SizedBox.shrink(),
  //
  //               showStoryRec ? Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 12.5),
  //                 child: Icon(
  //                   snapshot.data.data()["type"] == "regular" ? Icons.send_rounded :
  //                   snapshot.data.data()["type"] == "friends" ? Icons.auto_awesome :
  //                   Icons.settings_input_antenna,
  //                   color: Colors.white
  //                 ),
  //               ) : SizedBox.shrink(),
  //             ],
  //           ),
  //         );
  //       }else{
  //         return SizedBox.shrink();
  //       }
  //     }
  //   );
  // }

  Widget storyInfoPanel() {
    List tags = widget.mediaGallery != null
        ? widget.mediaGallery[0]['tags']
        : widget.mediaObj["tags"];
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 13.5),
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.72,
                  height: MediaQuery.of(context).size.height * 0.325,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      userIcon(context, widget.senderId, sendBy, profileImg,
                          anonImg, widget.anon, blocked),
                      const SizedBox(
                        height: 5,
                      ),
                      tags != null && tags.isNotEmpty && tags[0].isNotEmpty
                          ? hashTags(
                              tags: tags,
                              boxColor: Colors.black54,
                              borderColor: Colors.transparent,
                              textColor: Colors.orange)
                          : const SizedBox.shrink()
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  getChatSendTime() async {
    if (widget.groupId != null) {
      DocumentSnapshot chatDS = await DatabaseMethods()
          .groupChatCollection
          .doc(widget.groupId)
          .collection('chats')
          .doc(widget.mediaId)
          .get();

      if (chatDS.exists) sendTime = chatDS.get('time');
    }
  }

  getStoryComments() {
    comStream = DatabaseMethods().getStoryComments(widget.mediaId);
  }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_SnippetSeen' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_SnippetSeen', true);
    setState(() {
      _seen = true;
    });
    return _seen;
  }

  void showTutorial() {
    if (_seen == null || false) {
      initTargets();
      tutorialCoachMark = TutorialCoachMark(
        context,
        targets: targets,
        colorShadow: Colors.red,
        textSkip: "SKIP",
        paddingFocus: 10,
        opacityShadow: 0.8,
        onFinish: () {
          markSeen();
        },
        onClickTarget: (target) {},
        onSkip: () {
          markSeen();
        },
        onClickOverlay: (target) {},
      )..show();
    }
  }

  void initTargets() {
    targets.add(
      TargetFocus(
        identify: "Share",
        keyTarget: key1,
        color: Colors.deepOrangeAccent,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Snippet Share !",
                  style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "Share this snippet with other users or circles ",
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
        shape: ShapeLightFocus.Circle,
        radius: 5,
      ),
    );

    targets.add(TargetFocus(
      identify: "Comment",
      keyTarget: key2,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    "Comment",
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                ),
                Text(
                  "Comment on the Snippet!",
                  style: GoogleFonts.varelaRound(
                    color: Colors.white,
                  ),
                ),
              ],
            )),
      ],
      shape: ShapeLightFocus.Circle,
    ));
    targets.add(TargetFocus(
      identify: "Options",
      keyTarget: key3,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    "Options",
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                ),
                Text(
                  "Tap this to share this Snippet outside of Spidr, or block/report the user of the Snippet",
                  style: GoogleFonts.varelaRound(
                    color: Colors.white,
                  ),
                ),
              ],
            )),
      ],
      shape: ShapeLightFocus.Circle,
    ));
    targets.add(
      TargetFocus(
        identify: "Save Media",
        keyTarget: key4,
        color: Colors.orange,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Save Media",
                  style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "Save this to your backpack. Your backpack can be found in your profile page ",
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
        radius: 5,
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Circle Limit",
        keyTarget: key5,
        color: Colors.orange,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Circle Limit",
                  style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "Choose how many users can join your Circle ",
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
        radius: 5,
      ),
    );
  }

  @override
  void dispose() {
    unbindBackgroundIsolate();
    if (commentEditingController != null) commentEditingController.dispose();
    if (replyEditingController != null) replyEditingController.dispose();
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    SendPort sendPort;
    if (IsolateNameServer.lookupPortByName('downloader_send_port') != null) {
      sendPort = IsolateNameServer.lookupPortByName('downloader_send_port');
      sendPort.send([id, status, progress]);
    }
  }

  @override
  void initState() {
    bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);

    if (widget.showInfo) {
      if (widget.story == null || !widget.story) {
        getChatSendTime();
        checkChatExist();
      } else {
        replyEditingController = TextEditingController();
        commentEditingController = TextEditingController();
        DatabaseMethods(uid: Constants.myUserId)
            .markSeenStory(widget.senderId, widget.mediaId);
        getStoryComments();
        checkStoryExist();
      }
    }
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    Future.delayed(const Duration(milliseconds: 100), showTutorial);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    String mediaUrl;
    if (widget.mediaObj != null) {
      mediaUrl = widget.mediaObj['imgUrl'] ?? (widget.mediaObj['fileUrl']);
    }

    bool video = widget.mediaObj != null &&
        widget.mediaObj["imgName"] != null &&
        videoChecker(widget.mediaObj["imgName"]);

    bool mature = widget.mediaObj != null &&
        widget.mediaObj['mature'] != null &&
        widget.mediaObj['mature'];

    String fileName =
        widget.mediaObj != null && widget.mediaObj["fileName"] != null
            ? widget.mediaObj["fileName"]
            : null;

    String audioName =
        fileName != null && audioChecker(fileName) ? fileName : null;
    String pdfName = fileName != null && pdfChecker(fileName) ? fileName : null;

    String caption =
        widget.mediaObj != null ? widget.mediaObj['caption'] : null;
    String link = widget.mediaObj != null ? widget.mediaObj['link'] : null;

    List<Widget> gifyStickers =
        widget.mediaObj != null && widget.mediaObj['gifs'] != null
            ? conGifWidgets(widget.mediaObj['gifs'])
            : null;

    return Scaffold(
        extendBodyBehindAppBar: audioName == null && pdfName == null,
        appBar: AppBar(
          leading: BackButton(
            color: audioName == null && pdfName == null
                ? Colors.white
                : Colors.black,
          ),
          title: status == DownloadTaskStatus.running
              ? LinearProgressIndicator(value: progress / 100)
              : null,
          backgroundColor: audioName == null && pdfName == null
              ? Colors.transparent
              : Colors.white,
          elevation: 0,
          actions: audioName != null || pdfName != null
              ? [
                  IconButton(
                      icon: Icon(
                        status == DownloadTaskStatus.undefined ||
                                status == DownloadTaskStatus.canceled
                            ? platform == TargetPlatform.android
                                ? Icons.download_rounded
                                : CupertinoIcons.download_circle
                            : status == DownloadTaskStatus.running
                                ? Icons.close
                                : status == DownloadTaskStatus.complete
                                    ? Icons.open_in_new_rounded
                                    : status == DownloadTaskStatus.failed
                                        ? Icons.refresh
                                        : null,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        if (status == DownloadTaskStatus.undefined ||
                            status == DownloadTaskStatus.canceled) {
                          String fileName = audioName ?? pdfName;
                          startDownload(platform, mediaUrl, fileName);
                        } else if (status == DownloadTaskStatus.running) {
                          cancelDownload();
                        } else if (status == DownloadTaskStatus.complete) {
                          openDownload();
                        } else if (status == DownloadTaskStatus.failed) {
                          retryDownload();
                        }
                      })
                ]
              : null,
        ),
        body: Stack(
          children: [
            Stack(alignment: Alignment.bottomCenter, children: [
              widget.mediaGallery == null
                  ? MediaDisplay(
                      video: video,
                      audioName: audioName,
                      pdfName: pdfName,
                      mediaUrl: mediaUrl,
                      link: link,
                      story: widget.story,
                      caption: caption,
                      gifyStickers: gifyStickers,
                      mature: mature,
                      senderId: widget.senderId,
                    )
                  : MediaGalleryTile(
                      senderId: widget.senderId,
                      story: widget.story,
                      startIndex: widget.mediaIndex,
                      mediaGallery: widget.mediaGallery,
                      height: MediaQuery.of(context).size.height,
                      autoPlay: false,
                    ),
              widget.showInfo
                  ? StreamBuilder(
                      stream: DatabaseMethods()
                          .userCollection
                          .doc(widget.senderId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data.data() != null) {
                          var val = snapshot.data;
                          int imgIndex = val.data()["anonImg"];
                          sendBy = val.data()["name"];
                          profileImg = val.data()["profileImg"];
                          anonImg = userMIYUs[imgIndex];
                          blocked = val.data()["blockedBy"] != null &&
                              val
                                  .data()["blockedBy"]
                                  .contains(Constants.myUserId);
                          return widget.story != null && widget.story
                              ? storyInfoPanel()
                              : gcInfoPanel();
                        } else {
                          return const SizedBox.shrink();
                        }
                      })
                  : const SizedBox.shrink()
            ]),

            // Padding(
            //   padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.225),
            //   child: Align(
            //     alignment: Alignment.topRight,
            //     child: Constants.myUserId == widget.senderId ?
            //     storyRecList(platform) :
            //     SizedBox.shrink(),
            //   ),
            // ),
          ],
        ),
        floatingActionButton: widget.showInfo
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  widget.story != null && widget.story
                      ? widget.senderId == Constants.myUserId
                          ? seenBtt(context, widget.senderId, widget.mediaId)
                          : const SizedBox.shrink()
                      : (chatExist != null && chatExist) &&
                              (widget.senderId == Constants.myUserId)
                          ? exploreMediaBtt()
                          : const SizedBox.shrink(),
                  const SizedBox(height: 8),
                  widget.story != null && widget.story
                      ? sendBtt(
                          context,
                          widget.senderId,
                          widget.mediaObj,
                          widget.mediaGallery,
                          widget.mediaId,
                          widget.anon,
                          key1)
                      : sendMediaBtt(
                          context,
                          widget.senderId,
                          widget.mediaObj,
                          widget.mediaId,
                          widget.groupId,
                          widget.mediaGallery,
                          widget.anon),
                  const SizedBox(height: 10),
                  widget.story != null && widget.story
                      ? commentBtt(
                          context,
                          comStream,
                          widget.mediaId,
                          widget.senderId,
                          storyExist,
                          commentEditingController,
                          replyEditingController,
                          comFormKey,
                          reFormKey,
                          key2,
                        )
                      : toggleSaveMediaBtt(
                          context,
                          widget.senderId,
                          widget.mediaObj != null &&
                                  widget.mediaObj["imgName"] != null
                              ? widget.mediaObj
                              : null,
                          widget.mediaObj != null &&
                                  widget.mediaObj["fileName"] != null
                              ? widget.mediaObj
                              : null,
                          widget.mediaId,
                          widget.groupId,
                          widget.mediaGallery,
                          widget.anon,
                        ),
                  const SizedBox(height: 10),
                  widget.story != null && widget.story
                      ? moreOpsBtt(
                          context,
                          widget.mediaObj,
                          widget.mediaGallery,
                          widget.groupId,
                          widget.senderId,
                          widget.mediaId,
                          widget.anon,
                          key3)
                      : moreOpsMediaBtt(
                          context: context,
                          imgObj: widget.mediaObj != null &&
                                  widget.mediaObj["imgName"] != null
                              ? widget.mediaObj
                              : null,
                          fileObj: widget.mediaObj != null &&
                                  widget.mediaObj["fileName"] != null
                              ? widget.mediaObj
                              : null,
                          mediaGallery: widget.mediaGallery,
                          senderId: widget.senderId,
                          groupId: widget.groupId,
                          mediaId: widget.mediaId,
                          anon: widget.anon),
                ],
              )
            : null);
  }
}

class MediaDisplay extends StatefulWidget {
  final bool video;
  final String audioName;
  final String pdfName;
  final String mediaUrl;
  final String mediaPath;
  final bool story;
  final String caption;
  final String link;
  // final String heroTag;
  final List<Widget> gifyStickers;
  final bool mature;
  final String senderId;

  const MediaDisplay(
      {this.video,
      this.audioName,
      this.pdfName,
      this.mediaUrl,
      this.mediaPath,
      this.story,
      this.caption,
      this.link,
      // this.heroTag,
      this.gifyStickers,
      this.mature = false,
      this.senderId});

  @override
  _MediaDisplayState createState() => _MediaDisplayState();
}

class _MediaDisplayState extends State<MediaDisplay> {
  bool mature = false;

  Widget matureFilter() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/icon/nsfwIcon.png",
                scale: 2.5,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  setState(() {
                    mature = false;
                  });
                },
                child: const Text('View Media',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              Divider(
                height: 9,
                thickness: 1.5,
                indent: MediaQuery.of(context).size.width * 0.25,
                endIndent: MediaQuery.of(context).size.width * 0.25,
              ),
              const Text(
                "The media you are about to view contains sensitive content that might be offensive or disturbing",
                style: TextStyle(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )),
    );
  }

  @override
  void initState() {
    mature = widget.mature;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery.of(context).size.height * 0.15;
    return Stack(
      children: [
        widget.pdfName != null
            ? GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DocViewScreen(
                              fileUrl: widget.mediaUrl,
                              fileName: widget.pdfName)));
                },
                child: DocDisplay(
                  fileName: widget.pdfName,
                  fullScreen: true,
                  displayGifs: true,
                  gifs: widget.gifyStickers,
                  caption: widget.caption,
                  link: widget.link,
                ))
            : widget.video || widget.audioName != null
                ? widget.mediaUrl != null
                    ? VideoAudioUrlPreview(
                        fileURL: widget.mediaUrl,
                        play: !mature || widget.senderId == Constants.myUserId,
                        video: widget.video,
                        audioName: widget.audioName,
                        fullScreen: true,
                        muteBttAlign: Alignment.topRight,
                        muteBttPadding: widget.video
                            ? EdgeInsets.fromLTRB(
                                0.0,
                                MediaQuery.of(context).size.height * 0.125,
                                9.0,
                                0.0)
                            : null,
                        gifs: widget.gifyStickers,
                        caption: widget.caption,
                        link: widget.link,
                        displayGifs: true,
                        topPadding: widget.video ? topPadding : 9,
                      )
                    : VideoAudioFilePreview(
                        filePath: widget.mediaPath,
                        fullScreen: true,
                        play: true,
                        gifs: widget.gifyStickers,
                        caption: widget.caption,
                        link: widget.link,
                        displayGifs: true,
                        displayLink: true,
                        topPadding: topPadding,
                      )
                : widget.mediaUrl != null
                    ? ImageUrlPreview(
                        fileURL: widget.mediaUrl,
                        gifs: widget.gifyStickers,
                        caption: widget.caption,
                        link: widget.link,
                        fullScreen: true,
                        displayGifs: true,
                        displayLink: true,
                        topPadding: topPadding,
                      )
                    : ImageFilePreview(
                        filePath: widget.mediaPath,
                        fullScreen: true,
                        gifs: widget.gifyStickers,
                        caption: widget.caption,
                        link: widget.link,
                        displayGifs: true,
                        topPadding: topPadding,
                      ),
        widget.senderId != Constants.myUserId && mature
            ? matureFilter()
            : const SizedBox.shrink(),
      ],
    );
  }
}
