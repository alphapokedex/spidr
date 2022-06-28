import  'package:flutter/material.dart';
import  'package:spidr_app/decorations/widgetDecorations.dart';
import  'package:spidr_app/helper/constants.dart';
import  'package:spidr_app/services/database.dart';
import  'package:spidr_app/widgets/mediaGalleryWidgets.dart';
import  'package:spidr_app/widgets/mediaInfoWidgets.dart';
import  'package:spidr_app/widgets/widget.dart';

class BackPackScreen extends StatefulWidget {
  // final ScrollController scrollController;
  const BackPackScreen(
      // this.scrollController
      );
  @override
  _BackPackScreenState createState() => _BackPackScreenState();
}

class _BackPackScreenState extends State<BackPackScreen> {
  Stream storyStream;
  Stream mediaStream;
  Stream audioStream;
  Stream pdfStream;

  List<GroupIconWithId> mdGroups = [];
  List<GroupIconWithId> adGroups = [];
  List<GroupIconWithId> pdfGroups = [];

  bool expandMd = false;
  bool expandAd = false;
  bool expandPDF = false;

  constructGroupList() async {
    List<List<String>> groupIds =
        await DatabaseMethods(uid: Constants.myUserId).constructGroupIdLists();
    setState(() {
      mdGroups = groupIds[0].map((id) => GroupIconWithId(id)).toList();
      adGroups = groupIds[1].map((id) => GroupIconWithId(id)).toList();
      pdfGroups = groupIds[2].map((id) => GroupIconWithId(id)).toList();
    });
  }

  Widget noItem(String noItemsMsg) {
    return Center(
      child: Text(
        noItemsMsg,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget groupItemList(snapshot, String noItemsMsg) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2.5,
      child: snapshot.hasData
          ? snapshot.data.docs.length > 0
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    String groupId =
                        snapshot.data.docs[index].data()["groupId"];
                    String messageId = snapshot.data.docs[index].id;
                    String senderId =
                        snapshot.data.docs[index].data()["senderId"];
                    Map fileObj = snapshot.data.docs[index].data()["fileObj"];
                    Map imgObj = snapshot.data.docs[index].data()["imgObj"];
                    List mediaGallery =
                        snapshot.data.docs[index].data()["mediaGallery"];
                    bool anon = snapshot.data.docs[index].data()["anon"];

                    return !Constants.myBlockList.contains(senderId)
                        ? BackPackGroupItem(
                            imgObj: imgObj,
                            fileObj: fileObj,
                            mediaGallery: mediaGallery,
                            senderId: senderId,
                            groupId: groupId,
                            messageId: messageId,
                            anon: anon,
                          )
                        : const SizedBox.shrink();
                  })
              : noItem(noItemsMsg)
          : sectionLoadingIndicator(),
    );
  }

  filterSavedMedia(String groupId) {
    setState(() {
      mediaStream =
          DatabaseMethods(uid: Constants.myUserId).filterSavedMedia(groupId);
    });
  }

  getSavedMedia() {
    setState(() {
      mediaStream = DatabaseMethods(uid: Constants.myUserId).getSavedMedia();
    });
  }

  filterSavedAudios(String groupId) {
    setState(() {
      audioStream =
          DatabaseMethods(uid: Constants.myUserId).filterSavedAudios(groupId);
    });
  }

  getSavedAudios() {
    setState(() {
      audioStream = DatabaseMethods(uid: Constants.myUserId).getSavedAudios();
    });
  }

  filterSavedPDFs(String groupId) {
    setState(() {
      pdfStream =
          DatabaseMethods(uid: Constants.myUserId).filterSavedPDFs(groupId);
    });
  }

  getSavedPDFs() {
    setState(() {
      pdfStream = DatabaseMethods(uid: Constants.myUserId).getSavedPDFs();
    });
  }

  Widget savedMediaList() {
    return StreamBuilder(
        stream: mediaStream,
        builder: (context, snapshot) {
          return groupItemList(snapshot, "No saved media");
        });
  }

  Widget savedAudioList() {
    return StreamBuilder(
        stream: audioStream,
        builder: (context, snapshot) {
          return groupItemList(snapshot, "No saved audios");
        });
  }

  Widget savedPDFList() {
    return StreamBuilder(
        stream: pdfStream,
        builder: (context, snapshot) {
          return groupItemList(snapshot, "No saved PDFs");
        });
  }

  @override
  void initState() {
    // getSavedStories();
    getSavedMedia();
    getSavedAudios();
    getSavedPDFs();
    constructGroupList();
    // constructUserList();
    super.initState();
  }

  Widget sectLabWithGroups(
      String label, List groups, Function filter, Function getAll) {
    bool media = label == "Media";
    bool audio = label == "Audio";
    bool pdf = label == "PDF";
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          sectionLabel(label, Colors.black, Colors.white),
          media && expandMd || audio && expandAd || pdf && expandPDF
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_right_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    getAll();
                    setState(() {
                      expandMd = media ? false : expandMd;
                      expandAd = audio ? false : expandAd;
                      expandPDF = pdf ? false : expandPDF;
                    });
                  },
                )
              : const SizedBox.shrink(),
          media && expandMd || audio && expandAd || pdf && expandPDF
              ? SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                            onTap: () {
                              filter(groupId: groups[index].groupId);
                            },
                            child: groups[index]);
                      }))
              : const SizedBox.shrink(),
          media && !expandMd || audio && !expandAd || pdf && !expandPDF
              ? const Spacer()
              : const SizedBox.shrink(),
          media && !expandMd && mdGroups.isNotEmpty ||
                  audio && !expandAd && adGroups.isNotEmpty ||
                  pdf && !expandPDF && pdfGroups.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      expandMd = media ? true : expandMd;
                      expandAd = audio ? true : expandAd;
                      expandPDF = pdf ? true : expandPDF;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: RichText(
                      text: const TextSpan(children: [
                        WidgetSpan(
                          child: Icon(
                            Icons.arrow_left_rounded,
                            size: 15,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                            text: " All",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600))
                      ]),
                    ),
                  ),
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: const Icon(Icons.backpack_rounded),
          elevation: 0.0,
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectLabWithGroups(
                  "Media", mdGroups, filterSavedMedia, getSavedMedia),
              savedMediaList(),
              sectLabWithGroups(
                  "Audio", adGroups, filterSavedAudios, getSavedAudios),
              savedAudioList(),
              sectLabWithGroups(
                  "PDF", pdfGroups, filterSavedPDFs, getSavedPDFs),
              savedPDFList()
            ],
          ),
        ));

    // Container(
    // padding: EdgeInsets.only(top: height*0.065, right: 10, left: 10),
    // child: Column(
    //     children: [
    //       Icon(Icons.backpack_rounded, color: Colors.white,),
    //       Divider(height: 27, thickness: 1.5, color: Colors.white, indent: width*0.1, endIndent: width*0.1,),
    //       Expanded(
    //         child: ListView(
    //           shrinkWrap: true,
    //           controller: widget.scrollController,
    //           children: [
    //             sectLabWithGroups("Media", mdGroups, filterSavedMedia, getSavedMedia),
    //             savedMediaList(),
    //             sectLabWithGroups("Audio", adGroups, filterSavedAudios, getSavedAudios),
    //             savedAudioList(),
    //             sectLabWithGroups("PDF", pdfGroups, filterSavedPDFs, getSavedPDFs),
    //             savedPDFList()
    //           ],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}

