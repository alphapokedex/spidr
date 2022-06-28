import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/personalChatScreen.dart';
import 'package:spidr_app/widgets/profilePageWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

Widget iconTextTitle({icon, text, color = Colors.black}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Icon(icon, color: color),
      const SizedBox(
        width: 5,
      ),
      Flexible(
          child: Text(text,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)))
    ],
  );
}

class GetStartedDialog extends StatefulWidget {
  @override
  _GetStartedDialogState createState() => _GetStartedDialogState();
}

class _GetStartedDialogState extends State<GetStartedDialog> {
  TextEditingController tagController = TextEditingController();

  List sugTags = [];
  Map selTags = {};

  List tags = [];
  bool loading = true;

  getSugTags() {
    DatabaseMethods().getSugTags(max: 18).then((tags) {
      setState(() {
        sugTags = tags;
        loading = false;
      });
    });
  }

  @override
  void initState() {
    getSugTags();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.white,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(18, 27, 18, 0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    children: [
                      Text(
                          "Welcome! ${Constants.myName != null && Constants.myName != "null null" ? Constants.myName : ""}",
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                          "Add 3-5 Spidr Tags of your interests to receive broadcasts and discover circles!",
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                          textAlign: TextAlign.center),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                  Column(children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(30)),
                            child: TextField(
                              style: const TextStyle(color: Colors.black),
                              controller: tagController,
                              decoration: const InputDecoration(
                                  icon: Icon(Icons.tag),
                                  border: InputBorder.none,
                                  hintText:
                                      "UofG,Parties,Toronto,Music,Sports...",
                                  hintStyle: TextStyle(
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 11)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.orange),
                          onPressed: () {
                            if (tags.length < 5) {
                              var tag = tagController.text as dynamic;
                              if (tag.isNotEmpty) {
                                if (tag.length <= 18) {
                                  setState(() {
                                    tags = [tag] + tags;
                                  });
                                  tagController.text = "";
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Sorry, tag length exceeds 18",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.SNACKBAR,
                                    timeInSecForIosWeb: 3,
                                  );
                                }
                              }
                            }
                          },
                        )
                      ],
                    ),
                    tags.isNotEmpty
                        ? Container(
                            height: 45,
                            margin: const EdgeInsets.symmetric(vertical: 9),
                            child: ListView.builder(
                              itemCount: tags.length,
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return Stack(children: [
                                  Container(
                                      margin: const EdgeInsets.only(right: 9),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.black, width: 2.0),
                                      ),
                                      child: Center(
                                          child: Text(
                                              tags[index].startsWith("#")
                                                  ? tags[index]
                                                  : "#" + tags[index],
                                              style: const TextStyle(
                                                  color: Colors.black)))),
                                  Positioned(
                                    bottom: 9,
                                    right: -3,
                                    child: IconButton(
                                        icon: const Icon(Icons.cancel_rounded,
                                            size: 18, color: Colors.black),
                                        onPressed: () {
                                          int sugIndex = selTags[tags[index]];
                                          if (sugIndex != null) {
                                            sugTags.insert(
                                                sugIndex, tags[index]);
                                          }
                                          tags.removeAt(index);

                                          setState(() {});
                                        }),
                                  ),
                                ]);
                              },
                            ),
                          )
                        : const SizedBox.shrink()
                  ]),
                  Expanded(
                    child: !loading
                        ? GridView.count(
                            physics: const BouncingScrollPhysics(),
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            children: sugTags
                                .map((tag) => TextButton(
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.black),
                                    ),
                                    onPressed: () {
                                      if (tags.length < 5) {
                                        selTags[tag] = sugTags.indexOf(tag);
                                        tags = [tag] + tags;
                                        sugTags.remove(tag);
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        bottom:
                                            5, // Space between underline and text
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              "#" + tag,
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 13),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.black,
                                            size: 13.5,
                                          )
                                        ],
                                      ),
                                    )))
                                .toList(),
                          )
                        : sectionLoadingIndicator(),
                  ),
                  Column(
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          DatabaseMethods()
                              .userCollection
                              .doc(Constants.myUserId)
                              .update({
                            "getStarted": false,
                          });
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                        child: const Text("skip",
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ),
                      GestureDetector(
                          onTap: () {
                            if (tags.isNotEmpty) {
                              DatabaseMethods()
                                  .userCollection
                                  .doc(Constants.myUserId)
                                  .update({"getStarted": false, "tags": tags});
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 9),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13.5, horizontal: 18),
                            decoration: BoxDecoration(
                                color: tags.isNotEmpty
                                    ? const Color(0xffFF914D)
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(30)),
                            child: const Text("I'm Ready!",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          )),
                    ],
                  )
                ],
              ),
              const Positioned(
                  top: -54,
                  child: CircleAvatar(
                      radius: 27,
                      backgroundImage:
                          AssetImage("assets/images/SpidrNet.png")))
            ],
          ),
        ));
  }
}

