import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/conversationScreen.dart';
import 'package:spidr_app/views/search.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class StreamScreen extends StatefulWidget {
  @override
  _StreamScreenState createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen>
    with WidgetsBindingObserver {
  PageController controller = PageController();
  PageController pageController = PageController();
  ItemScrollController scrollController = ItemScrollController();

  Stream groupStream;

  List<String> groupTags = [];
  String selTag = '';

  bool creating = false;
  bool onGenCir = false;

  bool openKeyBoard = false;
  bool loading = true;
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();
  GlobalKey key5 = GlobalKey();

  // bool lastPage = false;
  // bool searchBar = false;
  // TextEditingController searchTextController = TextEditingController();

  getGroups() {
    groupStream = DatabaseMethods().getPublicGroup(selTag, selTag.isEmpty);
  }

  buildGroupTags() async {
    List tags = await DatabaseMethods().getSugTags();
    if (mounted) {
      setState(() {
        groupTags = tags;
        loading = false;
        selTag = selTag.isNotEmpty ? tags[0] : '';
      });
      getGroups();
    }
  }

  resetGroupStream() async {
    setState(() {
      loading = true;
    });
    await buildGroupTags();
    if (selTag.isNotEmpty) {
      Timer(
        const Duration(milliseconds: 100),
        () => pageController.jumpToPage(1),
      );
    }
  }

  Widget genCircleBtt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        !creating
            ? IconButton(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  Random random = Random();
                  String profileImg =
                      groupMIYUs[random.nextInt(groupMIYUs.length)];

                  String hashTag = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CreateHashTagDialog(selTag);
                      });

                  if (hashTag != null) {
                    setState(() {
                      creating = true;
                    });
                    await DatabaseMethods(uid: Constants.myUserId)
                        .createGroupChat(
                      hashTag: !hashTag.startsWith('#')
                          ? '#${hashTag.toUpperCase()}'
                          : hashTag.toUpperCase(),
                      username: Constants.myName,
                      chatRoomState: 'public',
                      time: now.microsecondsSinceEpoch,
                      groupCapacity: 50,
                      groupPic: profileImg,
                      anon: true,
                      oneDay: true,
                      tags: [selTag],
                    );
                    Timer(const Duration(milliseconds: 4500), () {
                      getGroups();
                      setState(() {
                        creating = false;
                      });
                      if (controller.hasClients) {
                        controller.animateToPage(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn);
                      }
                    });
                  }
                },
                icon: Container(
                  foregroundDecoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.deepOrangeAccent],
                        begin: Alignment(0, 0),
                        end: Alignment(0, 1),
                      ),
                      backgroundBlendMode: BlendMode.screen),
                  child: const Icon(Icons.add_circle_rounded),
                ),
                iconSize: 75,
                color: Colors.black)
            : sectionLoadingIndicator(),
        const SizedBox(
          height: 10,
        ),
        const Text(
          'Start Conversation',
          style: TextStyle(
            fontSize: 18,
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
        ),
      ],
    );
  }

  Widget groupChatsList() {
    final width = MediaQuery.of(context).size.width;
    return StreamBuilder(
        stream: groupStream,
        builder: (context, snapshot) {
          if (!loading && snapshot.hasData && snapshot.data != null) {
            return PageView.builder(
                key: key3,
                physics: const BouncingScrollPhysics(),
                controller: pageController,
                itemCount: groupTags.length + 1,
                onPageChanged: (int index) {
                  setState(() {
                    // lastPage = index == groupTags.length;
                    selTag = index == 0 ? '' : groupTags[index - 1];
                  });
                  getGroups();
                  if (index > 0) scrollController.jumpTo(index: index - 1);
                },
                itemBuilder: (context, index) {
                  if (snapshot.data.hits.length > 0) {
                    int numOfHits = snapshot.data.hits.length as int;
                    int itemCount =
                        selTag.isNotEmpty ? numOfHits + 1 : numOfHits;
                    return PageView.builder(
                        itemCount: itemCount,
                        scrollDirection: Axis.vertical,
                        controller: controller,
                        itemBuilder: (context, index) {
                          if (index < numOfHits) {
                            return Column(
                              children: [
                                Expanded(
                                  child: ConversationScreen(
                                    groupChatId:
                                        snapshot.data.hits[index].objectID,
                                    uid: Constants.myUserId,
                                    spectate: false,
                                    preview: true,
                                    initIndex: 0,
                                    hideBackButton: true,
                                  ),
                                ),
                                !openKeyBoard
                                    ? itemCount > 1 && index < itemCount - 1
                                        ? GestureDetector(
                                            onTap: () {
                                              controller.nextPage(
                                                  duration: const Duration(
                                                      milliseconds: 150),
                                                  curve: Curves.easeIn);
                                            },
                                            child: const Icon(
                                                Icons.keyboard_arrow_down))
                                        : Divider(
                                            color: Colors.black,
                                            thickness: 3,
                                            indent: width * 0.475,
                                            endIndent: width * 0.475,
                                          )
                                    : const SizedBox.shrink(),
                              ],
                            );
                          } else {
                            return genCircleBtt();
                          }
                        });
                  } else {
                    if (selTag.isNotEmpty) {
                      return genCircleBtt();
                    } else if (_seen == null || false) {
                      return Center(
                          child: Image.asset('assets/images/convoExample.png'));
                    } else {
                      return Center(
                          child: Image.asset('assets/icon/Spidr_News.png'));
                    }
                  }
                });
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_streamSeen' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_streamSeen', true);
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

  void initTargets() {
    targets.add(
      TargetFocus(
        identify: 'Search Bar',
        keyTarget: key1,
        color: Colors.deepOrangeAccent,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Search Bar !',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Text(
                      'Search for Circles or Users on Spidr ',
                      style: GoogleFonts.varelaRound(
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
      ),
    );

    targets.add(TargetFocus(
      identify: 'Trending',
      keyTarget: key2,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Trending Tab!',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Select one of the trending hashtags to scroll through all Circles related to that hashtag',
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
    targets.add(TargetFocus(
      identify: 'Chats',
      keyTarget: key3,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(
                top: 10, bottom: 20, left: 12, right: 12),
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Circles',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                  Text(
                    'You can swipe up or down to check out all the chats under a hashtag. Check some hashtags out and discover a Circle for you!',
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
    targets.add(
      TargetFocus(
        identify: 'Circle Privacy',
        keyTarget: key4,
        color: Colors.orange,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Choose your Circle privacy',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Choose how intimate you want your Circle to be ',
                      style: GoogleFonts.varelaRound(
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
        radius: 5,
      ),
    );
    targets.add(
      TargetFocus(
        identify: 'Circle Limit',
        keyTarget: key5,
        color: Colors.orange,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Circle Limit',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Choose how many users can join your Circle ',
                      style: GoogleFonts.varelaRound(
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
        radius: 5,
      ),
    );
  }

  @override
  void didChangeMetrics() {
    // TODO: implement didChangeMetrics
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      openKeyBoard = bottomInset > 0.0;
    });
    super.didChangeMetrics();
  }

  @override
  void initState() {
    buildGroupTags();
    WidgetsBinding.instance.addObserver(this);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final TargetPlatform platform = Theme.of(context).platform;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
          child: TextField(
            key: key1,
            readOnly: true,
            onTap: () {
              Navigator.push(
                  context,
                  PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SearchScreen()));
            },
            decoration: const InputDecoration(
                icon: Icon(Icons.search),
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
            child: Row(
              key: key2,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selTag = '';
                    });
                    getGroups();
                    pageController.jumpToPage(0);
                  },
                  child: tagTile(
                    all: 'Trending',
                    borderColor:
                        selTag.isNotEmpty ? Colors.white : Colors.orange,
                    textColor: selTag.isNotEmpty ? Colors.orange : Colors.white,
                  ),
                ),
                Flexible(
                    child:
                        // !searchBar ?
                        !loading
                            ? groupTags.isNotEmpty
                                ? ScrollablePositionedList.builder(
                                    itemScrollController: scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: groupTags.length,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selTag = groupTags[index];
                                          });
                                          getGroups();
                                          pageController.jumpToPage(index + 1);
                                          scrollController.jumpTo(index: index);
                                        },
                                        child: tagTile(
                                          tag: groupTags[index],
                                          borderColor:
                                              selTag != groupTags[index]
                                                  ? Colors.white
                                                  : Colors.orange,
                                          textColor: selTag != groupTags[index]
                                              ? Colors.orange
                                              : Colors.white,
                                        ),
                                      );
                                    })
                                : const SizedBox.shrink()
                            : sizedLoadingIndicator(
                                size: 18, strokeWidth: 1.5)),
                GestureDetector(
                    onTap: () {
                      resetGroupStream();
                    },
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.orange)),
              ],
            ),
          ),
          Expanded(child: groupChatsList()),
        ],
      ),
    );
  }
}
