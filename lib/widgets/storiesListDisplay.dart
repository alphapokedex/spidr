import 'package:spidr_app/helper/storyFunctions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/widgets/mediaGalleryWidgets.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'package:spidr_app/helper/functions.dart';

Widget storyTile(
    {String senderId,
    String storyId,
    Map mediaObj,
    List mediaGallery,
    bool owner,
    String sender,
    bool anon,
    int sendTime,
    AsyncSnapshot storySnapshot,
    int storyIndex,
    String type,
    double height,
    double width,
    double iconSize,
    String friendId,
    String groupId,
    bool viewUser}) {
  return StreamBuilder(
      stream: DatabaseMethods()
          .userCollection
          .doc(senderId)
          .collection('stories')
          .doc(storyId)
          .snapshots(),
      builder: (context, snapshot) {
        bool seen = snapshot.hasData && snapshot.data.data() != null
            ? snapshot.data.data()['seenList'].contains(Constants.myUserId)
            : null;

        int timeElapsed = getTimeElapsed(sendTime);
        if (timeElapsed / Duration.secondsPerDay >= 1) {
          storyRemove(
              owner: owner,
              storyId: storyId,
              mediaObj: mediaObj,
              mediaGallery: mediaGallery,
              friendId: friendId,
              groupId: groupId,
              type: type,
              seen: seen);
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    timerIndicator(
                        height: height,
                        width: width,
                        timeElapsed: timeElapsed,
                        color: seen != null && !seen
                            ? Colors.orangeAccent
                            : Colors.grey,
                        strokeWidth: 2),
                    SizedBox(
                        width: height,
                        height: width,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Stack(
                              children: [
                                SizedBox.expand(
                                  child: mediaGallery == null
                                      ? mediaAndFileDisplay(
                                          context: context,
                                          imgObj: mediaObj,
                                          div: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              60,
                                          mediaId: storyId,
                                          senderId: senderId,
                                          showInfo: true,
                                          anon: anon,
                                          story: true,
                                          numOfLines: 1,
                                          storySnapshot: storySnapshot,
                                          storyIndex: storyIndex,
                                          play: false,
                                          toPageView: true,
                                          displayLink: false)
                                      : MediaGalleryTile(
                                          mediaGallery: mediaGallery,
                                          storyId: storyId,
                                          senderId: senderId,
                                          height: 60,
                                          div: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              60,
                                          startIndex: 0,
                                          story: true,
                                          storyPreview: true,
                                          autoPlay: true,
                                          anon: anon,
                                          storyIndex: storyIndex,
                                          snapshot: storySnapshot,
                                          toPageView: true,
                                        ),
                                ),
                                viewUser &&
                                        !owner &&
                                        sender == null &&
                                        (anon != null && anon)
                                    ? Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(5.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Center(
                                            child: Image.asset(
                                                'assets/icon/icons8-anonymous-mask-50.png',
                                                scale: 2.5),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
                Positioned(
                    top: height * 0.78,
                    left: width * 0.345,
                    child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(blurRadius: 5, color: Colors.white24)
                          ],
                        ),
                        child: Icon(
                          type == 'regular'
                              ? Icons.send_rounded
                              : type == 'friends'
                                  ? Icons.auto_awesome
                                  : Icons.settings_input_antenna,
                          color: Colors.orange,
                          size: iconSize,
                        )))
              ],
            ),
            sender != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(anon != null && anon ? 'Anonymous' : sender,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                        textAlign: TextAlign.center),
                  )
                : owner && !viewUser && (friendId == null && groupId == null)
                    ? GestureDetector(
                        onTap: () {
                          storyRemove(
                              owner: owner,
                              storyId: storyId,
                              mediaObj: mediaObj,
                              mediaGallery: mediaGallery,
                              type: type);
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Icon(Icons.cancel_rounded),
                        ),
                      )
                    : const SizedBox.shrink()
          ],
        );
      });
}

Widget storyList({
  AsyncSnapshot snapshot,
  double height = 105,
  double width,
  Alignment align,
  double tileHeight = 65,
  double tileWidth = 65,
  double iconSize = 22,
  String friendId,
  String groupId,
  bool singleDisplay = false,
  bool viewUser = false,
}) {
  return Container(
    height: height,
    width: width,
    alignment: align,
    child: !singleDisplay
        ? ListView.builder(
            itemCount: snapshot.data.docs.length,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              String storyId = snapshot.data.docs[index].id;
              String senderId = snapshot.data.docs[index].data()['senderId'];
              Map mediaObj = snapshot.data.docs[index].data()['mediaObj'];
              List mediaGallery =
                  snapshot.data.docs[index].data()['mediaGallery'];
              bool anon = snapshot.data.docs[index].data()['anon'];
              int sendTime = snapshot.data.docs[index].data()['sendTime'];
              String sender = snapshot.data.docs[index].data()['sender'];
              String type = snapshot.data.docs[index].data()['type'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: storyTile(
                    storyId: storyId,
                    senderId: senderId,
                    mediaObj: mediaObj,
                    mediaGallery: mediaGallery,
                    owner: senderId == Constants.myUserId,
                    sender: sender,
                    anon: anon,
                    sendTime: sendTime,
                    storySnapshot: snapshot,
                    storyIndex: index,
                    type: type,
                    height: tileHeight,
                    width: tileWidth,
                    iconSize: iconSize,
                    friendId: friendId,
                    groupId: groupId,
                    viewUser: viewUser),
              );
            })
        : Stack(
            children: [
              storyTile(
                  storyId: snapshot.data.docs[0].id,
                  senderId: snapshot.data.docs[0].data()['senderId'],
                  mediaObj: snapshot.data.docs[0].data()['mediaObj'],
                  mediaGallery: snapshot.data.docs[0].data()['mediaGallery'],
                  owner: snapshot.data.docs[0].data()['senderId'] ==
                      Constants.myUserId,
                  sender: snapshot.data.docs[0].data()['sender'],
                  anon: snapshot.data.docs[0].data()['anon'],
                  sendTime: snapshot.data.docs[0].data()['sendTime'],
                  storySnapshot: snapshot,
                  storyIndex: 0,
                  type: snapshot.data.docs[0].data()['type'],
                  height: tileHeight,
                  width: tileWidth,
                  iconSize: iconSize,
                  friendId: friendId,
                  groupId: groupId,
                  viewUser: viewUser),
              snapshot.data.docs.length > 1
                  ? const Icon(
                      Icons.dynamic_feed_rounded,
                      color: Colors.orange,
                    )
                  : const SizedBox.shrink()
            ],
          ),
  );
}

Widget storyStreamWrapper({
  Stream storyStream,
  double height = 105,
  double width,
  Alignment align,
  double tileHeight = 65,
  double tileWidth = 65,
  double iconSize = 22,
  String friendId,
  String groupId,
  bool singleDisplay = false,
  bool viewUser = false,
}) {
  return StreamBuilder(
      stream: storyStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.docs.length > 0) {
            return storyList(
                snapshot: snapshot,
                height: height,
                width: width,
                align: align,
                tileHeight: tileHeight,
                tileWidth: tileWidth,
                iconSize: iconSize,
                friendId: friendId,
                groupId: groupId,
                singleDisplay: singleDisplay,
                viewUser: viewUser);
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return const SizedBox.shrink();
        }
      });
}
