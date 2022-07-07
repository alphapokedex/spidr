import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/sendMedia.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'bottomSheetWidgets.dart';

Widget mediaAndFileTile({
  BuildContext context,
  Map imgObj,
  Map fileObj,
  String senderId,
  String messageId,
  List mediaGallery,
  int mediaIndex,
  bool play,
}) {
  Widget tile = Container(
      decoration:
          imgObj != null && imgObj['sticker'] != null && imgObj['sticker']
              ? null
              : shadowEffect(30),
      margin: const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: mediaAndFileDisplay(
          context: context,
          imgObj: imgObj,
          fileObj: fileObj,
          senderId: senderId,
          mediaId: messageId,
          play: play,
          showInfo: false,
          mediaGallery: mediaGallery,
          mediaIndex: mediaIndex,
          displayGifs: true,
        ),
      ));

  return mediaGallery == null ? Expanded(child: tile) : tile;
}

class MediaGalleryFeed extends StatefulWidget {
  final List mediaGallery;
  final String senderId;
  final String messageId;
  const MediaGalleryFeed(
    this.mediaGallery,
    this.senderId,
    this.messageId,
  );
  @override
  _MediaGalleryFeedState createState() => _MediaGalleryFeedState();
}

class _MediaGalleryFeedState extends State<MediaGalleryFeed> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CarouselSlider(
          items: widget.mediaGallery.map((m) {
            int index = widget.mediaGallery.indexOf(m);
            return mediaAndFileTile(
              context: context,
              imgObj: m,
              senderId: widget.senderId,
              messageId: widget.messageId,
              mediaGallery: widget.mediaGallery,
              mediaIndex: index,
              play: current == index,
            );
          }).toList(),
          options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              enlargeCenterPage: true,
              initialPage: current,
              onPageChanged: (index, reason) {
                setState(() {
                  current = index;
                });
              })),
    );
  }
}

Widget infoListTile(
  BuildContext context,
  String senderId,
  String messageId,
  Map imgObj,
  Map fileObj,
  List mediaGallery,
  int sendTime,
  bool anon,
  String groupId,
  String hashTag,
) {
  return SizedBox(
    height: 63,
    child: ListTile(
        leading: userProfile(userId: senderId, anon: anon, blockAble: false),
        title: Text(
          hashTag,
          style: const TextStyle(
              color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        subtitle:
            userName(userId: senderId, anon: anon, fontWeight: FontWeight.bold),
        trailing: StreamBuilder(
            stream: DatabaseMethods()
                .groupChatCollection
                .doc(groupId)
                .collection('chats')
                .doc(messageId)
                .snapshots(),
            builder: (context, snapshot) {
              int numOfReplies = 0;
              bool replied;
              List replies = [];
              if (snapshot.hasData && snapshot.data.data() != null) {
                replies = snapshot.data.data()['replies'];
                replied = checkRepliedMsg(replies);
                numOfReplies = getNumOfReplies(replies);
              }

              return Constants.myUserId == senderId && numOfReplies > 0
                  ? GestureDetector(
                      onTap: () {
                        showRepliedUsersDialog(replies, messageId, groupId,
                            context, anon != null && anon);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                  blurRadius: 6.0)
                            ],
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.orange),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        child: Text(
                          '$numOfReplies users replied',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12.5),
                        ),
                      ),
                    )
                  : Constants.myUserId != senderId &&
                          replied != null &&
                          !replied
                      ? IconButton(
                          icon: const Icon(Icons.maps_ugc, color: Colors.black),
                          onPressed: () {
                            showReplyBox(
                              context: context,
                              groupId: groupId,
                              hashTag: hashTag,
                              anon: anon,
                              userId: senderId,
                              text: '',
                              sendTime: sendTime,
                              imgMap: imgObj,
                              fileMap: fileObj,
                              mediaGallery: mediaGallery,
                              messageId: messageId,
                            );
                          })
                      : const SizedBox.shrink();
            })),
  );
}

Widget feedTile(
  BuildContext context,
  Map imgObj,
  Map fileObj,
  List mediaGallery,
  String senderId,
  int sendTime,
  String messageId,
  bool anon,
  String groupId,
  String hashTag,
) {
  final TargetPlatform platform = Theme.of(context).platform;
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.5),
        child: Column(
          children: [
            infoListTile(context, senderId, messageId, imgObj, fileObj,
                mediaGallery, sendTime, anon, groupId, hashTag),
            mediaGallery == null
                ? mediaAndFileTile(
                    context: context,
                    imgObj: imgObj,
                    fileObj: fileObj,
                    senderId: senderId,
                    messageId: messageId,
                    play: true)
                : MediaGalleryFeed(mediaGallery, senderId, messageId),
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          IconButton(
                              icon: Icon(platform == TargetPlatform.android
                                  ? Icons.add_comment_rounded
                                  : CupertinoIcons.conversation_bubble),
                              color: Colors.black,
                              iconSize:
                                  platform == TargetPlatform.android ? 25 : 20,
                              onPressed: () {
                                showMediaCommentDialog(
                                    context, messageId, anon);
                              }),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              icon: const Icon(Feather.send),
                              color: Colors.black,
                              iconSize:
                                  platform == TargetPlatform.android ? 25 : 20,
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SendMediaScreen(
                                              ogSenderId: senderId,
                                              imgObj: imgObj,
                                              fileObj: fileObj,
                                              messageId: messageId,
                                              groupId: groupId,
                                              mediaGallery: mediaGallery,
                                              anon: anon,
                                            )));
                              }),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      StreamBuilder(
                          stream: DatabaseMethods()
                              .userCollection
                              .doc(Constants.myUserId)
                              .collection('backpack')
                              .doc(messageId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              bool saved = snapshot.data.data() != null;
                              return IconButton(
                                  icon: Icon(!saved
                                      ? Icons.bookmark_border
                                      : Icons.bookmark),
                                  color: Colors.black,
                                  iconSize: platform == TargetPlatform.android
                                      ? 25
                                      : 20,
                                  onPressed: () async {
                                    if (!saved) {
                                      await DatabaseMethods(
                                              uid: Constants.myUserId)
                                          .saveMedia(
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
                                      await DatabaseMethods(
                                              uid: Constants.myUserId)
                                          .removeSavedMedia(messageId);
                                      showCenterFlash(
                                          alignment: Alignment.center,
                                          context: context,
                                          text: 'Unsaved');
                                    }
                                  });
                            } else {
                              return const SizedBox.shrink();
                            }
                          }),
                      StreamBuilder(
                          stream: DatabaseMethods()
                              .reportedContentCollection
                              .doc(messageId)
                              .collection('reporters')
                              .doc(Constants.myUserId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            return IconButton(
                                icon: Icon(platform == TargetPlatform.android
                                    ? Icons.more_horiz
                                    : CupertinoIcons.ellipsis),
                                color: Colors.black,
                                iconSize: platform == TargetPlatform.android
                                    ? 25
                                    : 20,
                                onPressed: () {
                                  openMoreOpsBttSheet(
                                    context: context,
                                    platform: platform,
                                    groupId: groupId,
                                    senderId: senderId,
                                    mediaId: messageId,
                                    mediaGallery: mediaGallery,
                                    imgObj: imgObj,
                                    fileObj: fileObj,
                                    reported: snapshot.hasData &&
                                        snapshot.data.data() != null,
                                    toChat: false,
                                    anon: anon,
                                  );
                                });
                          })
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 63, left: 13.5),
            child: mediaCommentList(
                context: context,
                mediaId: messageId,
                heightDiv: 0.15,
                anon: anon),
          ))
    ],
  );
}