showGetStartedDialog(BuildContext context) async {
  return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return GetStartedDialog();
      });
}

class ReplyBoxDialog extends StatefulWidget {
  final String groupId;
  final String hashTag;
  final bool anon;
  final String userId;
  final String text;
  final int sendTime;
  final Map imgMap;
  final Map fileMap;
  final List mediaGallery;
  final String messageId;
  final String ogMediaId;

  const ReplyBoxDialog(
    this.groupId,
    this.hashTag,
    this.anon,
    this.userId,
    this.text,
    this.sendTime,
    this.imgMap,
    this.fileMap,
    this.mediaGallery,
    this.messageId,
    this.ogMediaId,
  );

  @override
  _ReplyBoxDialogState createState() => _ReplyBoxDialogState();
}

class _ReplyBoxDialogState extends State<ReplyBoxDialog> {
  TextEditingController replyEditingController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  replyMessage() async {
    if (formKey.currentState.validate()) {
      String replyMsg = replyEditingController.text;
      DateTime now = DateTime.now();

      Map<String, dynamic> replyMap = {
        'text': replyMsg,
        'sender': widget.anon == null || !widget.anon
            ? Constants.myName
            : "Anonymous",
        'senderId': Constants.myUserId,
        'sendTime': now.microsecondsSinceEpoch,
        'sendTo': widget.userId,
        'group': '${widget.groupId}_${widget.hashTag}',
        'msgId': widget.messageId,
        'imgMap': null,
        'fileMap': null,
        'mediaGallery': null,
      };

      await DatabaseMethods(
        uid: Constants.myUserId,
      )
          .createPersonalChat(
        userId: widget.userId,
        text: widget.text,
        sendTime: widget.sendTime,
        imgMap: widget.imgMap,
        fileMap: widget.fileMap,
        mediaGallery: widget.mediaGallery,
        myReply: replyMap,
        groupId: widget.groupId,
        hashTag: widget.hashTag,
        anon: widget.anon,
        messageId: widget.messageId,
        actionType: "REPLY_CHAT",
        ogMediaId: widget.ogMediaId,
      )
          .then((personalChatId) {
        DatabaseMethods(uid: Constants.myUserId).updateConversationMessages(
          groupChatId: widget.groupId,
          messageId: widget.messageId,
          personalChatId: personalChatId,
          userId: widget.userId,
          username: widget.anon == null || !widget.anon
              ? Constants.myName
              : "Anonymous",
          actionType: "ADD_REPLY",
        );

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => PersonalChatScreen(
                      personalChatId: personalChatId,
                      contactId: widget.userId,
                      openByOther: false,
                      anon: widget.anon,
                      friend: false,
                    )));
      });

      replyEditingController.text = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      title: iconTextTitle(icon: Icons.maps_ugc, text: "Private Chat"),
      content: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          validator: (val) {
            return emptyStrChecker(val) ? "Hey! type something in" : null;
          },
          controller: replyEditingController,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text("CANCEL")),
        TextButton(
            onPressed: () {
              replyMessage();
            },
            child: const Text("SEND")),
      ],
    );
  }
}

