import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class DownloadMethods {
  static prepareSaveDir(TargetPlatform platform) async {
    Directory extDir;

    if (platform == TargetPlatform.android) {
      extDir = await getExternalStorageDirectory();
    } else if (platform == TargetPlatform.iOS) {
      extDir = await getApplicationDocumentsDirectory();
    }

    String localPath = '${extDir.path}${Platform.pathSeparator}Download';
    final savedDir = Directory(localPath);
    bool hasExisted = await savedDir.exists();

    if (!hasExisted) {
      savedDir.create();
    }

    return localPath;
  }

  static startDownload(String fileName, String url, String savedDir) async {
    String taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        showNotification: true,
        openFileFromNotification: true,
        fileName: fileName);
    return taskId;
  }

  static cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  static retryDownload(String taskId) async {
    String newTaskId = await FlutterDownloader.retry(taskId: taskId);
    return newTaskId;
  }

  static openDownloadedFile(String taskId) {
    if (taskId != null) {
      return FlutterDownloader.open(taskId: taskId);
    } else {
      return Future.value(false);
    }
  }
}
