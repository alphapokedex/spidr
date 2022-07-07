import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/newFileUpload.dart';
import 'package:spidr_app/views/docViewScreen.dart';
import 'package:spidr_app/views/sendSnippetDialog.dart';
import 'package:spidr_app/widgets/dynamicStackItem.dart';
import 'package:spidr_app/widgets/mediaAndFilePicker.dart';
import 'package:spidr_app/widgets/mediaGalleryWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'mediaPreview.dart';

class PreviewScreen extends StatefulWidget {
  final String filePath;
  final bool vidOrAud;
  final bool tagPublic;
  final String personalChatId;
  final bool friend;
  final String contactId;
  final String groupChatId;

  final File file;
  final String audioName;
  final String fileName;
  final bool edit;
  final String caption;
  final String link;
  final List<DynamicStackItem> gifs;

  final List<SelectedFile> selMedia;
  final bool mature;

  const PreviewScreen({
    this.filePath,
    this.vidOrAud,
    this.tagPublic,
    this.personalChatId,
    this.friend,
    this.contactId,
    this.groupChatId,
    this.file,
    this.audioName,
    this.fileName,
    this.edit = false,
    this.caption,
    this.link,
    this.gifs,
    this.selMedia,
    this.mature = false,
  });

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with WidgetsBindingObserver {
  File imgFile;
  final formKey = GlobalKey<FormState>();
  TextEditingController captionEditingController = TextEditingController();
  TextEditingController linkEditingController = TextEditingController();

  // int numOfGroups = 0;
  // int numOfFriends = 0;

  bool addCaption = false;
  bool attachLink = false;

  bool validCaption = false;
  bool validLink = false;

  List<DynamicStackItem> gifyStickers = [];
  List mediaList = [];

  bool loading = false;
  bool mature = false;
  bool openKeyBoard = false;
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  bool _seen = false;

  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();
  GlobalKey key3 = GlobalKey();
  GlobalKey key4 = GlobalKey();

  sendMediaToChats() {
    if (widget.selMedia != null) {
      mediaListSendToChats();
    } else {
      mediaSendToChat();
    }
    Navigator.of(context).pop();
  }

  tagPublic() async {
    bool sent;
    // if(numOfFriends > 0 || numOfGroups > 0){
    //   sent = await showDialog(
    //       context: context,
    //       builder: (BuildContext context){
    //         return SendMediaDialog(
    //           mediaList: widget.selMedia != null ? mediaList : null,
    //           // mediaList: widget.selMedia != null ? conMediaList(widget.selMedia) : null,
    //           mediaPath: widget.file != null ? widget.file.path : widget.filePath != null ? widget.filePath : null,
    //           caption: captionEditingController.text,
    //           gifs: conGifMap(gifyStickers),
    //           video: widget.vidOrAud,
    //         );
    //       }
    //   );
    // }else{
    sent = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SendSnippetDialog(
            mediaList: widget.selMedia != null ? mediaList : null,
            mediaPath: widget.file != null ? widget.file.path : widget.filePath,
            caption: captionEditingController.text,
            link: linkEditingController.text,
            gifs: conGifMap(gifyStickers),
            video: widget.vidOrAud,
            mature: mature,
          );
        });
    // }