showReplyBox({
  BuildContext context,
  String groupId,
  String hashTag,
  bool anon,
  String userId,
  String text,
  int sendTime,
  Map imgMap,
  Map fileMap,
  List mediaGallery,
  String messageId,
  String ogMediaId,
}) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReplyBoxDialog(
          groupId,
          hashTag,
          anon,
          userId,
          text,
          sendTime,
          imgMap,
          fileMap,
          mediaGallery,
          messageId,
          ogMediaId,
        );
      });
}

showMediaCommentDialog(BuildContext context, String mediaId, bool anon) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30))),
            content: SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: mediaCommentList(
                          context: context, mediaId: mediaId, anon: anon)),
                  MediaCommentComposer(mediaId: mediaId, autoFocus: true)
                ],
              ),
            ));
      });
}

class AddTagOnCreateDialog extends StatefulWidget {
  @override
  _AddTagOnCreateDialogState createState() => _AddTagOnCreateDialogState();
}

class _AddTagOnCreateDialogState extends State<AddTagOnCreateDialog> {
  List tags = [];
  TextEditingController tagController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool noTag = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      titlePadding: const EdgeInsets.fromLTRB(24, 27, 0, 14),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      title: Text(!noTag ? "Add Tags" : "Sorry, one more tag is required",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: !noTag ? Colors.black : Colors.redAccent,
            fontSize: !noTag ? 18 : 14,
          )),
      content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('add relevant tags to enhance your public circle',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey))),
              const SizedBox(height: 13.5),
              SizedBox(
                  height: 45,
                  child: ProfileTagList(
                    editable: true,
                    tags: tags,
                    tagController: tagController,
                    formKey: formKey,
                    tagNum: Constants.maxTags,
                  )),
            ],
          )),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("CANCEL",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              )),
        ),
        TextButton(
          onPressed: () {
            if (tags.isEmpty) {
              setState(() {
                noTag = true;
              });
            } else {
              Navigator.pop(context, tags);
            }
          },
          child: const Text("OK",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              )),
        ),
      ],
    );
  }
}

