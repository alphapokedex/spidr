import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/conversationScreen.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/views/personalChatScreen.dart';
import 'package:spidr_app/views/sendMedia.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'bottomSheetWidgets.dart';

Widget gcHashTag(String hashTag, double size) {
  return Container(
    decoration: shadowEffect(15),
    child: Text(
      hashTag,
      style: TextStyle(
          fontSize: size, color: Colors.orange, fontWeight: FontWeight.bold),
    ),
  );
}

Widget groupIcon(
    BuildContext context,
    String groupId,
    String hashTag,
    String admin,
    String profileImg,
    String groupState,
    bool anon,
    bool oneDay,
    int createdAt) {
  int timeElapsed = getTimeElapsed(createdAt);
  return Column(
    children: [
      GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GroupProfileScreen(
                      groupId: groupId,
                      admin: admin,
                      fromChat: false,
                      preview: true)));
        },
        child: groupProfile(
            groupId: groupId,
            oneDay: oneDay,
            timeElapsed: timeElapsed,
            profileImg: profileImg),
      ),
      gcHashTag(hashTag, 12),
      groupStateIndicator(groupState, anon, MainAxisAlignment.center)
    ],
  );
}

Widget userIcon(BuildContext context, String senderId, String sendBy,
    String profileImg, String anonImg, bool anon, bool blocked) {
  sendBy = senderId == Constants.myUserId
      ? 'Me'
      : anon != null && anon
          ? 'Anonymous'
          : sendBy;
  DateTime now = DateTime.now();
  return GestureDetector(
    onTap: () async {
      if (anon == null || !anon) {
        openUserProfileBttSheet(context, senderId, sendBy, profileImg);
        // Navigator.push(context, MaterialPageRoute(
        //     builder: (context) => UserProfileScreen(
        //       userId:senderId,
        //       profileImg:profileImg,
        //       username:sendBy,
        //       blockAble: false,
        //     )
        // ));
      } else if (anon) {
        await DatabaseMethods(
          uid: Constants.myUserId,
        )
            .createPersonalChat(
          userId: senderId,
          sendTime: now.microsecondsSinceEpoch,
          anon: true,
          actionType: 'START_CONVO',
        )
            .then((personalChatId) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => PersonalChatScreen(
                        personalChatId: personalChatId,
                        contactId: senderId,
                        openByOther: true,
                        anon: true,
                        friend: false,
                      )));
        });
      }
    },
    child: Column(
      children: [
        avatarImg(anon != null && anon ? anonImg : profileImg, 24, false),
        const SizedBox(height: 5),
        userLabel(sendBy, anon, blocked),
      ],
    ),
  );
}

Widget userLabel(String sendBy, bool anon, bool blocked) {
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.orange, borderRadius: BorderRadius.circular(15)),
      child: RichText(
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: [
            WidgetSpan(
                child: blocked
                    ? const Icon(
                        Icons.block_rounded,
                        color: Colors.red,
                      )
                    : const SizedBox.shrink()),
            TextSpan(
                text: sendBy,
                style: GoogleFonts.hammersmithOne(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
          ])));
}

Widget mediaCommentSenderPanel(
    {BuildContext context,
    String mediaId,
    String senderId,
    String sendBy,
    String profileImg,
    String anonImg,
    bool anon,
    bool blocked,
    fillColor,
    bool disabled,
    double heightDiv = 0.1}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            mediaCommentList(
                context: context,
                mediaId: mediaId,
                heightDiv: heightDiv,
                anon: anon),
            senderId != null
                ? Flexible(
                    child: userIcon(context, senderId, sendBy, profileImg,
                        anonImg, anon, blocked))
                : const SizedBox.shrink()
          ],
        ),
      ),
      MediaCommentComposer(
        mediaId: mediaId,
        autoFocus: false,
        fillColor: fillColor,
        disabled: disabled,
      )
    ],
  );
}

Widget mediaFuncBtt(icon) {
  return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white24,
          border: Border.all(color: Colors.orange, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(4.5),
        child: Icon(icon, size: 22, color: Colors.orange),
      ));
}

Widget imgToChatBtt(BuildContext context, String groupState, String groupId,
    String messageId, bool isMember) {
  return GestureDetector(
      onTap: () {
        if (groupState == 'public' || isMember) {
          DatabaseMethods().getMsgIndex(groupId, messageId).then((val) {
            if (val != -1) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ConversationScreen(
                            groupChatId: groupId,
                            uid: Constants.myUserId,
                            spectate: false,
                            preview: true,
                            initIndex: val,
                            hideBackButton: false,
                          )));
            } else {
              Fluttertoast.showToast(
                  msg: 'Sorry, this message has been deleted');
            }
          });
        }
      },
      child: mediaFuncBtt(groupState == 'private' && !isMember
          ? Icons.lock_rounded
          : Icons.remove_red_eye_rounded));
}

