import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:video_compress/video_compress.dart';

class UploadMethods {
  final String userId;
  final String userName;
  final String profileImg;
  final String groupId;

  UploadMethods({this.userId, this.userName, this.profileImg, this.groupId});

  Future<File> compressImage(File file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      rotate: 0,
    );
    return result;
  }

  Future getImage() async {
    var pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
    );

    if (pickedImage != null) {
      return File(pickedImage.path);
    } else {
      return null;
    }
  }

  Future getVideo() async {
    XFile pickedVideo = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedVideo != null) {
      return File(pickedVideo.path);
    } else {
      return null;
    }
  }

  Future getFile() async {
    FilePickerResult pickedFile = await FilePicker.platform.pickFiles();

    if (pickedFile != null) {
      return pickedFile;
    } else {
      return null;
    }
  }

  Future<File> getProfImage() async {
    //get image from gallery
    var pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
    );
    //crop image with imageCropper (Make sure manifest dependency is there)
    File croppedImage;
    if (pickedImage != null) {
      CroppedFile image = await ImageCropper().cropImage(
        sourcePath: pickedImage.path,
        cropStyle: CropStyle.circle,
        maxWidth: 1000,
        maxHeight: 1000,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );
      croppedImage = File(image.path);
    }

    if (croppedImage != null) {
      return File(croppedImage.path);
    } else {
      return null;
    }
  }

  Future pickAndUploadMedia(String type, bool video) async {
    File cImg;
    File imgFile;
    String imgUrl;

    if (!video) {
      if (type == "USER_PROFILE_IMG" || type == "GROUP_PROFILE_IMG") {
        imgFile = await getProfImage();
      } else {
        imgFile = await getImage();
      }
    } else {
      imgFile = await getVideo();
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath =
        !video ? '${extDir.path}/Pictures' : '${extDir.path}/Videos';
    await Directory(dirPath).create(recursive: true);
    final String imgName = !video
        ? '${DateTime.now().microsecondsSinceEpoch}.jpeg'
        : '${DateTime.now().microsecondsSinceEpoch}.mp4';
    final String filepath = '$dirPath/$imgName';

    if (imgFile != null) {
      if (video) {
        final compressedMedia = await VideoCompress.compressVideo(
          imgFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
        final x = compressedMedia.toJson();
        final cVid = File(x['path']);
        cImg = cVid;
      } else {
        cImg = await compressImage(imgFile, filepath);
      }

      switch (type) {
        case "USER_PROFILE_IMG":
          if (!profileImg.startsWith('assets', 0)) {
            Reference imgRef = FirebaseStorage.instance.refFromURL(profileImg);
            await imgRef.delete();
          }

          Reference ref = FirebaseStorage.instance
              .ref()
              .child('usersProfileImg/${Constants.myUserId}/$imgName');

          await ref.putFile(cImg).then((value) async {
            await value.ref.getDownloadURL().then((val) {
              imgUrl = val;
            });
          });
          return imgUrl;
          break;
        case "GROUP_PROFILE_IMG":
          if (!profileImg.startsWith('assets', 0)) {
            Reference imgRef = FirebaseStorage.instance.refFromURL(profileImg);
            await imgRef.delete();
          }

          Reference ref = FirebaseStorage.instance
              .ref()
              .child('groupProfileImg/$groupId/$imgName');
          await ref.putFile(cImg).then((value) async {
            await value.ref.getDownloadURL().then((val) {
              imgUrl = val;
            });
          });
          return imgUrl;
          break;
        case "USER_BANNER":
          Reference ref = FirebaseStorage.instance
              .ref()
              .child('usersBanner/${Constants.myUserId}/$imgName');

          await ref.putFile(cImg).then((value) async {
            await value.ref.getDownloadURL().then((val) {
              imgUrl = val;
            });
          });
          return imgUrl;
          break;
      }
    }
  }

  // Future pickAndUploadFile(String chatId, String type) async {
  //   final FilePickerResult pickedFile = await getFile();
  //   Directory tempDir = await getTemporaryDirectory();
  //   bool audio = false;
  //   bool document = false;
  //
  //   if(pickedFile != null){
  //     File file = File(pickedFile.files.single.path);
  //     PlatformFile platformFile = pickedFile.files.first;
  //
  //     String fileName = platformFile.name;
  //     String filePath = '${tempDir.path}/$fileName';
  //     int size = platformFile.size;
  //     String fileSize = filesize(size);
  //     final mimeType = lookupMimeType(filePath);
  //
  //     audio = mimeType.contains('audio/flac') ||
  //         mimeType.contains('audio/wav') ||
  //         mimeType.contains('audio/wma') ||
  //         mimeType.contains('audio/aac') ||
  //         mimeType.contains('audio/mp3');
  //
  //     document = mimeType.contains('application/pdf');
  //
  //     if (getFileSize(file) > 20){
  //       Fluttertoast.showToast(
  //           msg: "File size is greater than 20MB. Please upload a file smaller than 20MB",
  //           toastLength: Toast.LENGTH_SHORT,
  //           gravity: ToastGravity.SNACKBAR,
  //           timeInSecForIosWeb: 3,
  //           backgroundColor: Colors.black,
  //           textColor: Colors.white,
  //           fontSize: 16.0
  //       );
  //       return null;
  //     }
  //
  //     switch(type){
  //       case "PERSONAL":
  //         Reference ref = FirebaseStorage.instance
  //             .ref()
  //             .child('personalChats/${Constants.myUserId}/${DateTime.now().microsecondsSinceEpoch}.file');
  //
  //         ref.putFile(file).then((value){
  //           value.ref.getDownloadURL().then((val){
  //             sendFile(null, {"fileUrl":val,"fileName":fileName, "fileSize":fileSize}, chatId, type, audio, document);
  //           });
  //         });
  //         break;
  //       case "GROUP":
  //         Reference ref = FirebaseStorage.instance
  //             .ref()
  //             .child('groupChats/${Constants.myUserId}/${DateTime.now().microsecondsSinceEpoch}.file');
  //
  //         ref.putFile(file).then((value){
  //           value.ref.getDownloadURL().then((val){
  //             sendFile(null, {"fileUrl":val,"fileName":fileName, "fileSize":fileSize}, chatId, type, audio, document);
  //           });
  //         });
  //         break;
  //     }
  //
  //   }
  //
  // }

}
