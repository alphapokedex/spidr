import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/sendMedia.dart';
import 'package:spidr_app/widgets/storyCommentsWidgets.dart';
import 'package:spidr_app/widgets/storyRepliesWidgets.dart';
import 'package:spidr_app/widgets/storySeensWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'bottomSheetWidgets.dart';

Widget moreOpsBtt(
  BuildContext context,
  Map mediaObj,
  List mediaGallery,
  String groupId,
  String senderId,
  String mediaId,
  bool anon,
  GlobalKey tutorialKey,
) {
  final TargetPlatform platform = Theme.of(context).platform;
  return SizedBox(
    key: tutorialKey,
    width: 40,
    height: 40,
    child: StreamBuilder(
        stream: DatabaseMethods()
            .reportedContentCollection
            .doc(mediaId)
            .collection('reporters')
            .doc(Constants.myUserId)
            .snapshots(),
        builder: (context, snapshot) {
          return FloatingActionButton(
            heroTag: 'moreOps',
            backgroundColor: Colors.black45,
            onPressed: () async {
              bool removed = await openMoreOpsBttSheet(
                  context: context,
                  platform: platform,
                  senderId: senderId,
                  mediaId: mediaId,
                  mediaGallery: mediaGallery,
                  imgObj: mediaObj,
                  reported: snapshot.hasData && snapshot.data.data() != null,
                  anon: anon,
                  groupId: groupId,
                  story: true);
              if (removed != null && removed) {
                Navigator.of(context).pop();
              }
            },
            child: Icon(
                platform == TargetPlatform.android
                    ? Icons.more_horiz
                    : CupertinoIcons.ellipsis,
                color: Colors.orange),
          );
        }),
  );
}

Widget sendBtt(
  BuildContext context,
  String senderId,
  Map mediaObj,
  List mediaGallery,
  String mediaId,
  bool anon,
  GlobalKey tutorialKey,
) {
  return SizedBox(
    key: tutorialKey,
    width: 40,
    height: 40,
    child: FloatingActionButton(
      backgroundColor: Colors.black45,
      heroTag: 'send',
      child: const Icon(
        Feather.send,
        color: Colors.orange,
      ),
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SendMediaScreen(
                      ogSenderId: senderId,
                      imgObj: mediaObj,
                      mediaGallery: mediaGallery,
                      storyId: mediaId,
                      anon: anon,
                    )));
      },
    ),
  );
}