class ReportContentDialog extends StatefulWidget {
  @override
  _ReportContentDialogState createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return AlertDialog(
      title: iconTextTitle(
          icon: platform == TargetPlatform.android
              ? Icons.flag_rounded
              : CupertinoIcons.flag_fill,
          text: "Report Content"),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        width: MediaQuery.of(context).size.width * 0.5,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          children: reportReasons.map((m) {
            int index = reportReasons.indexOf(m);
            return CheckboxListTile(
              title: Text(m),
              value: selectedIndex == index,
              onChanged: (bool val) {
                setState(() {
                  selectedIndex = val ? index : -1;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            "CANCEL",
            style:
                TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {
            if (selectedIndex != -1) {
              Navigator.pop(context, reportReasons[selectedIndex]);
            }
          },
          child: Text(
            "REPORT",
            style: TextStyle(
                color: selectedIndex != -1 ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class ShareMediaGalleryDialog extends StatefulWidget {
  final List mediaGallery;
  const ShareMediaGalleryDialog(this.mediaGallery);

  @override
  _ShareMediaGalleryDialogState createState() =>
      _ShareMediaGalleryDialogState();
}

class _ShareMediaGalleryDialogState extends State<ShareMediaGalleryDialog> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return AlertDialog(
      title: iconTextTitle(
          icon: platform == TargetPlatform.android
              ? Icons.share
              : CupertinoIcons.share,
          text: "Share Media"),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      titlePadding: const EdgeInsets.all(18),
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.25,
        width: MediaQuery.of(context).size.width,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: widget.mediaGallery.map((m) {
            int index = widget.mediaGallery.indexOf(m);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Container(
                    width:
                        MediaQuery.of(context).size.width * 0.3, // custom width
                    height: MediaQuery.of(context).size.height * 0.2,
                    decoration: shadowEffect(30),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: mediaAndFileDisplay(
                          context: context,
                          imgObj: m,
                          div: 3,
                          numOfLines: 1,
                          play: false,
                          showInfo: false,
                        )),
                  ),
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: Checkbox(
                      value: selectedIndex == index,
                      onChanged: (val) {
                        if (val) {
                          setState(() {
                            selectedIndex = index;
                          });
                        } else {
                          setState(() {
                            selectedIndex = -1;
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            "CANCEL",
            style:
                TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {
            if (selectedIndex != -1) {
              Navigator.pop(context, widget.mediaGallery[selectedIndex]);
            }
          },
          child: const Text(
            "OK",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

showBanMemberDialog(
    BuildContext context, String hashTag, String userId, bool anon) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          // contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: iconTextTitle(
              icon: Icons.do_disturb_on_rounded,
              text: "Ban User",
              color: Colors.red),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    WidgetSpan(
                      child: Column(
                        children: [
                          userProfile(userId: userId, anon: anon, size: 18),
                          userName(
                              userId: userId,
                              anon: anon,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)
                        ],
                      ),
                    ),
                    const TextSpan(
                      text: " will be banned from ",
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: hashTag,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w600),
                    )
                  ])),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context, "LEAVE_GROUP");
                },
                child: const Text("Just Once",
                    style: TextStyle(color: Colors.orange))),
            TextButton(
                onPressed: () {
                  Navigator.pop(context, "BAN_USER");
                },
                child: const Text("Permanently",
                    style: TextStyle(color: Colors.black)))
          ],
        );
      });
}

showAlertDialog(String text, BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          title: const Text("Sorry", style: TextStyle(color: Colors.orange)),
          content: Text(text),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text("OK", style: TextStyle(color: Colors.blue)))
          ],
        );
      });
}

showLogOutDialog(BuildContext context) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          title: iconTextTitle(icon: Icons.logout, text: "Hop Off"),
          content: RichText(
            text: const TextSpan(
              text: 'Are you sure you want to hop off?',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                "CANCEL",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.black,
                elevation: 3,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SURE'),
            ),
          ],
        );
      });
}

showClearSearchDialog(BuildContext context) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          title: iconTextTitle(
              icon: Icons.history_rounded, text: "Clear Search History"),
          content: RichText(
            text: const TextSpan(
              text: 'Are you sure you want to clear your search history?',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                "CANCEL",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.black,
                elevation: 3,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SURE'),
            ),
          ],
        );
      });
}

showRepliedUsersDialog(List replies, String messageId, String groupId,
    BuildContext context, bool anon) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: replies.length,
                itemBuilder: (context, index) {
                  String userId = replies[index]["userId"];
                  String personalChatId = replies[index]["personalChatId"];
                  String username = replies[index]["username"];
                  bool opened = replies[index]["open"];
                  return !opened
                      ? Card(
                          elevation: 0.0,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          child: Container(
                            child: GestureDetector(
                              onTap: () async {
                                await DatabaseMethods(uid: Constants.myUserId)
                                    .updateConversationMessages(
                                        groupChatId: groupId,
                                        messageId: messageId,
                                        personalChatId: personalChatId,
                                        userId: userId,
                                        actionType: "OPEN_REPLY");
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PersonalChatScreen(
                                              personalChatId: personalChatId,
                                              contactId: userId,
                                              openByOther: true,
                                              friend: false,
                                              anon: anon,
                                            )));
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 10.0),
                                title: Text("From $username"),
                                trailing: const Icon(
                                  Icons.keyboard_arrow_right,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                }),
          ),
        );
      });
}

