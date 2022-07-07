import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/groupChatsView.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/widgets/widget.dart';

class GroupsList extends StatefulWidget {
  final String searchText;
  const GroupsList(this.searchText);

  @override
  _GroupsListState createState() => _GroupsListState();
}

class _GroupsListState extends State<GroupsList> {
  DatabaseMethods databaseMethods = DatabaseMethods();
  List recentSearch;
  Stream groupChatsStream;

  searchChats(String searchText) {
    setState(() {
      groupChatsStream = DatabaseMethods().searchGroupChats(searchText);
    });
  }

  Widget searchGroupTile(
      {String groupId,
      String hashTag,
      String admin,
      String profileImg,
      String adminName,
      String chatRoomState,
      bool anon,
      int index,
      AsyncSnapshot snapshot,
      bool oneDay,
      int createdAt,
      bool recent}) {
    int timeElapsed = getTimeElapsed(createdAt);
    bool expired = oneDay && timeElapsed / Duration.secondsPerDay >= 1;
    if (expired && recent) {
      DatabaseMethods(uid: Constants.myUserId)
          .removeRecentSearch('reGroupSearch', groupId);
    }

    return !expired
        ? GestureDetector(
            onTap: () {
              if (!recent) {
                DatabaseMethods(uid: Constants.myUserId)
                    .addRecentSearch('reGroupSearch', groupId);
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GroupProfileScreen(
                          groupId: groupId,
                          admin: admin,
                          fromChat: false,
                          preview: true)));
            },
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    groupProfile(
                        groupId: groupId,
                        oneDay: oneDay,
                        timeElapsed: timeElapsed,
                        profileImg: profileImg),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hashTag,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              )),
                          anon == null || !anon
                              ? Text(
                                  'Admin: $adminName',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const SizedBox.shrink(),

                          // program != null && program.isNotEmpty ? RichText(
                          //     text: TextSpan(
                          //         children: [
                          //           WidgetSpan(child: Icon(Icons.school, size: 16,)),
                          //           WidgetSpan(child: SizedBox(width: 5,)),
                          //           TextSpan(text: program, style: TextStyle(color: Colors.black))
                          //         ]
                          //     )) : SizedBox.shrink(),
                          // school != null && school.isNotEmpty ? RichText(
                          //     text: TextSpan(
                          //         children: [
                          //           WidgetSpan(child: Icon(Icons.account_balance_rounded, size: 16,)),
                          //           WidgetSpan(child: SizedBox(width: 5,)),
                          //           TextSpan(text: school, style: TextStyle(color: Colors.black))
                          //         ]
                          //     )) : SizedBox.shrink(),

                          groupStateIndicator(
                              chatRoomState, anon, MainAxisAlignment.start),
                          // Text(chatRoomState, style: TextStyle(
                          //     fontSize: 16,
                          //     color: chatRoomState == "public" ? Colors.green : Colors.red
                          // ),)
                        ],
                      ),
                    ),
                    const Spacer(),
                    recent
                        ? const Icon(Icons.history_rounded, color: Colors.grey)
                        : GestureDetector(
                            onTap: () {
                              if (!recent) {
                                DatabaseMethods(uid: Constants.myUserId)
                                    .addRecentSearch('reGroupSearch', groupId);
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => GroupChatsScreen(
                                          Constants.myUserId,
                                          index,
                                          snapshot)));
                            },
                            child: iconContainer(
                              icon: Icons.remove_red_eye_rounded,
                              contColor: Colors.black,
                              horPad: 5,
                              verPad: 5,
                            )),
                  ],
                )),
          )
        : const SizedBox.shrink();
  }

  Widget searchGroupList() {
    return StreamBuilder(
        stream: groupChatsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return snapshot.data.hits.length as int > 0
                  ? ListView.builder(
                      itemCount: snapshot.data.hits.length as int,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> docData =
                            snapshot.data.hits[index].data;
                        return searchGroupTile(
                            groupId: snapshot.data.hits[index].objectID,
                            hashTag: docData['hashTag'],
                            admin: docData['admin'],
                            profileImg: docData['profileImg'],
                            adminName: docData['adminName'],
                            chatRoomState: docData['chatRoomState'],
                            anon: docData['anon'],
                            index: index,
                            snapshot: snapshot,
                            oneDay:
                                docData['oneDay'] != null && docData['oneDay'],
                            createdAt: docData['createdAt'],
                            recent: false);
                      })
                  : noItems(
                      icon: Icons.search_rounded, text: 'search not found');
            } else {
              return const SizedBox.shrink();
            }
          } else {
            return sectionLoadingIndicator();
          }
        });
  }

  Widget recentSearchList() {
    return recentSearch != null
        ? ListView.builder(
            itemCount: recentSearch.length,
            itemBuilder: (context, index) {
              String groupId = recentSearch[index];
              return StreamBuilder(
                  stream: databaseMethods.groupChatCollection
                      .doc(groupId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data.data() != null) {
                        var docData = snapshot.data.data();
                        return searchGroupTile(
                            groupId: groupId,
                            hashTag: docData['hashTag'],
                            admin: docData['admin'],
                            profileImg: docData['profileImg'],
                            adminName: docData['adminName'],
                            chatRoomState: docData['chatRoomState'],
                            anon: docData['anon'],
                            oneDay:
                                docData['oneDay'] != null && docData['oneDay'],
                            createdAt: docData['createdAt'],
                            recent: true);
                      } else {
                        DatabaseMethods(uid: Constants.myUserId)
                            .removeRecentSearch('reGroupSearch', groupId);
                        return const SizedBox.shrink();
                      }
                    } else {
                      return const SizedBox.shrink();
                    }
                  });
            },
          )
        : const SizedBox.shrink();
  }

  @override
  void didUpdateWidget(covariant GroupsList oldWidget) {
    // TODO: implement didUpdateWidget
    searchChats(widget.searchText);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    searchChats(widget.searchText);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.data() != null) {
            recentSearch = snapshot.data.data()['reGroupSearch'];
            return widget.searchText.isNotEmpty
                ? searchGroupList()
                : recentSearchList();
          } else {
            return screenLoadingIndicator(context);
          }
        });
  }
}
