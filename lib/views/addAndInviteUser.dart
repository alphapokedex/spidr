import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/bottomSheetWidgets.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class AddAndInviteUserScreen extends StatefulWidget {
  final String groupId;
  final String uid;
  final String hashTag;
  final bool isAdmin;
  final List members;
  final Map joinReq;
  final Map waitList;
  final List invites;
  final List bannedUsers;
  const AddAndInviteUserScreen(
    this.groupId,
    this.uid,
    this.hashTag,
    this.isAdmin,
    this.members,
    this.joinReq,
    this.waitList,
    this.invites,
    this.bannedUsers,
  );
  @override
  State<AddAndInviteUserScreen> createState() => _AddAndInviteUserScreenState();
}

class _AddAndInviteUserScreenState extends State<AddAndInviteUserScreen> {
  Stream usersStream;

  TextEditingController spidrIDSearchController = TextEditingController();
  List members = [];
  Map joinReq = {};
  Map waitList = {};
  List invites = [];
  List bannedUsers = [];

  bool searching = false;

  // List blockList = [];

  searchUsers(String searchText) {
    setState(() {
      searching = true;
    });

    setState(() {
      usersStream = DatabaseMethods().searchUsers(searchText);
      searching = false;
    });
  }

  addUser(String userId, String username) async {
    DocumentSnapshot groupSnapshot =
        await DatabaseMethods().getGroupChatById(widget.groupId);
    int numOfGroupMem = groupSnapshot.get("members").length;

    double groupCap = groupSnapshot.get("groupCapacity");

    if (numOfGroupMem < groupCap) {
      setState(() {
        members.add(userId);
      });
      DatabaseMethods(uid: userId)
          .toggleGroupMembership(widget.groupId, "ADD_USER");
    } else {
      showAlertDialog(
          "Your group has already reached its full capacity.", context);
    }
  }

  inviteUser(String userId, String username) async {
    DocumentSnapshot groupSnapshot =
        await DatabaseMethods().getGroupChatById(widget.groupId);
    String groupState = groupSnapshot.get('chatRoomState');

    DatabaseMethods(uid: userId)
        .inviteUser(widget.groupId, widget.hashTag, groupState);
    setState(() {
      invites.add(userId);
    });
  }

  Widget userTile(String userId, String username, String profileImg) {
    bool joined = members.contains(userId);
    bool onWaitList = waitList.containsKey(userId);
    bool onRequest = joinReq.containsKey(userId);
    bool invited = invites.contains(userId);
    bool gotBanned = bannedUsers.contains(userId);
    return GestureDetector(
      onTap: () {
        openUserProfileBttSheet(context, userId, username, profileImg);
        // Navigator.push(context, MaterialPageRoute(
        //     builder: (context) => UserProfileScreen(
        //         userId:userId,
        //         profileImg:profileImg,
        //         username: username
        //     )
        // ));
      },
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              avatarImg(profileImg, 24, false),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child:
                    Text(username, style: const TextStyle(color: Colors.black)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (!gotBanned) {
                    if (widget.isAdmin) {
                      if (!joined && !onWaitList && !onRequest) {
                        addUser(userId, username);
                      }
                    } else {
                      if (!joined && !invited && !onRequest && !onWaitList) {
                        inviteUser(userId, username);
                      }
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: gotBanned
                          ? Colors.black54
                          : joined || onWaitList || invited || onRequest
                              ? Colors.grey
                              : Colors.blue,
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13.5, vertical: 9),
                  child: Text(
                    gotBanned
                        ? "Banned"
                        : invited
                            ? "Invited"
                            : joined
                                ? "Joined"
                                : onWaitList
                                    ? "Waitlisted"
                                    : onRequest
                                        ? "On Request"
                                        : widget.isAdmin
                                            ? "Add"
                                            : "Invite",
                    style: simpleTextStyle(),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Widget userList() {
    return StreamBuilder(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data.hits.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  Map<String, dynamic> docData = snapshot.data.hits[index].data;
                  String userId = snapshot.data.hits[index].objectID;

                  return userId != Constants.myUserId &&
                          !Constants.myBlockList.contains(userId)
                      ? userTile(
                          userId,
                          docData["name"],
                          docData["profileImg"],
                        )
                      : const SizedBox.shrink();
                });
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  @override
  void initState() {
    setState(() {
      members = widget.members;
      joinReq = widget.joinReq;
      waitList = widget.waitList;
      invites = widget.invites != null && !widget.isAdmin ? widget.invites : [];
      bannedUsers = widget.bannedUsers ?? [];
    });
    searchUsers(spidrIDSearchController.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: const BackButton(
          color: Colors.black,
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
          child: TextField(
            autofocus: true,
            controller: spidrIDSearchController,
            onChanged: (String val) {
              searchUsers(val);
            },
            decoration: const InputDecoration(
                icon: Icon(Icons.search),
                border: InputBorder.none,
                hintText: "Search user",
                hintStyle: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // StreamBuilder(
              //   stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
              //   builder: (context, snapshot) {
              //     if(snapshot.hasData && snapshot.data.data() != null){
              //       blockList = snapshot.data.data()["blockList"] != null ? snapshot.data.data()["blockList"] : [];
              //     }
              //     return

              Expanded(
                  child: spidrIDSearchController.text.isNotEmpty
                      ? userList()
                      : const SizedBox.shrink())
              //   }
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