showJoinGroupAlertDialog(
    BuildContext context, String groupState, String groupId, String hashTag) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hey!", style: TextStyle(color: Colors.orange)),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          content: Text(groupState == 'public' || groupState == 'invisible'
              ? "This group you are trying to join has reached its full capacity. Do you want to be on the waitlist and spectate?"
              : "This group you are requesting to join has reached its full capacity. Do you want to be on the waitlist?"),
          actions: [
            FlatButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text("NO", style: TextStyle(color: Colors.red))),
            FlatButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  DatabaseMethods(uid: Constants.myUserId).putOnWaitList(
                      groupId,
                      Constants.myName,
                      Constants.myUserId,
                      Constants.myEmail,
                      null);
                },
                child:
                    const Text("YES", style: TextStyle(color: Colors.green))),
          ],
        );
      });
}

class SelectAnonImgDialog extends StatefulWidget {
  final int imgIndex;
  const SelectAnonImgDialog(this.imgIndex);

  @override
  _SelectAnonImgDialogState createState() => _SelectAnonImgDialogState();
}

class _SelectAnonImgDialogState extends State<SelectAnonImgDialog> {
  PageController controller;
  int imgIndex;

  @override
  void initState() {
    imgIndex = widget.imgIndex;
    controller = PageController(
        initialPage: imgIndex, keepPage: false, viewportFraction: 0.5);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, imgIndex);
        return true;
      },
      child: Dialog(
          insetPadding: const EdgeInsets.all(15),
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    avatarImg(userMIYUs[imgIndex], 36, false),
                    Positioned(
                      top: 81,
                      child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 2.5, color: Colors.white)
                            ],
                          ),
                          child: Image.asset(
                              "assets/icon/icons8-anonymous-mask-50.png",
                              scale: 2.25)),
                    )
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: miyuList(),
                )
              ],
            ),
          )),
    );
  }

  Widget miyuList() {
    return PageView.builder(
        itemCount: userMIYUs.length,
        controller: controller,
        onPageChanged: (val) {
          setState(() {
            imgIndex = val;
          });
        },
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              double value = 1.0;
              if (controller.position.haveDimensions) {
                value = controller.page - index;
                value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);
              }
              return Center(
                child: SizedBox(
                  height: Curves.easeOut.transform(value) * 150,
                  width: Curves.easeOut.transform(value) * 300,
                  child: child,
                ),
              );
            },
            child: miyuDisplay(userMIYUs, index),
          );
        });
  }
}

class DeleteGroupDialog extends StatefulWidget {
  final String groupId;
  final String hashTag;

  const DeleteGroupDialog(this.hashTag, this.groupId);

  @override
  _DeleteGroupDialogState createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends State<DeleteGroupDialog> {
  final formKey = GlobalKey<FormState>();
  TextEditingController hashTagConfirmController = TextEditingController();
  bool matchTag = false;

  deleteGroup() {
    if (formKey.currentState.validate()) {
      DatabaseMethods(uid: Constants.myUserId).deleteGroupChat(widget.groupId);
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    hashTagConfirmController.addListener(() {
      if (hashTagConfirmController.text == widget.hashTag) {
        matchTag = true;
      } else {
        matchTag = false;
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    hashTagConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(18),
      contentPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      title: iconTextTitle(
          icon: Icons.delete_forever_outlined,
          text: "Delete Circle",
          color: Colors.red),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                text:
                    'Confirm that it is time delete this circle by typing its hashtag: ',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey),
                children: <TextSpan>[
                  TextSpan(
                      text: widget.hashTag,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Form(
                key: formKey,
                child: TextFormField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) {
                      return val != widget.hashTag ? "Incorrect hashtag" : null;
                    },
                    controller: hashTagConfirmController,
                    style: const TextStyle(color: Colors.black),
                    decoration: msgInputDec(
                        hintText: widget.hashTag,
                        hintColor: Colors.grey,
                        fillColor: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text(
            "CANCEL",
            style:
                TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.black,
            elevation: 3,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30))),
          ),
          onPressed: matchTag ? () => deleteGroup() : null,
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}

List<Widget> recTagButtons(TextEditingController editor, List tags) {
  return tags
      .map((tag) => TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
          ),
          onPressed: () {
            editor.text = tag;
          },
          child: Text(
            "#" + tag,
          )))
      .toList();
}

showTextBoxDialog(
    {@required BuildContext context,
    @required String text,
    @required TextEditingController textEditingController,
    @required String errorText,
    Function editQuote,
    Function editTag,
    @required formKey,
    int index}) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30))),
          title: Text(text),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Form(
              key: formKey,
              child: TextFormField(
                autofocus: true,
                validator: (val) {
                  if (emptyStrChecker(val)) {
                    return errorText;
                  } else if ((text == "About Me" || text == "About Circle") &&
                      val.length > 100) {
                    return "Content > 100 characters";
                  } else if (text == "Tag" && val.length > 18) {
                    return "Tag > 18 characters";
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.black, fontSize: 14),
                controller: textEditingController,
              ),
            ),
            text == "Tag"
                ? FutureBuilder(
                    future: DatabaseMethods().getSugTags(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: Wrap(
                                children: recTagButtons(
                                    textEditingController, snapshot.data)),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    })
                : const SizedBox.shrink()
          ]),
          actions: [
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "CANCEL",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                )),
            FlatButton(
                onPressed: () {
                  if (editQuote != null) {
                    editQuote(textEditingController.text);
                  } else if (editTag != null) {
                    editTag(textEditingController.text, index);
                  } else {
                    Navigator.pop(context, textEditingController.text);
                  }
                },
                child: const Text(
                  "SAVE",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ))
          ],
        );
      });
}

