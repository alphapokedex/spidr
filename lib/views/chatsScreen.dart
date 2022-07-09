import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/myCircles.dart';
import 'package:spidr_app/widgets/storiesListDisplay.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'createGroup.dart';
import 'myFriends.dart';

class ChatsScreen extends StatefulWidget {
  final int initialPage;
  const ChatsScreen({this.initialPage = 0, Key key}) : super(key: key);
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  PageController pageController;
  ScrollController scrollController;

  int curPage;

  Stream storyStream;

  getStories() {
    storyStream = DatabaseMethods(uid: Constants.myUserId).getReceiverStories();
    setState(() {});
  }

  @override
  void initState() {
    pageController = PageController(initialPage: widget.initialPage);
    scrollController = ScrollController();
    curPage = widget.initialPage;
    getStories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
        builder: (context, snapshot) {
          List mutedChats = [];
          List receivedFdReq = [];
          if (snapshot.hasData && snapshot.data.data() != null) {
            mutedChats = snapshot.data.data()['mutedChats'] ?? [];
            receivedFdReq = snapshot.data.data()['receivedFdReq'];
            receivedFdReq = receivedFdReq != null
                ? receivedFdReq
                    .where(
                      (userId) => !Constants.myBlockList.contains(userId),
                    )
                    .toList()
                : [];
          }
          return NestedScrollView(
            controller: scrollController,
            headerSliverBuilder: (BuildContext context, bool isScroller) {
              return [
                StreamBuilder(
                  stream: storyStream,
                  builder: (context, snapshot) {
                    return SliverAppBar(
                      backgroundColor: Colors.white,
                      elevation: 0.0,
                      centerTitle: true,
                      leading: Constants.myProfileImg != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 7.5),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: Constants.myProfileImg
                                        .startsWith('assets', 0)
                                    ? AssetImage(Constants.myProfileImg)
                                    : NetworkImage(Constants.myProfileImg),
                              ),
                            )
                          : const Icon(Icons.person),
                      title: Text(
                        'Spidr',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateGroupScreen(
                                  Constants.myUserId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add_box,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.help,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                      pinned: true,
                      expandedHeight: snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data.docs.length > 0
                          ? 200
                          : null,
                      flexibleSpace: snapshot.hasData && snapshot.data != null
                          ? FlexibleSpaceBar(
                              background: Padding(
                                padding: const EdgeInsets.only(
                                  top: 27.0,
                                ),
                                child: storyList(
                                  snapshot: snapshot,
                                  align: Alignment.center,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ];
            },
            body: MyCirclesScreen(mutedChats),
          );
        },
      ),
    );
  }

  Widget tabItem(icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        pageController.jumpToPage(index);
        curPage = index;
        setState(() {});
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: curPage == index ? Colors.black : Colors.grey),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontWeight: curPage == index ? FontWeight.bold : null,
              color: curPage == index ? Colors.black : Colors.grey,
            ),
          )
        ],
      ),
    );
  }
}
