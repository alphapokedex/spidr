import 'package:algolia/algolia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/conversationScreen.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/views/viewJoinRequests.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/storiesListDisplay.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MyCirclesScreen extends StatefulWidget {
  final List mutedChats;
  const MyCirclesScreen(this.mutedChats);
  @override
  _MyCirclesScreenState createState() => _MyCirclesScreenState();
}

class _MyCirclesScreenState extends State<MyCirclesScreen> {
  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  Stream myGroupsStream;
  Stream mySpectateStream;
  Stream myInvitesStream;
  List<AlgoliaObjectSnapshot> suggestedGroups;
  String profileImg = '';
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;
  bool isLoading = true;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();
  GlobalKey key5 = GlobalKey();

  Widget mySpecChatList() {
    return StreamBuilder(
        stream: mySpectateStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data.docs.length,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SpecGroupTile(
                      snapshot.data.docs[index].data()['groupId'],
                      snapshot.data.docs[index].data()['numOfNewMsg'],
                      snapshot.data.docs[index].data()['createdAt'],
                    );
                  });
            } else {
              return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: noItems(
                      icon: Icons.donut_small,
                      text: 'no spectating circles yet',
                      mAxAlign: MainAxisAlignment.start));
            }
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  Widget myPinnedGroupList() {
    return StreamBuilder(
        stream: DatabaseMethods(uid: Constants.myUserId).getMyGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data.docs.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    String groupId =
                        snapshot.data.docs[index].data()['groupId'];
                    return snapshot.data.docs[index].data()['pinned'] != null &&
                            snapshot.data.docs[index].data()['pinned']
                        ? MyGroupTile(
                            groupId,
                            snapshot.data.docs[index].data()['joinRequests'],
                            snapshot.data.docs[index].data()['numOfNewMsg'],
                            snapshot.data.docs[index].data()['replies'],
                            snapshot.data.docs[index].data()['numOfUploads'],
                            snapshot.data.docs[index].data()['createdAt'],
                            true,
                            widget.mutedChats.contains(groupId),
                          )
                        : const SizedBox.shrink();
                  });
            } else {
              return const SizedBox.shrink();
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }

  Widget myGroupChatList() {
    return StreamBuilder(
        stream: DatabaseMethods(uid: Constants.myUserId).getMyGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data.docs.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    String groupId =
                        snapshot.data.docs[index].data()['groupId'];
                    return snapshot.data.docs[index].data()['pinned'] == null ||
                            !snapshot.data.docs[index].data()['pinned']
                        ? MyGroupTile(
                            groupId,
                            snapshot.data.docs[index].data()['joinRequests'],
                            snapshot.data.docs[index].data()['numOfNewMsg'],
                            snapshot.data.docs[index].data()['replies'],
                            snapshot.data.docs[index].data()['numOfUploads'],
                            snapshot.data.docs[index].data()['createdAt'],
                            false,
                            widget.mutedChats.contains(groupId),
                          )
                        : const SizedBox.shrink();
                  });
            } else {
              return Container(
                  height: 135,
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: noItems(
                      icon: Icons.donut_large_rounded,
                      text: 'no joined circles yet',
                      mAxAlign: MainAxisAlignment.start));
            }
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  acceptGroupInvite(String groupId, String hashTag, String groupState) async {
    DocumentSnapshot groupSnapshot =
        await DatabaseMethods().getGroupChatById(groupId);
    int numOfMem = groupSnapshot.get('members').length;
    double groupCap = groupSnapshot.get('groupCapacity');

    if (numOfMem < groupCap) {
      DatabaseMethods(uid: Constants.myUserId)
          .toggleGroupMembership(groupId, 'JOIN_PUB_GROUP_CHAT');
    } else {
      showJoinGroupAlertDialog(context, groupState, groupId, hashTag);
    }
  }

  requestJoinPvtGroup(String groupId, String hashTag, String groupState) async {
    DocumentSnapshot groupSnapshot =
        await DatabaseMethods().getGroupChatById(groupId);
    int numOfMem = groupSnapshot.get('members').length;
    double groupCap = groupSnapshot.get('groupCapacity');

    if (numOfMem < groupCap) {
      DatabaseMethods(uid: Constants.myUserId).requestJoinGroup(groupId,
          Constants.myName, Constants.myUserId, Constants.myEmail, null);

      showCenterFlash(
          alignment: Alignment.center,
          context: context,
          text: 'You request has been sent');
    } else {
      showJoinGroupAlertDialog(context, groupState, groupId, hashTag);
    }
  }

  Widget inviteTile(
      String groupId, String groupState, String invitorName, String hashTag) {
    return Container(
        color: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hashTag,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Text('From: $invitorName',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  groupState,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: groupState == 'invisible'
                          ? Colors.black
                          : groupState == 'public'
                              ? Colors.green
                              : Colors.red),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (groupState != 'private') {
                  acceptGroupInvite(groupId, hashTag, groupState);
                } else {
                  requestJoinPvtGroup(groupId, hashTag, groupState);
                }
              },
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(groupState != 'private' ? 'Join' : 'Request',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
            ),
            const SizedBox(
              width: 10,
            ),
            GestureDetector(
              onTap: () {
                DatabaseMethods(uid: Constants.myUserId).removeInvite(groupId);
              },
              child: Container(
                  child: const Text('Ignore',
                      style: TextStyle(
                          fontWeight: FontWeight.normal, color: Colors.black))),
            )
          ],
        ));
  }

  Widget myInvitesList() {
    return StreamBuilder(
        stream: myInvitesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.docs.length > 0) {
            return ListView.builder(
                itemCount: snapshot.data.docs.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return inviteTile(
                    snapshot.data.docs[index].id,
                    snapshot.data.docs[index].data()['groupState'],
                    snapshot.data.docs[index].data()['invitorName'],
                    snapshot.data.docs[index].data()['hashTag'],
                  );
                });
          } else {
            return const SizedBox.shrink();
          }
        });
  }

  Widget sugGroupTile(
      {String hashTag,
      String groupId,
      String admin,
      String groupState,
      String profileImg,
      bool anon,
      BuildContext context,
      bool preview,
      int createdAt,
      bool oneDay}) {
    int timeElapsed = getTimeElapsed(createdAt);
    bool expired = oneDay && timeElapsed / Duration.secondsPerDay >= 1;

    return GestureDetector(
      onTap: () {
        if (!expired) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GroupProfileScreen(
                      groupId: groupId,
                      admin: admin,
                      fromChat: false,
                      preview: preview)));
        }
      },
      child: Column(
        children: [
          groupProfile(
              groupId: groupId,
              oneDay: oneDay,
              timeElapsed: timeElapsed,
              profileImg: profileImg),
          groupStateIndicator(groupState, anon, MainAxisAlignment.center),
          Stack(children: [
            !expired
                ? StreamBuilder(
                    stream: DatabaseMethods()
                        .groupChatCollection
                        .doc(groupId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data.data() != null) {
                        bool onRequest = snapshot.data
                            .data()['joinRequests']
                            .containsKey(Constants.myUserId);
                        bool waitlisted = snapshot.data
                            .data()['waitList']
                            .containsKey(Constants.myUserId);
                        return borderedText(
                            hashTag,
                            onRequest
                                ? Colors.grey
                                : waitlisted
                                    ? Colors.red
                                    : Colors.black);
                      } else {
                        return borderedText(hashTag, Colors.black);
                      }
                    })
                : borderedText('Expired', Colors.grey),
          ]),
        ],
      ),
    );
  }

  Widget suggestionList() {
    if (suggestedGroups != null) {
      if (suggestedGroups.isNotEmpty) {
        return ListView.builder(
            itemCount: suggestedGroups.length,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              Map<String, dynamic> docData = suggestedGroups[index].data;
              return sugGroupTile(
                  groupId: suggestedGroups[index].objectID,
                  hashTag: docData['hashTag'],
                  admin: docData['admin'],
                  groupState: docData['chatRoomState'],
                  profileImg: docData['profileImg'],
                  anon: docData['anon'] != null && docData['anon'],
                  preview: true,
                  context: context,
                  createdAt: docData['createdAt'],
                  oneDay: docData['oneDay'] != null && docData['oneDay']);
            });
      } else {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: noItems(
                icon: Icons.edit,
                text: 'add or edit your tags',
                mAxAlign: MainAxisAlignment.start));
      }
    } else {
      return sectionLoadingIndicator();
    }
  }

  getGroupChats() {
    myGroupsStream = DatabaseMethods(uid: Constants.myUserId).getMyGroups();
  }

  getSpectChats() {
    mySpectateStream =
        DatabaseMethods(uid: Constants.myUserId).getSpectatingChats();
  }

  getInvites() {
    myInvitesStream = DatabaseMethods(uid: Constants.myUserId).getMyInvites();
  }

  getSuggestion() {
    DatabaseMethods(uid: Constants.myUserId).suggestGroups().then((val) {
      if (mounted) {
        setState(() {
          suggestedGroups = val;
        });
      }
    });
  }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_myCircleSeen' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_myCircleSeen', true);
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
        identify: 'Avatar Selector',
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
                    'Select an Avatar !',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Represent your group chat with an anonymous MIYU avatar ',
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
        shape: ShapeLightFocus.Circle,
        radius: 5,
      ),
    );

    targets.add(TargetFocus(
      identify: 'Circle Name',
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
                      'Circle Name',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Give your group a unique name!',
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
      identify: 'Toggles',
      keyTarget: key3,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      '24 Hours / Anon Mode',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Turn these on to make your circle only exist for 24 hours, You can also choose to make your circle Anonymous',
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

  Future loadCheck() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    getGroupChats();
    getInvites();
    getSpectChats();
    getSuggestion();
    setState(() {});
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    loadCheck();
    //Future.delayed(Duration(milliseconds: 100), showTutorial);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.orange,
              highlightColor: Colors.black,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionLabel('Suggestions', Colors.black, Colors.white),
                    Container(
                        height: 135.0,
                        padding: const EdgeInsets.only(left: 9),
                        child: suggestionList()),
                    sectionLabel('Your Circles', Colors.orange, Colors.white),
                    myPinnedGroupList(),
                    myGroupChatList(),
                    sectionLabel('Spectating', Colors.orange, Colors.white),
                    Container(
                      height: 135.0,
                      padding: const EdgeInsets.only(left: 9),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  myInvitesList(),
                  sectionLabel('Suggestions', Colors.black, Colors.white),
                  Container(
                      height: 135.0,
                      padding: const EdgeInsets.only(left: 9),
                      child: suggestionList()),
                  sectionLabel('Your Circles', Colors.orange, Colors.white),
                  myPinnedGroupList(),
                  myGroupChatList(),
                  sectionLabel('Spectating', Colors.orange, Colors.white),
                  Container(
                      height: 135.0,
                      padding: const EdgeInsets.only(left: 9),
                      child: mySpecChatList()),
                ],
              ),
            ),
    );
  }
}

