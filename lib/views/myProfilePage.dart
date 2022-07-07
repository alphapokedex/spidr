import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/helper/authenticate.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/auth.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/services/fileUpload.dart';
import 'package:spidr_app/views/aboutSpidr.dart';
import 'package:spidr_app/views/backpackScreen.dart';
import 'package:spidr_app/views/settingsScreen.dart';
import 'package:spidr_app/views/viewBanner.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/groupsListDisplay.dart';
import 'package:spidr_app/widgets/profilePageWidgets.dart';
import 'package:spidr_app/widgets/storiesListDisplay.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen();

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Stream itemsStream;
  Stream storyStream;

  TextEditingController quoteController =
      TextEditingController(text: Constants.myQuote);
  TextEditingController tagController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();
  GlobalKey key5 = GlobalKey();

  bool uploading = false;
  File pickedImage;

  editAboutMe(String newQuote) {
    if (formKey.currentState.validate()) {
      DatabaseMethods(uid: Constants.myUserId).editUserQuote(newQuote);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  deleteMyTag(String tag) {
    DatabaseMethods(uid: Constants.myUserId).deleteUserTag(tag);
  }

  addOrEditMyTag(String newTag, int index) {
    if (formKey.currentState.validate()) {
      DatabaseMethods(uid: Constants.myUserId).addUserTag(newTag, index);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  getMyStories() {
    storyStream =
        DatabaseMethods(uid: Constants.myUserId).getSenderStories(true);
    setState(() {});
  }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_myProfilePageSeen' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_myProfilePageSeen', true);
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
                      'Represent yourself in Anonymous Circles with a MIYU avatar ',
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
      ),
    );

    targets.add(TargetFocus(
      identify: 'Avatar Picture',
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
                      'Profile Picture',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Your profile picture. View and change it here!',
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )),
      ],
      shape: ShapeLightFocus.Circle,
    ));
    targets.add(TargetFocus(
      identify: 'About Me',
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
                      'About Me',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Describe yourself so users on Spidr can start to get to know you!',
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
      identify: 'Hashtag',
      keyTarget: key4,
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
                      'Hashtags',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Add hashtags to your profile to see Circles and Snippets relevant to you',
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
        identify: 'Groupchat List',
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
                    'Circle List',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'This is where the Circles you have joined will appear ',
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
  }

  @override
  void initState() {
    getMyStories();
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    Future.delayed(const Duration(milliseconds: 100), showTutorial);
    super.initState();
  }

  Widget menuItem({String label, icon, color = Colors.white}) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
        color: Colors.orange,
      ),
      margin: const EdgeInsets.only(left: 18),
      child: ListTile(
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          trailing: iconContainer(
            icon: icon,
            contColor: Colors.black,
            horPad: 5,
            verPad: 5,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      endDrawer: Container(
        width: width * 0.81,
        margin: EdgeInsets.symmetric(vertical: height * 0.05),
        child: Drawer(
            child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                height: height * 0.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()),
                          );
                        },
                        child: menuItem(
                          label: 'Settings',
                          icon: Icons.settings,
                        )),
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AboutSpidrScreen()),
                          );
                        },
                        child: menuItem(
                          label: 'About',
                          icon: Icons.info_rounded,
                        )),
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BackPackScreen()),
                          );
                        },
                        child: menuItem(
                          label: 'Backpack',
                          icon: Icons.backpack_rounded,
                        )),
                  ],
                ),
              ),
              GestureDetector(
                  onTap: () async {
                    bool hopOff = await showLogOutDialog(context);
                    if (hopOff != null && hopOff) {
                      DatabaseMethods(uid: Constants.myUserId)
                          .hopOffNotifSetUp();
                      AuthMethods().signOut().then((res) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Authenticate()));
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 1,
                        )
                      ],
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.only(left: 18),
                    child: ListTile(
                        title: const Text(
                          'Hop Off',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        trailing: iconContainer(
                          icon: Icons.logout,
                          contColor: Colors.black,
                          horPad: 5,
                          verPad: 5,
                        )),
                  )),
            ],
          ),
        )),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            final ScaffoldState scaffold = Scaffold.maybeOf(context);
            final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);
            final bool hasEndDrawer = scaffold?.hasEndDrawer ?? false;
            final bool canPop = parentRoute?.canPop ?? false;

            if (hasEndDrawer && canPop) {
              return const BackButton();
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
      ),

      // TODO please create user model and create a from json
      body: StreamBuilder(
          stream: DatabaseMethods()
              .userCollection
              .doc(Constants.myUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.data() != null) {
              String quote = snapshot.data.data()['quote'];
              String profileImg = snapshot.data.data()['profileImg'];
              int imgIndex = snapshot.data.data()['anonImg'];
              String anonImg = imgIndex != null ? userMIYUs[imgIndex] : null;
              List tags = snapshot.data.data()['tags'];
              List banner = snapshot.data.data()['banner'];

              if (anonImg == null) {
                DatabaseMethods(uid: Constants.myUserId).setUpAnonImg();
              }

              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      // physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              banner != null && banner.isNotEmpty
                                  ? bannerSlide(
                                      context: context,
                                      height: height * 0.35,
                                      banner: banner,
                                      userId: Constants.myUserId,
                                      delTag: deleteMyTag,
                                      editTag: addOrEditMyTag,
                                      editAboutMe: editAboutMe,
                                      formKey: formKey,
                                      quoteController: quoteController,
                                      tagController: tagController,
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    BannerScreen(
                                                      userId:
                                                          Constants.myUserId,
                                                      delTag: deleteMyTag,
                                                      editTag: addOrEditMyTag,
                                                      editAboutMe: editAboutMe,
                                                      formKey: formKey,
                                                      quoteController:
                                                          quoteController,
                                                      tagController:
                                                          tagController,
                                                    )));
                                      },
                                      child: Container(
                                        height: height * 0.35,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        child: Center(
                                          child: Text(
                                            'Add Photos :)',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.varelaRound(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const SizedBox(
                                    width: 54,
                                  ),
                                  Container(
                                    height: 81,
                                    width: 81,
                                    margin:
                                        EdgeInsets.only(top: height * 0.275),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      // boxShadow: [circleShadow],
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          key: key2,
                                          padding: const EdgeInsets.all(4.5),
                                          child:
                                              avatarImg(profileImg, 36, false),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            if (!uploading) {
                                              setState(() {
                                                uploading = true;
                                              });
                                              String imgUrl =
                                                  await UploadMethods(
                                                          profileImg:
                                                              profileImg)
                                                      .pickAndUploadMedia(
                                                          'USER_PROFILE_IMG',
                                                          false);
                                              setState(() {
                                                uploading = false;
                                              });
                                              if (imgUrl != null) {
                                                DatabaseMethods(
                                                        uid: Constants.myUserId)
                                                    .replaceUserPic(imgUrl);
                                              }
                                            }
                                          },
                                          child: Align(
                                              alignment: Alignment.bottomRight,
                                              child: !uploading
                                                  ? imgEditBtt()
                                                  : SizedBox(
                                                      height: 25,
                                                      width: 25,
                                                      child:
                                                          sectionLoadingIndicator())),
                                        )
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      int newImgIndex = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return SelectAnonImgDialog(
                                                imgIndex);
                                          });
                                      if (newImgIndex != null &&
                                          imgIndex != newImgIndex) {
                                        DatabaseMethods(uid: Constants.myUserId)
                                            .replaceUserAnonPic(newImgIndex);
                                      }
                                    },
                                    child: Container(
                                      height: 54,
                                      width: 54,
                                      margin:
                                          EdgeInsets.only(top: height * 0.3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: const Offset(0,
                                                3), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        key: key1,
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(4.5),
                                            child:
                                                avatarImg(anonImg, 24, false),
                                          ),
                                          Positioned(
                                            top: 54,
                                            child: Image.asset(
                                                'assets/icon/icons8-anonymous-mask-50.png',
                                                scale: 2.5),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                Constants.myName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              Text(
                                Constants.myEmail,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: height * 0.05,
                          ),
                          quote.isEmpty
                              ? GestureDetector(
                                  key: key3,
                                  onTap: () {
                                    showTextBoxDialog(
                                        context: context,
                                        text: 'About Me',
                                        textEditingController: quoteController,
                                        errorText:
                                            'Sorry, this can not be empty',
                                        editQuote: editAboutMe,
                                        formKey: formKey);
                                  },
                                  child: infoEditBtt(
                                      context: context, text: 'About Me'),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        infoText(
                                            text: quote,
                                            textAlign: TextAlign.center),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        GestureDetector(
                                            onTap: () {
                                              showTextBoxDialog(
                                                  context: context,
                                                  text: 'About Me',
                                                  textEditingController:
                                                      quoteController,
                                                  errorText:
                                                      'Sorry, about me can not be empty',
                                                  editQuote: editAboutMe,
                                                  formKey: formKey);
                                            },
                                            child: infoEditIcon())
                                      ]),
                                ),
                          SizedBox(
                            height: height * 0.025,
                          ),
                          storyStreamWrapper(
                            storyStream: storyStream,
                            align: Alignment.center,
                          ),
                          SizedBox(
                            height: height * 0.015,
                          ),
                          Container(
                              key: key4,
                              height: 45,
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: ProfileTagList(
                                  editable: true,
                                  tagController: tagController,
                                  tags: tags,
                                  editTag: addOrEditMyTag,
                                  delTag: deleteMyTag,
                                  formKey: formKey,
                                  tagNum: tags.length < Constants.maxTags
                                      ? tags.length + 1
                                      : Constants.maxTags)),
                          SizedBox(
                            height: height * 0.05,
                          ),
                          Container(
                              key: key5,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 27),
                              child: groupList(Constants.myUserId))
                        ],
                      ),
                    ),
                  ),
                  Container(
                      height: 90,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                            Colors.black.withOpacity(0.75),
                            Colors.black.withOpacity(0)
                          ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter)))
                ],
              );
            } else {
              return screenLoadingIndicator(context);
            }
          }),
      // floatingActionButton: FloatingActionButton(
      //   elevation: 1.0,
      //   backgroundColor: Colors.orange,
      //   child: Icon(Icons.backpack_rounded, color: Colors.white,),
      //   onPressed: (){
      //     openBackpackBttSheet(context);
      //   },
      //
      // ),
    );
  }
}