Widget sendMediaBtt(
  BuildContext context,
  String senderId,
  Map mediaObj,
  String mediaId,
  String groupId,
  List mediaGallery,
  bool anon,
) {
  return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SendMediaScreen(
                      ogSenderId: senderId,
                      imgObj: mediaObj != null && mediaObj['imgName'] != null
                          ? mediaObj
                          : null,
                      fileObj: mediaObj != null && mediaObj['fileName'] != null
                          ? mediaObj
                          : null,
                      messageId: mediaId,
                      groupId: groupId,
                      mediaGallery: mediaGallery,
                      anon: anon,
                    )));
      },
      child: mediaFuncBtt(Feather.send));
}

Widget toggleSaveMediaBtt(
  BuildContext context,
  String senderId,
  Map imgObj,
  Map fileObj,
  String messageId,
  String groupId,
  List mediaGallery,
  bool anon,
) {
  return StreamBuilder(
      stream: DatabaseMethods()
          .userCollection
          .doc(Constants.myUserId)
          .collection('backpack')
          .doc(messageId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          bool saved = snapshot.data.data() != null;
          return GestureDetector(
              onTap: () async {
                if (!saved) {
                  await DatabaseMethods(uid: Constants.myUserId).saveMedia(
                      imgObj,
                      fileObj,
                      mediaGallery,
                      groupId,
                      senderId,
                      messageId,
                      anon);
                  showCenterFlash(
                      alignment: Alignment.center,
                      context: context,
                      text: 'Saved');
                } else {
                  await DatabaseMethods(uid: Constants.myUserId)
                      .removeSavedMedia(messageId);
                  showCenterFlash(
                      alignment: Alignment.center,
                      context: context,
                      text: 'Unsaved');
                }
              },
              child: mediaFuncBtt(
                  !saved ? Icons.bookmark_border : Icons.bookmark_rounded));
        } else {
          return const SizedBox.shrink();
        }
      });
}

Widget shareMediaBtt(
    BuildContext context, Map mediaObj, List mediaGallery, platform) {
  return GestureDetector(
      onTap: () {
        shareMediaFile(
            context: context, mediaGallery: mediaGallery, imgObj: mediaObj);
      },
      child: mediaFuncBtt(platform == TargetPlatform.android
          ? Icons.share_rounded
          : CupertinoIcons.share));
}

Widget moreOpsMediaBtt(
    {BuildContext context,
    Map imgObj,
    Map fileObj,
    List mediaGallery,
    String senderId,
    String groupId,
    String mediaId,
    bool anon,
    bool explore = false}) {
  final TargetPlatform platform = Theme.of(context).platform;
  return StreamBuilder(
      stream: DatabaseMethods()
          .reportedContentCollection
          .doc(mediaId)
          .collection('reporters')
          .doc(Constants.myUserId)
          .snapshots(),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () {
            openMoreOpsBttSheet(
                context: context,
                platform: platform,
                groupId: groupId,
                senderId: senderId,
                mediaId: mediaId,
                mediaGallery: mediaGallery,
                imgObj: imgObj,
                fileObj: fileObj,
                reported: snapshot.hasData && snapshot.data.data() != null,
                anon: anon,
                explore: explore);
          },
          child: mediaFuncBtt(platform == TargetPlatform.android
              ? Icons.more_horiz
              : CupertinoIcons.ellipsis),
        );
      });
}

Widget profileIconWithId({String groupId, String userId}) {
  return groupId != null ? GroupIconWithId(groupId) : UserIconWithId(userId);
}

class GroupIconWithId extends StatelessWidget {
  final String groupId;
  const GroupIconWithId(this.groupId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseMethods().groupChatCollection.doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.data() != null &&
                (snapshot.data.data()['deleted'] == null ||
                    !snapshot.data.data()['deleted'])) {
              var gcDS = snapshot.data;
              String profileImg = gcDS.data()['profileImg'];
              String hashTag = gcDS.data()['hashTag'];
              return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      avatarImg(profileImg, 18, false),
                      gcHashTag(hashTag, 10),
                    ],
                  ));
            } else {
              return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      const Icon(Icons.timer, color: Colors.grey),
                      gcHashTag('Expired', 10),
                    ],
                  ));
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}

class UserIconWithId extends StatelessWidget {
  final String userId;
  const UserIconWithId(this.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseMethods().userCollection.doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            var userDS = snapshot.data;
            String profileImg = userDS.data()['profileImg'];
            String username = userDS.data()['name'];
            return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    avatarImg(profileImg, 18, false),
                    Container(
                      decoration: shadowEffect(15),
                      child: Text(
                        username,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ));
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