Widget seenBtt(BuildContext context, String senderId, String mediaId) {
  return SizedBox(
    width: 50,
    height: 50,
    child: StreamBuilder(
        stream: DatabaseMethods()
            .userCollection
            .doc(senderId)
            .collection('stories')
            .doc(mediaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            List seenList = snapshot.data.data()['seenList'];
            int numOfSeen = seenList.fold(
                0,
                (sum, e) =>
                    !Constants.myBlockList.contains(e) ? sum + 1 : sum + 0);
            return Stack(
              children: [
                SizedBox(
                  height: 40,
                  width: 45,
                  child: FloatingActionButton(
                    backgroundColor: Colors.black45,
                    heroTag: 'view',
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_rounded,
                              color: Colors.orange),
                          onPressed: () {
                            storyBttSheet(
                                context: context,
                                seenLS: snapshot.data.data()['seenList']);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                numOfSeen > 0
                    ? notifIcon(numOfSeen, false)
                    : const SizedBox.shrink()
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
  );
}

Widget listTile(
    {BuildContext context,
    String userId,
    String text,
    String storyId,
    String commentId,
    String replyId,
    bool storyExist,
    TextEditingController replyEditingController,
    reFormKey,
    List reportedBy,
    int maxLines,
    overflow}) {
  bool trailing = storyId != null || commentId != null || replyId != null;
  bool reply = replyId != null;

  return ListTile(
      leading: userProfile(userId: userId, anon: false),
      title: userName(
          userId: userId, fontWeight: FontWeight.bold, color: Colors.orange),
      subtitle: !urlRegExp.hasMatch(text)
          ? Text(text,
              style: const TextStyle(
                color: Colors.black,
              ))
          : urlPreviewWrapper(
              context: context,
              text: text,
              url: extractUrl(text),
              textColor: Colors.orange,
              linkColor: Colors.blue,
              simpleUrl: false,
              maxLines: maxLines,
              overflow: overflow,
            ),
      trailing: trailing
          ? Wrap(
              children: [
                !reply
                    ? StreamBuilder(
                        stream: DatabaseMethods()
                            .getCommentReplies(storyId, commentId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            int numOfRep = snapshot.data.docs.fold(
                                0,
                                (sum, e) => !Constants.myBlockList
                                        .contains(e.data()['senderId'])
                                    ? sum + 1
                                    : sum + 0);
                            return Stack(
                              children: [
                                IconButton(
                                    icon: const Icon(
                                      Icons.reply_rounded,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () {
                                      storyBttSheet(
                                          context: context,
                                          replyStream: DatabaseMethods()
                                              .getCommentReplies(
                                                  storyId, commentId),
                                          storyId: storyId,
                                          commentId: commentId,
                                          storyExist: storyExist,
                                          replyEditingController:
                                              replyEditingController,
                                          reFormKey: reFormKey,
                                          ogComment: {
                                            'senderId': userId,
                                            'comment': text
                                          });
                                    }),
                                numOfRep > 0
                                    ? notifIcon(numOfRep, false)
                                    : const SizedBox.shrink()
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        })
                    : const SizedBox.shrink(),
                userId == Constants.myUserId
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          if (!reply) {
                            DatabaseMethods(uid: userId)
                                .delStoryComment(storyId, commentId);
                          } else {
                            DatabaseMethods(uid: userId)
                                .delCommentReply(storyId, commentId, replyId);
                          }
                        })
                    : reportedBy == null ||
                            !reportedBy.contains(Constants.myUserId)
                        ? IconButton(
                            icon: const Icon(
                              Icons.flag_rounded,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              reportContent(
                                  storyId: storyId,
                                  contentId: !reply ? commentId : replyId,
                                  commentId: reply ? commentId : null,
                                  context: context);
                            })
                        : const SizedBox.shrink(),
              ],
            )
          : const SizedBox.shrink());
}

storyBttSheet(
    {BuildContext context,
    Stream comStream,
    Stream replyStream,
    List seenLS,
    Map ogComment,
    String storyId,
    String storySenderId,
    String commentId,
    bool storyExist,
    TextEditingController commentEditingController,
    TextEditingController replyEditingController,
    comFormKey,
    reFormKey}) {
  final TargetPlatform platform = Theme.of(context).platform;
  showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0))),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.75,
            initialChildSize: 0.65,
            builder: (BuildContext context, ScrollController controller) {
              return Container(
                color: comStream != null || replyStream != null
                    ? Colors.white
                    : Colors.black45,
                child: Column(
                  children: [
                    replyStream != null
                        ? Flexible(
                            child: listTile(
                                context: context,
                                userId: ogComment['senderId'],
                                text: ogComment['comment'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          )
                        : const SizedBox.shrink(),
                    comStream != null
                        ? buildCommentComposer(
                            controller,
                            platform,
                            context,
                            storyId,
                            storySenderId,
                            storyExist,
                            commentEditingController,
                            comFormKey)
                        : replyStream != null
                            ? buildReplyComposer(
                                controller,
                                platform,
                                context,
                                storyId,
                                commentId,
                                storyExist,
                                replyEditingController,
                                reFormKey)
                            : seenLS != null
                                ? Center(
                                    child: Container(
                                    margin: const EdgeInsets.all(10),
                                    child: const Text('Viewers',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ))
                                : const SizedBox.shrink(),
                    Expanded(
                        child: comStream != null
                            ? commentList(controller, comStream, storyId,
                                storyExist, replyEditingController, reFormKey)
                            : replyStream != null
                                ? replyList(
                                    controller, replyStream, storyId, commentId)
                                : seenLS != null
                                    ? seenList(controller, seenLS)
                                    : const SizedBox.shrink()),
                  ],
                ),
              );
            });
      });
}
