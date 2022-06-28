import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/newFileUpload.dart';
import 'package:spidr_app/views/mediaPreview.dart';
import 'package:spidr_app/views/preview.dart';
import 'package:spidr_app/widgets/dynamicStackItem.dart';
import 'package:spidr_app/widgets/widget.dart';

Widget videoIcon() {
  return const Align(
    alignment: Alignment.bottomRight,
    child: Padding(
      padding: EdgeInsets.only(right: 5, bottom: 5),
      child: Icon(Icons.videocam_rounded, color: Colors.white),
    ),
  );
}

class AssetDisplay extends StatelessWidget {
  final AssetEntity asset;
  const AssetDisplay(this.asset);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: asset.thumbnailData,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        return bytes != null
            ? Stack(
                children: [
                  SizedBox.expand(
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                  if (asset.type == AssetType.video) videoIcon(),
                  Align(
                      alignment: Alignment.bottomLeft,
                      child: GestureDetector(
                        onTap: () async {
                          File file = await asset.file;
                          if (asset.type == AssetType.video) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => VideoAudioFilePreview(
                                          videoFile: file,
                                          fullScreen: true,
                                          play: true,
                                        )));
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PhotoView(
                                          imageProvider: FileImage(file),
                                        )));
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.orange,
                          ),
                        ),
                      )),
                ],
              )
            : const CircularProgressIndicator();
      },
    );
  }
}

class FileDisplay extends StatelessWidget {
  final File file;
  final bool vidOrAud;
  final String audioName;
  final String fileName;
  const FileDisplay({this.file, this.vidOrAud, this.audioName, this.fileName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: vidOrAud
              ? VideoAudioFilePreview(
                  videoFile: file,
                  fullScreen: false,
                  play: false,
                  audioName: audioName)
              : fileName == null
                  ? Image.file(file, fit: BoxFit.cover)
                  : filePreview(
                      context, "assets/images/docImage.png", fileName, false),
        ),
        if (vidOrAud) audioName == null ? videoIcon() : const SizedBox.shrink(),
      ],
    );
  }
}

class UnknownFileDisplay extends StatelessWidget {
  final String fileName;
  const UnknownFileDisplay(this.fileName);

  @override
  Widget build(BuildContext context) {
    return filePreview(
        context, "assets/images/unknownFile.png", fileName, false);
  }
}

class MediaAndFileGallery extends StatefulWidget {
  final ScrollController controller;
  final String groupId;
  final String personalChatId;
  final bool friend;
  final String contactId;
  final int numOfAvlUpl;
  final String uploadTo;
  final String type;
  final bool singleFile;

  const MediaAndFileGallery({
    this.controller,
    this.groupId,
    this.personalChatId,
    this.friend,
    this.contactId,
    this.numOfAvlUpl,
    this.uploadTo,
    this.type,
    this.singleFile,
  });
  @override
  _MediaAndFileGalleryState createState() => _MediaAndFileGalleryState();
}

class _MediaAndFileGalleryState extends State<MediaAndFileGallery> {
  ScrollController selController = ScrollController();

  List<SelectedFile> selFiles = [];
  int numOfSFs = 0;

  List<Widget> assets = [];
  int currentPage = 0;
  int lastPage;

  bool uploadedSnip = false;

  // List<SelectedFile> delFile = [];

  fetchMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) {
      return;
    }
    // Further requests can be only procceed with authorized or limited.
    if (ps != PermissionState.authorized && ps != PermissionState.limited) {
      Fluttertoast.showToast(msg: 'Permission is not granted.');
      return;
    }
    if (ps.isAuth) {
      lastPage = currentPage;
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      List<AssetEntity> mediaList = await albums.first.getAssetListPaged(
        size: 60,
        page: currentPage,
      );
      List<Widget> temp = mediaList.map((e) => assetTile(e)).toList();
      if (mounted) {
        setState(() {
          assets.addAll(temp);
          currentPage++;
        });
      }
    }
  }

  @override
  void initState() {
    // setState(() {
    //   selFiles = widget.type == "MEDIA" ? List.from(Globals.nonSentMedia) :
    //   widget.type == "AUDIO" ? List.from(Globals.nonSentAudio) :
    //   List.from(Globals.nonSentPDF);
    //
    //   numOfSFs = widget.type == "MEDIA" ? Globals.nonSentMedia.length :
    //   widget.type == "AUDIO" ? Globals.nonSentAudio.length :
    //   Globals.nonSentPDF.length;
    // });

    if (widget.type == "MEDIA") {
      fetchMedia();
      widget.controller.addListener(() {
        if (widget.controller.position.pixels /
                widget.controller.position.maxScrollExtent >
            0.33) if (currentPage != lastPage) fetchMedia();
      });
    }

    super.initState();
  }

  Widget assetTile(AssetEntity asset) {
    return GestureDetector(
      onTap: () async {
        if (widget.singleFile == null || !widget.singleFile) {
          bool moreUplAvl = widget.numOfAvlUpl == null
              ? numOfSFs < Constants.maxFileUpload
              : numOfSFs < widget.numOfAvlUpl;

          if (moreUplAvl) {
            File file = await asset.file;
            bool selected = false;
            for (SelectedFile sm in selFiles) {
              if (!sm.deleted) {
                if (sm.asset.id == asset.id) {
                  selected = true;
                  break;
                }
              }
            }
            if (!selected) {
              setState(() {
                selFiles
                    .add(SelectedFile(asset: asset, uploadTo: widget.uploadTo));
                numOfSFs++;
              });

              Timer(
                const Duration(seconds: 1),
                () => selController
                    .jumpTo(selController.position.maxScrollExtent),
              );
            }
          }
        } else {
          File file = await asset.file;
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => PreviewScreen(
                        file: file,
                        vidOrAud: asset.type == AssetType.video,
                        tagPublic: widget.personalChatId == null &&
                            widget.groupId == null,
                        personalChatId: widget.personalChatId,
                        contactId: widget.contactId,
                        groupChatId: widget.groupId,
                      )));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AssetDisplay(asset),
        ),
      ),
    );
  }

  sendToChat(rdyFile) {
    DateTime now = DateTime.now();
    if (widget.type == "MEDIA") {
      List<Map> mediaList = conMediaList(rdyFile);
      fileUploadToChats(
        file: mediaList.length == 1 ? File(mediaList[0]["imgPath"]) : null,
        personalChatId: widget.personalChatId,
        contactId: widget.contactId,
        friend: widget.friend,
        groupChatId: widget.groupId,
        imgObj: mediaList.length == 1 ? mediaList[0] : null,
        mediaGallery: mediaList.length > 1 ? mediaList : null,
        time: now.microsecondsSinceEpoch,
      );

      // if(widget.uploadTo == "GROUP"){
      //   DatabaseMethods(uid: Constants.myUserId).addConversationMessages(
      //     groupChatId:widget.groupId,
      //     message:"",
      //     username:Constants.myName,
      //     userId:Constants.myUserId,
      //     dateTime:DateFormat('yyyy-MM-dd hh:mm a').format(now),
      //     time:now.microsecondsSinceEpoch,
      //     imgObj:mediaList.length == 1 ? mediaList[0]: null,
      //     mediaGallery: mediaList.length > 1 ? mediaList : null,
      //   );
      // }else if(widget.uploadTo == "PERSONAL"){
      //   DatabaseMethods(uid: Constants.myUserId).addPersonalMessage(
      //     personalChatId:widget.personalChatId,
      //     text:"",
      //     userName:Constants.myName,
      //     formattedDate:DateFormat('yyyy-MM-dd hh:mm a').format(now),
      //     sendTime:now.microsecondsSinceEpoch,
      //     imgMap:mediaList.length == 1 ? mediaList[0]: null,
      //     mediaGallery: mediaList.length > 1 ? mediaList : null,
      //     contactId:widget.contactId,
      //     friend: widget.friend
      //   );
      // }
    } else {
      for (SelectedFile rf in rdyFile) {
        // rf.sent = true;
        // DatabaseMethods().clearNonSentFiles(rf.fileId);
        List gifs = [];
        if (rf.gifs != null) gifs = conGifMap(rf.gifs);
        Map fileObj = {
          "filePath": rf.filePath,
          "fileName": rf.fileName,
          "fileSize": rf.fileSize,
          "caption": rf.caption,
          "link": rf.link,
          "gifs": gifs
        };

        DateTime now = DateTime.now();
        int time = now.microsecondsSinceEpoch;

        fileUploadToChats(
            file: File(rf.filePath),
            personalChatId: widget.personalChatId,
            contactId: widget.contactId,
            friend: widget.friend,
            groupChatId: widget.groupId,
            fileObj: fileObj,
            time: time,
            numOfFiles: rdyFile.length);
      }
    }

    Navigator.of(context).pop();
  }

  readyToSend() {
    // int numOfIncUpl = 0;
    List<SelectedFile> rdyFile = selFiles.where((sf) => !sf.deleted).toList();

    // for(SelectedFile sm in selFiles){
    //   if(!sm.deleted){
    //     rdyFile.add(sm);
    //
    //     // if(sm.fileUrl != null && !sm.uploading){
    //     //   rdyFile.add(sm);
    //     // }else{
    //     //   numOfIncUpl++;
    //     // }
    //
    //   }
    // }

    sendToChat(rdyFile);

    // if(numOfIncUpl == 0){
    //   sendToChat(rdyFile);
    // }else{
    //   incUploadAlert(rdyFile, numOfIncUpl);
    // }
  }

  // @override
  // void dispose() {
  //
  //   if(widget.type == "MEDIA"){
  //     if(!uploadedSnip){
  //       Globals.nonSentMedia = disposeMFPicker(selFiles, delFile);
  //     }
  //   }
  //   else if(widget.type == "AUDIO")
  //     Globals.nonSentAudio = disposeMFPicker(selFiles, delFile);
  //   else if(widget.type == "PDF")
  //     Globals.nonSentPDF = disposeMFPicker(selFiles, delFile);
  //
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 15, right: 10, left: 10),
      child: Column(
        children: [
          numOfSFs > 0
              ? Row(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.15,
                      width: MediaQuery.of(context).size.width * 0.775,
                      child: ListView.builder(
                          reverse: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: selFiles.length,
                          controller: selController,
                          itemBuilder: (context, index) {
                            return !selFiles[index].deleted
                                ? Container(
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                    margin: const EdgeInsets.only(
                                        left: 5, right: 5),
                                    decoration: shadowEffect(15),
                                    child: Stack(
                                      children: [
                                        selFiles[index],
                                        Align(
                                            alignment: Alignment.topCenter,
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.cancel_rounded,
                                                  color: Colors.red),
                                              onPressed: () {
                                                // delFile.add(selFiles[index]);
                                                setState(() {
                                                  numOfSFs--;
                                                  selFiles[index].deleted =
                                                      true;
                                                });
                                              },
                                            ))
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(widget.numOfAvlUpl == null
                              ? platform == TargetPlatform.android
                                  ? Icons.send
                                  : CupertinoIcons.arrow_up_circle
                              : Icons.upload_rounded),
                          iconSize: 20.0,
                          color: Colors.orange,
                          onPressed: () {
                            if (widget.numOfAvlUpl == null) {
                              readyToSend();
                            } else {
                              uploadedSnip = true;
                              Navigator.pop(context,
                                  selFiles.where((m) => !m.deleted).toList());
                            }
                          },
                        ),
                        Text(
                            widget.numOfAvlUpl == null
                                ? "$numOfSFs/${Constants.maxFileUpload}"
                                : "$numOfSFs/${widget.numOfAvlUpl}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black))
                      ],
                    )
                  ],
                )
              : const SizedBox.shrink(),
          const Divider(
            height: 25,
            thickness: 2.5,
            color: Colors.black,
            indent: 90,
            endIndent: 90,
          ),
          widget.type == "MEDIA"
              ? Expanded(
                  child: GridView.builder(
                      controller: widget.controller,
                      itemCount: assets.length,
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3),
                      itemBuilder: (BuildContext context, int index) {
                        return assets[index];
                      }),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      numOfSFs == 0
                          ? Image.asset(
                              widget.type == "AUDIO"
                                  ? "assets/images/audiofile.png"
                                  : "assets/images/docImage.png",
                              fit: BoxFit.cover,
                              scale: 2.5,
                            )
                          : const SizedBox.shrink(),
                      numOfSFs < Constants.maxFileUpload
                          ? TextButton.icon(
                              onPressed: () async {
                                FilePickerResult result;
                                if (widget.type == "AUDIO") {
                                  result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowMultiple: true,
                                    allowedExtensions: [
                                      'mp3',
                                      'wav',
                                      'wma',
                                      'aac',
                                      'flac',
                                      'm4a'
                                    ],
                                  );
                                } else if (widget.type == "PDF") {
                                  result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowMultiple: true,
                                    allowedExtensions: ['pdf'],
                                  );
                                }

                                if (result != null) {
                                  List<PlatformFile> files = result
                                              .files.length >
                                          Constants.maxFileUpload - numOfSFs
                                      ? result.files.sublist(
                                          0, Constants.maxFileUpload - numOfSFs)
                                      : result.files;

                                  for (PlatformFile file in files) {
                                    selFiles.add(SelectedFile(
                                        platformFile: file,
                                        uploadTo: widget.uploadTo));
                                    numOfSFs++;
                                  }
                                  setState(() {});

                                  Timer(
                                    const Duration(seconds: 1),
                                    () => selController.jumpTo(
                                        selController.position.maxScrollExtent),
                                  );
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(
                                widget.type == "AUDIO"
                                    ? "select audio files"
                                    : "select PDF files",
                                style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.black),
                                textAlign: TextAlign.center,
                              ))
                          : const SizedBox.shrink(),
                    ],
                  ),
                )
        ],
      ),
    );
  }

  // incUploadAlert(List<SelectedFile> rdyFile, int numOfIncUpl){
  //   showDialog(
  //       context: context,
  //       builder: (BuildContext context){
  //         return AlertDialog(
  //           title: Text("Heads up",style: TextStyle(color: Colors.orange)),
  //           content: Text("${numOfSFs-numOfIncUpl}/$numOfSFs of selected files were uploaded successfully" ),
  //           actions: [
  //             TextButton(
  //                 onPressed:(){
  //                   Navigator.of(context, rootNavigator: true).pop();
  //                 },
  //                 child: Text("Wait",style: TextStyle(color: Colors.blue))
  //             ),
  //             rdyFile.length > 0 ? TextButton(
  //                 onPressed:(){
  //                   sendToChat(rdyFile);
  //                   Navigator.of(context, rootNavigator: true).pop();
  //                 },
  //                 child: Text("Send Anyways",style: TextStyle(color: Colors.blue))
  //             ) : SizedBox.shrink(),
  //           ],
  //         );
  //       }
  //   );
  // }
}