class MyGroupTile extends StatelessWidget {
  final String groupId;
  final Map joinRequests;
  final int numOfNewMsg;
  final Map replies;
  final int numOfUploads;
  final int createdAt;
  final bool pinned;
  final bool muted;

  const MyGroupTile(this.groupId, this.joinRequests, this.numOfNewMsg,
      this.replies, this.numOfUploads, this.createdAt, this.pinned, this.muted);

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    int numOfJoinReq = joinRequests != null
        ? joinRequests.keys
            .where((userId) => !Constants.myBlockList.contains(userId))
            .toList()
            .length
        : 0;
    Offset tapDownPos;
    return StreamBuilder(
        stream: DatabaseMethods().groupChatCollection.doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            String hashTag = snapshot.data.data()['hashTag'];
            String admin = snapshot.data.data()['admin'];
            String profileImg = snapshot.data.data()['profileImg'];
            String groupState = snapshot.data.data()['chatRoomState'];
            bool anon = snapshot.data.data()['anon'] != null &&
                snapshot.data.data()['anon'];

            bool oneDay = createdAt != null;
            int timeElapsed = oneDay ? getTimeElapsed(createdAt) : null;
            return GestureDetector(
              //Space between camera and #ID
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConversationScreen(
                              groupChatId: groupId,
                              uid: Constants.myUserId,
                              spectate: false,
                              preview: false,
                              initIndex: 0,
                              hideBackButton: false,
                            )));
              },
              onTapDown: (TapDownDetails details) {
                tapDownPos = details.globalPosition;
              },
              onLongPress: () async {
                RenderBox overlay =
                    Overlay.of(context).context.findRenderObject();
                int value = await showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      tapDownPos.dx,
                      tapDownPos.dy,
                      overlay.size.width - tapDownPos.dx,
                      overlay.size.height - tapDownPos.dy,
                    ),
                    items: [
                      PopupMenuItem(
                        value: 1,
                        child: Text(!pinned ? 'Pin to Top' : 'Unpin from Top'),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: Text(!muted
                            ? 'Mute Notification'
                            : 'Unmute Notification'),
                      ),
                    ]);
                if (value == 1) {
                  if (!pinned) {
                    DatabaseMethods(uid: Constants.myUserId)
                        .pinMyGroup(groupId);
                  } else {
                    DatabaseMethods(uid: Constants.myUserId)
                        .unPinMyGroup(groupId);
                  }
                } else if (value == 2) {
                  if (!muted) {
                    DatabaseMethods(uid: Constants.myUserId)
                        .muteMyGroup(groupId);
                  } else {
                    DatabaseMethods(uid: Constants.myUserId)
                        .unMuteMyGroup(groupId);
                  }
                }
              },
              child: SizedBox(
                height: 81,
                child: ListTile(
                  leading: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GroupProfileScreen(
                                    groupId: groupId,
                                    admin: admin,
                                    fromChat: false,
                                    preview: false)));
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          groupProfile(
                              groupId: groupId,
                              oneDay: oneDay,
                              timeElapsed: timeElapsed,
                              profileImg: profileImg),
                          numOfUploads != null && numOfUploads > 0
                              ? const Positioned(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange),
                                  ))
                              : numOfNewMsg != null && numOfNewMsg > 0
                                  ? notifIcon(numOfNewMsg, false)
                                  : const SizedBox.shrink(),
                          storyStreamWrapper(
                              storyStream:
                                  DatabaseMethods(uid: Constants.myUserId)
                                      .getGroupStory(groupId),
                              height: 63,
                              width: 54,
                              tileHeight: 54,
                              tileWidth: 54,
                              iconSize: 18,
                              groupId: groupId,
                              singleDisplay: true,
                              align: Alignment.center),
                        ],
                      )),
                  title: Row(
                    children: [
                      Flexible(
                          child: GestureDetector(
                              //Group #ID
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ConversationScreen(
                                              groupChatId: groupId,
                                              uid: Constants.myUserId,
                                              spectate: false,
                                              preview: false,
                                              initIndex: 0,
                                              hideBackButton: false,
                                            )));
                              },
                              child: Text(
                                hashTag,
                                style: GoogleFonts.varelaRound(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))),
                      const SizedBox(
                        width: 8,
                      ),
                      admin == Constants.myUserId
                          ? Container(
                              width: 10,
                              height: 10,
                              alignment: Alignment.topCenter,
                              child: const Icon(Icons.home_filled,
                                  color: Colors.black, size: 17),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      groupStateIndicator(
                          groupState, anon, MainAxisAlignment.start),
                      Row(
                        children: [
                          pinned
                              ? const Icon(
                                  Icons.push_pin_rounded,
                                  color: Colors.grey,
                                  size: 13.5,
                                )
                              : const SizedBox.shrink(),
                          muted
                              ? const Icon(
                                  Icons.notifications_off_rounded,
                                  color: Colors.grey,
                                  size: 13.5,
                                )
                              : const SizedBox.shrink()
                        ],
                      ),
                      //divider set 1
                      const Divider(
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      replies.isNotEmpty
                          ? iconNum(Icons.maps_ugc, replies.length)
                          : const SizedBox.shrink(),
                      const SizedBox(
                        width: 15,
                      ),
                      numOfJoinReq > 0 && admin == Constants.myUserId
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            JoinRequestsScreen(joinRequests,
                                                groupId, hashTag)));
                              },
                              child: Stack(
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.all(7.0),
                                      child: iconNum(
                                          Icons.person_add, numOfJoinReq)),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return ListTile(
              leading: const CircleAvatar(
                radius: 24,
              ),
              title: Text('#HASHTAG',
                  style: GoogleFonts.varelaRound(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              subtitle: const Text('...',
                  style: TextStyle(fontSize: 16, color: Colors.orange)),
              trailing: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                    platform == TargetPlatform.iOS
                        ? CupertinoIcons.chat_bubble_fill
                        : Icons.send_rounded,
                    color: Colors.black),
              ),
            );
          }
        });
  }
}

