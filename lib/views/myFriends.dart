import  'dart:math';

import  'package:algolia/algolia.dart';
import  'package:flutter/material.dart';
import  'package:shimmer/shimmer.dart';
import  'package:spidr_app/helper/constants.dart';
import  'package:spidr_app/helper/functions.dart';
import  'package:spidr_app/services/database.dart';
import  'package:spidr_app/views/personalChatScreen.dart';
import  'package:spidr_app/views/userProfilePage.dart';
import  'package:spidr_app/widgets/bottomSheetWidgets.dart';
import  'package:spidr_app/widgets/widget.dart';

class MyFriendsScreen extends StatefulWidget {
  final List mutedChats;
  const MyFriendsScreen(this.mutedChats);
  @override
  _MyFriendsScreenState createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen> {
  Stream personalChatsStream;
  // Stream friendsStream;

  PageController pageController;
  int currentUser;
  // Stream usersStream;

  List friends;
  List receivedFdReq;
  List sentFdReq;
  List blockList;

  Offset tapDownPos;

  List<AlgoliaObjectSnapshot> sugUsers;

  bool isLoading = true;

  getSugUsers() {
    DatabaseMethods(uid: Constants.myUserId).suggestUsers().then((val) {
      if (mounted) {
        setState(() {
          sugUsers = val;
        });
        int randPage = Random().nextInt(sugUsers.length);
        pageController = PageController(
            initialPage: randPage, keepPage: false, viewportFraction: 0.5);
        currentUser = randPage;
      }
    });
  }

  getPersonalChats() {
    personalChatsStream =
        DatabaseMethods(uid: Constants.myUserId).getPersonalChats();
  }

  // getMyFriends(){
  //   friendsStream = DatabaseMethods(uid: Constants.myUserId).getMyFriends();
  // }

  acceptFriendReq(String userId) {
    DatabaseMethods(uid: Constants.myUserId).acceptFriendRequest(userId);
    DatabaseMethods(uid: Constants.myUserId)
        .createPersonalChat(userId: userId, actionType: "FRIEND_CHAT");
  }

  ignoreFriendReq(String userId) {
    DatabaseMethods(uid: Constants.myUserId).ignoreFriendRequest(userId);
  }

  removeContact(String personalChatId, String contactId) {
    DatabaseMethods(uid: Constants.myUserId)
        .deletePersonalChat(personalChatId, contactId);
  }

  @override
  void initState() {
    getSugUsers();
    getPersonalChats();
    // getMyFriends();
    setState(() {});
    loadCheck();
    super.initState();
  }

  Widget friendReqTile(String userId) {
    return Container(
      height: 72,
      color: Colors.orange,
      child: ListTile(
          leading: userProfile(userId: userId),
          title: userName(
            userId: userId,
            fontWeight: FontWeight.bold,
          ),
          subtitle: const Text("befriend"),
          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  acceptFriendReq(userId);
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: const Text("Accept",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              GestureDetector(
                onTap: () {
                  ignoreFriendReq(userId);
                },
                child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: const Text("Ignore",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black))),
              )
            ],
          )),
    );
  }

  Widget friendTile(String userId, String personalChatId, int numOfNewMsg,
      int numOfUploads, bool pinned, bool muted) {
    final TargetPlatform platform = Theme.of(context).platform;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PersonalChatScreen(
                      personalChatId: personalChatId,
                      contactId: userId,
                      openByOther: true,
                      anon: false,
                      friend: true,
                    )));
      },
      onTapDown: (TapDownDetails details) {
        tapDownPos = details.globalPosition;
      },
      onLongPress: () async {
        RenderBox overlay = Overlay.of(context).context.findRenderObject();
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
                child: Text(!pinned ? "Pin to Top" : "Unpin from Top"),
              ),
              PopupMenuItem(
                value: 2,
                child:
                    Text(!muted ? "Mute Notification" : "Unmute Notification"),
              ),
            ]);
        if (value == 1) {
          if (!pinned) {
            DatabaseMethods(uid: Constants.myUserId).pinMyFriend(userId);
          } else {
            DatabaseMethods(uid: Constants.myUserId).unPinMyFriend(userId);
          }
        } else if (value == 2) {
          if (!muted) {
            DatabaseMethods(uid: Constants.myUserId)
                .muteMyFriend(personalChatId);
          } else {
            DatabaseMethods(uid: Constants.myUserId)
                .unMuteMyFriend(personalChatId);
          }
        }
      },
      child: Container(
        height: 81,
        color: Colors.white,
        child: ListTile(
          leading: userProfile(userId: userId),
          title: userName(
            userId: userId,
            fontWeight: FontWeight.bold,
          ),
          subtitle: pinned || muted
              ? Row(
                  children: [
                    pinned
                        ? const Icon(
                            Icons.push_pin_rounded,
                            color: Colors.grey,
                            size: 13.5,
                          )
                        : const SizedBox.shrink(),
                    muted != null && muted
                        ? const Icon(
                            Icons.notifications_off_rounded,
                            color: Colors.grey,
                            size: 13.5,
                          )
                        : const SizedBox.shrink()
                  ],
                )
              : null,
          trailing: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PersonalChatScreen(
                            personalChatId: personalChatId,
                            contactId: userId,
                            openByOther: true,
                            anon: false,
                            friend: true,
                          )));
            },
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.comment_rounded, color: Colors.black),
                ),
                numOfUploads != null && numOfUploads > 0
                    ? const Positioned(
                        height: 45,
                        width: 55,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.orange),
                        ))
                    : numOfNewMsg != null && numOfNewMsg > 0
                        ? notifIcon(numOfNewMsg, false)
                        : const SizedBox.shrink()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget friendReqList() {
    return StreamBuilder(
      stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
      builder: (context, snapshot) {
        return snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data.data()['receivedFdReq'] != null &&
                snapshot.data.data()['receivedFdReq'].length > 0
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data.data()['receivedFdReq'].length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  String userId = snapshot.data.data()['receivedFdReq'][index];
                  return blockList == null || !blockList.contains(userId)
                      ? friendReqTile(userId)
                      : const SizedBox.shrink();
                })
            : const SizedBox.shrink();
      },
    );
  }

  Widget friendPinnedList() {
    return StreamBuilder(
      stream: DatabaseMethods(uid: Constants.myUserId).getMyFriends(),
      builder: (context, snapshot) {
        return snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data.docs.length > 0
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data.docs.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  String friendId =
                      snapshot.data.docs[index].data()['friendId'];
                  String plChatId =
                      snapshot.data.docs[index].data()['personalChatId'];
                  return (blockList == null || !blockList.contains(friendId)) &&
                          (snapshot.data.docs[index].data()['pinned'] != null &&
                              snapshot.data.docs[index].data()['pinned'])
                      ? friendTile(
                          friendId,
                          plChatId,
                          snapshot.data.docs[index].data()['numOfNewMsg'],
                          snapshot.data.docs[index].data()['numOfUploads'],
                          true,
                          widget.mutedChats.contains(plChatId))
                      : const SizedBox.shrink();
                })
            : const SizedBox.shrink();
      },
    );
  }

  Widget friendList() {
    return StreamBuilder(
      stream: DatabaseMethods(uid: Constants.myUserId).getMyFriends(),
      builder: (context, snapshot) {
        return snapshot.hasData && snapshot.data != null
            ? snapshot.data.docs.length > 0
                ? ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: snapshot.data.docs.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      String friendId =
                          snapshot.data.docs[index].data()['friendId'];
                      String plChatId =
                          snapshot.data.docs[index].data()['personalChatId'];
                      return (blockList == null ||
                                  !blockList.contains(friendId)) &&
                              (snapshot.data.docs[index].data()['pinned'] ==
                                      null ||
                                  !snapshot.data.docs[index].data()['pinned'])
                          ? friendTile(
                              friendId,
                              plChatId,
                              snapshot.data.docs[index].data()['numOfNewMsg'],
                              snapshot.data.docs[index].data()['numOfUploads'],
                              false,
                              widget.mutedChats.contains(plChatId))
                          : const SizedBox.shrink();
                    })
                : noFriendWidget()
            : sectionLoadingIndicator();
      },
    );
  }

  Widget noFriendWidget() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: sugUsers != null
          ? PageView.builder(
              itemCount: sugUsers.length,
              controller: pageController,
              onPageChanged: (page) {
                setState(() {
                  currentUser = page;
                });
              },
              itemBuilder: (context, index) {
                String userId = sugUsers[index].objectID;
                String profileImg = sugUsers[index].data['profileImg'];
                String username = sugUsers[index].data['name'];
                return AnimatedBuilder(
                  animation: pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (pageController.position.haveDimensions) {
                      value = pageController.page - index;
                      value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);
                    }
                    return Center(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          SizedBox(
                            height: Curves.easeOut.transform(value) * 200,
                            width: Curves.easeOut.transform(value) * 450,
                            child: child,
                          ),
                          currentUser == index
                              ? Container(
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(30)),
                                      gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.75),
                                            Colors.black.withOpacity(0)
                                          ],
                                          end: Alignment.topCenter,
                                          begin: Alignment.bottomCenter)),
                                  child: ListTile(
                                    title: Text(username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                    trailing: friendShipToggler(userId: userId),
                                  ),
                                )
                              : const SizedBox.shrink()
                        ],
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  UserProfileScreen(userId: userId)));
                    },
                    child: profileDisplay(profileImg),
                  ),
                );
              })
          : sectionLoadingIndicator(),
    );
  }

  Widget friendShipToggler({String userId, bool anon}) {
    bool befriended = friends != null && friends.contains(userId);
    bool sentReq = sentFdReq != null && sentFdReq.contains(userId);
    bool receivedReq = receivedFdReq != null && receivedFdReq.contains(userId);
    return !befriended
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
                onTap: () {
                  if (!sentReq && !receivedReq) {
                    DatabaseMethods(uid: Constants.myUserId)
                        .sendFriendRequest(userId);
                    showCenterFlash(
                        alignment: Alignment.center,
                        context: context,
                        text: 'Requested');
                  } else if (sentReq) {
                    DatabaseMethods(uid: Constants.myUserId)
                        .cancelFriendRequest(userId);
                    showCenterFlash(
                        alignment: Alignment.center,
                        context: context,
                        text: 'Canceled');
                  }
                },
                child: iconContainer(
                    icon: !sentReq ? Icons.person_add : Icons.cancel_rounded,
                    contColor: !sentReq && !receivedReq
                        ? Colors.orange
                        : receivedReq
                            ? Colors.grey
                            : Colors.red)),
          )
        : const SizedBox.shrink();
  }

  Widget personalChatTile(
      String contactId,
      String personalChatId,
      int numOfNewMsg,
      bool openByOther,
      int numOfUploads,
      int chatStartTime,
      bool anon) {
    int timeElapsed;

    if (chatStartTime != null) {
      timeElapsed = getTimeElapsed(chatStartTime);
      if (timeElapsed / Duration.secondsPerDay >= 1) {
        removeContact(personalChatId, contactId);
      }
    } else {
      if (openByOther) {
        removeContact(personalChatId, contactId);
      }
    }

    return StreamBuilder(
        stream: DatabaseMethods()
            .personalChatCollection
            .doc(personalChatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            bool anon = snapshot.data.data()["anon"];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PersonalChatScreen(
                              personalChatId: personalChatId,
                              contactId: contactId,
                              openByOther: openByOther,
                              anon: anon,
                              friend: false,
                            )));
              },
              onDoubleTap: () {
                if (openByOther != null && openByOther) {
                  openCameraBttSheet(
                    context: context,
                    personalChatId: personalChatId,
                    friend: false,
                    contactId: contactId,
                  );
                }
              },
              child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Column(
                    children: [
                      Stack(alignment: Alignment.center, children: [
                        timerIndicator(
                            height: 54,
                            width: 54,
                            timeElapsed: timeElapsed,
                            color: openByOther ? Colors.black : Colors.grey,
                            strokeWidth: 2.5),
                        Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            userProfile(
                                userId: contactId,
                                toProfile: false,
                                anon: anon),
                            numOfNewMsg != null && numOfNewMsg > 0
                                ? notifIcon(numOfNewMsg, false)
                                : const SizedBox.shrink()
                          ],
                        ),
                        numOfUploads != null && numOfUploads > 0
                            ? sizedLoadingIndicator(size: 48)
                            : const SizedBox.shrink()
                      ]),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          userName(
                              userId: contactId,
                              anon: anon,
                              fontWeight: FontWeight.bold),
                          friendShipToggler(userId: contactId, anon: anon),
                        ],
                      )
                    ],
                  )),
            );
          } else {
            return const SizedBox.shrink();
          }
        });
  }

  Widget personalChatsList(BuildContext context) {
    return StreamBuilder(
        stream: personalChatsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.docs.length > 0) {
              return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    String contactId =
                        snapshot.data.docs[index].data()["contactId"];
                    String personalChatId = snapshot.data.docs[index].id;
                    int numOfNewMsg =
                        snapshot.data.docs[index].data()['numOfNewMsg'];
                    bool openByOther =
                        snapshot.data.docs[index].data()['openByOther'];
                    int numOfUploads =
                        snapshot.data.docs[index].data()['numOfUploads'];
                    int chatStartTime =
                        snapshot.data.docs[index].data()['chatStartTime'];
                    bool anon = snapshot.data.docs[index].data()['anon'];

                    return blockList == null ||
                            !blockList.contains(contactId) ||
                            !isLoading
                        ? personalChatTile(
                            contactId,
                            personalChatId,
                            numOfNewMsg,
                            openByOther,
                            numOfUploads,
                            chatStartTime,
                            anon)
                        : const SizedBox.shrink();
                  });
            } else {
              return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: noItems(
                      icon: Icons.maps_ugc,
                      text: "no private chats yet",
                      mAxAlign: MainAxisAlignment.start));
            }
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  Future loadCheck() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            friends = snapshot.data.data()["friends"];
            receivedFdReq = snapshot.data.data()["receivedFdReq"];
            sentFdReq = snapshot.data.data()["sentFdReq"];
            blockList = snapshot.data.data()["blockList"];
          }
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
                          sectionLabel(
                              "Private Chats", Colors.black, Colors.white),
                          Container(
                            height: 125.0,
                            padding: const EdgeInsets.only(left: 9),
                          ),
                          sectionLabel(
                              "Your Friends", Colors.orange, Colors.white),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        friendReqList(),
                        sectionLabel(
                            "Private Chats", Colors.black, Colors.white),
                        Container(
                          height: 125.0,
                          padding: const EdgeInsets.only(left: 9),
                          child: personalChatsList(context),
                        ),
                        sectionLabel(
                            "Your Friends", Colors.orange, Colors.white),
                        friendPinnedList(),
                        friendList()
                      ],
                    ),
                  ),
          );
        });
  }
}
