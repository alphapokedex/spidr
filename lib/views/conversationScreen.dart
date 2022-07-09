import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/services/toggleMembership.dart';
import 'package:spidr_app/views/editGroup.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/widgets/chatBubbleWidgets.dart';
import 'package:spidr_app/widgets/chatFuncWidgets.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'addAndInviteUser.dart';

class ConversationScreen extends StatefulWidget {
  final String groupChatId;
  final String uid;
  final bool spectate;
  final bool preview;
  final int initIndex;
  final bool hideBackButton;
  const ConversationScreen({
    Key key,
    this.groupChatId,
    this.uid,
    this.spectate,
    this.preview,
    this.initIndex,
    this.hideBackButton,
  }) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  TextEditingController messageController = TextEditingController();

  Stream chatMessageStream;
  List<String> highlightWords = [];
  // bool searchKeyWord = false;
  bool loading = false;
  bool writing = false;

  ItemScrollController scrollController = ItemScrollController();

  String groupChatId;
  String groupPic;
  String groupState;
  String hashTag = '';
  String admin = '';
  double groupCapacity;
  bool oneDay;
  int createdAt;
  int numOfMem;
  List tags;
  String groupInfo;
  List members;
  Map joinReq;
  Map waitList;
  List invites;
  List bannedUsers;
  List writingMem = [];
  Map inCallUsers;
  // String loudUser;

  // Map keyWordMap = {};
  // int wordCount = 0;
  // List indexes = [];
  // int curKeyWordIndex = 0;

  bool isMyChat;
  bool anon;

  Map<String, dynamic> replyInfo = {};
  String msgReplyTo;
  List blockList;

  // bool openKeyBoard = false;

  getMessages() {
    if (mounted) {
      setState(() {
        chatMessageStream = DatabaseMethods(uid: widget.uid)
            .getConversationMessages(widget.groupChatId);
      });
    }
  }

  sendMessage({Map inChatReply}) {
    if (!emptyStrChecker(messageController.text)) {
      DateTime now = DateTime.now();

      String message = messageController.text;
      String ogSenderId;
      if (inChatReply != null) {
        if (inChatReply['msgReplyTo'] is List &&
            inChatReply['msgReplyTo'][0]['ogSenderId'] != null) {
          ogSenderId = inChatReply['msgReplyTo'][0]['ogSenderId'];
        } else if (inChatReply['msgReplyTo'] is Map &&
            inChatReply['msgReplyTo']['ogSenderId'] != null) {
          ogSenderId = inChatReply['msgReplyTo']['ogSenderId'];
        } else {
          ogSenderId = inChatReply['userReplyTo'];
        }
      }

      DatabaseMethods(uid: widget.uid).addConversationMessages(
        groupChatId: widget.groupChatId,
        message: message,
        username: Constants.myName,
        userId: widget.uid,
        time: now.microsecondsSinceEpoch,
        inChatReply: inChatReply,
        ogMediaId: inChatReply != null ? inChatReply['msgId'] : null,
        ogSenderId: ogSenderId,
      );
      setState(() {
        writing = false;
      });

      if (inChatReply != null) {
        if (inChatReply['msgReplyTo'] is Map ||
            inChatReply['msgReplyTo'] is List) {
          DatabaseMethods().addFileCopies(mediaId: inChatReply['msgId']);
        }
        setState(() {
          msgReplyTo = null;
          replyInfo = {};
        });
      }

      // for(String word in keyWordMap.keys){
      //   List indexes = keyWordMap[word];
      //   for(int i = 0; i < indexes.length; i++){
      //     keyWordMap[word][i] += 1;
      //   }
      // }
      //
      // String lowerWord = message.toLowerCase();
      // List wList = lowerWord.split(' ');
      // for(String word in wList){
      //   if(keyWordMap.containsKey(word)){
      //     List indexes = keyWordMap[word];
      //     indexes.add(0);
      //   }else{
      //     keyWordMap[word]= [0];
      //   }
      // }
      messageController.text = '';
    }
  }

  deleteMessage(String chatId, Map imgObj, Map fileObj, List mediaGallery,
      int msgIndex, String message) {
    DatabaseMethods(uid: widget.uid).deleteConversationMessage(
        groupChatId: widget.groupChatId, chatId: chatId);
    // DatabaseMethods(uid: widget.uid).deleteNotification(widget.groupChatId, hashTag, chatId);

    // if(imgObj != null || fileObj != null || mediaGallery != null){
    //   DatabaseMethods(uid: widget.uid).deleteGroupFeed(widget.groupChatId, chatId);
    // }

    // List wList = [];
    // if(message != null) wList = message.split(' ');
    //
    // for(String word in wList){
    //   List indexes = keyWordMap[word];
    //   indexes.remove(msgIndex);
    //   if(indexes.isEmpty) keyWordMap.remove(word);
    // }
    //
    // for(String word in keyWordMap.keys){
    //   List indexes = keyWordMap[word];
    //   for(int i=0; i<indexes.length; i++){
    //     if(keyWordMap[word][i] > msgIndex) keyWordMap[word][i] --;
    //   }
    // }
  }

  Widget textField(bool expired) {
    return Expanded(
      child: TextField(
          autofocus: replyInfo.isNotEmpty ? true : false,
          style: const TextStyle(color: Colors.orange),
          onChanged: (val) {
            setState(() {
              writing = true;
            });
          },
          maxLines: null,
          controller: messageController,
          textCapitalization: TextCapitalization.sentences,
          decoration: darkMsgInputDec(
              context: context,
              hintText: !expired ? 'Message' : 'Expired',
              groupChatId: widget.groupChatId,
              gif: true,
              disabled: expired,
              fillColor: Colors.black)),
    );
  }

