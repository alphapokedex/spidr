import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/docViewScreen.dart';
import 'package:spidr_app/views/mediaViewScreen.dart';
import 'package:spidr_app/widgets/mediaInfoWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

Widget mediaFuncColumn(
    BuildContext context,
    Map mediaObj,
    List mediaGallery,
    String senderId,
    String mediaId,
    String groupId,
    bool anon,
    String groupState,
    bool isMember,
    String hashTag) {
  Map imgObj =
      mediaObj != null && mediaObj['imgName'] != null ? mediaObj : null;
  Map fileObj =
      mediaObj != null && mediaObj['fileName'] != null ? mediaObj : null;

  return Container(
    width: MediaQuery.of(context).size.width * 0.15,
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        sendMediaBtt(
            context, senderId, mediaObj, mediaId, groupId, mediaGallery, anon),
        const SizedBox(height: 10),
        toggleSaveMediaBtt(context, senderId, imgObj, fileObj, mediaId, groupId,
            mediaGallery, anon),
        const SizedBox(height: 10),
        moreOpsMediaBtt(
            context: context,
            imgObj: imgObj,
            fileObj: fileObj,
            mediaGallery: mediaGallery,
            senderId: senderId,
            groupId: groupId,
            mediaId: mediaId,
            anon: anon,
            explore: true),
      ],
    ),
  );
}

Widget exploreMedia({
  BuildContext context,
  Map mediaObj,
  List mediaGallery,
  String mediaId,
  String groupId,
  String hashTag,
  bool isMember,
  String groupProfile,
  String admin,
  String groupState,
  bool oneDay,
  int createdAt,
  String userId,
  String userName,
  String userProfile,
  String anonProfile,
  bool blocked,
  bool anon,
  bool expiredGroup,
}) {
  return StreamBuilder(
      stream: DatabaseMethods().mediaCollection.doc(mediaId).snapshots(),
      builder: (context, snapshot) {
        bool removed = false;
        if (snapshot.hasData && snapshot.data.data() != null) {
          List notVisibleTo = snapshot.data.data()['notVisibleTo'] ?? [];
          removed = notVisibleTo.contains(Constants.myUserId);
        }
        return !removed
            ? GestureDetector(
                onTap: () {
                  if (mediaObj != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                mediaObj['fileName'] == null ||
                                        !pdfChecker(mediaObj['fileName'])
                                    ? MediaViewScreen(
                                        mediaObj: mediaObj,
                                        senderId: userId,
                                        mediaId: mediaId,
                                        showInfo: false,
                                      )
                                    : DocViewScreen(
                                        fileUrl: mediaObj['fileUrl'],
                                        fileName: mediaObj['fileName'])));
                  }
                },
                child: Container(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        mediaGallery == null
                            ? SizedBox.expand(
                                child: mediaAndFilePreview(
                                senderId: userId,
                                context: context,
                                imgObj: mediaObj['imgName'] != null
                                    ? mediaObj
                                    : null,
                                fileObj: mediaObj['fileName'] != null
                                    ? mediaObj
                                    : null,
                                muteBttAlign: Alignment.topRight,
                                play: true,
                                displayGifs: true,
                              ))
                            : MediaGalleryExplore(
                                mediaGallery,
                                userId,
                                mediaId,
                              ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.3,
                            decoration:
                                mediaGallery == null ? mediaViewDec() : null,
                            child: Column(
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      15.0, 0.0, 15.0, 5.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      mediaCommentSenderPanel(
                                          context: context,
                                          mediaId: mediaId,
                                          fillColor: Colors.white24,
                                          disabled: expiredGroup,
                                          heightDiv: 0.15,
                                          anon: anon),
                                      !expiredGroup
                                          ? mediaFuncColumn(
                                              context,
                                              mediaObj,
                                              mediaGallery,
                                              userId,
                                              mediaId,
                                              groupId,
                                              anon,
                                              groupState,
                                              isMember,
                                              hashTag)
                                          : const SizedBox.shrink()
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: !expiredGroup
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.45,
                                  child: CarouselSlider(
                                      items: [
                                        groupIcon(
                                            context,
                                            groupId,
                                            hashTag,
                                            admin,
                                            groupProfile,
                                            groupState,
                                            anon,
                                            oneDay,
                                            createdAt),
                                        userIcon(
                                            context,
                                            userId,
                                            userName,
                                            userProfile,
                                            anonProfile,
                                            anon,
                                            blocked)
                                      ],
                                      options: CarouselOptions(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.175,
                                          viewportFraction: 1.0,
                                          autoPlay: true)),
                                )
                              : Column(
                                  children: [
                                    const Icon(Icons.timer, color: Colors.grey),
                                    borderedText('Expired', Colors.grey),
                                  ],
                                ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Media has been removed',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(
                    height: 10,
                  ),
                  TextButton(
                      onPressed: () {
                        DatabaseMethods(uid: Constants.myUserId)
                            .undoRemoveMedia(mediaId);
                      },
                      child: const Text(
                        'UNDO',
                        style: TextStyle(color: Colors.blue),
                      ))
                ],
              );
      });
}

class MediaGalleryExplore extends StatefulWidget {
  final List mediaGallery;
  final String senderId;
  final String mediaId;
  const MediaGalleryExplore(
    this.mediaGallery,
    this.senderId,
    this.mediaId,
  );
  @override
  _MediaGalleryExploreState createState() => _MediaGalleryExploreState();
}

class _MediaGalleryExploreState extends State<MediaGalleryExplore> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
        items: widget.mediaGallery.map((m) {
          int index = widget.mediaGallery.indexOf(m);
          return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: mediaAndFileDisplay(
                context: context,
                imgObj: m,
                senderId: widget.senderId,
                mediaId: widget.mediaId,
                play: current == index,
                showInfo: false,
                muteBttAlign: Alignment.topRight,
                div: 1.0,
                mediaGallery: widget.mediaGallery,
                mediaIndex: index,
                displayGifs: true,
                // displayLink: true
              ));
        }).toList(),
        options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            enlargeCenterPage: true,
            initialPage: current,
            onPageChanged: (index, reason) {
              setState(() {
                current = index;
              });
            }));
  }
}