class SelectedFile extends StatefulWidget {
  final AssetEntity asset;
  final File file;
  final PlatformFile platformFile;
  final bool video;
  final String uploadTo;
  SelectedFile({
    this.asset,
    this.file,
    this.platformFile,
    this.video,
    this.uploadTo,
  });

  // String fileUrl;
  String fileName;
  String filePath;
  String fileSize;
  String caption = "";
  List<DynamicStackItem> gifs = [];
  String link;
  bool mature = false;

  // String fileId;

  bool deleted = false;
  // bool sent = false;
  // bool uploading = false;
  //
  // UploadTask uploadTask;
  // double progressPercent = 0.0;

  @override
  _SelectedFileState createState() => _SelectedFileState();
}

class _SelectedFileState extends State<SelectedFile> {
  // String fileUrl;
  String caption = "";
  List<DynamicStackItem> gifs = [];
  String link = "";
  bool mature = false;

  bool isVidOrAud;

  File file;
  String audioName;
  String fileName;

  // handelUploadEvents(bool resumed){
  //   widget.uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  //     if(mounted)
  //       setState(() {
  //         widget.progressPercent = snapshot.bytesTransferred / snapshot.totalBytes;
  //       });
  //     if(snapshot.state == TaskState.success){
  //       snapshot.ref.getDownloadURL().then((String url) async {
  //         if(widget.fileId == null && !resumed) widget.fileId = await DatabaseMethods().storeNonSentFiles(url);
  //         widget.fileUrl = url;
  //         widget.uploading = false;
  //         if(mounted){
  //           setState(() {
  //             fileUrl = url;
  //           });
  //         }
  //       });
  //     }
  //   });
  // }
  //
  // startUpload() async{
  //   DateTime now = DateTime.now();
  //   widget.uploading = true;
  //   File file;
  //   if(widget.asset != null)
  //     file = await widget.asset.file;
  //   else if(widget.platformFile != null)
  //     file = File(widget.platformFile.path);
  //   else
  //     file = widget.file;
  //
  //   if(widget.platformFile == null) {
  //     if(isVidOrAud){
  //       widget.fileName = '${now.microsecondsSinceEpoch}.mp4';
  //     }else{
  //       widget.fileName = '${now.microsecondsSinceEpoch}.jpeg';
  //     }
  //   }else{
  //     widget.fileName = widget.platformFile.name;
  //     widget.fileSize = filesize(widget.platformFile.size);
  //   }
  //
  //   Reference ref;
  //   switch(widget.uploadTo){
  //     case"GROUP":
  //       ref = FirebaseStorage.instance
  //           .ref()
  //           .child('groupChats/${Constants.myUserId}/${now.microsecondsSinceEpoch}');
  //       break;
  //     case"PERSONAL":
  //       ref = FirebaseStorage.instance
  //           .ref()
  //           .child('personalChats/${Constants.myUserId}/${now.microsecondsSinceEpoch}');
  //       break;
  //     case"SNIPPET":
  //       ref = FirebaseStorage.instance
  //           .ref().child('stories/${Constants.myUserId}/${now.microsecondsSinceEpoch}');
  //       break;
  //   }
  //
  //   widget.uploadTask = ref.putFile(file);
  //   handelUploadEvents(false);
  // }
  //
  // resumeUpload(){
  //   if(widget.uploadTask != null)
  //     handelUploadEvents(true);
  // }
  //
  // fileUrlSetUp()async{
  //   DocumentSnapshot fileDS = await DatabaseMethods().nonSentFileCollection.doc(widget.fileId).get();
  //   if(fileDS.exists)
  //     setState(() {
  //       fileUrl = widget.fileUrl;
  //     });
  //   else{
  //     widget.fileId = null;
  //     startUpload();
  //   }
  //
  // }
  //
  // @override
  // void dispose() {
  //
  //   if(widget.deleted){
  //     if(widget.fileUrl == null)
  //       widget.uploadTask.cancel();
  //     else{
  //       DatabaseMethods().clearNonSentFiles(widget.fileId);
  //       rmvFileFromStorage(widget.fileUrl);
  //       widget.fileUrl = null;
  //     }
  //   }
  //
  //   super.dispose();
  // }

