import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/mediaGalleryWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class SendMediaScreen extends StatefulWidget {
  final String ogSenderId;
  final Map imgObj;
  final Map fileObj;
  final List mediaGallery;
  final String messageId;
  final String groupId;
  final String storyId;
  final bool anon;

  const SendMediaScreen(
      {this.ogSenderId,
      this.imgObj,
      this.fileObj,
      this.mediaGallery,
      this.messageId,
      this.groupId,
      this.storyId,
      this.anon});
  @override
  _SendMediaScreenState createState() => _SendMediaScreenState();
}

class _SendMediaScreenState extends State<SendMediaScreen> {
  Map<String, dynamic> fdChats = {};
  Map<String, dynamic> gcChats = {};
  final List<String> categories = ['Circles', 'Friends'];
  int selectedIndex = 0;
  Stream fdStream;
  Stream gcStream;
  TextEditingController msgController = TextEditingController();
  String mediaId;

  shareToChats() async {
    DateTime now = DateTime.now();
    DatabaseMethods()
        .addFileCopies(mediaId: mediaId, numC: fdChats.length + gcChats.length);
    String msg = msgController.text;
    bool attachMsg = !emptyStrChecker(msg);

    if (widget.fileObj != null) {
      widget.fileObj['ogSenderId'] = widget.ogSenderId;
      widget.fileObj['ogChatId'] = widget.messageId;
      widget.fileObj['ogGroupId'] = widget.groupId;
      widget.fileObj['anon'] = widget.anon;
    } else if (widget.imgObj != null || widget.mediaGallery != null) {
      Map imgObj = widget.imgObj ?? widget.mediaGallery[0];
      imgObj['ogSenderId'] = widget.ogSenderId;
      imgObj['anon'] = widget.anon;
      if (widget.storyId != null) {
        imgObj['ogStoryId'] = widget.storyId;
      } else {
        imgObj['ogChatId'] = widget.messageId;
        imgObj['ogGroupId'] = widget.groupId;
      }
    }

    for (String gcId in gcChats.keys) {
      await DatabaseMethods(uid: Constants.myUserId).addConversationMessages(
          groupChatId: gcId,
          message: '',
          username: Constants.myName,
          userId: Constants.myUserId,
          time: now.microsecondsSinceEpoch,
          imgObj: widget.imgObj,
          fileObj: widget.fileObj,
          mediaGallery: widget.mediaGallery,
          ogMediaId: mediaId,
          ogSenderId: widget.ogSenderId);
      if (attachMsg) {
        DatabaseMethods(uid: Constants.myUserId).addConversationMessages(
          groupChatId: gcId,
          message: msg,
          username: Constants.myName,
          userId: Constants.myUserId,
          time: now.microsecondsSinceEpoch,
        );
      }
    }

    for (String fdId in fdChats.keys) {
      await DatabaseMethods(uid: Constants.myUserId).addPersonalMessage(
          personalChatId: fdChats[fdId]['personalChatId'],
          text: '',
          userName: Constants.myName,
          sendTime: now.microsecondsSinceEpoch,
          imgMap: widget.imgObj,
          fileMap: widget.fileObj,
          mediaGallery: widget.mediaGallery,
          contactId: fdId,
          ogMediaId: mediaId,
          ogSenderId: widget.ogSenderId,
          friend: true);

      if (attachMsg) {
        DatabaseMethods(uid: Constants.myUserId).addPersonalMessage(
            personalChatId: fdChats[fdId]['personalChatId'],
            text: msg,
            userName: Constants.myName,
            sendTime: now.microsecondsSinceEpoch,
            contactId: fdId,
            friend: true);
      }
    }
  }

