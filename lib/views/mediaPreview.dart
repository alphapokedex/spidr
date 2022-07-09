import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:spidr_app/helper/globals.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:video_player/video_player.dart';

Widget thumbnailPreview(String assetImg) {
  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(assetImg),
        fit: BoxFit.cover,
      ),
    ),
  );
}

Widget auxiliaryDisplay(
    {BuildContext context,
    List gifs,
    String caption,
    String link,
    double div = 1.0,
    int numOfLines,
    bool displayGifs = false,
    bool displayLink = true,
    double topPadding = 9.0}) {
  return Stack(
    children: [
      gifs != null && gifs.isNotEmpty
          ? displayGifs
              ? Stack(
                  children:
                      gifs.map((e) => Image.network(e['gifUrl'])).toList(),
                )
              : gifIndicator()
          : const SizedBox.shrink(),
      link != null && link.isNotEmpty
          ? linkIndicator(
              context: context,
              link: link,
              displayLink: displayLink,
              topPadding: topPadding)
          : const SizedBox.shrink(),
      caption != null && caption.isNotEmpty
          ? mediaCaption(context, caption, div, numOfLines)
          : const SizedBox.shrink(),
    ],
  );
}

class ImageFilePreview extends StatelessWidget {
  final String filePath;
  final File imgFile;
  final bool fullScreen;
  final List gifs;
  final String caption;
  final String link;
  final double div;
  final int numOfLines;
  final bool displayGifs;
  final bool displayLink;
  final double topPadding;

  const ImageFilePreview(
      {this.filePath,
      this.imgFile,
      this.fullScreen,
      this.gifs,
      this.caption,
      this.link,
      this.div = 1.0,
      this.numOfLines,
      this.displayGifs = false,
      this.displayLink = true,
      this.topPadding = 9.0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.file(
              filePath != null ? File(filePath) : imgFile,
              fit: fullScreen ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace stackTrace) {
                return Image.asset('assets/images/imageLoading.png',
                    fit: BoxFit.cover);
              },
            )),
        auxiliaryDisplay(
            context: context,
            gifs: gifs,
            caption: caption,
            link: link,
            div: div,
            numOfLines: numOfLines,
            displayGifs: displayGifs,
            displayLink: displayLink,
            topPadding: topPadding)
      ],
    );
  }
}

class ImageUrlPreview extends StatelessWidget {
  final String fileURL;
  final List gifs;
  final String caption;
  final String link;
  final double div;
  final int numOfLines;
  final bool fullScreen;
  final bool displayGifs;
  final bool displayLink;
  final String heroTag;
  final BoxFit boxFit;
  final double topPadding;

  const ImageUrlPreview(
      {this.fileURL,
      this.gifs,
      this.caption,
      this.link,
      this.div = 1.0,
      this.numOfLines,
      this.fullScreen = false,
      this.displayGifs = false,
      this.displayLink = true,
      this.heroTag,
      this.boxFit = BoxFit.cover,
      this.topPadding = 9.0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        !fullScreen
            ? SizedBox.expand(
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/imageLoading.png',
                  image: fileURL,
                  imageScale: 2,
                  fit: boxFit,
                  fadeInDuration: const Duration(milliseconds: 1),
                ),
              )
            : PhotoView(
                loadingBuilder: (context, event) => SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.asset(
                    'assets/images/imageLoading.png',
                    fit: BoxFit.cover,
                  ),
                ),
                imageProvider: NetworkImage(fileURL),
                heroAttributes: heroTag != null
                    ? PhotoViewHeroAttributes(tag: heroTag)
                    : null,
              ),
        auxiliaryDisplay(
            context: context,
            gifs: gifs,
            caption: caption,
            link: link,
            div: div,
            numOfLines: numOfLines,
            displayGifs: displayGifs,
            displayLink: displayLink,
            topPadding: topPadding)
      ],
    );
  }
}

class VideoAudioFilePreview extends StatefulWidget {
  final String filePath;
  final File videoFile;
  final String audioName;
  final bool fullScreen;
  final bool play;

  final List gifs;
  final String caption;
  final String link;
  final double div;
  final int numOfLines;
  final bool displayGifs;
  final bool displayLink;
  final double topPadding;

  const VideoAudioFilePreview(
      {this.filePath,
      this.videoFile,
      this.audioName,
      this.fullScreen,
      this.play,
      this.gifs,
      this.caption,
      this.link,
      this.div = 1.0,
      this.numOfLines,
      this.displayGifs = false,
      this.displayLink = true,
      this.topPadding = 9.0});

  @override
  _VideoAudioFilePreviewState createState() => _VideoAudioFilePreviewState();
}

class _VideoAudioFilePreviewState extends State<VideoAudioFilePreview> {
  VideoPlayerController _controller;

  @override
  void initState() {
    _controller = VideoPlayerController.file(
      widget.filePath != null ? File(widget.filePath) : widget.videoFile,
    );
    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((_) {
      if (widget.play) _controller.play();
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: Stack(
          children: [
            _controller.value.isInitialized
                ? SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: widget.audioName == null
                        ? FittedBox(
                            fit: widget.fullScreen != null && !widget.fullScreen
                                ? BoxFit.cover
                                : BoxFit.contain,
                            child: SizedBox(
                                width: _controller.value.size?.width ?? 0,
                                height: _controller.value.size?.height ?? 0,
                                child: VideoPlayer(_controller)),
                          )
                        : filePreview(context, 'assets/images/audiofile.png',
                            widget.audioName, widget.fullScreen),
                  )
                : widget.audioName == null
                    ? thumbnailPreview('assets/images/videofile.png')
                    : const SizedBox.shrink(),
            auxiliaryDisplay(
                context: context,
                gifs: widget.gifs,
                caption: widget.caption,
                link: widget.link,
                div: widget.div,
                numOfLines: widget.numOfLines,
                displayGifs: widget.displayGifs,
                displayLink: widget.displayLink,
                topPadding: widget.topPadding)
          ],
        ));
  }
}