class CreateHashTagDialog extends StatefulWidget {
  final String selTag;
  const CreateHashTagDialog(this.selTag);
  @override
  _CreateHashTagDialogState createState() => _CreateHashTagDialogState();
}

class _CreateHashTagDialogState extends State<CreateHashTagDialog> {
  final formKey = GlobalKey<FormState>();
  TextEditingController hashTagController = TextEditingController();
  bool validHashTag = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      title: Text(widget.selTag),
      content: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          onChanged: (val) {
            setState(() {
              validHashTag = val.length <= 18 && !emptyStrChecker(val);
            });
          },
          validator: (val) {
            if (emptyStrChecker(val)) {
              return "Please enter a hashTag";
            } else if (val.length > 18) {
              return "Maximum length 18";
            }
            return null;
          },
          style: const TextStyle(color: Colors.black, fontSize: 14),
          controller: hashTagController,
          decoration:
              hashTagFromDec(hashTagController.text.length, validHashTag),
        ),
      ),
      actions: [
        FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            )),
        FlatButton(
            onPressed: () {
              if (formKey.currentState.validate()) {
                Navigator.pop(context, hashTagController.text);
              }
            },
            child: const Text(
              "CREATE",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ))
      ],
    );
  }
}

showSpidrIdBoxDialog(
  BuildContext context,
  DocumentReference userDocRef,
  spidrIdKey,
  TextEditingController spidrIdEditingController,
) async {
  return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: Colors.white,
            child: SizedBox(
              height: 250,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  const SizedBox(height: 24),
                  const Text(
                    "Update your Spidr ID",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(
                          top: 10, bottom: 10, right: 15, left: 15),
                      child: Form(
                        key: spidrIdKey,
                        child: TextFormField(
                          validator: (val) {
                            return val.length > 18
                                ? "Max length 18"
                                : emptyStrChecker(val)
                                    ? "Sorry, Spidr ID can not be empty"
                                    : null;
                          },
                          controller: spidrIdEditingController,
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.orangeAccent,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            hintText: "Enter a Username",
                            labelText: "Spidr ID",
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      )),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                          onPressed: () {
                            if (spidrIdKey.currentState.validate()) {
                              String name = spidrIdEditingController.text;
                              Constants.myName = name;
                              userDocRef.update({'name': name});
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                          },
                          child: const Text("Continue")),
                    ],
                  ),
                ],
              ),
            ));
      });
}