    if (sent != null && sent) Navigator.of(context).pop();
    return sent != null && sent;
  }

  // getUserInfo() async{
  //   QuerySnapshot groupQS = await DatabaseMethods().userCollection.doc(Constants.myUserId).collection('groups').get();
  //   numOfGroups = groupQS.docs.length;
  //   QuerySnapshot friendQS = await DatabaseMethods().userCollection.doc(Constants.myUserId).collection('friends').get();
  //   numOfFriends = friendQS.docs.length;
  // }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    return WillPopScope(
      onWillPop: () async {
        if (widget.edit != null && widget.edit) {
          String caption =
              validCaption ? captionEditingController.text : widget.caption;
          String link = validLink ? linkEditingController.text : widget.link;
          Navigator.pop(context, [caption, link, gifyStickers, mature]);
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar:
            widget.audioName == null && widget.fileName == null,
        appBar: AppBar(
          leading: BackButton(
              color: widget.audioName == null && widget.fileName == null
                  ? Colors.white
                  : Colors.black),
          backgroundColor: widget.audioName == null && widget.fileName == null
              ? Colors.transparent
              : Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: widget.fileName == null
                        ? SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: widget.selMedia != null
                                ? MediaGalleryTile(
                                    story: true,
                                    startIndex: 0,
                                    mediaGallery: mediaList,
                                    height: MediaQuery.of(context).size.height,
                                    autoPlay: false,
                                  )
                                : widget.vidOrAud
                                    ? VideoAudioFilePreview(
                                        filePath: widget.filePath,
                                        videoFile: widget.file,
                                        audioName: widget.audioName,
                                        fullScreen: true,
                                        play: true,
                                      )
                                    : ImageFilePreview(
                                        filePath: widget.filePath,
                                        imgFile: widget.file,
                                        fullScreen: true,
                                      ))
                        : GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DocViewScreen(
                                          file: widget.file,
                                          fileName: widget.fileName)));
                            },
                            child: DocDisplay(
                                fileName: widget.fileName, fullScreen: true))),

                widget.selMedia == null
                    ? Stack(children: gifyStickers)
                    : const SizedBox.shrink(),

                Form(
                  key: formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        addCaption
                            ? TextFormField(
                                autofocus: true,
                                minLines: 1,
                                maxLines: 3,
                                onChanged: (val) {
                                  setState(() {
                                    validCaption = val.length <= 300 &&
                                        !emptyStrChecker(val);
                                  });
                                },
                                validator: (val) {
                                  return emptyStrChecker(val)
                                      ? 'try typing in something'
                                      : val.length > 300
                                          ? 'sorry, caption > 300 characters'
                                          : null;
                                },
                                controller: captionEditingController,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                                decoration: previewInputDec(
                                    hintText: 'ADD A CAPTION',
                                    valid: validCaption,
                                    textEtController: captionEditingController,
                                    maxLength: 300,
                                    icon: Icons.text_fields_rounded,
                                    fillColor: Colors.white54,
                                    fontColor: Colors.black,
                                    outlineColor: Colors.orange,
                                    borderSide: BorderSide.none),
                              )
                            : const SizedBox.shrink(),
                        attachLink
                            ? TextFormField(
                                autofocus: true,
                                minLines: 1,
                                maxLines: 1,
                                onChanged: (val) {
                                  setState(() {
                                    validLink = urlRegExp.hasMatch(val);
                                  });
                                },
                                validator: (val) {
                                  return !urlRegExp.hasMatch(val)
                                      ? 'invalid url'
                                      : null;
                                },
                                controller: linkEditingController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                decoration: previewInputDec(
                                    hintText: 'ATTACH A LINK',
                                    valid: validLink,
                                    textEtController: linkEditingController,
                                    icon: platform == TargetPlatform.android
                                        ? Icons.link_rounded
                                        : CupertinoIcons.link,
                                    fillColor: Colors.black54,
                                    fontColor: Colors.white,
                                    outlineColor: Colors.orange,
                                    borderSide: BorderSide.none),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 13.5, bottom: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      widget.tagPublic
                          ? SizedBox(
                              width: 90,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '24 hrs',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      widget.selMedia == null &&
                              widget.audioName == null &&
                              widget.fileName == null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Switch(
                                  value: mature,
                                  onChanged: (val) {
                                    setState(() {
                                      mature = val;
                                    });
                                  },
                                  activeTrackColor: Colors.orangeAccent,
                                  activeColor: Colors.orange,
                                ),
                                Text(
                                  'sensitive content?',
                                  style: GoogleFonts.varelaRound(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
                // loading ?
                // screenLoadingIndicator(context) :
                // SizedBox.shrink(),
              ],
            )),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            !openKeyBoard && widget.selMedia == null
                ? SizedBox(
                    height: 36,
                    width: 36,
                    key: key1,
                    child: FloatingActionButton(
                      heroTag: 'cap',
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.text_fields_rounded,
                          size: 27, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          addCaption = !addCaption;
                        });
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            SizedBox(height: widget.selMedia == null ? 10 : 0),
            !openKeyBoard && widget.selMedia == null
                ? SizedBox(
                    height: 36,
                    width: 36,
                    child: FloatingActionButton(
                      heroTag: 'gif',
                      key: key2,
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.gif_rounded,
                          size: 36, color: Colors.white),
                      onPressed: () async {
                        GiphyGif gif = await GiphyGet.getGif(
                            context: context,
                            apiKey: Constants.giphyAPIKey,
                            tabColor: Colors.orange);
                        if (gif != null) {
                          if (gif.images.original.webp != null) {
                            setState(() {
                              gifyStickers.add(
                                  DynamicStackItem(gif.images.original.webp));
                            });
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Sorry, this gif is corrupted',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.SNACKBAR,
                                timeInSecForIosWeb: 3,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 14.0);
                          }
                        }
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            SizedBox(height: widget.selMedia == null ? 10 : 0),
            !openKeyBoard && widget.selMedia == null
                ? SizedBox(
                    height: 36,
                    width: 36,
                    child: FloatingActionButton(
                      heroTag: 'link',
                      key: key3,
                      backgroundColor: Colors.orange,
                      child: Icon(
                          platform == TargetPlatform.android
                              ? Icons.link_rounded
                              : CupertinoIcons.link,
                          size: 27,
                          color: Colors.white),
                      onPressed: () {
                        setState(() {
                          attachLink = !attachLink;
                        });
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            SizedBox(height: widget.selMedia == null ? 10 : 0),
            !widget.edit
                ? GestureDetector(
                    key: key4,
                    onTap: () async {
                      if (formKey.currentState.validate() && !loading) {
                        setState(() {
                          loading = true;
                        });
                        if (widget.tagPublic) {
                          bool sent = await tagPublic();
                          if (sent) {
                            Navigator.of(context).pop();
                          }
                        } else {
                          await sendMediaToChats();
                          Navigator.of(context).pop();
                        }

                        setState(() {
                          loading = false;
                        });
                      }
                    },
                    child: mediaSendBtt(
                        icon: widget.tagPublic ? Icons.tag : Icons.send_rounded,
                        labelColor: Colors.white,
                        off: false,
                        text: widget.tagPublic ? 'Send to:' : 'Send to:'),
                  )
                : const SizedBox.shrink(),
          ],
        ),
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getSeen().then((seen) {
      //calling setState will refresh your build method.
      setState(() {
        _seen = seen;
      });
    });
    Future.delayed(const Duration(milliseconds: 100), showTutorial);
    WidgetsBinding.instance.addObserver(this);

    if (widget.selMedia != null) mediaList = conMediaList(widget.selMedia);

    if (widget.filePath != null) imgFile = File(widget.filePath);

    if (widget.edit != null && widget.edit) {
      if (widget.caption.isNotEmpty) {
        captionEditingController.text = widget.caption;
        addCaption = true;
        validCaption =
            widget.caption.length <= 300 && !emptyStrChecker(widget.caption);
      }
      if (widget.link.isNotEmpty) {
        linkEditingController.text = widget.link;
        attachLink = true;
        validLink = urlRegExp.hasMatch(widget.link);
      }
      if (widget.gifs.isNotEmpty) gifyStickers = widget.gifs;
      mature = widget.mature;
    }
    setState(() {});
  }

  getSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool('_seen1' ?? false);
    return _seen;
  }

  markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_seen1', true);
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
        onFinish: () {},
        onClickTarget: (target) {},
        onSkip: () {},
        onClickOverlay: (target) {},
      )..show();
    }
  }

  void initTargets() {
    targets.add(
      TargetFocus(
        identify: 'Caption Button',
        keyTarget: key1,
        color: Colors.deepOrangeAccent,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Add A Caption !',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Add some more life to your broadcast by sending it with a caption ',
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
      identify: 'GIF Button',
      keyTarget: key2,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'GIF Button',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    "Tap this to add GIF's to your broadcasts!",
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
      identify: 'URL Button',
      keyTarget: key3,
      color: Colors.orange,
      contents: [
        TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'URL Button',
                      style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                    ),
                  ),
                  Text(
                    'Tap this to attach a link to your broadcasts!',
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
    targets.add(
      TargetFocus(
        identify: 'Hashtag Button',
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
                    'Tag your Broadcast',
                    style: GoogleFonts.varelaRound(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Tap this to choose who gets to see your masterpiece !',
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

  mediaSendToChat() {
    DateTime now = DateTime.now();
    int time = now.microsecondsSinceEpoch;

    Map imgObj = {
      'imgPath': widget.filePath ?? widget.file.path,
      'imgName': widget.vidOrAud ? '$time.mp4' : '$time.jpeg',
      'caption': captionEditingController.text,
      'gifs': conGifMap(gifyStickers),
      'mature': mature,
      'link': linkEditingController.text
    };

    fileUploadToChats(
      file: widget.file ?? File(widget.filePath),
      personalChatId: widget.personalChatId,
      contactId: widget.contactId,
      friend: widget.friend,
      groupChatId: widget.groupChatId,
      imgObj: imgObj,
      time: time,
    );
  }

  mediaListSendToChats() {
    DateTime now = DateTime.now();
    fileUploadToChats(
      file: mediaList.length == 1 ? File(mediaList[0]['imgPath']) : null,
      personalChatId: widget.personalChatId,
      contactId: widget.contactId,
      friend: widget.friend,
      groupChatId: widget.groupChatId,
      imgObj: mediaList.length == 1 ? mediaList[0] : null,
      mediaGallery: mediaList.length > 1 ? mediaList : null,
      time: now.microsecondsSinceEpoch,
    );
  }
}
