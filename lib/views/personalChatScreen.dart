import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/chatBubbleWidgets.dart';
import 'package:spidr_app/widgets/chatFuncWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class PersonalChatScreen extends StatefulWidget {
  final String personalChatId;
  final String contactId;
  final bool openByOther;
  final bool anon;
  final bool friend;
  // final String chatType;
  const PersonalChatScreen(
      {this.personalChatId,
      this.contactId,
      this.openByOther,
      this.anon,
      this.friend
      // this.chatType
      });

  @override
  _PersonalChatScreenState createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen>
    with WidgetsBindingObserver {
  Stream personalMessageStream;
  TextEditingController textController = TextEditingController();
  bool chatExist = true;
  bool blocked = false;
  bool writing = false;
  bool contactWriting = false;
  Map inCallUsers = {};
  // String profileImg;
  // String anonImg;
  // String contactName = '';

  // bool anon;
  // bool friend;
  // bool ready = false;

  checkBlocked() async {
    DocumentSnapshot userDS =
        await DatabaseMethods(uid: widget.contactId).getUserById();
    List blockList = userDS.get('blockList');
    setState(() {
      blocked = blockList != null && blockList.contains(Constants.myUserId);
    });
  }

  // Check to see if the chat has been deleted by the other user
  checkChatStatus() async {
    if (!widget.friend) {
      DocumentReference contactDocRef = DatabaseMethods()
          .userCollection
          .doc(widget.contactId)
          .collection('replies')
          .doc(widget.personalChatId);

      DocumentSnapshot contactSnapshot = await contactDocRef.get();
      setState(() {
        chatExist = contactSnapshot.exists;
      });
    }
  }

  getMessages() {
    setState(() {
      personalMessageStream =
          DatabaseMethods().getPersonalMessages(widget.personalChatId);
    });
  }

  sendMessage() {
    if (!emptyStrChecker(textController.text)) {
      DateTime now = DateTime.now();
      String text = textController.text;

      DatabaseMethods(uid: Constants.myUserId).addPersonalMessage(
          personalChatId: widget.personalChatId,
          text: text,
          userName: Constants.myName,
          sendTime: now.microsecondsSinceEpoch,
          contactId: widget.contactId,
          friend: widget.friend);

      setState(() {
        writing = false;
      });
      textController.text = '';
    }
  }

  deleteMessage(String textId) {
    DatabaseMethods(uid: Constants.myUserId)
        .deletePersonalMessage(widget.personalChatId, textId);
    if (widget.friend) {
      DatabaseMethods(uid: Constants.myUserId)
          .deleteFdChatNotif(widget.contactId, textId);
    } else {
      DatabaseMethods()
          .deletePerChatNotif(widget.contactId, widget.personalChatId, textId);
    }
  }

  Widget textField() {
    return Expanded(
      child: TextField(
          style: const TextStyle(color: Colors.orange),
          readOnly: blocked || !widget.openByOther || !chatExist,
          cursorColor: Colors.orange,
          maxLines: null,
          onChanged: (val) {
            setState(() {
              writing = true;
            });
          },
          controller: textController,
          textCapitalization: TextCapitalization.sentences,
          decoration: msgInputDec(
              context: context,
              hintText: blocked || !widget.openByOther || !chatExist
                  ? 'Disabled'
                  : 'Message',
              personalChatId: widget.personalChatId,
              friend: widget.friend,
              contactId: widget.contactId,
              disabled: blocked || !widget.openByOther || !chatExist,
              gif: true,
              fillColor: Colors.white)),
    );
  }

  Widget textTile(
      String text,
      String dateTime,
      Map imgMap,
      Map fileMap,
      List mediaGallery,
      bool isSendByMe,
      String textId,
      bool newDay,
      bool reported) {
    String hourMin = dateTime.substring(dateTime.indexOf(' ') + 1);
    String date = dateTime.substring(0, dateTime.indexOf(' '));
    bool blocked = imgMap != null &&
            imgMap['ogSenderId'] != null &&
            Constants.myBlockList.contains(imgMap['ogSenderId']) ||
        fileMap != null &&
            fileMap['ogSenderId'] != null &&
            Constants.myBlockList.contains(fileMap['ogSenderId']) ||
        mediaGallery != null &&
            mediaGallery[0]['ogSenderId'] != null &&
            Constants.myBlockList.contains(mediaGallery[0]['ogSenderId']);

    final TargetPlatform platform = Theme.of(context).platform;
    double width = MediaQuery.of(context).size.width;
    return !blocked
        ? Column(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                      onLongPress: () {
                        if (text.isNotEmpty ||
                            (imgMap != null && imgMap['imgUrl'] != null) ||
                            fileMap != null && fileMap['fileUrl'] != null ||
                            (mediaGallery != null &&
                                mediaGallery[0]['imgUrl'] != null)) {
                          if (isSendByMe) {
                            showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                    0.0,
                                    MediaQuery.of(context).size.height,
                                    0.0,
                                    0.0),
                                items: <PopupMenuEntry>[
                                  PopupMenuItem(
                                      value: 1,
                                      child: iconText(
                                          platform == TargetPlatform.android
                                              ? Icons.delete
                                              : CupertinoIcons.delete,
                                          ' Delete')),
                                ]).then((value) {
                              if (value == 1) {
                                deleteMessage(textId);
                              }
                            });
                          } else {
                            if (!reported) {
                              showMenu(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                      0.0,
                                      MediaQuery.of(context).size.height,
                                      0.0,
                                      0.0),
                                  items: <PopupMenuEntry>[
                                    PopupMenuItem(
                                        value: 1,
                                        child: iconText(
                                            platform == TargetPlatform.android
                                                ? Icons.flag_rounded
                                                : CupertinoIcons.flag_fill,
                                            ' Report')),
                                  ]).then((value) {
                                if (value == 1) {
                                  reportContent(
                                    context: context,
                                    personalChatId: widget.personalChatId,
                                    senderId: widget.contactId,
                                    contentId: textId,
                                  );
                                }
                              });
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                            left: isSendByMe ? width * 0.25 : 9,
                            right: isSendByMe ? 9 : width * 0.25),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: width,
                        alignment: isSendByMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                            padding: text.isNotEmpty
                                ? const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 9)
                                : const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 9),
                            decoration: chatBubbleDec(
                                isSendByMe,
                                text.isNotEmpty ||
                                    (fileMap != null &&
                                        !audioChecker(fileMap['fileName']) &&
                                        !pdfChecker(fileMap['fileName']))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text != ''
                                    ? personalTextBubble(
                                        context, text, isSendByMe)
                                    : fileMap != null
                                        ? fileMap['ogSenderId'] != null
                                            ? SharedChatBubble(
                                                fileObj: fileMap,
                                                isSendByMe: isSendByMe,
                                                mediaId: fileMap['ogChatId'],
                                              )
                                            : fileChatBubble(
                                                context: context,
                                                fileObj: fileMap,
                                                messageId: textId,
                                                isSendByMe: isSendByMe,
                                                platform: platform,
                                                senderId: isSendByMe
                                                    ? Constants.myUserId
                                                    : widget.contactId,
                                                toPageView: false,
                                                // personalChatId: widget.personalChatId,
                                                audio: audioChecker(
                                                    fileMap['fileName']),
                                                document: pdfChecker(
                                                    fileMap['fileName']),
                                              )
                                        : imgMap != null
                                            ? imgMap['ogSenderId'] != null
                                                ? SharedChatBubble(
                                                    imgObj: imgMap,
                                                    isSendByMe: isSendByMe,
                                                    mediaId:
                                                        imgMap['ogChatId'] ??
                                                            imgMap['ogStoryId'],
                                                  )
                                                : mediaChatBubble(
                                                    imgObj: imgMap,
                                                    messageId: textId,
                                                    context: context,
                                                    senderId: isSendByMe
                                                        ? Constants.myUserId
                                                        : widget.contactId,
                                                    toPageView: false
                                                    // personalChatId: widget.personalChatId
                                                    )
                                            : const SizedBox.shrink(),
                                mediaGallery != null
                                    ? mediaGallery[0]['ogSenderId'] != null
                                        ? SharedChatBubble(
                                            mediaGallery: mediaGallery,
                                            isSendByMe: isSendByMe,
                                            mediaId: mediaGallery[0]
                                                    ['ogChatId'] ??
                                                mediaGallery[0]['ogStoryId'])
                                        : MediaGalleryBubble(
                                            mediaGallery: mediaGallery,
                                            messageId: textId,
                                            isSendByMe: isSendByMe,
                                            senderId: isSendByMe
                                                ? Constants.myUserId
                                                : widget.contactId,
                                            toPageView: false,
                                            // personalChatId: widget.personalChatId,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.45,
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
              dateDivider(newDay, date)
            ],
          )
        : const SizedBox.shrink();
  }

  Widget textList() {
    return StreamBuilder(
      stream: personalMessageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                reverse: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  int sendTime = snapshot.data.docs[index].data()['sendTime'];
                  String sendDatetime = timeToString(sendTime);
                  bool newDay = false;

                  if (index > 0) {
                    int prevSendTime =
                        snapshot.data.docs[index - 1].data()['sendTime'];
                    String prevDatetime = timeToString(prevSendTime);
                    newDay = isNewDay(sendDatetime, prevDatetime);
                  }

                  return textTile(
                      snapshot.data.docs[index].data()['text'],
                      sendDatetime,
                      snapshot.data.docs[index].data()['imgMap'],
                      snapshot.data.docs[index].data()['fileMap'],
                      snapshot.data.docs[index].data()['mediaGallery'],
                      snapshot.data.docs[index].data()['senderId'] ==
                          Constants.myUserId,
                      snapshot.data.docs[index].id,
                      newDay,
                      snapshot.data.docs[index].data()['reported'] != null &&
                          snapshot.data.docs[index].data()['reported']);
                })
            : Container();
      },
    );
  }

  rmvWritingInd() {
    DatabaseMethods().personalChatCollection.doc(widget.personalChatId).update({
      'writingUsers': FieldValue.arrayRemove([Constants.myUserId])
    });
  }

  @override
  void dispose() {
    DatabaseMethods(uid: Constants.myUserId).closePersonalChat(
        widget.personalChatId, widget.contactId, widget.friend);
    rmvWritingInd();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // TODO: implement didChangeMetrics
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    DatabaseMethods().personalChatCollection.doc(widget.personalChatId).update({
      'writingUsers': bottomInset > 0.0
          ? FieldValue.arrayUnion([Constants.myUserId])
          : FieldValue.arrayRemove([Constants.myUserId])
    });
    super.didChangeMetrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    if (state == AppLifecycleState.inactive) rmvWritingInd();
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    getMessages();
    checkBlocked();
    DatabaseMethods(uid: Constants.myUserId).openPersonalChat(
        widget.personalChatId, widget.contactId, widget.friend);
    rmvWritingInd();
    if (widget.openByOther) checkChatStatus();
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  Widget writingUserIndicator() {
    return contactWriting
        ? Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(4.5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  userProfile(
                      userId: widget.contactId, anon: widget.anon, size: 18),
                  sizedLoadingIndicator(size: 36, strokeWidth: 1.5)
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    return StreamBuilder(
        stream: DatabaseMethods()
            .personalChatCollection
            .doc(widget.personalChatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            List writingUsers = snapshot.data.data()['writingUsers'];
            contactWriting =
                writingUsers != null && writingUsers.contains(widget.contactId);
            inCallUsers = snapshot.data.data()['inCallUsers'];
          }
          return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                centerTitle: true,
                leading: const BackButton(
                  color: Colors.black,
                ),
                title: RichText(
                    text: TextSpan(children: [
                  WidgetSpan(
                      child: userProfile(
                          userId: widget.contactId,
                          anon: widget.anon,
                          blockAble: false)),
                  WidgetSpan(
                      child: userName(
                          userId: widget.contactId,
                          anon: widget.anon,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ])),
                elevation: 0,
                actions: !widget.friend
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
                                      child: iconText(
                                          Icons.do_disturb_on_outlined,
                                          ' Remove')),
                                ],
                            onSelected: (value) {
                              if (value == 1) {
                                DatabaseMethods(uid: Constants.myUserId)
                                    .deletePersonalChat(widget.personalChatId,
                                        widget.contactId);
                                Navigator.of(context).pop();
                              }
                            })
                      ]
                    : null,
              ),
              body: GestureDetector(
                onTap: () {
                  setState(() {
                    writing = false;
                  });
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: [
                    blocked || !widget.openByOther || !chatExist
                        ? Container(
                            height: 30.0,
                            width: double.infinity,
                            color: blocked
                                ? Colors.red
                                : !chatExist
                                    ? Colors.black54
                                    : Colors.grey,
                            child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(children: [
                                  WidgetSpan(
                                      child: Icon(
                                    blocked
                                        ? Icons.do_disturb_on_rounded
                                        : !widget.openByOther
                                            ? Icons.access_time_rounded
                                            : platform == TargetPlatform.android
                                                ? Icons.warning_amber_rounded
                                                : CupertinoIcons
                                                    .exclamationmark_triangle,
                                    color: Colors.white,
                                  )),
                                  TextSpan(
                                      text: !widget.openByOther
                                          ? 'This chat has not been opened yet'
                                          : !chatExist
                                              ? 'This chat has been removed'
                                              : 'You have been blocked by this user',
                                      style:
                                          const TextStyle(color: Colors.white))
                                ])),
                          )
                        : const SizedBox.shrink(),
                    Expanded(
                      child: textList(),
                    ),
                    writingUserIndicator(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9.0),
                      height: 54.0,
                      color: Colors.white,
                      child: Row(
                        children: [
                          writing
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      writing = !writing;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.black,
                                  ))
                              : const SizedBox.shrink(),
                          !writing
                              ? filesPickerBtt(
                                  context: context,
                                  platform: platform,
                                  personalChatId: widget.personalChatId,
                                  friend: widget.friend,
                                  contactId: widget.contactId,
                                  disabled: blocked || !widget.openByOther)
                              : const SizedBox.shrink(),
                          !writing
                              ? callBtt(
                                  context: context,
                                  platform: platform,
                                  personalChatId: widget.personalChatId,
                                  anon: widget.anon,
                                  inCallUsers: inCallUsers ?? {},
                                  role: ClientRole.Broadcaster,
                                  disabled: blocked || !widget.openByOther)
                              : const SizedBox.shrink(),
                          textField(),
                          const SizedBox(
                            width: 5,
                          ),
                          sendChatBtt(
                              context: context,
                              platform: platform,
                              sendMessage: sendMessage,
                              disabled: blocked || !widget.openByOther)
                        ],
                      ),
                    )
                  ],
                ),
              ));
        });
  }
}