  Widget messageTile(
      String message,
      Map imgObj,
      Map fileObj,
      List mediaGallery,
      String sendBy,
      String dateTime,
      int time,
      String userId,
      bool isSendByMe,
      String messageId,
      List replies,
      bool newDay,
      int index,
      Map inChatReply,
      String ogMediaId,
      bool reported,
      String ogSenderId) {
    final TargetPlatform platform = Theme.of(context).platform;

    String hourMin = dateTime.substring(dateTime.indexOf(' ') + 1);
    String date = dateTime.substring(0, dateTime.indexOf(' '));

    bool replied = checkRepliedMsg(replies);
    int numOfReplies = getNumOfReplies(replies);
    bool blocked = ogSenderId != null && blockList.contains(ogSenderId);

    double width = MediaQuery.of(context).size.width;

    Widget mediaCommentBtt = IconButton(
      icon: const Icon(Icons.add_comment_rounded, color: Colors.orange),
      onPressed: () {
        showMediaCommentDialog(context, messageId, anon);
      },
    );

    return !blocked
        ? Column(
            children: [
              !isSendByMe
                  ? Row(
                      children: [
                        Container(
                            margin: const EdgeInsets.fromLTRB(9, 0.0, 2.5, 2.5),
                            child: userProfile(
                                userId: userId, anon: anon != null && anon)),
                        anon == null || !anon
                            ? RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: '$sendBy ',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  userId == admin
                                      ? WidgetSpan(
                                          child: Icon(
                                            !isSendByMe
                                                ? Icons.home_filled
                                                : null,
                                            size: 14,
                                            color: Colors.orange,
                                          ),
                                        )
                                      : const TextSpan(),
                                ]),
                              )
                            : const SizedBox.shrink()
                      ],
                    )
                  : const SizedBox.shrink(),
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                reverse: !isSendByMe ? true : false,
                child: Row(
                  children: [
                    !isSendByMe
                        ? Center(
                            child: Text(
                              hourMin,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : const SizedBox.shrink(),
                    GestureDetector(
                      onLongPress: () async {
                        if (message.isNotEmpty ||
                            (imgObj != null && imgObj['imgUrl'] != null) ||
                            fileObj != null && fileObj['fileUrl'] != null ||
                            (mediaGallery != null &&
                                mediaGallery[0]['imgUrl'] != null)) {
                          DocumentSnapshot mdDS = await DatabaseMethods()
                              .mediaCollection
                              .doc(messageId)
                              .get();

                          isSendByMe
                              ? showMenu(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                      0.0,
                                      MediaQuery.of(context).size.height,
                                      0.0,
                                      0.0),
                                  items: <PopupMenuEntry>[
                                      (imgObj != null &&
                                                  imgObj['ogSenderId'] ==
                                                      null) ||
                                              (mediaGallery != null &&
                                                  mediaGallery[0]
                                                          ['ogSenderId'] ==
                                                      null) ||
                                              (fileObj != null &&
                                                  (pdfChecker(fileObj[
                                                          'fileName']) ||
                                                      audioChecker(
                                                          fileObj['fileName'])))
                                          ? PopupMenuItem(
                                              value: 2,
                                              child: iconText(
                                                  mdDS.exists
                                                      ? Icons
                                                          .explore_off_rounded
                                                      : Icons.explore_rounded,
                                                  mdDS.exists
                                                      ? ' Hide'
                                                      : ' Post'))
                                          : null,
                                      PopupMenuItem(
                                          value: 1,
                                          child: iconText(
                                              numOfReplies == 0
                                                  ? CupertinoIcons.delete
                                                  : Icons.open_in_new,
                                              numOfReplies == 0
                                                  ? ' Delete'
                                                  : ' Open Replies')),
                                    ]).then((value) {
                                  if (value == 1) {
                                    if (numOfReplies == 0) {
                                      String deleteMsg;
                                      if (message.isNotEmpty) {
                                        deleteMsg = message.toLowerCase();
                                      } else {
                                        if (imgObj != null) {
                                          if (imgObj['caption'] != null &&
                                              imgObj['caption'].isNotEmpty) {
                                            deleteMsg =
                                                imgObj['caption'].toLowerCase();
                                          }
                                        }
                                      }
                                      deleteMessage(messageId, imgObj, fileObj,
                                          mediaGallery, index, deleteMsg);
                                    } else {
                                      showRepliedUsersDialog(
                                          replies,
                                          messageId,
                                          widget.groupChatId,
                                          context,
                                          anon != null && anon);
                                    }
                                  } else if (value == 2) {
                                    if (mdDS.exists) {
                                      removeMediaItem(context, messageId);
                                    } else {
                                      addMediaItem(
                                          context: context,
                                          groupId: widget.groupChatId,
                                          anon: anon,
                                          sendBy: sendBy,
                                          senderId: userId,
                                          mediaId: messageId,
                                          sendTime: time,
                                          mediaObj: imgObj ?? fileObj,
                                          mediaGallery: mediaGallery);
                                    }
                                  }
                                })
                              : showMenu(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                      0.0,
                                      MediaQuery.of(context).size.height,
                                      0.0,
                                      0.0),
                                  items: [
                                      !replied
                                          ? PopupMenuItem(
                                              value: 1,
                                              child: iconText(
                                                  Icons.maps_ugc, ' Chat'))
                                          : null,
                                      isMyChat
                                          ? PopupMenuItem(
                                              value: 2,
                                              child: iconText(
                                                  platform ==
                                                          TargetPlatform.android
                                                      ? Icons.reply_rounded
                                                      : CupertinoIcons.reply,
                                                  ' Reply'))
                                          : null,
                                      !reported
                                          ? PopupMenuItem(
                                              value: 3,
                                              child: iconText(
                                                  platform ==
                                                          TargetPlatform.android
                                                      ? Icons.flag_rounded
                                                      : CupertinoIcons
                                                          .flag_fill,
                                                  ' Report'))
                                          : null,
                                    ]).then((value) {
                                  if (value == 1) {
                                    if (!replied) {
                                      showReplyBox(
                                          context: context,
                                          groupId: widget.groupChatId,
                                          hashTag: hashTag,
                                          anon: anon,
                                          userId: userId,
                                          text: message,
                                          sendTime: time,
                                          imgMap: imgObj,
                                          fileMap: fileObj,
                                          mediaGallery: mediaGallery,
                                          messageId: messageId,
                                          ogMediaId: ogMediaId);
                                    }
                                  } else if (value == 2) {
                                    String msg = message.isNotEmpty
                                        ? message
                                        : imgObj != null
                                            ? imgObj['imgName']
                                            : fileObj != null
                                                ? fileObj['fileName']
                                                : mediaGallery
                                                    .map((e) => e['imgName'])
                                                    .toList()
                                                    .join(' ');

                                    setState(() {
                                      msgReplyTo = msg;
                                      replyInfo = {
                                        'userReplyTo': userId,
                                        'msgReplyTo': message.isNotEmpty
                                            ? message
                                            : imgObj ?? fileObj ?? mediaGallery,
                                        'msgId': ogMediaId ?? messageId
                                      };
                                    });
                                  } else if (value == 3) {
                                    reportContent(
                                      context: context,
                                      groupId: widget.groupChatId,
                                      senderId: userId,
                                      contentId: messageId,
                                    );
                                  }
                                });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                            left: isSendByMe ? width * 0.25 : 9,
                            right: isSendByMe ? 9 : width * 0.25),
                        width: width,
                        alignment: isSendByMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                            padding: message.isNotEmpty
                                ? const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 13.5)
                                : const EdgeInsets.only(bottom: 9),
                            decoration: chatBubbleDec(
                                isSendByMe,
                                message.isNotEmpty ||
                                    (fileObj != null &&
                                        !audioChecker(fileObj['fileName']) &&
                                        !pdfChecker(fileObj['fileName']))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                inChatReply != null
                                    ? Container(
                                        padding:
                                            const EdgeInsets.only(bottom: 9),
                                        // decoration: BoxDecoration(
                                        //   borderRadius: BorderRadius.all(Radius.circular(10)),
                                        // ),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin:
                                                    const EdgeInsets.fromLTRB(
                                                        2.5, 0.0, 0.0, 2.5),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.reply_rounded,
                                                      color: isSendByMe
                                                          ? Colors.black
                                                          : Colors.orange,
                                                    ),
                                                    const SizedBox(
                                                      width: 2.5,
                                                    ),
                                                    userProfile(
                                                        userId: inChatReply[
                                                            'userReplyTo'],
                                                        anon: anon != null &&
                                                            anon,
                                                        size: 18),
                                                    const SizedBox(
                                                      width: 2.5,
                                                    ),
                                                    anon == null || !anon
                                                        ? userName(
                                                            userId: inChatReply[
                                                                'userReplyTo'],
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: isSendByMe
                                                                ? Colors.black
                                                                : Colors.orange)
                                                        : const SizedBox
                                                            .shrink()
                                                  ],
                                                ),
                                              ),
                                              inChatReply['msgReplyTo']
                                                      is String
                                                  ? replyTextBubble(
                                                      context,
                                                      inChatReply['msgReplyTo'],
                                                      isSendByMe)
                                                  : inChatReply['msgReplyTo']
                                                          is Map
                                                      ? inChatReply['msgReplyTo']
                                                                  [
                                                                  'ogSenderId'] !=
                                                              null
                                                          ? SharedChatBubble(
                                                              imgObj: inChatReply[
                                                                              'msgReplyTo']
                                                                          [
                                                                          'imgName'] !=
                                                                      null
                                                                  ? inChatReply[
                                                                      'msgReplyTo']
                                                                  : null,
                                                              fileObj: inChatReply[
                                                                              'msgReplyTo']
                                                                          [
                                                                          'fileName'] !=
                                                                      null
                                                                  ? inChatReply[
                                                                      'msgReplyTo']
                                                                  : null,
                                                              isSendByMe:
                                                                  isSendByMe,
                                                              mediaId: inChatReply[
                                                                              'msgReplyTo']
                                                                          [
                                                                          'fileName'] !=
                                                                      null
                                                                  ? inChatReply[
                                                                          'msgReplyTo']
                                                                      [
                                                                      'ogChatId']
                                                                  : inChatReply[
                                                                              'msgReplyTo']
                                                                          [
                                                                          'ogChatId'] ??
                                                                      inChatReply[
                                                                              'msgReplyTo']
                                                                          [
                                                                          'ogStoryId'],
                                                              reply: true,
                                                            )
                                                          : replyMediaBubble(
                                                              context: context,
                                                              imgObj: inChatReply['msgReplyTo']
                                                                          [
                                                                          'imgName'] !=
                                                                      null
                                                                  ? inChatReply[
                                                                      'msgReplyTo']
                                                                  : null,
                                                              fileObj: inChatReply['msgReplyTo']
                                                                          [
                                                                          'fileName'] !=
                                                                      null
                                                                  ? inChatReply[
                                                                      'msgReplyTo']
                                                                  : null,
                                                              messageId:
                                                                  messageId,
                                                              isSendByMe:
                                                                  isSendByMe,
                                                              platform:
                                                                  platform,
                                                              senderId: inChatReply[
                                                                  'userReplyTo'])
                                                      : inChatReply['msgReplyTo']
                                                                      [0]
                                                                  ['ogSenderId'] !=
                                                              null
                                                          ? SharedChatBubble(
                                                              mediaGallery:
                                                                  inChatReply[
                                                                      'msgReplyTo'],
                                                              isSendByMe:
                                                                  isSendByMe,
                                                              mediaId: inChatReply[
                                                                          'msgReplyTo'][0]
                                                                      [
                                                                      'ogChatId'] ??
                                                                  inChatReply[
                                                                          'msgReplyTo'][0]
                                                                      [
                                                                      'ogStoryId'],
                                                              reply: true,
                                                            )
                                                          : MediaGalleryBubble(
                                                              mediaGallery:
                                                                  inChatReply[
                                                                      'msgReplyTo'],
                                                              messageId:
                                                                  messageId,
                                                              senderId: inChatReply[
                                                                  'userReplyTo'],
                                                              isSendByMe:
                                                                  isSendByMe,
                                                              reply: true,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.35,
                                                            )
                                            ]),
                                      )
                                    : const SizedBox.shrink(),

                                // inChatReply != null ?
                                // Divider(color: Colors.white, thickness: 1.0, height: 9,) :
                                // SizedBox.shrink(),

                                message.isNotEmpty
                                    ? groupTextBubble(context, message,
                                        highlightWords, isSendByMe)
                                    : fileObj != null
                                        ? fileObj['ogSenderId'] != null
                                            ? SharedChatBubble(
                                                fileObj: fileObj,
                                                isSendByMe: isSendByMe,
                                                mediaId: fileObj['ogChatId'],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  fileChatBubble(
                                                    context: context,
                                                    fileObj: fileObj,
                                                    messageId: messageId,
                                                    isSendByMe: isSendByMe,
                                                    platform: platform,
                                                    audio: audioChecker(
                                                        fileObj['fileName']),
                                                    document: pdfChecker(
                                                        fileObj['fileName']),
                                                    senderId: userId,
                                                    groupId: widget.groupChatId,
                                                    hashTag: hashTag,
                                                    anon: anon,
                                                  ),
                                                  audioChecker(fileObj[
                                                              'fileName']) ||
                                                          pdfChecker(fileObj[
                                                              'fileName'])
                                                      ? mediaCommentBtt
                                                      : const SizedBox.shrink()
                                                ],
                                              )
                                        : imgObj != null
                                            ? imgObj['ogSenderId'] != null
                                                ? SharedChatBubble(
                                                    imgObj: imgObj,
                                                    isSendByMe: isSendByMe,
                                                    mediaId:
                                                        imgObj['ogChatId'] ??
                                                            imgObj['ogStoryId'])
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      mediaChatBubble(
                                                        imgObj: imgObj,
                                                        messageId: messageId,
                                                        context: context,
                                                        senderId: userId,
                                                        groupId:
                                                            widget.groupChatId,
                                                        hashTag: hashTag,
                                                        anon: anon,
                                                      ),
                                                      mediaCommentBtt
                                                    ],
                                                  )
                                            : mediaGallery != null
                                                ? mediaGallery[0]
                                                            ['ogSenderId'] !=
                                                        null
                                                    ? SharedChatBubble(
                                                        mediaGallery:
                                                            mediaGallery,
                                                        isSendByMe: isSendByMe,
                                                        mediaId: mediaGallery[0]
                                                                ['ogChatId'] ??
                                                            mediaGallery[0]
                                                                ['ogStoryId'],
                                                      )
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          MediaGalleryBubble(
                                                            mediaGallery:
                                                                mediaGallery,
                                                            messageId:
                                                                messageId,
                                                            isSendByMe:
                                                                isSendByMe,
                                                            senderId: userId,
                                                            groupId: widget
                                                                .groupChatId,
                                                            hashTag: hashTag,
                                                            anon: anon,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.45,
                                                          ),
                                                          mediaCommentBtt
                                                        ],
                                                      )
                                                : const SizedBox.shrink(),

                                isSendByMe && numOfReplies > 0
                                    ? GestureDetector(
                                        onTap: () {
                                          showRepliedUsersDialog(
                                              replies,
                                              messageId,
                                              widget.groupChatId,
                                              context,
                                              anon != null && anon);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.black,
                                                width: 3.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 5),
                                          margin: const EdgeInsets.fromLTRB(
                                              0.0, 10.0, 10.0, 0.0),
                                          child: Text(
                                            numOfReplies > 1
                                                ? '$numOfReplies users replied'
                                                : '$numOfReplies user replied',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            )),
                      ),
                    ),
                    isSendByMe
                        ? Center(
                            child: Text(
                              hourMin,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              dateDivider(newDay, date)
            ],
          )
        : const SizedBox.shrink();
  }

  Widget chatMessageList() {
    final TargetPlatform platform = Theme.of(context).platform;
    return widget.preview && groupState == 'private' && !isMyChat
        ? privateGroupSign(platform)
        : StreamBuilder(
            stream: chatMessageStream,
            builder: (context, snapshot) {
              return snapshot.hasData && snapshot.data != null
                  ? snapshot.data.docs.length > 0
                      ? ScrollablePositionedList.builder(
                          itemScrollController: scrollController,
                          initialScrollIndex: widget.initIndex,
                          reverse: true,
                          itemCount: snapshot.data.docs.length,
                          itemBuilder: (context, index) {
                            List reportedBy =
                                snapshot.data.docs[index].data()['reportedBy'];
                            bool reported = reportedBy != null &&
                                reportedBy.contains(Constants.myUserId);
                            String senderId =
                                snapshot.data.docs[index].data()['userId'];

                            int sendTime =
                                snapshot.data.docs[index].data()['time'];
                            String sendDateTime = timeToString(sendTime);
                            bool newDay = false;

                            if (index > 0) {
                              int prevSendTime =
                                  snapshot.data.docs[index - 1].data()['time'];
                              String preSendDateTime =
                                  timeToString(prevSendTime);
                              newDay = isNewDay(sendDateTime, preSendDateTime);
                            }

                            return !blockList.contains(senderId)
                                ? messageTile(
                                    snapshot.data.docs[index].data()['message'],
                                    snapshot.data.docs[index].data()['imgObj'],
                                    snapshot.data.docs[index].data()['fileObj'],
                                    snapshot.data.docs[index]
                                        .data()['mediaGallery'],
                                    snapshot.data.docs[index].data()['sendBy'],
                                    sendDateTime,
                                    sendTime,
                                    senderId,
                                    senderId == Constants.myUserId,
                                    snapshot.data.docs[index].id,
                                    snapshot.data.docs[index].data()['replies'],
                                    newDay,
                                    index,
                                    snapshot.data.docs[index]
                                        .data()['inChatReply'],
                                    snapshot.data.docs[index]
                                        .data()['ogMediaId'],
                                    reported,
                                    snapshot.data.docs[index]
                                        .data()['ogSenderId'],
                                  )
                                : const SizedBox.shrink();
                          })
                      : Center(child: Image.asset('assets/icon/emptyChat.png'))
                  : const SizedBox.shrink();
            },
          );
  }

  Widget buildMsgCompAndMemTog(platform, bool isOnWaitList, bool reqJoin,
      bool gotBanned, bool isMember, bool expired) {
    return Container(
        height: 54.0,
        color: Colors.white,
        child: isMember != null && isMember
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                height: 54.0,
                color: Colors.black,
                child: Row(
                  children: [
                    writing
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                writing = !writing;
                              });
                            },
                            icon: const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.black))
                        : const SizedBox.shrink(),
                    !writing
                        ? filesPickerBtt(
                            context: context,
                            platform: platform,
                            groupChatId: widget.groupChatId,
                            disabled: expired,
                            color: Colors.orange)
                        : const SizedBox.shrink(),
                    !writing
                        ? callBtt(
                            color: Colors.orange,
                            context: context,
                            platform: platform,
                            groupId: widget.groupChatId,
                            anon: anon != null && anon,
                            role: ClientRole.Broadcaster,
                            disabled: expired,
                            inCallUsers: inCallUsers ?? {},
                            // loudUser: loudUser != null ? loudUser : ""
                          )
                        : const SizedBox.shrink(),
                    textField(expired),
                    const SizedBox(width: 5),
                    newsendChatBtt(
                        context: context,
                        platform: platform,
                        sendMessage: sendMessage,
                        replyInfo: replyInfo,
                        disabled: expired)
                  ],
                ),
              )
            : !expired
                ? GestureDetector(
                    onTap: () async {
                      if (!gotBanned) {
                        if (groupState == 'private') {
                          if (!isOnWaitList && !reqJoin && !loading) {
                            setState(() {
                              loading = true;
                            });
                            if (numOfMem < groupCapacity) {
                              await ToggleMemMethods(
                                      userId: widget.uid, context: context)
                                  .requestJoin(
                                      widget.groupChatId,
                                      numOfMem,
                                      groupCapacity,
                                      groupState,
                                      hashTag,
                                      admin);
                            } else {
                              await ToggleMemMethods(
                                      userId: widget.uid, context: context)
                                  .goOnWaitListAndOrSpectate(widget.groupChatId,
                                      hashTag, admin, groupState);
                            }
                            setState(() {
                              loading = false;
                            });
                          }
                        } else if (groupState == 'public') {
                          if (!isOnWaitList && !isMyChat && !loading) {
                            setState(() {
                              loading = true;
                            });

                            if (numOfMem < groupCapacity) {
                              await ToggleMemMethods(
                                      userId: widget.uid, context: context)
                                  .joinChat(hashTag, widget.groupChatId,
                                      Constants.myName, admin);
                            } else {
                              await ToggleMemMethods(
                                      context: context, userId: widget.uid)
                                  .goOnWaitListAndOrSpectate(widget.groupChatId,
                                      hashTag, admin, groupState);
                            }

                            setState(() {
                              loading = false;
                            });
                          }
                        }
                      }
                    },
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                            border: isOnWaitList
                                ? Border.all(
                                    color: Colors.redAccent, width: 3.0)
                                : null,
                            color: gotBanned
                                ? Colors.black54
                                : !isOnWaitList
                                    ? !reqJoin
                                        ? numOfMem == groupCapacity
                                            ? Colors.redAccent
                                            : Colors.blue
                                        : Colors.grey
                                    : null,
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Text(
                            gotBanned
                                ? 'Banned'
                                : !isOnWaitList
                                    ? !reqJoin
                                        ? numOfMem == groupCapacity
                                            ? groupState == 'private'
                                                ? 'Full | Waitlist'
                                                : 'Full | Spectate'
                                            : groupState == 'public'
                                                ? 'Join'
                                                : 'Request'
                                        : 'Requested'
                                    : groupState == 'private'
                                        ? 'Waitlisted'
                                        : 'Spectating',
                            style: TextStyle(
                                color: isOnWaitList
                                    ? Colors.redAccent
                                    : Colors.white,
                                fontWeight: FontWeight.w400)),
                      ),
                    ),
                  )
                : Center(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: const Text('Expired',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400)),
                    ),
                  ));
  }

  // Widget searchKeyWordBar(){
  //   return Container(
  //     color: Colors.white,
  //     padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  //     child: TextField(
  //       autofocus: true,
  //       onChanged: (String val){
  //         if(val != ""){
  //           List<String> newHighlight = [val];
  //           setState(() {
  //             highlightWords = newHighlight;
  //           });
  //           String lowerWord = val.toLowerCase();
  //           if(keyWordMap.containsKey(lowerWord)){
  //             List<int> keyWordIndexes = keyWordMap[lowerWord];
  //             keyWordIndexes.sort((a, b) => b.compareTo(a));
  //             setState(() {
  //               wordCount = keyWordMap[lowerWord].length;
  //               indexes = keyWordIndexes;
  //             });
  //             scrollController.scrollTo(index: keyWordIndexes[curKeyWordIndex], duration: Duration(milliseconds: 500));
  //           }
  //         }else{
  //           setState(() {
  //             indexes = [];
  //             wordCount = 0;
  //             curKeyWordIndex = 0;
  //             highlightWords = [];
  //           });
  //         }},
  //       style: TextStyle(color: Colors.black),
  //       decoration: InputDecoration(
  //         hintText: "Search text",
  //         hintStyle: TextStyle(
  //             color: Colors.black54
  //         ),
  //           focusedBorder: UnderlineInputBorder(
  //             borderSide: BorderSide(color: Colors.black),
  //           ),
  //         suffix: wordCount > 0 ? Text("${curKeyWordIndex+1}/$wordCount") : SizedBox.shrink()
  //       ),
  //     ),
  //   );
  // }

  leaveGroupChat() {
    DatabaseMethods(uid: widget.uid)
        .toggleGroupMembership(widget.groupChatId, 'LEAVE_GROUP');
    // Navigator.of(context).pop();
  }

  quitSpectating() {
    DatabaseMethods(uid: widget.uid)
        .toggleGroupMembership(widget.groupChatId, 'QUIT_SPECTATING');
    // Navigator.of(context, rootNavigator: true).pop();
  }

  tryJoining() async {
    DocumentSnapshot groupSnapshot =
        await DatabaseMethods().getGroupChatById(widget.groupChatId);
    int numOfMem = groupSnapshot.get('members').length;
    double groupCap = groupSnapshot.get('groupCapacity');
    if (numOfMem < groupCap) {
      await DatabaseMethods(uid: widget.uid)
          .toggleGroupMembership(widget.groupChatId, 'QUIT_SPECTATING');
      DatabaseMethods(uid: widget.uid)
          .toggleGroupMembership(widget.groupChatId, 'JOIN_PUB_GROUP_CHAT');
      // Navigator.of(context, rootNavigator: true).pop();
    } else {
      showAlertDialog('This group is still at its full capacity', context);
    }
  }

  Widget msgReplyTile() {
    return Container(
      padding: const EdgeInsets.all(9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              msgReplyTo,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
              onTap: () {
                setState(() {
                  msgReplyTo = null;
                });
              },
              child: const Icon(Icons.close, color: Colors.black, size: 13.5)),
        ],
      ),
    );
  }

  Widget writingMemList(List memList) {
    return memList.isNotEmpty
        ? Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: memList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.5),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      userProfile(
                          userId: memList[index],
                          anon: anon != null && anon,
                          size: 18),
                      sizedLoadingIndicator(size: 36, strokeWidth: 1.5)
                    ],
                  ),
                );
              },
            ),
          )
        : const SizedBox.shrink();
  }

  rmvWritingInd() {
    DatabaseMethods().groupChatCollection.doc(widget.groupChatId).update({
      'writingMem': FieldValue.arrayRemove([Constants.myUserId])
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) rmvWritingInd();
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    // keyWordMap = {};
    DatabaseMethods(uid: widget.uid).closeChat(widget.groupChatId);
    DatabaseMethods(uid: widget.uid).closeSpecChat(widget.groupChatId);
    rmvWritingInd();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    DatabaseMethods().groupChatCollection.doc(widget.groupChatId).update({
      'writingMem': bottomInset > 0.0
          ? FieldValue.arrayUnion([Constants.myUserId])
          : FieldValue.arrayRemove([Constants.myUserId])
    });
    super.didChangeMetrics();
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    if (groupChatId != widget.groupChatId) {
      groupChatId = widget.groupChatId;
      getMessages();
      // keyWordMap = DatabaseMethods().constructKeyWordMap(widget.groupChatId);
      DatabaseMethods(uid: Constants.myUserId).openChat(widget.groupChatId);
      DatabaseMethods(uid: Constants.myUserId).openSpecChat(widget.groupChatId);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    groupChatId = widget.groupChatId;
    getMessages();
    // keyWordMap = DatabaseMethods().constructKeyWordMap(widget.groupChatId);
    DatabaseMethods(uid: Constants.myUserId).openChat(widget.groupChatId);
    DatabaseMethods(uid: Constants.myUserId).openSpecChat(widget.groupChatId);
    rmvWritingInd();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    return StreamBuilder(
        stream: DatabaseMethods()
            .groupChatCollection
            .doc(widget.groupChatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            bool oneDay;
            int createdAt;
            int timeElapsed;

            bool isOnWaitList;
            bool reqJoin;
            bool gotBanned;

            bool disabled;
            List memList = [];
            if (snapshot.data.data() != null &&
                (snapshot.data.data()['deleted'] == null ||
                    !snapshot.data.data()['deleted'])) {
              var groupSnapshot = snapshot.data;
              isMyChat =
                  groupSnapshot.data()['members'].contains(Constants.myUserId);
              groupCapacity = groupSnapshot.data()['groupCapacity'];
              groupPic = groupSnapshot.data()['profileImg'];
              groupState = groupSnapshot.data()['chatRoomState'];
              tags = groupSnapshot.data()['tags'];
              groupInfo = groupSnapshot.data()['about'];
              members = groupSnapshot.data()['members'];
              joinReq = groupSnapshot.data()['joinRequests'];
              waitList = groupSnapshot.data()['waitList'];
              invites = groupSnapshot.data()['invites'];
              bannedUsers = groupSnapshot.data()['bannedUsers'];
              hashTag = groupSnapshot.data()['hashTag'];
              admin = groupSnapshot.data()['admin'];
              anon = groupSnapshot.data()['anon'];
              numOfMem = groupSnapshot.data()['members'].length;
              writingMem = groupSnapshot.data()['writingMem'];
              inCallUsers = groupSnapshot.data()['inCallUsers'];
              // loudUser = groupSnapshot.data()['loudUser'];

              memList = writingMem != null
                  ? writingMem
                      .where((userId) => userId != Constants.myUserId)
                      .toList()
                  : [];

              oneDay = groupSnapshot.data()['oneDay'] != null &&
                  groupSnapshot.data()['oneDay'];
              createdAt = groupSnapshot.data()['createdAt'];
              timeElapsed = getTimeElapsed(createdAt);

              isOnWaitList = waitList.containsKey(Constants.myUserId);
              reqJoin = joinReq.containsKey(Constants.myUserId);
              gotBanned = bannedUsers != null &&
                  bannedUsers.contains(Constants.myUserId);
              disabled = oneDay && timeElapsed / Duration.secondsPerDay >= 1;
            } else {
              disabled = true;
            }
            return Scaffold(
              backgroundColor: const Color.fromARGB(255, 32, 32, 41),
              appBar: AppBar(
                  iconTheme: const IconThemeData(
                    color: Colors.black,
                  ),
                  backgroundColor: const Color.fromARGB(255, 32, 32, 41),
                  centerTitle: true,
                  leading: BackButton(
                    color: !widget.hideBackButton
                        ? Colors.orange
                        : Colors.transparent,
                  ),
                  actions: !disabled
                      ? [
                          // IconButton(
                          //   icon: Icon(platform == TargetPlatform.android ? Icons.search : CupertinoIcons.search),
                          //   color: Colors.black,
                          //   onPressed: (){
                          //     setState(() {
                          //       indexes = [];
                          //       wordCount = 0;
                          //       curKeyWordIndex = 0;
                          //       searchKeyWord = !searchKeyWord;
                          //       highlightWords = [];
                          //     });
                          //   },
                          // ),

                          !widget.spectate && admin == widget.uid
                              ? IconButton(
                                  icon: const Icon(Icons.group_add_rounded),
                                  color: Colors.orange,
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AddAndInviteUserScreen(
                                                    widget.groupChatId,
                                                    widget.uid,
                                                    hashTag,
                                                    true,
                                                    members,
                                                    joinReq,
                                                    waitList,
                                                    invites,
                                                    bannedUsers)));
                                  },
                                )
                              : const SizedBox.shrink(),

                          !widget.preview && admin == widget.uid
                              ? IconButton(
                                  icon: Icon(platform == TargetPlatform.android
                                      ? Icons.settings
                                      : CupertinoIcons.settings),
                                  color: Colors.orange,
                                  onPressed: () async {
                                    bool deleted = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EditGroupScreen(
                                                    widget.uid,
                                                    widget.groupChatId,
                                                    hashTag,
                                                    groupPic,
                                                    groupState,
                                                    groupCapacity,
                                                    members.length,
                                                    anon,
                                                    tags,
                                                    groupInfo,
                                                    oneDay,
                                                    timeElapsed)));

                                    if (deleted != null && deleted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                )
                              : const SizedBox.shrink(),

                          admin != widget.uid && isMyChat
                              ? PopupMenuButton(
                                  icon: Icon(
                                    platform == TargetPlatform.android
                                        ? Icons.more_vert
                                        : CupertinoIcons.ellipsis_vertical,
                                    color: Colors.orange,
                                  ),
                                  itemBuilder: (BuildContext context) => [
                                        PopupMenuItem(
                                            value: !widget.spectate
                                                ? 'Invite Friends'
                                                : 'Become a member',
                                            child: Text(
                                              !widget.spectate
                                                  ? 'Invite friends'
                                                  : 'Become a member',
                                            )),
                                        PopupMenuItem(
                                            value: !widget.spectate
                                                ? 'Leave $hashTag'
                                                : 'Quit spectating',
                                            child: Text(
                                                !widget.spectate
                                                    ? 'Leave $hashTag'
                                                    : 'Quit spectating',
                                                style: const TextStyle(
                                                    color: Colors.red))),
                                      ],
                                  onSelected: (value) {
                                    if (value == 'Invite Friends') {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AddAndInviteUserScreen(
                                                      widget.groupChatId,
                                                      widget.uid,
                                                      hashTag,
                                                      false,
                                                      members,
                                                      joinReq,
                                                      waitList,
                                                      invites,
                                                      bannedUsers)));
                                    } else if (value == 'Leave $hashTag') {
                                      leaveGroupChat();
                                    } else if (value == 'Become a member') {
                                      tryJoining();
                                    } else if (value == 'Quit spectating') {
                                      quitSpectating();
                                    }
                                  })
                              : const SizedBox.shrink(),
                        ]
                      : null,
                  title: !disabled
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GroupProfileScreen(
                                        groupId: widget.groupChatId,
                                        admin: admin,
                                        fromChat: true)));
                          },
                          child: RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(children: [
                              WidgetSpan(
                                child: groupProfile(
                                    groupId: widget.groupChatId,
                                    height: 36,
                                    width: 36,
                                    oneDay: oneDay,
                                    timeElapsed: timeElapsed,
                                    profileImg: groupPic,
                                    avatarSize: 14),
                              ),
                              TextSpan(
                                text: '$hashTag ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 12.5,
                                ),
                              ),
                              hashTag.isNotEmpty && anon != null && anon
                                  ? WidgetSpan(
                                      child: Image.asset(
                                          'assets/icon/icons8-anonymous-mask-50.png',
                                          scale: 3.0),
                                    )
                                  : const TextSpan(),
                            ]),
                          ),
                        )
                      : RichText(
                          text: const TextSpan(children: [
                            WidgetSpan(
                              child: Icon(
                                Icons.timer,
                                color: Colors.orange,
                              ),
                            ),
                            TextSpan(
                              text: 'Expired',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 12.5,
                              ),
                            ),
                          ]),
                        ),
                  elevation: 0),
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        writing = false;
                      });
                      FocusScope.of(context).unfocus();
                    },
                    onDoubleTap: () {
                      setState(() {
                        // indexes = [];
                        // wordCount = 0;
                        // curKeyWordIndex = 0;
                        // searchKeyWord = false;
                        // highlightWords = [];
                        msgReplyTo = null;
                        replyInfo = {};
                        writing = false;
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Column(
                      children: [
                        StreamBuilder(
                            stream: DatabaseMethods(uid: Constants.myUserId)
                                .getMyStream(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data.data() != null) {
                                blockList =
                                    snapshot.data.data()['blockList'] ?? [];
                                return Expanded(
                                  child: chatMessageList(),
                                );
                              } else {
                                return sectionLoadingIndicator();
                              }
                            }),
                        writingMemList(memList),
                        msgReplyTo != null
                            ? msgReplyTile()
                            : const SizedBox.shrink(),
                        buildMsgCompAndMemTog(platform, isOnWaitList, reqJoin,
                            gotBanned, isMyChat, disabled),
                      ],
                    ),
                  ),
                  loading
                      ? screenLoadingIndicator(context)
                      : const SizedBox.shrink(),
                ],
              ),
              // floatingActionButton: Column(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     curKeyWordIndex > 0 ? Container(
              //       height: 45,
              //       width: 45,
              //       child: FloatingActionButton(
              //         backgroundColor: Colors.orangeAccent,
              //         heroTag: "prev",
              //         child: Icon(platform == TargetPlatform.android ? Icons.keyboard_arrow_up_rounded : CupertinoIcons.arrowtriangle_up, color: Colors.black,),
              //         onPressed: (){
              //           setState(() {
              //             curKeyWordIndex --;
              //           });
              //           scrollController.scrollTo(index: indexes[curKeyWordIndex], duration: Duration(milliseconds: 500));
              //         },
              //       ),
              //     ) : SizedBox.shrink(),
              //
              //     SizedBox(height: 15,),
              //     curKeyWordIndex < indexes.length - 1  ? Container(
              //       margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height*0.05),
              //       height: 45,
              //       width: 45,
              //       child: FloatingActionButton(
              //         backgroundColor: Colors.orangeAccent,
              //         heroTag: "next",
              //         child: Icon(platform == TargetPlatform.android ? Icons.keyboard_arrow_down_rounded : CupertinoIcons.arrowtriangle_down, color: Colors.black,),
              //         onPressed: (){
              //           setState(() {
              //             curKeyWordIndex ++;
              //           });
              //           scrollController.scrollTo(index: indexes[curKeyWordIndex], duration: Duration(milliseconds: 500));
              //         },
              //       ),
              //     ) : SizedBox.shrink(),
              //   ],
              // ),
            );
          } else {
            return screenLoadingIndicator(context);
          }
        });
  }
}
