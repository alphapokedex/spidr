import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/views/mediaViewScreen.dart';
import 'package:spidr_app/widgets/widget.dart';

class MediaGalleryTile extends StatefulWidget {
  final List mediaGallery;
  final String groupId;
  final String messageId;
  final String senderId;
  final String sendBy;
  final int profileIndex;
  final int startIndex;
  final double height;
  final double div;
  final bool story;
  final bool storyPreview;
  final bool autoPlay;
  final bool toPageView;

  final String storyId;
  final bool anon;

  final int storyIndex;
  final snapshot;

  const MediaGalleryTile({
    this.mediaGallery,
    this.groupId,
    this.messageId,
    this.senderId,
    this.sendBy,
    this.profileIndex,
    this.startIndex,
    this.height,
    this.div,
    this.story,
    this.storyPreview = false,
    this.autoPlay = false,
    this.toPageView = false,
    this.storyId,
    this.anon,
    this.storyIndex,
    this.snapshot,
  });

  @override
  _MediaGalleryTileState createState() => _MediaGalleryTileState();
}

class _MediaGalleryTileState extends State<MediaGalleryTile> {
  int current = 0;

  @override
  void initState() {
    setState(() {
      current = widget.startIndex ?? 0;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double devHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        CarouselSlider(
          items: widget.mediaGallery.map((m) {
            int index = widget.mediaGallery.indexOf(m);
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: widget.messageId != null || widget.storyId != null
                  ? SizedBox.expand(
                      child: mediaAndFileDisplay(
                          imgObj: m,
                          context: context,
                          mediaId: widget.messageId ?? widget.storyId,
                          sendBy: widget.sendBy,
                          senderId: widget.senderId,
                          play: false,
                          groupChatId: widget.groupId,
                          showInfo: true,
                          toPageView: widget.toPageView,
                          mediaGallery: widget.mediaGallery,
                          mediaIndex: index,
                          story: widget.story,
                          anon: widget.anon,
                          storySnapshot: widget.snapshot,
                          storyIndex: widget.storyIndex,
                          div: widget.profileIndex != null
                              ? widget.profileIndex % 7 == 0
                                  ? 3 / 2
                                  : 3
                              : widget.div,
                          numOfLines: 1,
                          displayLink: !widget.storyPreview),
                    )
                  : MediaDisplay(
                      video: videoChecker(m['imgName']),
                      mediaUrl: m['imgUrl'],
                      mediaPath: m['imgPath'],
                      story: widget.story,
                      caption: m["caption"],
                      link: m["link"],
                      gifyStickers: conGifWidgets(m["gifs"]),
                      mature: m['mature'] != null && m['mature'],
                      senderId: widget.senderId,
                    ),
            );
          }).toList(),
          options: CarouselOptions(
              initialPage: current,
              height: widget.profileIndex != null
                  ? widget.profileIndex % 7 == 0
                      ? devHeight / 3
                      : devHeight / 6
                  : widget.height,
              autoPlay: widget.autoPlay,
              enlargeCenterPage: false,
              enableInfiniteScroll: widget.mediaGallery.length > 1,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  current = index;
                });
              }),
        ),
        widget.mediaGallery.length > 1 && !widget.storyPreview
            ? Padding(
                padding: EdgeInsets.only(
                    top: widget.messageId == null && widget.storyId == null
                        ? MediaQuery.of(context).size.height * 0.065
                        : 7.5),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: galleryIndicator(widget.mediaGallery, current),
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}

Widget galleryIndicator(List mediaGallery, int current) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: mediaGallery.map((media) {
      int index = mediaGallery.indexOf(media);
      return Container(
        width: 9.0,
        height: 9.0,
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: current == index ? Colors.orange : Colors.grey,
        ),
      );
    }).toList(),
  );
}