  Widget friendList() {
    return StreamBuilder(
        stream: fdStream,
        builder: (context, snapshot) {
          return snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data.docs.length > 0
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    String friendId = snapshot.data.docs[index].id;
                    String personalChatId =
                        snapshot.data.docs[index].data()['personalChatId'];
                    return !Constants.myBlockList.contains(friendId)
                        ? CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: userName(
                                userId: friendId,
                                fontWeight: FontWeight.normal,
                                fontSize: 12),
                            secondary: userProfile(userId: friendId),
                            value: fdChats.containsKey(friendId),
                            onChanged: (bool value) {
                              if (value) {
                                setState(() {
                                  fdChats[friendId] = {
                                    'personalChatId': personalChatId
                                  };
                                });
                              } else {
                                setState(() {
                                  fdChats.remove(friendId);
                                });
                              }
                            },
                          )
                        : const SizedBox.shrink();
                  })
              : noItems(
                  icon: Icons.auto_awesome,
                  text: 'no friends yet',
                  mAxAlign: MainAxisAlignment.center);
        });
  }

  Widget groupList() {
    return StreamBuilder(
        stream: gcStream,
        builder: (context, snapshot) {
          return snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data.docs.length > 0
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    String groupId = snapshot.data.docs[index].id;
                    String hashTag =
                        snapshot.data.docs[index].data()['hashTag'];
                    String profileImg =
                        snapshot.data.docs[index].data()['profileImg'];

                    return groupId != widget.groupId
                        ? CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(hashTag,
                                style: const TextStyle(fontSize: 12)),
                            secondary: avatarImg(profileImg, 24, false),
                            value: gcChats.containsKey(groupId),
                            onChanged: (bool value) {
                              if (value) {
                                setState(() {
                                  gcChats[groupId] = {'hashTag': hashTag};
                                });
                              } else {
                                setState(() {
                                  gcChats.remove(groupId);
                                });
                              }
                            },
                          )
                        : const SizedBox.shrink();
                  },
                )
              : noItems(
                  icon: Icons.donut_large_rounded,
                  text: 'no circles yet',
                  mAxAlign: MainAxisAlignment.center);
        });
  }

  getFdChats() {
    setState(() {
      fdStream = DatabaseMethods()
          .userCollection
          .doc(Constants.myUserId)
          .collection('friends')
          .snapshots();
    });
  }

  getGCChats() async {
    setState(() {
      gcStream = DatabaseMethods()
          .groupChatCollection
          .where('deleted', isNotEqualTo: true)
          .where('members', arrayContains: Constants.myUserId)
          .snapshots();
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      mediaId = widget.messageId ?? widget.storyId;
    });
    getGCChats();
    getFdChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.mediaGallery == null
              ? SizedBox.expand(
                  child: mediaAndFileDisplay(
                      context: context,
                      imgObj: widget.imgObj,
                      fileObj: widget.fileObj,
                      mediaId: widget.messageId ?? widget.storyId,
                      play: false,
                      showInfo: false,
                      anon: widget.anon),
                )
              : MediaGalleryTile(
                  story: widget.storyId != null,
                  startIndex: 0,
                  mediaGallery: widget.mediaGallery,
                  height: MediaQuery.of(context).size.height,
                  autoPlay: true,
                  anon: widget.anon,
                ),
          Container(
            color: Colors.transparent,
          ),
          AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30))),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8, // custom width
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    height: 30.0,
                    child: ListView.builder(
                        reverse: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: index == selectedIndex
                                        ? Colors.black
                                        : Colors.black54),
                              ),
                            ),
                          );
                        }),
                  ),

                  Expanded(
                    child: PageView(
                      reverse: true,
                      onPageChanged: (val) {
                        setState(() {
                          selectedIndex = val;
                        });
                      },
                      children: [groupList(), friendList()],
                    ),
                  ),
                  // selectedIndex == 0 ? groupList() : personalList(),

                  Container(
                    child: TextField(
                      controller: msgController,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: Colors.orange,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          Icons.message_rounded,
                          color: Colors.orange,
                        ),
                        hintText: 'Add a message',
                        hintStyle: TextStyle(color: Colors.black54),
                        labelText: 'Message',
                        labelStyle: TextStyle(color: Colors.orange),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (fdChats.isNotEmpty || gcChats.isNotEmpty) {
                    shareToChats();
                    showCenterFlash(
                        alignment: Alignment.center,
                        context: context,
                        text: 'Sent');
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'SEND',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
