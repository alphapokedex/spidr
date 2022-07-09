import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/helper/helperFunctions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/chatsScreen.dart';
import 'package:spidr_app/views/circleMediaScreen.dart';
import 'package:spidr_app/views/createGroup.dart';
import 'package:spidr_app/views/myProfilePage.dart';
import 'package:spidr_app/views/streamScreen.dart';
import 'package:spidr_app/widgets/bottomSheetWidgets.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class PageViewsWrapper extends StatefulWidget {
  const PageViewsWrapper({Key key}) : super(key: key);

  @override
  _PageViewsWrapperState createState() => _PageViewsWrapperState();
}

class _PageViewsWrapperState extends State<PageViewsWrapper> {
  int _selectedIndex = 1;
  final PageController pageController = PageController(
    initialPage: 1,
    keepPage: false,
  );
  final spidrIdKey = GlobalKey<FormState>();
  TextEditingController spidrIdTextEditingController = TextEditingController();
  bool ready = false;

  setUserInfo() async {
    User user = FirebaseAuth.instance.currentUser;
    Constants.myName = await HelperFunctions.getUserNameInSharedPreference();
    Constants.myUserId = user.uid;
    DocumentReference userDocRef =
        DatabaseMethods().userCollection.doc(Constants.myUserId);
    DocumentSnapshot userSnapshot = await userDocRef.get();
    bool getStarted = userSnapshot.data().toString().contains('getStarted')
        ? userSnapshot.get('getStarted') != null &&
            userSnapshot.get('getStarted')
        : true;

    try {
      getStarted = userSnapshot.get('getStarted') != null &&
          userSnapshot.get('getStarted');
    } on StateError {
      userDocRef.update({'getStarted': true});
      getStarted = true;
    }

    if (getStarted) await showGetStartedDialog(context);

    if (Constants.myName == null || Constants.myName == 'null null') {
      String name = userSnapshot.data().toString().contains('name')
          ? userSnapshot.get('name')
          : null;
      if (name == null || name == 'null null') {
        if (name == 'null null') spidrIdTextEditingController.text = name;
        await showSpidrIdBoxDialog(
          context,
          userDocRef,
          spidrIdKey,
          spidrIdTextEditingController,
        );
      } else {
        Constants.myName = name;
      }
    }

    Constants.myProfileImg = userSnapshot.get('profileImg');
    Constants.myAnonImg = userSnapshot.get('anonImg');
    Constants.myEmail = user.email;
    Constants.myQuote = userSnapshot.get('quote');
    Constants.myBlockList = userSnapshot.data().toString().contains('blockList')
        ? userSnapshot.get('blockList')
        : [];
    // Constants.myRemovedMedia = userSnapshot.data()['removedMedia'] != null ? userSnapshot.data()['removedMedia'] : [];

    ready = true;
    setState(() {});
    registerNotification(context, Constants.myUserId);
  }

  @override
  void initState() {
    //DatabaseMethods().cleanUpDeletedGroups();
    DatabaseMethods().storyCleanUp();
    setUserInfo();
    super.initState();
  }

  void bottomTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    pageController.jumpToPage(_selectedIndex);
  }

  void pageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedIndex == 2 ? Colors.black : Colors.white,
      resizeToAvoidBottomInset: false,
      body: ready
          ? PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: pageChanged,
              children: [
                const ChatsScreen(),
                StreamScreen(),
                CircleMediaScreen(),
                const MyProfileScreen(),
              ],
            )
          : sectionLoadingIndicator(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 5.0,
        backgroundColor: Colors.orange,
        child: const Icon(
          Icons.settings_input_antenna_sharp,
          color: Colors.white,
        ),
        onPressed: () {
          openCameraBttSheet(context: context);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        elevation: 0.0,
        notchMargin: 5,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              bottomAppBarItem(
                null,
                0,
                true,
                Column(
                  children: [
                    if (_selectedIndex == 0)
                      Container(
                        height: 2,
                        width: 8,
                        color: Colors.orange,
                      ),
                    Expanded(
                      child: Icon(
                        Icons.forum_rounded,
                        color:
                            _selectedIndex == 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              bottomAppBarItem(
                null,
                1,
                true,
                Column(
                  children: [
                    if (_selectedIndex == 1)
                      Container(
                        height: 2,
                        width: 8,
                        color: Colors.orange,
                      ),
                    Expanded(
                      child: Icon(
                        Icons.group,
                        color:
                            _selectedIndex == 1 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              bottomAppBarItem(
                null,
                2,
                true,
                Column(
                  children: [
                    if (_selectedIndex == 2)
                      Container(
                        height: 2,
                        width: 8,
                        color: Colors.orange,
                      ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedIndex == 2 ? Colors.orange : Colors.grey,
                        ),
                        child: const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomAppBarItem(
                null,
                3,
                true,
                Column(
                  children: [
                    if (_selectedIndex == 3)
                      Container(
                        height: 2,
                        width: 8,
                        color: Colors.orange,
                      ),
                    Expanded(
                      child: Icon(
                        Icons.explore,
                        color:
                            _selectedIndex == 3 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomAppBarItem(
    String iconPath,
    int index,
    bool icon,
    Widget iconWidget,
  ) {
    return GestureDetector(
      onTap: () {
        bottomTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40.5,
            width: 40.5,
            child:
                !icon ? Image.asset(iconPath, fit: BoxFit.contain) : iconWidget,
          ),
          // _selectedIndex == index ?
          // Icon(Icons.circle, size: 4.5,color: Colors.orange, ) :
          // SizedBox.shrink()
        ],
      ),
    );
  }
}