  fileSetUp() async {
    if (widget.file != null) {
      file = widget.file;
    } else if (widget.asset != null) {
      file = await widget.asset.file;
    } else if (widget.platformFile != null) {
      file = File(widget.platformFile.path);
      audioName = audioChecker(widget.platformFile.name)
          ? widget.platformFile.name
          : null;
      fileName = pdfChecker(widget.platformFile.name)
          ? widget.platformFile.name
          : null;
    }

    DateTime now = DateTime.now();

    if (widget.platformFile == null) {
      widget.filePath = file.path;
      if (isVidOrAud) {
        widget.fileName = '${now.microsecondsSinceEpoch}.mp4';
      } else {
        widget.fileName = '${now.microsecondsSinceEpoch}.jpeg';
      }
    } else {
      widget.fileName = widget.platformFile.name;
      widget.filePath = widget.platformFile.path;
      widget.fileSize = filesize(widget.platformFile.size);
    }

    setState(() {});
  }

  @override
  void initState() {
    if (widget.video != null) {
      isVidOrAud = widget.video;
    } else if (widget.asset != null) {
      isVidOrAud = widget.asset.type == AssetType.video;
    } else {
      isVidOrAud = audioChecker(widget.platformFile.name);
    }
    fileSetUp();

    // if(widget.fileUrl == null && !widget.uploading)
    //   startUpload();
    // else if(widget.fileUrl != null && !widget.uploading)
    //   fileUrlSetUp();
    // else if(widget.fileUrl == null && widget.uploading)
    //   resumeUpload();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return GestureDetector(
      onTap: () async {
        if (widget.platformFile == null ||
            audioChecker(widget.platformFile.name) ||
            pdfChecker(widget.platformFile.name)) {
          List res = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PreviewScreen(
                        file: file,
                        audioName: audioName,
                        fileName: fileName,
                        edit: true,
                        caption: caption,
                        link: link,
                        gifs: gifs,
                        mature: mature,
                        tagPublic: false,
                        vidOrAud: isVidOrAud,
                      )));

          widget.caption = res[0];
          widget.link = res[1];
          widget.gifs = res[2];
          widget.mature = res[3];
          setState(() {
            caption = widget.caption;
            link = widget.link;
            gifs = widget.gifs;
            mature = widget.mature;
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: file != null
            ? Stack(
                children: [
                  widget.asset != null
                      ? AssetDisplay(widget.asset)
                      : widget.file != null ||
                              (widget.platformFile != null &&
                                  (audioChecker(widget.platformFile.name) ||
                                      pdfChecker(widget.platformFile.name)))
                          ? FileDisplay(
                              file: file,
                              vidOrAud: isVidOrAud,
                              audioName: audioName,
                              fileName: fileName)
                          : UnknownFileDisplay(widget.platformFile.name),

                  // fileUrl == null ?
                  // Container(
                  //   color: Colors.black54,
                  //   child: Center(
                  //       child: CircularProgressIndicator(value: widget.progressPercent, backgroundColor: Colors.white,)
                  //   )
                  // ) : SizedBox.shrink(),

                  caption.isNotEmpty
                      ? mediaCaption(context, caption, 3.0, 1)
                      : const SizedBox.shrink(),

                  link.isNotEmpty
                      ? Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.black54,
                            ),
                            child: Icon(
                              platform == TargetPlatform.android
                                  ? Icons.link_rounded
                                  : CupertinoIcons.link,
                              size: 27,
                              color: Colors.white,
                            ),
                          ))
                      : const SizedBox.shrink(),

                  gifs.isNotEmpty
                      ? const Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            Icons.gif_rounded,
                            size: 27,
                            color: Colors.orange,
                          ))
                      : const SizedBox.shrink(),

                  widget.platformFile == null ||
                          audioChecker(widget.platformFile.name) ||
                          pdfChecker(widget.platformFile.name)
                      ? Align(
                          alignment: Alignment.bottomLeft,
                          child: imgEditBtt(),
                        )
                      : const SizedBox.shrink(),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
