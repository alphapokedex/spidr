import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/views/preview.dart';

import '../views/preview.dart';

class CameraMethods {
  static getCameraLensIcons(CameraLensDirection lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return CupertinoIcons.photo_camera;
      default:
        return Icons.device_unknown;
    }
  }

  static onSwitchCamera(
      List cameras, int selectedCameraIndex, Function initCamera) {
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    initCamera(selectedCamera);
  }

  static onCaptureForSingle(
    BuildContext context,
    CameraController cameraController,
    String personalChatId,
    bool friend,
    String contactId,
    String groupId,
  ) async {
    try {
      await cameraController.takePicture().then((XFile file) async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PreviewScreen(
                      filePath: file.path,
                      vidOrAud: false,
                      tagPublic: personalChatId == null && groupId == null,
                      personalChatId: personalChatId,
                      friend: friend,
                      contactId: contactId,
                      groupChatId: groupId,
                    )));
      });
    } catch (e) {
      showCameraException(e);
    }
  }

  static stopVideoForSingle(
    BuildContext context,
    CameraController cameraController,
    String personalChatId,
    bool friend,
    String contactId,
    String groupId,
  ) async {
    try {
      await cameraController.stopVideoRecording().then((XFile file) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PreviewScreen(
                      filePath: file.path,
                      vidOrAud: true,
                      tagPublic: personalChatId == null && groupId == null,
                      personalChatId: personalChatId,
                      friend: friend,
                      contactId: contactId,
                      groupChatId: groupId,
                    )));
      });
    } catch (e) {
      showCameraException(e);
    }
  }

  static onCaptureForMulti(
    context,
    CameraController cameraController,
  ) async {
    try {
      XFile imgFile = await cameraController.takePicture();
      return File(imgFile.path);
    } catch (e) {
      showCameraException(e);
    }
  }

  static stopVideoForMulti(
    BuildContext context,
    CameraController cameraController,
    String filepath,
  ) async {
    try {
      XFile videoFile = await cameraController.stopVideoRecording();
      return File(videoFile.path);
    } catch (e) {
      showCameraException(e);
    }
  }

  static onCaptureVideo(
      BuildContext context, CameraController cameraController) async {
    try {
      await cameraController.startVideoRecording();
    } on CameraException catch (e) {
      showCameraException(e);
      return null;
    }
  }

  static void logError(String code, String message) {
    if (message != null) {
      debugPrint('Error: $code\nError Message: $message');
    } else {
      debugPrint('Error: $code');
    }
  }

  static void showCameraException(CameraException e) {
    logError(e.code, e.description);
  }
}
