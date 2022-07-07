import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/exploreMediaItem.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class CircleMediaScreen extends StatefulWidget {
  @override
  _CircleMediaScreenState createState() => _CircleMediaScreenState();
}

class _CircleMediaScreenState extends State<CircleMediaScreen> {
  PageController gcmdController = PageController();
  Stream gcMediaStr;

  String type = 'Media';

  TextEditingController searchController = TextEditingController();
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();
  GlobalKey key5 = GlobalKey();

  Widget gcMediaList() {
    return StreamBuilder(
        stream: gcMediaStr,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? snapshot.data != null && snapshot.data.hits.length > 0
                  ? PageView.builder(
                      itemCount: snapshot.data.hits.length as int,
                      scrollDirection: Axis.vertical,
                      controller: gcmdController,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> docData =
                            snapshot.data.hits[index].data;
                        String mediaId = snapshot.data.hits[index].objectID;
                        String senderId = docData['senderId'];
                        String sendBy = docData['sendBy'];
                        Map mediaObj = docData['mediaObj'];
                        List mediaGallery = docData['mediaGallery'];
                        String groupId = docData['groupId'];
                        String hashTag = docData['hashTag'];
                        List tags = docData['tags'];
                        return groupMedia(
                          mediaObj,
                          mediaGallery,
                          groupId,
                          hashTag,
                          tags,
                          senderId,
                          sendBy,
                          mediaId,
                        );
                      },
                    )
                  : Center(
                      child: Text(
                      'no ${type.toLowerCase()} available',
                      style: const TextStyle(color: Colors.orange),
                    ))
              : sectionLoadingIndicator();
        });
  }

  getGCMedia() {
    setState(() {
      gcMediaStr = DatabaseMethods()
          .getGCMedia(type: type, searchTxt: searchController.text);
    });
  }

  // fetchGCMedia(){
  //   if(mdIndices.isNotEmpty){
  //     List<DocumentSnapshot> temp = DatabaseMethods().getGCMedia(mediaQS: mediaList, mdIndices: mdIndices);
  //     gcMedia.addAll(temp.map((DocumentSnapshot e) => groupMedia(
  //         e.data()["mediaObj"],
  //         e.data()["mediaGallery"],
  //         e.data()["groupId"],
  //         e.data()["hashTag"],
  //         e.data()["tags"],
  //         e.data()["senderId"],
  //         e.data()["sendBy"],
  //         e.id,
  //       )).toList());
  //       currentPage += 1;
  //   }
  //
  //   setState(() {});
  // }

  // setUp()async{
  //   QuerySnapshot mediaQS = await DatabaseMethods().mediaCollection
  //       .orderBy("sendTime", descending: true)
  //       .get();
  //
  //   int index = 0;
  //   mediaQS.docs.forEach((DocumentSnapshot mediaDS) {
  //     if(!Constants.myBlockList.contains(mediaDS.data()["senderId"]) && !Constants.myRemovedMedia.contains(mediaDS.id)){
  //       mediaList.add(mediaDS);
  //       mdIndices.add(index);
  //       index++;
  //     }
  //   });
  //   gcMedia = [];
  //   // mdIndices = [for(int i=0; i<mediaQS.docs.length; i+=1) i];
  //   fetchGCMedia();
  // }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_discoverSeen' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_discoverSeen', true);
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
        identify: 'Media Selector',
        keyTarget: key1,
        color: Colors.deepOrangeAccent,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Circle Media Selector',
                  style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Select between Media, Audio, PDF to see Circles with those files!',
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
      ),
    );

    targets.add(TargetFocus(
      identify: 'Circle Search',
      keyTarget: key2,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Circle Search Bar',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                ),
                Text(
                  'Search for circles here to view them on the discover page',
                  style: GoogleFonts.varelaRound(
                    color: Colors.white,
                  ),
                ),
              ],
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
    // gcmdController.addListener(() {
    //   setState(() {
    //     gcCurPage = gcmdController.page;
    //   });
    // });
    getGCMedia(); // for group media
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    Future.delayed(const Duration(milliseconds: 100), showTutorial);
    // setUp();
    // gcmdController.addListener(() {
    //   if(currentPage - (gcmdController.page/Constants.maxMediaLoad) <= 0.12 ||
    //       mdIndices.length/Constants.maxMediaLoad < 1){
    //     fetchGCMedia();
    //   }
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // leading: myAvatar(),
        backgroundColor: Colors.black,
        elevation: 0.0,
        centerTitle: true,
        title:

            // Transform.scale(scale:0.7,child: Image.asset("assets/icon/dicoverTitle.png")),

            Text('Discover',
                style: platform == TargetPlatform.android
                    ? GoogleFonts.electrolize(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)
                    : GoogleFonts.electrolize(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
        actions: [snippetBtt(context, platform)],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DropdownButton(
                  key: key1,
                  value: type,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.orange,
                  ),
                  iconSize: 15,
                  elevation: 18,
                  onChanged: (val) {
                    setState(() {
                      type = val;
                    });
                    getGCMedia();
                  },
                  items: ['Media', 'Audio', 'PDF']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e,
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14))))
                      .toList(),
                ),
                SizedBox(
                  key: key2,
                  height: 30,
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: TextField(
                    onChanged: (val) {
                      getGCMedia();
                    },
                    controller: searchController,
                    style: const TextStyle(color: Colors.orange, fontSize: 14),
                    cursorColor: Colors.orange,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.orange, fontSize: 14),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orangeAccent),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orangeAccent),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orangeAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: gcMediaList(),
          )
          // gcMedia != null ? Expanded(
          //     child: gcMedia.length > 0 ?
          //     PageView.builder(
          //       scrollDirection: Axis.vertical,
          //       controller: gcmdController,
          //       itemCount: gcMedia.length,
          //       itemBuilder: (BuildContext context, int index) {
          //         return gcMedia[index];
          //       },
          //     ) : Center(child: Image.asset("assets/icon/spidrCityScene.png"))
          // ) : screenLoadingIndicator(context),
        ],
      ),
    );
  }
}