class BackPackGroupItem extends StatefulWidget {
  final Map fileObj;
  final Map imgObj;
  final List mediaGallery;
  final String senderId;
  final bool anon;
  final String groupId;
  final String messageId;

  const BackPackGroupItem(
      {this.fileObj,
      this.imgObj,
      this.mediaGallery,
      this.senderId,
      this.anon,
      this.groupId,
      this.messageId});
  @override
  _BackPackGroupItemState createState() => _BackPackGroupItemState();
}

class _BackPackGroupItemState extends State<BackPackGroupItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 1.75,
      margin: const EdgeInsets.only(bottom: 15, left: 5, right: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            SizedBox.expand(
              child: widget.mediaGallery == null
                  ? mediaAndFileDisplay(
                      context: context,
                      imgObj: widget.imgObj,
                      fileObj: widget.fileObj,
                      mediaId: widget.messageId,
                      senderId: widget.senderId,
                      groupChatId: widget.groupId,
                      play: false,
                      showInfo: true,
                      story: false,
                      anon: widget.anon,
                      div: 1.5,
                    )
                  : MediaGalleryTile(
                      mediaGallery: widget.mediaGallery,
                      groupId: widget.groupId,
                      messageId: widget.messageId,
                      senderId: widget.senderId,
                      height: MediaQuery.of(context).size.height / 2.25,
                      div: 1.5,
                      startIndex: 0,
                      story: false,
                      anon: widget.anon,
                    ),
            ),
            mediaCommentList(
                context: context, mediaId: widget.messageId, heightDiv: 0.1),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 54,
                decoration: mediaViewDec(),
                child: ListTile(
                  leading:
                      userProfile(userId: widget.senderId, anon: widget.anon),
                  title: userName(
                      userId: widget.senderId,
                      anon: widget.anon,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14),
                  trailing: GestureDetector(
                      onTap: () {
                        DatabaseMethods(uid: Constants.myUserId)
                            .removeSavedMedia(widget.messageId);
                      },
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Colors.white,
                        size: 20,
                      )),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
