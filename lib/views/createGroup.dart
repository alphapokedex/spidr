import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/conversationScreen.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class CreateGroupScreen extends StatefulWidget {
  final String uid;
  const CreateGroupScreen(this.uid);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  bool anon = false;
  bool oneDay = false;
  final formKey = GlobalKey<FormState>();
  TextEditingController hashTagController = TextEditingController();

  double groupCapacity = 20;
  bool validHashTag = true;

  bool creating = false;
  int randNum;
  String profileImg;

  int state = 1;
  PageController controller;

  List tags = [];
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();
  GlobalKey key5 = GlobalKey();

  createChatAndStartConvo() async {
    setState(() {
      creating = true;
    });

    String hashTag = hashTagController.text;
    hashTag = !hashTag.startsWith('#') ? '#${hashTagController.text}' : hashTag;
    String chatRoomState = state == 1
        ? 'public'
        : state == 2
            ? 'private'
            : 'invisible';

    DateTime now = DateTime.now();
    DatabaseMethods(uid: widget.uid)
        .createGroupChat(
            hashTag: hashTag.toUpperCase(),
            username: Constants.myName,
            chatRoomState: chatRoomState,
            time: now.microsecondsSinceEpoch,
            groupCapacity: groupCapacity,
            groupPic: profileImg,
            anon: anon,
            tags: tags,
            oneDay: oneDay)
        .then((groupChatId) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ConversationScreen(
                    groupChatId: groupChatId,
                    uid: widget.uid,
                    spectate: false,
                    preview: false,
                    initIndex: 0,
                    hideBackButton: false,
                  )));
    }, onError: (error) {
      print(error);
    });

    hashTagController.text = '';
    setState(() {
      creating = false;
    });
  }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_createGroupSeen' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_createGroupSeen', true);
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
                      'Represent your group chat with a MIYU ',
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
                    'Name your own circle here!',
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

  @override
  void initState() {
    Random random = Random();
    randNum = random.nextInt(groupMIYUs.length);
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    controller = PageController(
        initialPage: randNum, keepPage: false, viewportFraction: 0.5);
    setState(() {
      profileImg = groupMIYUs[randNum];
    });
    Future.delayed(const Duration(milliseconds: 100), showTutorial);
    super.initState();
  }

  Widget mainText(String text) {
    return Text(
      text,
      style: const TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Pick a group avatar',
            style: GoogleFonts.varelaRound(
                color: Colors.black,
                fontSize: 15.0,
                fontWeight: FontWeight.bold)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: const Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                            height: MediaQuery.of(context).size.width / 4,
                            width: MediaQuery.of(context).size.width / 2,
                            child: profileImg != null
                                ? SizedBox(
                                    key: key1,
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                    child: miyuList(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Form(
                          key: formKey,
                          child: TextFormField(
                            key: key2,
                            autofocus: false,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(color: Colors.black),
                            controller: hashTagController,
                            onChanged: (val) {
                              setState(() {
                                validHashTag =
                                    val.length <= 18 && !emptyStrChecker(val);
                              });
                            },
                            validator: (val) {
                              return val.length > 18
                                  ? 'Maximum length 18'
                                  : emptyStrChecker(val)
                                      ? 'Please enter a hashTag'
                                      : null;
                            },
                            decoration: hashTagFromDec(
                                hashTagController.text.length, validHashTag),
                          )),
                      Column(
                        key: key3,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.timer,
                                color: Colors.orange,
                                size: 22.5,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text('24 hrs',
                                  style: GoogleFonts.varelaRound(
                                      color: Colors.orange,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(
                                width: 5,
                              ),
                              Switch(
                                value: oneDay,
                                onChanged: (value) {
                                  setState(() {
                                    oneDay = value;
                                  });
                                },
                                activeTrackColor: Colors.orangeAccent,
                                activeColor: Colors.orange,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Image.asset(
                                  'assets/icon/icons8-anonymous-mask-50.png',
                                  scale: 2.5),
                              const SizedBox(
                                width: 10,
                              ),
                              Text('Anonymity',
                                  style: GoogleFonts.varelaRound(
                                      color: Colors.black,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(
                                width: 5,
                              ),
                              Switch(
                                value: anon,
                                onChanged: (value) {
                                  setState(() {
                                    anon = value;
                                  });
                                },
                                activeTrackColor: Colors.black54,
                                activeColor: Colors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        key: key4,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          RadioListTile(
                            activeColor: Colors.orange,
                            value: 1,
                            groupValue: state,
                            title: const Text(
                              'Public',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onChanged: (T) {
                              setState(() {
                                state = T;
                              });
                            },
                          ),
                          RadioListTile(
                            activeColor: Colors.orange,
                            value: 2,
                            groupValue: state,
                            title: const Text(
                              'Private',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onChanged: (T) {
                              setState(() {
                                state = T;
                              });
                            },
                          ),
                          RadioListTile(
                            activeColor: Colors.orange,
                            value: 3,
                            groupValue: state,
                            title: Text(
                              'Invisible'.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onChanged: (T) {
                              setState(() {
                                state = T;
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        key: key5,
                        children: [
                          Slider(
                            activeColor: Colors.orange,
                            value: groupCapacity,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            onChanged: (newCapacity) {
                              setState(() {
                                groupCapacity = newCapacity;
                              });
                            },
                            label: '$groupCapacity',
                          ),
                          Text('Circle Limit (50)',
                              style: GoogleFonts.varelaRound(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                                side: const BorderSide(color: Colors.orange)),
                          ),
                        ),
                        onPressed: () async {
                          if (!creating) {
                            if (formKey.currentState.validate()) {
                              if (state == 1) {
                                tags = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddTagOnCreateDialog();
                                    });
                                if (tags != null) {
                                  createChatAndStartConvo();
                                }
                              } else {
                                createChatAndStartConvo();
                              }
                            }
                          }
                        },
                        child: Text('Create Circle',
                            style: GoogleFonts.varelaRound(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              creating
                  ? screenLoadingIndicator(context)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget miyuList() {
    return PageView.builder(
        itemCount: groupMIYUs.length,
        controller: controller,
        onPageChanged: (val) {
          setState(() {
            profileImg = groupMIYUs[val];
          });
        },
        itemBuilder: (context, index) {
          return miyuDisplay(groupMIYUs, index);
        });
  }
}