Widget groupMedia(
  Map mediaObj,
  List mediaGallery,
  String groupId,
  String hashTag,
  List tags,
  String userId,
  String username,
  String mediaId,
) {
  return StreamBuilder(
      stream: DatabaseMethods().groupChatCollection.doc(groupId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var groupDS = snapshot.data;
          String groupProfile;
          String groupState = '';
          String admin;
          bool anon;
          bool oneDay;
          int createdAt;
          bool isMember;
          bool expiredGroup = false;
          if (groupDS.data() != null &&
              (groupDS.data()['deleted'] == null ||
                  !groupDS.data()['deleted'])) {
            groupProfile = groupDS.data()['profileImg'];
            groupState = groupDS.data()['chatRoomState'];
            admin = groupDS.data()['admin'];
            anon = groupDS.data()['anon'];
            oneDay =
                groupDS.data()['oneDay'] != null && groupDS.data()['oneDay'];
            createdAt = groupDS.data()['createdAt'];
            isMember = groupDS.data()['members'].contains(Constants.myUserId);
          } else {
            expiredGroup = true;
          }
          return StreamBuilder(
              stream: DatabaseMethods().userCollection.doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data.data() != null) {
                  String userProfile = snapshot.data.data()['profileImg'];
                  int imgIndex = snapshot.data.data()['anonImg'];
                  String anonImg = userMIYUs[imgIndex];
                  bool blocked = snapshot.data.data()['blockedBy'] != null &&
                      snapshot.data
                          .data()['blockedBy']
                          .contains(Constants.myUserId);
                  return exploreMedia(
                    context: context,
                    mediaObj: mediaObj,
                    mediaGallery: mediaGallery,
                    mediaId: mediaId,
                    groupId: groupId,
                    hashTag: hashTag,
                    groupProfile: groupProfile,
                    admin: admin,
                    oneDay: oneDay,
                    createdAt: createdAt,
                    groupState: groupState,
                    userId: userId,
                    userName: username,
                    userProfile: userProfile,
                    anonProfile: anonImg,
                    anon: anon,
                    blocked: blocked,
                    isMember: isMember,
                    expiredGroup: expiredGroup,
                  );
                } else {
                  return const SizedBox.shrink();
                }
              });
        } else {
          return sectionLoadingIndicator();
        }
      });
}
