import 'dart:async';

import 'package:algolia/algolia.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/storyFunctions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/views/pageViewsWrapper.dart';
import 'package:spidr_app/views/userProfilePage.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class SendSnippetDialog extends StatefulWidget {
  final List mediaList;
  final String mediaPath;
  final String caption;
  final String link;
  final List gifs;
  final bool video;
  final bool mature;

  const SendSnippetDialog(
      {this.mediaList,
      this.mediaPath,
      this.caption,
      this.link,
      this.gifs,
      this.video,
      this.mature});
  @override
  _SendSnippetDialogState createState() => _SendSnippetDialogState();
}

class _SendSnippetDialogState extends State<SendSnippetDialog> {
  TextEditingController tagsEditingController = TextEditingController();
  // ScrollController scrollController = ScrollController();
  // ScrollController sendToController = ScrollController();

  bool anon = false;
  List blockList;
  bool _seen = false;

  final TextStyle textStyle = const TextStyle(
      fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600);
  final TextStyle sectTxtStyle = const TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.white54,
        offset: Offset(1, 1.5),
        blurRadius: 1,
      ),
    ],
  );
  final TextStyle nameTxtStyle = const TextStyle(
      fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold);
  final formKey = GlobalKey<FormState>();

  bool validTags = true;

  Stream usStream;
  Stream gcStream;
  // Stream selGCStream;

  List rmvGroups = [];
  List rmvUsers = [];
  AsyncSnapshot groupSnapshot;
  AsyncSnapshot userSnapshot;
  List<AlgoliaObjectSnapshot> sugGroups;
  List<AlgoliaObjectSnapshot> sugUsers;
  List<TargetFocus> targets = <TargetFocus>[];
  TutorialCoachMark tutorialCoachMark;
  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();

  // Map selUsers = {};
  // Map selGroups = {};

  Widget userTile(String profileImg, String userId, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              avatarImg(profileImg, 24, false),
              !rmvUsers.contains(userId) &&
                      tagsEditingController.text.isNotEmpty
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : const SizedBox.shrink()
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: nameTxtStyle,
              ),
              const SizedBox(
                width: 5,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(userId: userId)));
                },
                child: iconContainer(
                    icon: Icons.remove_red_eye, contColor: Colors.blue),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget userList() {
    return StreamBuilder(
        stream: usStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            userSnapshot = snapshot;
            return snapshot.data.hits.length > 0
                ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data.hits.length as int,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> docData =
                          snapshot.data.hits[index].data;
                      String userId = snapshot.data.hits[index].objectID;
                      String profileImg = docData['profileImg'];
                      String name = docData['name'];
                      return userId != Constants.myUserId &&
                              (blockList == null || !blockList.contains(userId))
                          ? GestureDetector(
                              onTap: () {
                                // if(selUsers.containsKey(userId))
                                //   selUsers.remove(userId);
                                // else
                                //   selUsers[userId] = {"profileImg":profileImg, "label":name};

                                if (!rmvUsers.contains(userId)) {
                                  rmvUsers.add(userId);
                                } else {
                                  rmvUsers.remove(userId);
                                }
                                setState(() {});

                                // Timer(
                                //   Duration(seconds: 1),
                                //       () => sendToController.jumpTo(sendToController.position.maxScrollExtent),
                                // );
                              },
                              child: userTile(profileImg, userId, name),
                            )
                          : const SizedBox.shrink();
                    })
                : noItems(
                    icon: Icons.search_rounded,
                    text: 'no match found',
                    mAxAlign: MainAxisAlignment.center);
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  Widget sugUserList() {
    return sugUsers != null
        ? ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: sugUsers.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              Map<String, dynamic> docData = sugUsers[index].data;
              String userId = sugUsers[index].objectID;
              String profileImg = docData['profileImg'];
              String name = docData['name'];
              return blockList == null || !blockList.contains(userId)
                  ? userTile(profileImg, userId, name)
                  : const SizedBox.shrink();
            })
        : sectionLoadingIndicator();
  }

  Widget groupTile(
      String profileImg, String groupId, String hashTag, String admin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              avatarImg(profileImg, 24, false),
              tagsEditingController.text.isNotEmpty &&
                      !rmvGroups.contains(groupId)
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : const SizedBox.shrink()
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hashTag,
                style: nameTxtStyle,
              ),
              const SizedBox(width: 5),
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
                child: iconContainer(
                    icon: Icons.remove_red_eye, contColor: Colors.blue),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget groupList() {
    return StreamBuilder(
        stream: gcStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            groupSnapshot = snapshot;
            return snapshot.data.hits.length > 0
                ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data.hits.length as int,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> docData =
                          snapshot.data.hits[index].data;
                      String groupId = snapshot.data.hits[index].objectID;
                      String hashTag = docData['hashTag'];
                      String profileImg = docData['profileImg'];
                      String admin = docData['admin'];

                      return GestureDetector(
                        onTap: () {
                          // if(tagsEditingController.text.isEmpty){
                          //   if(selGroups.containsKey(groupId))
                          //     selGroups.remove(groupId);
                          //   else{
                          //     selGroups[groupId] = {"profileImg":profileImg, "label":hashTag};
                          //   }
                          // }else{
                          if (!rmvGroups.contains(groupId)) {
                            rmvGroups.add(groupId);
                          } else {
                            rmvGroups.remove(groupId);
                          }
                          // }

                          setState(() {});
                          // Timer(
                          //   Duration(seconds: 1),
                          //       () => sendToController.jumpTo(sendToController.position.maxScrollExtent),
                          // );
                        },
                        child: groupTile(profileImg, groupId, hashTag, admin),
                      );
                    },
                  )
                : noItems(
                    icon: Icons.search_rounded,
                    text: 'no match found',
                    mAxAlign: MainAxisAlignment.center);
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  Widget sugGroupList() {
    return sugGroups != null
        ? ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: sugGroups.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              Map<String, dynamic> docData = sugGroups[index].data;
              String groupId = sugGroups[index].objectID;
              String hashTag = docData['hashTag'];
              String profileImg = docData['profileImg'];
              String admin = docData['admin'];

              return groupTile(profileImg, groupId, hashTag, admin);
            },
          )
        : sectionLoadingIndicator();
  }

  searchUsers(String searchText) {
    setState(() {
      usStream = DatabaseMethods().searchUsers(searchText);
      // rmvUsers = [];
    });
  }

  searchGroups(String searchText) {
    setState(() {
      gcStream = DatabaseMethods().searchGroupChats(searchText);
      // selGCStream = searchText.isNotEmpty ? DatabaseMethods().searchGroupChats(searchText) : null;
      // rmvGroups = [];
    });
  }

  sendSnippet() {
    if (formKey.currentState.validate()) {
      String tagText = tagsEditingController.text;

      List<String> tags =
          tagText.trim().replaceAll(RegExp(r'[^\w\s]+'), '').split(' ');

      DateTime now = DateTime.now();

      storyUpload(
          mediaPath: widget.mediaPath,
          mediaList: widget.mediaList,
          anon: anon,
          tags: tags,
          caption: widget.caption,
          link: widget.link,
          gifs: widget.gifs,
          video: widget.video,
          sendTime: now.microsecondsSinceEpoch,
          type: 'snippet',
          groupSnapshot: groupSnapshot,
          rmvGroups: rmvGroups,
          userSnapshot: userSnapshot,
          rmvUsers: rmvUsers,
          mature: widget.mature);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PageViewsWrapper()),
      );
    }
  }

  getSugGroups() {
    DatabaseMethods(uid: Constants.myUserId).suggestGroups().then((val) {
      if (mounted) {
        setState(() {
          sugGroups = val;
        });
      }
    });
  }

  getSugUsers() {
    DatabaseMethods(uid: Constants.myUserId).suggestUsers().then((val) {
      if (mounted) {
        setState(() {
          sugUsers = val;
        });
      }
    });
  }

  void initTargets() {
    targets.add(TargetFocus(
      identify: 'Hashtag Explanation',
      keyTarget: key1,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Spidr Tags',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'By adding a Spidr hash tag to your broadcast, users and groups with the same hashtag in their profile can view, comment and share your post',
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )),
      ],
      shape: ShapeLightFocus.Circle,
      radius: 27,
    ));
    targets.add(TargetFocus(
      identify: 'Anonymous Toggle',
      keyTarget: key2,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Anonymous Mode',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'You can broadcast anonymously so your identity is not revealed in your post',
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )),
      ],
      shape: ShapeLightFocus.RRect,
    ));
  }

  void showTutorial() {
    if (_seen == null || false) {
      initTargets();
      tutorialCoachMark = TutorialCoachMark(
        context,
        targets: targets,
        colorShadow: Colors.red,
        textSkip: 'SKIP',
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

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_seen1' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_seen1', true);
    setState(() {
      _seen = true;
    });
    return _seen;
  }

  @override
  void initState() {
    super.initState();
    getSugGroups();
    getSugUsers();
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    Future.delayed(const Duration(milliseconds: 100), showTutorial);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            blockList = snapshot.data.data()['blockList'];
          }
          return Dialog(
            insetPadding: const EdgeInsets.all(18),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30))),
            backgroundColor: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Align(
                            alignment: Alignment
                                .center, // Align however you like (i.e .centerRight, centerLeft)
                            child: Text(
                              'Broadcast To:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                shadows: [
                                  Shadow(
                                    color: Colors.white54,
                                    offset: Offset(1, 1.5),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.1,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 9.0, vertical: 13.5),
                            child: Form(
                              key: formKey,
                              child: TextFormField(
                                autofocus: false,
                                onChanged: (val) {
                                  validTags = val.length < 150;
                                  searchUsers(val);
                                  searchGroups(val);
                                  // scrollController.jumpTo(scrollController.position.maxScrollExtent);
                                  setState(() {});
                                },
                                validator: (val) {
                                  return val.length > 150
                                      ? 'sorry, tags > 150 characters'
                                      : null;
                                },
                                controller: tagsEditingController,
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 20),
                                decoration: previewInputDec(
                                    hintText: 'UofG,Toronto,Sports ...',
                                    valid: validTags,
                                    textEtController: tagsEditingController,
                                    maxLength: 150,
                                    icon: Icons.tag,
                                    fillColor: Colors.black54,
                                    fontColor: Colors.white,
                                    outlineColor: Colors.orange,
                                    borderSide:
                                        const BorderSide(color: Colors.orange)),
                              ),
                            ),
                          ),
                          Text('Circles', style: sectTxtStyle),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.135,
                            key: key1,
                            child: tagsEditingController.text.isNotEmpty
                                ? groupList()
                                : sugGroupList(),
                          ),
                          Text('Users', style: sectTxtStyle),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.135,
                            child: tagsEditingController.text.isNotEmpty
                                ? userList()
                                : sugUserList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4.5, 0, 0, 4.5),
                      child: Row(
                        key: key2,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Switch(
                                value: anon,
                                onChanged: (value) {
                                  setState(() {
                                    anon = value;
                                  });
                                },
                                activeTrackColor: Colors.orangeAccent,
                                activeColor: Colors.orange,
                              ),
                              Text('Anonymous?',
                                  style: GoogleFonts.varelaRound(
                                      color: Colors.white,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          groupSnapshot != null &&
                                  groupSnapshot.data != null &&
                                  userSnapshot != null &&
                                  userSnapshot.data != null
                              ? Container(
                                  margin: const EdgeInsets.only(right: 9),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (tagsEditingController
                                              .text.isNotEmpty &&
                                          (groupSnapshot.data.hits.length -
                                                      rmvGroups.length >
                                                  0 ||
                                              userSnapshot.data.hits.length -
                                                      rmvUsers.length >
                                                  0)) sendSnippet();
                                    },
                                    child: mediaSendBtt(
                                      icon: Icons.settings_input_antenna,
                                      labelColor: tagsEditingController
                                                  .text.isEmpty ||
                                              (groupSnapshot.data.hits.length -
                                                          rmvGroups.length ==
                                                      0 &&
                                                  userSnapshot.data.hits
                                                              .length -
                                                          rmvUsers.length ==
                                                      0)
                                          ? Colors.orange
                                          : Colors.white,
                                      off: tagsEditingController.text.isEmpty ||
                                          (groupSnapshot.data.hits.length -
                                                      rmvGroups.length ==
                                                  0 &&
                                              userSnapshot.data.hits.length -
                                                      rmvUsers.length ==
                                                  0),
                                      text: 'Broadcast',
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