class SpecGroupTile extends StatelessWidget {
  final String groupId;
  final int numOfNewMsg;
  final int createdAt;

  const SpecGroupTile(this.groupId, this.numOfNewMsg, this.createdAt);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseMethods().groupChatCollection.doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data.data() != null) {
              var groupDS = snapshot.data;
              String profileImg = groupDS.data()['profileImg'];
              String hashTag = groupDS.data()['hashTag'];
              String groupState = groupDS.data()['chatRoomState'];
              bool anon = groupDS.data()['anon'];
              // bool oneDay = groupDS.data()['oneDay'] != null && groupDS.data()['ondDay'];
              // int createdAt = groupDS.data()['createdAt'];
              bool oneDay = createdAt != null;
              int timeElapsed = oneDay ? getTimeElapsed(createdAt) : null;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ConversationScreen(
                                groupChatId: groupId,
                                uid: Constants.myUserId,
                                spectate: true,
                                preview: false,
                                initIndex: 0,
                                hideBackButton: false,
                              )));
                },
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        groupProfile(
                            groupId: groupId,
                            oneDay: oneDay,
                            timeElapsed: timeElapsed,
                            profileImg: profileImg),
                        storyStreamWrapper(
                            storyStream:
                                DatabaseMethods(uid: Constants.myUserId)
                                    .getGroupStory(groupId),
                            height: 63,
                            width: 54,
                            tileHeight: 54,
                            tileWidth: 54,
                            iconSize: 18,
                            groupId: groupId,
                            singleDisplay: true,
                            align: Alignment.center),
                      ],
                    ),
                    groupStateIndicator(
                        groupState, anon, MainAxisAlignment.center),
                    Stack(children: [
                      borderedText(hashTag, Colors.orange),
                      numOfNewMsg > 0
                          ? Positioned(
                              top: 5,
                              left: 15,
                              child: Container(
                                height: 20,
                                width: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(40)),
                                child: Text(
                                  '$numOfNewMsg',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ))
                          : const SizedBox.shrink(),
                    ]),
                  ],
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