class VideoAudioUrlPreview extends StatefulWidget {
  final String fileURL;
  final String audioName;
  final bool play;
  final bool video;
  final bool fullScreen;
  final Alignment muteBttAlign;
  final EdgeInsets muteBttPadding;

  final List gifs;
  final String caption;
  final String link;
  final double div;
  final int numOfLines;
  final bool displayGifs;
  final bool displayLink;
  final double topPadding;

  const VideoAudioUrlPreview(
      {this.fileURL,
      this.play,
      this.video,
      this.audioName,
      this.fullScreen,
      this.muteBttAlign,
      this.muteBttPadding,
      this.gifs,
      this.caption,
      this.link,
      this.div = 1.0,
      this.numOfLines,
      this.displayGifs = false,
      this.displayLink = true,
      this.topPadding = 9.0});
  @override
  _VideoAudioUrlPreviewState createState() => _VideoAudioUrlPreviewState();
}

class _VideoAudioUrlPreviewState extends State<VideoAudioUrlPreview>
    with TickerProviderStateMixin {
  VideoPlayerController _controller;
  bool isMuted = Globals.isMuted;
  bool isPaused = false;
  String fileURL;
  String audioName = '';

  bool init = true;

  setUpPlayer() {
    if (mounted) {
      if (!widget.video) {
        setState(() {
          audioName = widget.audioName;
        });
      }

      _controller = VideoPlayerController.network(fileURL);
      _controller.addListener(() {
        setState(() {});
      });
      _controller.setVolume(isMuted ? 0.0 : 100.0);
      _controller.setLooping(true);
      _controller.initialize().then((_) {
        // if(widget.play && ModalRoute.of(context).isCurrent) _controller.play();
        init = false;
        playToggle();
      });
    }
  }

  playToggle() {
    if (!widget.play || !ModalRoute.of(context).isCurrent) {
      _controller.pause();
    } else if (!init && widget.play && ModalRoute.of(context).isCurrent) {
      _controller.play();
    }
  }

  @override
  void didChangeDependencies() {
    playToggle();
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant VideoAudioUrlPreview oldWidget) {
    // TODO: implement didUpdateWidget
    playToggle();
    if (fileURL != widget.fileURL) {
      fileURL = widget.fileURL;
      setUpPlayer();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    fileURL = widget.fileURL;
    setUpPlayer();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleMute() {
    setState(() {
      _controller.setVolume(isMuted ? 100.0 : 0.0);
      isMuted = !isMuted;
    });
    Globals.isMuted = !Globals.isMuted;
  }

  void togglePause() {
    setState(() {
      isPaused ? _controller.play() : _controller.pause();
      isPaused = !isPaused;
    });
  }

  Widget muteButton() {
    return Padding(
      padding: widget.muteBttPadding ?? const EdgeInsets.all(9.0),
      child: Align(
        alignment: widget.muteBttAlign,
        child: GestureDetector(
          onTap: toggleMute,
          child: SizedBox(
            child: Container(
              margin: const EdgeInsets.all(4.5),
              padding: const EdgeInsets.all(9.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                // color:  Colors.orange.withOpacity(0.5)
              ),
              child: Icon(isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 25, color: Colors.orange),
            ),
          ),
        ),
      ),
    );
  }

  Widget vidAudDisplay() {
    return SizedBox.expand(
      child: !widget.video
          ? filePreview(context, 'assets/images/audiofile.png',
              widget.audioName, widget.fullScreen)
          : FittedBox(
              fit: !widget.fullScreen ? BoxFit.cover : BoxFit.contain,
              child: SizedBox(
                  width: _controller.value.size?.width ?? 0,
                  height: _controller.value.size?.height ?? 0,
                  child: VideoPlayer(_controller)),
            ),
    );
  }

  Widget pauseButton() {
    return GestureDetector(
      onTap: togglePause,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50), color: Colors.white),
        child: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause,
            size: 45, color: Colors.orange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            children: [
              _controller.value.isInitialized
                  ? vidAudDisplay()
                  : thumbnailPreview(widget.video
                      ? 'assets/images/videofile.png'
                      : 'assets/images/audiofile.png'),
              auxiliaryDisplay(
                  context: context,
                  gifs: widget.gifs,
                  caption: widget.caption,
                  link: widget.link,
                  div: widget.div,
                  numOfLines: widget.numOfLines,
                  displayGifs: widget.displayGifs,
                  displayLink: widget.displayLink,
                  topPadding: widget.topPadding)
            ],
          ),

          !widget.play
              ? const Icon(
                  Icons.play_circle_fill,
                  size: 36,
                  color: Colors.orange,
                )
              : const SizedBox.shrink(),

          widget.play ? muteButton() : const SizedBox.shrink(),

          // !widget.video && widget.play ?
          // pauseButton() :
          // SizedBox.shrink(),
        ],
      ),
    );
  }
}
