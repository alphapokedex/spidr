import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/camera.dart';
import 'package:spidr_app/views/preview.dart';
import 'package:spidr_app/widgets/bottomSheetWidgets.dart';
import 'package:spidr_app/widgets/mediaAndFilePicker.dart';
import 'package:spidr_app/widgets/widget.dart';

class AppCameraScreen extends StatefulWidget {
  final String personalChatId;
  final bool friend;
  final String contactId;
  final String groupChatId;
  static const double MAX_VIDEO_DURATION = 10; //in seconds
  static const double CAMERA_BUTTON_SIZE = 120;
  final ScrollController camScrollController;
  bool backButton = true;

  AppCameraScreen(
      {this.personalChatId,
      this.friend,
      this.contactId,
      this.groupChatId,
      this.camScrollController,
      this.backButton});

  @override
  _AppCameraScreenState createState() => _AppCameraScreenState();
}

class _AppCameraScreenState extends State<AppCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  double percentOfMaxVideoDurationRecorded = 0;
  String _recordingProgressAnimation = "Idle";
  String filepath;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  AnimationController _flashModeControlRowAnimationController;
  Animation<double> _flashModeControlRowAnimation;
  AnimationController _multiMediaModeRowAnimationController;
  Animation<double> _multiMediaModeRowAnimation;
  AnimationController _exposureModeControlRowAnimationController;
  Animation<double> _exposureModeControlRowAnimation;
  AnimationController _focusModeControlRowAnimationController;
  Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  List<SelectedFile> selMedia = [];
  int numOfSMs = 0;
  ScrollController selController = ScrollController();

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool expandOpts = false;
  bool multiMedia = false;
  bool onCapture = false;

  var adFlashIcon = Icons.flash_auto;
  var iosFlashIcon = CupertinoIcons.bolt_badge_a_fill;

  Widget cameraPreview() {
    final size = MediaQuery.of(context).size;

    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale =
        cameraController == null || !cameraController.value.isInitialized
            ? 2
            : size.aspectRatio * cameraController.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return cameraController == null || !cameraController.value.isInitialized
        ? Center(
            child: Text(
              'Loading',
              style: simpleTextStyle(),
            ),
          )
        : Listener(
            onPointerDown: (_) => _pointers++,
            onPointerUp: (_) => _pointers--,
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(
                  cameraController,
                  child: LayoutBuilder(builder:
                      (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      onTapDown: (details) =>
                          onViewFinderTap(details, constraints),
                    );
                  }),
                ),
              ),
            ),
          );
  }

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController.value.hasError) {
      debugPrint('Camera Error ${cameraController.value.errorDescription}');
    }

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget cameraToggle() {
    if (cameras == null || cameras.isEmpty) {
      return const SizedBox.shrink();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;
    return Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () {
            int newCameraIndex = selectedCameraIndex == 0 ? 1 : 0;
            CameraMethods.onSwitchCamera(cameras, newCameraIndex, initCamera);
            setState(() {
              selectedCameraIndex = newCameraIndex;
            });
          },
          icon: Icon(
            CameraMethods.getCameraLensIcons(lensDirection),
            color: Colors.white,
            size: 27,
          ),
        ));
  }

  void takePicture() async {
    if (!onCapture) {
      setState(() {
        onCapture = true;
      });

      if (multiMedia) {
        File imgFile =
            await CameraMethods.onCaptureForMulti(context, cameraController);
        if (numOfSMs < Constants.maxFileUpload && imgFile != null) {
          String uploadTo =
              widget.groupChatId == null && widget.personalChatId == null
                  ? "SNIPPET"
                  : widget.groupChatId != null
                      ? "GROUP"
                      : "PERSONAL";

          setState(() {
            selMedia.add(
                SelectedFile(file: imgFile, uploadTo: uploadTo, video: false));
            numOfSMs++;
          });
          Timer(
            const Duration(seconds: 1),
            () => selController.jumpTo(selController.position.maxScrollExtent),
          );
        }
      } else {
        await CameraMethods.onCaptureForSingle(
          context,
          cameraController,
          widget.personalChatId,
          widget.friend,
          widget.contactId,
          widget.groupChatId,
        );
      }
      setState(() {
        onCapture = false;
      });
    }
  }

  void takeVideo() async {
    if (cameraController.value.isRecordingVideo) {
      return null;
    } //only proceed if not already recording

    filepath = await CameraMethods.onCaptureVideo(context, cameraController);

    setState(() {
      _recordingProgressAnimation =
          "Demo"; //setting to the name of the animation will trigger it to start
    });

    //debugPrint('camera recording: ${cameraController.value.isRecordingVideo}');
    //debugPrint("Starting Recording to file $filepath");

    Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (timer.tick >= AppCameraScreen.MAX_VIDEO_DURATION * 100) {
        // max recording time is 7 seconds, 700 durations of 10 milliseconds = 7 seconds
        stopVideo();
      }

      if (!cameraController.value.isRecordingVideo) {
        //debugPrint('Recorded ~${timer.tick / 100} seconds of video');
        timer.cancel();
        //push preview here?
        return;
      }

      if (timer.tick % 100 == 0) {
        //debugPrint('seconds recorded: ${timer.tick / 100}');
      }
      setState(() {
        percentOfMaxVideoDurationRecorded =
            timer.tick / (AppCameraScreen.MAX_VIDEO_DURATION * 100);
      });
    });
  }

  void stopVideo() async {
    //debugPrint("STOPPING VIDEO");
    if (cameraController.value.isRecordingVideo) {
      if (multiMedia) {
        File videoFile = await CameraMethods.stopVideoForMulti(
            context, cameraController, filepath);
        if (numOfSMs < Constants.maxFileUpload && videoFile != null) {
          String uploadTo =
              widget.groupChatId == null && widget.personalChatId == null
                  ? "SNIPPET"
                  : widget.groupChatId != null
                      ? "GROUP"
                      : "PERSONAL";

          setState(() {
            selMedia.add(
                SelectedFile(file: videoFile, uploadTo: uploadTo, video: true));
            numOfSMs++;
          });

          Timer(
            const Duration(seconds: 1),
            () => selController.jumpTo(selController.position.maxScrollExtent),
          );
        }
      } else {
        CameraMethods.stopVideoForSingle(
          context,
          cameraController,
          widget.personalChatId,
          widget.friend,
          widget.contactId,
          widget.groupChatId,
        );
      }
    }
    setState(() {
      _recordingProgressAnimation =
          "Idle"; //setting to a name that does not refer to an actual animation will stop it
    });
  }

  Widget cameraControl(context) {
    return Align(
        alignment: Alignment.center,
        child: GestureDetector(
            onLongPressStart: (val) {
              takeVideo();
            },
            onLongPressEnd: (val) {
              stopVideo();
            },
            onTap: takePicture,
            child: SizedBox(
                width: AppCameraScreen.CAMERA_BUTTON_SIZE,
                height: AppCameraScreen.CAMERA_BUTTON_SIZE,
                child: FlareActor(
                    "assets/animations/loading-fanimation-sun-flare.flr",
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                    animation: _recordingProgressAnimation))));
  }

  Widget _flashModeControlRowWidget() {
    final TargetPlatform platform = Theme.of(context).platform;
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(platform == TargetPlatform.android
                  ? Icons.flash_off
                  : CupertinoIcons.bolt_slash_fill),
              color: cameraController?.value?.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.white,
              onPressed: cameraController != null
                  ? () {
                      onSetFlashModeButtonPressed(FlashMode.off);
                      _flashModeControlRowAnimationController.reverse();
                      setState(() {
                        adFlashIcon = Icons.flash_off;
                        iosFlashIcon = CupertinoIcons.bolt_slash_fill;
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: Icon(platform == TargetPlatform.android
                  ? Icons.flash_auto
                  : CupertinoIcons.bolt_badge_a_fill),
              color: cameraController?.value?.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.white,
              onPressed: cameraController != null
                  ? () {
                      onSetFlashModeButtonPressed(FlashMode.auto);
                      _flashModeControlRowAnimationController.reverse();
                      setState(() {
                        adFlashIcon = Icons.flash_auto;
                        iosFlashIcon = CupertinoIcons.bolt_badge_a_fill;
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: Icon(platform == TargetPlatform.android
                  ? Icons.flash_on
                  : CupertinoIcons.bolt_fill),
              color: cameraController?.value?.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.white,
              onPressed: cameraController != null
                  ? () {
                      onSetFlashModeButtonPressed(FlashMode.always);
                      _flashModeControlRowAnimationController.reverse();
                      setState(() {
                        adFlashIcon = Icons.flash_on;
                        iosFlashIcon = CupertinoIcons.bolt_fill;
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.highlight),
              color: cameraController?.value?.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.white,
              onPressed: cameraController != null
                  ? () {
                      onSetFlashModeButtonPressed(FlashMode.torch);
                      _flashModeControlRowAnimationController.reverse();
                      setState(() {
                        adFlashIcon = Icons.highlight;
                        iosFlashIcon = Icons.highlight;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  multiMediaSetUp() {
    // if(widget.personalChatId == null && widget.groupChatId == null){
    //   selMedia = List.from(Globals.nonSentSnippet);
    //   Globals.numOfSMs = Globals.nonSentSnippet.length;
    // }else if(widget.groupChatId != null){
    //   selMedia = List.from(Globals.nonSentGroupMedia);
    //   Globals.numOfSMs = Globals.nonSentGroupMedia.length;
    // }else{
    //   selMedia = List.from(Globals.nonSentPersonalMedia);
    //   Globals.numOfSMs = Globals.nonSentPersonalMedia.length;
    // }

    multiMedia = true;
    setState(() {});
  }

  Widget _multiMediaModeControlRowWidget() {
    final TargetPlatform platform = Theme.of(context).platform;
    return SizeTransition(
      sizeFactor: _multiMediaModeRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(Icons.photo_library_rounded,
                  color: multiMedia ? Colors.orange : Colors.white),
              onPressed: () {
                if (!multiMedia) multiMediaSetUp();
                _multiMediaModeRowAnimationController.reverse();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.photo,
                color: !multiMedia ? Colors.orange : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  multiMedia = false;
                });
                _multiMediaModeRowAnimationController.reverse();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: cameraController?.value?.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.white,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: cameraController?.value?.exposureMode == ExposureMode.locked
          ? Colors.orange
          : Colors.white,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(5),
          color: Colors.black45,
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Exposure Mode",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    style: styleAuto,
                    onPressed: cameraController != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (cameraController != null) {
                        cameraController.setExposurePoint(null);
                        showInSnackBar('Resetting exposure point');
                      }
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: cameraController != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                ],
              ),
              const Center(
                child: Text("Exposure Offset",
                    style: TextStyle(color: Colors.white)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(_minAvailableExposureOffset.toString(),
                      style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString(),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: cameraController?.value?.focusMode == FocusMode.auto
          ? Colors.orange
          : Colors.white,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: cameraController?.value?.focusMode == FocusMode.locked
          ? Colors.orange
          : Colors.white,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(5.0),
          color: Colors.black45,
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Focus Mode",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    style: styleAuto,
                    onPressed: cameraController != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (cameraController != null) {
                        cameraController.setFocusPoint(null);
                      }
                      showInSnackBar('Resetting focus point');
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: cameraController != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (cameraController == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await cameraController.setZoomLevel(_currentScale);
  }

  void onMultiSnippetModeButtonPressed() {
    if (_multiMediaModeRowAnimationController.value == 1) {
      _multiMediaModeRowAnimationController.reverse();
    } else {
      _multiMediaModeRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
      _flashModeControlRowAnimationController.reverse();
    }
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
      _multiMediaModeRowAnimationController.reverse();
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  void onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
      _multiMediaModeRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
      _multiMediaModeRowAnimationController.reverse();
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController.setFlashMode(mode);
    } on CameraException catch (e) {
      showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController.setExposureMode(mode);
    } on CameraException catch (e) {
      showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (cameraController == null) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await cameraController.setExposureOffset(offset);
    } on CameraException catch (e) {
      showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController.setFocusMode(mode);
    } on CameraException catch (e) {
      showCameraException(e);
      rethrow;
    }
  }

  void logError(String code, String message) {
    if (message != null) {
      debugPrint('Error: $code\nError Message: $message');
    } else {
      debugPrint('Error: $code');
    }
  }

  void showCameraException(CameraException e) {
    logError(e.code, e.description);
  }

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (cameraController == null) {
      return;
    }
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Widget selectedMediaList() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: numOfSMs > 0
          ? ListView.builder(
              reverse: true,
              controller: selController,
              scrollDirection: Axis.horizontal,
              itemCount: selMedia.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return !selMedia[index].deleted
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 4,
                          child: Stack(
                            children: [
                              selMedia[index],
                              Align(
                                  alignment: Alignment.topCenter,
                                  child: IconButton(
                                    icon: const Icon(Icons.cancel_rounded,
                                        color: Colors.red),
                                    onPressed: () {
                                      // delMedia.add(widget.selMedia[index]);
                                      setState(() {
                                        numOfSMs--;
                                        selMedia[index].deleted = true;
                                      });
                                    },
                                  ))
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              })
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: MediaQuery.of(context).size.width / 4,
                color: Colors.white54,
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  sendToPreview() async {
    List<SelectedFile> rdyMedia = selMedia.where((sm) => !sm.deleted).toList();
    // for(SelectedFile sm in selMedia){
    //   if(!sm.deleted){
    //     rdyMedia.add(sm);
    //   }
    // }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PreviewScreen(
                  tagPublic: widget.personalChatId == null &&
                      widget.groupChatId == null,
                  selMedia: rdyMedia,
                  personalChatId: widget.personalChatId,
                  friend: widget.friend,
                  contactId: widget.contactId,
                  groupChatId: widget.groupChatId,
                )));
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final size = MediaQuery.of(context).size;
    final scale = 1 /
        (cameraController == null || !cameraController.value.isInitialized
            ? 2
            : cameraController.value.aspectRatio * size.aspectRatio);
    return GestureDetector(
      onDoubleTap: () {
        _flashModeControlRowAnimationController.reverse();
        _multiMediaModeRowAnimationController.reverse();
        _exposureModeControlRowAnimationController.reverse();
        _focusModeControlRowAnimationController.reverse();
      },
      child: Stack(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              widget.backButton
                  ? SingleChildScrollView(
                      controller: widget.camScrollController,
                      child: Container(
                        color: Colors.black,
                        height: MediaQuery.of(context).size.height,
                        child: cameraPreview(),
                      ))
                  : SingleChildScrollView(
                      controller: widget.camScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        color: Colors.black,
                        child: cameraPreview(),
                      ),
                    ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    multiMedia
                        ? Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  numOfSMs > 0
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.arrow_circle_up_rounded,
                                            color: Colors.white,
                                          ),
                                          iconSize: 36,
                                          onPressed: () {
                                            sendToPreview();
                                          },
                                        )
                                      : const SizedBox.shrink(),
                                  Row(
                                    children: [
                                      const Expanded(
                                          child: Divider(
                                        height: 25,
                                        thickness: 1.5,
                                        color: Colors.white54,
                                        indent: 45,
                                      )),
                                      Text(
                                        "$numOfSMs/${Constants.maxFileUpload}",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Expanded(
                                          child: Divider(
                                        height: 25,
                                        thickness: 1.5,
                                        color: Colors.white54,
                                        endIndent: 45,
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                              selectedMediaList(),
                              const Divider(
                                height: 15,
                                thickness: 1.5,
                                color: Colors.white54,
                                indent: 45,
                                endIndent: 45,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.15,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          widget.backButton
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    iconSize: 27,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          0.025),
                                  child: cameraToggle(),
                                ),
                          cameraControl(context),
                          cameras != null && cameras.isNotEmpty
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: multiMedia
                                        ? Icon(
                                            numOfSMs < Constants.maxFileUpload
                                                ? Icons.upload_rounded
                                                : Icons.upload_outlined,
                                            color: numOfSMs <
                                                    Constants.maxFileUpload
                                                ? Colors.white
                                                : Colors.white54)
                                        : const Icon(
                                            Icons.upload_rounded,
                                            color: Colors.white,
                                          ),
                                    iconSize: 27,
                                    onPressed: () async {
                                      String uploadTo =
                                          widget.groupChatId == null &&
                                                  widget.personalChatId == null
                                              ? "SNIPPET"
                                              : widget.groupChatId != null
                                                  ? "GROUP"
                                                  : "PERSONAL";

                                      if (multiMedia) {
                                        if (numOfSMs <
                                            Constants.maxFileUpload) {
                                          List<SelectedFile> localMedia =
                                              await openUploadBttSheet(
                                                  context: context,
                                                  uploadTo: uploadTo,
                                                  numOfAvlUpl:
                                                      Constants.maxFileUpload -
                                                          numOfSMs);

                                          if (localMedia != null) {
                                            setState(() {
                                              selMedia.addAll(localMedia);
                                              numOfSMs += localMedia.length;
                                            });
                                            Timer(
                                              const Duration(seconds: 1),
                                              () => selController.jumpTo(
                                                  selController.position
                                                      .maxScrollExtent),
                                            );
                                          }
                                        }
                                      } else {
                                        openUploadBttSheet(
                                          context: context,
                                          uploadTo: uploadTo,
                                          singleFile: true,
                                          personalChatId: widget.personalChatId,
                                          contactId: widget.contactId,
                                          groupId: widget.groupChatId,
                                        );
                                      }
                                    },
                                  ),
                                )
                              : const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.075),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  widget.groupChatId == null && widget.personalChatId == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Broadcast",
                                style: GoogleFonts.varelaRound(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ],
                        )
                      : const SizedBox.shrink(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      !widget.backButton
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.width *
                                      0.025),
                              child: cameraToggle(),
                            ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _flashModeControlRowWidget(),
                          IconButton(
                            icon: Icon(platform == TargetPlatform.android
                                ? adFlashIcon
                                : iosFlashIcon),
                            color: Colors.white,
                            onPressed: cameraController != null
                                ? onFlashModeButtonPressed
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _multiMediaModeControlRowWidget(),
                      IconButton(
                        icon: Icon(
                          !multiMedia ? Icons.photo : Icons.collections_rounded,
                          color: Colors.white,
                        ),
                        onPressed: cameraController != null
                            ? onMultiSnippetModeButtonPressed
                            : null,
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _exposureModeControlRowWidget(),
                      IconButton(
                        icon: const Icon(Icons.exposure),
                        color: Colors.white,
                        onPressed: cameraController != null
                            ? onExposureModeButtonPressed
                            : null,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _focusModeControlRowWidget(),
                      IconButton(
                        icon: const Icon(Icons.filter_center_focus),
                        color: Colors.white,
                        onPressed: cameraController != null
                            ? onFocusModeButtonPressed
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCamera(cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _multiMediaModeRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _focusModeControlRowAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _multiMediaModeRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _multiMediaModeRowAnimation = CurvedAnimation(
      parent: _multiMediaModeRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    super.initState();

    availableCameras().then((value) {
      cameras = value;
      if (cameras.isNotEmpty) {
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras[selectedCameraIndex]);
      } else {
        debugPrint("No camera available");
      }
    }).catchError((e) {
      debugPrint('Error: ${e.code}');
    });
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}


// class MultiMediaList extends StatefulWidget {
//   final int max;
//   List<SelectedFile> selMedia;
//   final ScrollController selController;
//   final String personalChatId;
//   final bool friend;
//   final String contactId;
//   final String groupChatId;
//
//   MultiMediaList(
//       this.selMedia,
//       this.max,
//       this.selController,
//       this.personalChatId,
//       this.friend,
//       this.contactId,
//       this.groupChatId,
//       );
//
//   @override
//   _MultiMediaListState createState() => _MultiMediaListState();
// }
//
// class _MultiMediaListState extends State<MultiMediaList> {
//
//   bool anon = true;
//   // String tags = '';
//   List<SelectedFile> delMedia = [];
//
//
//   Widget selectedMediaList(){
//     return Container(
//       height: MediaQuery.of(context).size.height*0.15,
//       width: MediaQuery.of(context).size.width,
//       alignment: Alignment.center,
//       child: numOfSMs > 0 ? ListView.builder(
//           reverse: true,
//           controller: widget.selController,
//           scrollDirection: Axis.horizontal,
//           itemCount: widget.selMedia.length,
//           shrinkWrap: true,
//           itemBuilder:(context, index){
//             return !widget.selMedia[index].deleted ? Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: Container(
//                 width: MediaQuery.of(context).size.width/4,
//                 child: Stack(
//                   children: [
//                     widget.selMedia[index],
//                     Align(
//                         alignment: Alignment.topCenter,
//                         child:IconButton(
//                           icon:Icon(Icons.cancel_rounded, color:Colors.red),
//                           onPressed: (){
//                             delMedia.add(widget.selMedia[index]);
//                             setState(() {
//                               numOfSMs--;
//                               widget.selMedia[index].deleted = true;
//                             });
//                           },
//                         )
//                     )
//                   ],
//                 ),
//               ),
//             ) : SizedBox.shrink();
//           }
//       ) : ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//
//         child: Container(
//           width: MediaQuery.of(context).size.width/4,
//           color: Colors.white54,
//           child: Center(
//             child: Icon(Icons.add_a_photo_outlined, color: Colors.white,),
//           ),
//         ),
//       ),
//     );
//   }
//
//   sendToPreview() async{
//     // int numOfIncUpl = 0;
//     List<SelectedFile> rdyMedia = [];
//
//     for(SelectedFile sm in widget.selMedia){
//       if(!sm.deleted){
//         rdyMedia.add(sm);
//
//         // if(sm.fileUrl != null && !sm.uploading){
//         //   rdyMedia.add(sm);
//         // }else{
//         //   numOfIncUpl++;
//         // }
//       }
//     }
//     // if(numOfIncUpl == 0){
//       Navigator.push(context, MaterialPageRoute(
//           builder: (context) => PreviewScreen(
//             tagPublic:widget.personalChatId == null && widget.groupChatId == null,
//             selMedia: rdyMedia,
//             // anon: anon,
//             // tags: tags,
//             personalChatId: widget.personalChatId,
//             friend: widget.friend,
//             contactId: widget.contactId,
//             groupChatId: widget.groupChatId,
//           )
//       ));
//
//     // }else{
//     //   Fluttertoast.showToast(
//     //       msg: "Sorry, $numOfIncUpl of the files are uploading",
//     //       toastLength: Toast.LENGTH_SHORT,
//     //       gravity: ToastGravity.SNACKBAR,
//     //       timeInSecForIosWeb: 3,
//     //       backgroundColor: Colors.black,
//     //       textColor: Colors.white,
//     //       fontSize: 14.0
//     //   );
//     // }
//   }
//
//   @override
//   void dispose() {
//     
//     Globals.numOfSMs = 0;
//     widget.selMedia = [];
//
//     // if(widget.personalChatId == null && widget.groupChatId == null)
//     //   Globals.nonSentSnippet = disposeMFPicker(widget.selMedia, delMedia);
//     // else if(widget.groupChatId != null)
//     //   Globals.nonSentGroupMedia = disposeMFPicker(widget.selMedia, delMedia);
//     // else
//     //   Globals.nonSentPersonalMedia = disposeMFPicker(widget.selMedia, delMedia);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Globals.numOfSMs > 0 ? IconButton(
//               icon: Icon(Icons.arrow_circle_up_rounded, color: Colors.white,),
//               iconSize: 36,
//               onPressed: (){
//                 sendToPreview();
//               },
//             ) : SizedBox.shrink(),
//             Row(
//               children: [
//                 Expanded(child: Divider(height: 25, thickness: 2.5, color: Colors.white54, indent: 45,)),
//                 Text("${Globals.numOfSMs}/${widget.max}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
//                 Expanded(child:Divider(height: 25, thickness: 2.5, color: Colors.white54, endIndent: 45,)),
//               ],
//             ),
//           ],
//         ),
//         selectedMediaList(),
//         Divider(height: 15, thickness: 2.5, color: Colors.white54, indent: 45, endIndent: 45,),
//       ],
//     );
//   }
// }
