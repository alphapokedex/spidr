import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/fileDownload.dart';
import 'package:spidr_app/widgets/widget.dart';

import 'mediaPreview.dart';

class DocViewScreen extends StatefulWidget {
  final File file;
  final String fileUrl;
  final String fileName;

  const DocViewScreen({this.file, this.fileUrl, this.fileName});
  @override
  _DocViewScreenState createState() => _DocViewScreenState();
}

class _DocViewScreenState extends State<DocViewScreen> {
  bool _isLoading = true;
  PDFDocument document;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;
  String savedDir;
  ReceivePort port = ReceivePort();

  bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }

    port.listen((data) {
      setState(() {
        taskId = data[0];
        status = data[1];
        progress = data[2];
      });
    });
  }

  unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  startDownload(TargetPlatform platform, String url) async {
    bool ready = await checkStoragePermission(platform);

    if (ready) {
      savedDir = await DownloadMethods.prepareSaveDir(platform);
      taskId =
          await DownloadMethods.startDownload(widget.fileName, url, savedDir);
      // if(taskId != null)
      //   Fluttertoast.showToast(
      //     msg: "Start download",
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.SNACKBAR,
      //     timeInSecForIosWeb: 3,
      //   );
    }
  }

  cancelDownload() async {
    await DownloadMethods.cancelDownload(taskId);
  }

  retryDownload() async {
    taskId = await DownloadMethods.retryDownload(taskId);
  }

  openDownload() async {
    bool success = await DownloadMethods.openDownloadedFile(taskId);
    if (!success) {
      Fluttertoast.showToast(
          msg: 'Sorry, please try again',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 3,
          fontSize: 14.0);
    }
  }

  loadDocument() async {
    if (widget.fileUrl != null) {
      document = await PDFDocument.fromURL(widget.fileUrl);
    } else {
      document = await PDFDocument.fromFile(widget.file);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    SendPort sendPort;
    if (IsolateNameServer.lookupPortByName('downloader_send_port') != null) {
      sendPort = IsolateNameServer.lookupPortByName('downloader_send_port');
      sendPort.send([id, status, progress]);
    }
  }

  @override
  void initState() {
    super.initState();
    bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    loadDocument();
  }

  @override
  void dispose() {
    unbindBackgroundIsolate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return Scaffold(
        appBar: AppBar(
          leading: const BackButton(
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          title: status != DownloadTaskStatus.running
              ? Text(widget.fileName,
                  style: GoogleFonts.roboto(
                      color: Colors.black, fontWeight: FontWeight.bold))
              : LinearProgressIndicator(
                  value: progress / 100,
                ),
          actions: widget.fileUrl != null
              ? [
                  IconButton(
                      icon: Icon(
                        status == DownloadTaskStatus.undefined ||
                                status == DownloadTaskStatus.canceled
                            ? platform == TargetPlatform.android
                                ? Icons.download_rounded
                                : CupertinoIcons.download_circle
                            : status == DownloadTaskStatus.running
                                ? Icons.close
                                : status == DownloadTaskStatus.complete
                                    ? Icons.open_in_new_rounded
                                    : status == DownloadTaskStatus.failed
                                        ? Icons.refresh
                                        : null,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        if (status == DownloadTaskStatus.undefined ||
                            status == DownloadTaskStatus.canceled) {
                          startDownload(platform, widget.fileUrl);
                        } else if (status == DownloadTaskStatus.running) {
                          cancelDownload();
                        } else if (status == DownloadTaskStatus.complete) {
                          openDownload();
                        } else if (status == DownloadTaskStatus.failed) {
                          retryDownload();
                        }
                      })
                ]
              : null,
        ),
        body: !_isLoading
            ? Center(
                child: PDFViewer(
                  document: document,
                  zoomSteps: 1,
                  lazyLoad: true,
                  scrollDirection: Axis.vertical,
                ),
              )
            : sectionLoadingIndicator());
  }
}

class DocDisplay extends StatelessWidget {
  final String fileName;
  final bool fullScreen;

  final List gifs;
  final String caption;
  final String link;
  final double div;
  final int numOfLines;
  final bool displayGifs;
  final double topPadding;

  const DocDisplay(
      {this.fileName,
      this.fullScreen = false,
      this.gifs,
      this.caption,
      this.link,
      this.div = 1.0,
      this.numOfLines,
      this.displayGifs = false,
      this.topPadding = 9.0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        filePreview(
            context, 'assets/images/docImage.png', fileName, fullScreen),
        auxiliaryDisplay(
            context: context,
            gifs: gifs,
            caption: caption,
            link: link,
            div: div,
            numOfLines: numOfLines,
            displayGifs: displayGifs,
            topPadding: topPadding)
      ],
    );
  }
}
