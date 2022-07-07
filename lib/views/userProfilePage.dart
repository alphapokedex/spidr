import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/personalChatScreen.dart';
import 'package:spidr_app/widgets/groupsListDisplay.dart';
import 'package:spidr_app/widgets/profilePageWidgets.dart';
import 'package:spidr_app/widgets/storiesListDisplay.dart';
import 'package:spidr_app/widgets/widget.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  // final String profileImg;
  // final String username;
  final bool blockAble;
  final ScrollController scrollController;
  const UserProfileScreen(
      {this.userId,
      // this.profileImg,
      // this.username,
      this.blockAble = true,
      this.scrollController});
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Stream storyStream;
  String username;
  String profileImg;

  String quote = '';
  // String school = "School";
  // String program = "Program";
  List tags = [];
  bool inChat = false;
  bool isMe;
  List banner = [];
  List blockedBy = [];

  List friends;
  List receivedFdReq;
  List sentFdReq;

  checkInChat() async {
    QuerySnapshot contactQS = await DatabaseMethods()
        .userCollection
        .doc(Constants.myUserId)
        .collection('replies')
        .where('contactId', isEqualTo: widget.userId)
        .get();

    setState(() {
      inChat = contactQS.docs.isNotEmpty;
    });
  }

  getUserStories() {
    storyStream = DatabaseMethods(uid: widget.userId).getSenderStories(false);
    setState(() {});
  }

  @override
  void initState() {
    getUserStories();
    checkInChat();
    super.initState();
  }

  Widget userContent(double height, bool blocked, bool befriended, bool sentReq,
      bool receivedReq) {
    return Container(
      alignment: Alignment.topCenter,
      color: Colors.white,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                banner != null && banner.isNotEmpty && !blocked
                    ? bannerSlide(
                        context: context,
                        height:
                            widget.blockAble ? height * 0.35 : height * 0.25,
                        banner: banner,
                        userId: widget.userId)
                    : Container(
                        height:
                            widget.blockAble ? height * 0.35 : height * 0.25,
                        width: MediaQuery.of(context).size.width,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(
                          child: Text(
                            'tell them to add some photos :)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.varelaRound(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    !isMe
                        ? SizedBox(
                            width: 54,
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                      top: widget.blockAble
                                          ? height * 0.3
                                          : height * 0.2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [circleShadow],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      befriended
                                          ? Icons.auto_awesome
                                          : !sentReq && !receivedReq
                                              ? Icons.person_add
                                              : receivedReq
                                                  ? Icons.cancel_rounded
                                                  : Icons.watch_later_rounded,
                                      color: sentReq
                                          ? Colors.grey
                                          : receivedReq
                                              ? Colors.red
                                              : Colors.black,
                                    ),
                                    onPressed: () {
                                      if (!befriended) {
                                        if (!sentReq && !receivedReq) {
                                          DatabaseMethods(
                                                  uid: Constants.myUserId)
                                              .sendFriendRequest(widget.userId);
                                          showCenterFlash(
                                              alignment: Alignment.center,
                                              context: context,
                                              text: 'Requested');
                                        } else if (receivedReq) {
                                          DatabaseMethods(
                                                  uid: Constants.myUserId)
                                              .cancelFriendRequest(
                                                  widget.userId);
                                          showCenterFlash(
                                              alignment: Alignment.center,
                                              context: context,
                                              text: 'Canceled');
                                        }
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  befriended
                                      ? 'My Friend'
                                      : !sentReq && !receivedReq
                                          ? 'Befriend'
                                          : receivedReq
                                              ? 'Cancel'
                                              : 'Request',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(1, 1.5),
                                        blurRadius: 1,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    Container(
                      height: 81,
                      width: 81,
                      margin: EdgeInsets.only(
                          top: widget.blockAble
                              ? height * 0.275
                              : height * 0.175),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        // boxShadow: [circleShadow],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.5),
                        child: avatarImg(profileImg, 36, false),
                      ),
                    ),
                    !isMe
                        ? SizedBox(
                            width: 54,
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                      top: widget.blockAble
                                          ? height * 0.3
                                          : height * 0.2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [circleShadow],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      !inChat && !blocked
                                          ? Icons.maps_ugc
                                          : blocked
                                              ? Icons.block_rounded
                                              : Icons.access_time_rounded,
                                      color: blocked
                                          ? Colors.red
                                          : inChat
                                              ? Colors.grey
                                              : Colors.black,
                                    ),
                                    onPressed: () {
                                      if (!inChat && !blocked) {
                                        DatabaseMethods(uid: Constants.myUserId)
                                            .createPersonalChat(
                                                userId: widget.userId,
                                                actionType: 'START_CONVO',
                                                anon: false)
                                            .then((personalChatId) {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PersonalChatScreen(
                                                        personalChatId:
                                                            personalChatId,
                                                        contactId:
                                                            widget.userId,
                                                        openByOther: true,
                                                        anon: false,
                                                        friend: false,
                                                      )));
                                        });
                                      } else if (blocked) {
                                        DatabaseMethods(uid: Constants.myUserId)
                                            .unBlockUser(widget.userId);
                                        showCenterFlash(
                                            alignment: Alignment.center,
                                            context: context,
                                            text: 'Unblocked');
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  !inChat && !blocked
                                      ? 'Chat'
                                      : blocked
                                          ? 'Unblock'
                                          : 'In Chat',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(1, 1.5),
                                        blurRadius: 1,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
            Text(isMe ? 'Me' : username,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(
              height: height * 0.025,
            ),
            quote.isNotEmpty
                ? Container(
                    margin: EdgeInsets.only(top: height * 0.025),
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        infoText(text: quote, textAlign: TextAlign.center),
                      ],
                    ))
                : const SizedBox.shrink(),
            SizedBox(
              height: height * 0.025,
            ),
            !blocked && widget.blockAble
                ? storyStreamWrapper(
                    storyStream: storyStream,
                    align: Alignment.center,
                    viewUser: true)
                : const SizedBox.shrink(),
            SizedBox(
              height: height * 0.025,
            ),
            tags.isNotEmpty
                ? Container(
                    height: 45,
                    margin: EdgeInsets.only(bottom: height * 0.025),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 13.5),
                    child: ProfileTagList(
                      editable: false,
                      tags: tags,
                      tagNum: tags.length,
                    ))
                : const SizedBox.shrink(),
            SizedBox(
              height: height * 0.05,
            ),
            !blocked && widget.blockAble
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 27),
                    child: groupList(widget.userId))
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    final TargetPlatform platform = Theme.of(context).platform;

    return StreamBuilder(
        stream: DatabaseMethods().userCollection.doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            var val = snapshot.data;
            username = val.data()['name'];
            profileImg = val.data()['profileImg'];
            quote = val.data()['quote'];
            tags = val.data()['tags'];
            banner = val.data()['banner'];
            friends = val.data()['friends'];
            receivedFdReq = val.data()['receivedFdReq'];
            sentFdReq = val.data()['sentFdReq'];
            blockedBy = val.data()['blockedBy'];
            isMe = widget.userId == Constants.myUserId;

            bool befriended =
                friends != null && friends.contains(Constants.myUserId);
            bool sentReq =
                sentFdReq != null && sentFdReq.contains(Constants.myUserId);
            bool receivedReq = receivedFdReq != null &&
                receivedFdReq.contains(Constants.myUserId);
            bool blocked =
                blockedBy != null && blockedBy.contains(Constants.myUserId);

            return widget.blockAble
                ? Scaffold(
                    extendBodyBehindAppBar: true,
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      actions: !blocked
                          ? [
                              PopupMenuButton(
                                  icon: Icon(
                                    platform == TargetPlatform.android
                                        ? Icons.more_vert
                                        : CupertinoIcons.ellipsis_vertical,
                                    color: Colors.black,
                                  ),
                                  itemBuilder: (BuildContext context) => [
                                        PopupMenuItem(
                                            value: 1,
                                            child: Row(children: const <Widget>[
                                              Icon(
                                                Icons.block_outlined,
                                                color: Colors.black,
                                              ),
                                              Text(' Block'),
                                            ])),
                                        PopupMenuItem(
                                            value: 2,
                                            child: Row(children: <Widget>[
                                              Icon(
                                                platform ==
                                                        TargetPlatform.android
                                                    ? Icons.flag_rounded
                                                    : CupertinoIcons.flag_fill,
                                                color: Colors.black,
                                              ),
                                              const Text(' Report'),
                                            ])),
                                      ],
                                  onSelected: (value) {
                                    if (value == 1) {
                                      DatabaseMethods(uid: Constants.myUserId)
                                          .blockUser(widget.userId);
                                      showCenterFlash(
                                          alignment: Alignment.center,
                                          context: context,
                                          text: 'Blocked');
                                    } else if (value == 2) {
                                      reportUser(
                                          userReportedId: widget.userId,
                                          senderId: Constants.myUserId,
                                          context: context);
                                    }
                                  })
                            ]
                          : null,
                    ),
                    body: userContent(
                        height, blocked, befriended, sentReq, receivedReq))
                : userContent(
                    height, blocked, befriended, sentReq, receivedReq);
          } else {
            return screenLoadingIndicator(context);
          }
        });
  }
}
