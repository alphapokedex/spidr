import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/services/fileUpload.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/membersListDisplay.dart';
import 'package:spidr_app/widgets/profilePageWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class EditGroupScreen extends StatefulWidget {
  final String uid;
  final String groupId;
  final String hashTag;
  final String profileImg;
  final String groupState;
  final double groupCapacity;
  final int numOfMem;
  final bool anon;
  final List tags;
  final String groupInfo;

  final bool oneDay;
  final int timeElapsed;

  const EditGroupScreen(
      this.uid,
      this.groupId,
      this.hashTag,
      this.profileImg,
      this.groupState,
      this.groupCapacity,
      this.numOfMem,
      this.anon,
      this.tags,
      this.groupInfo,
      this.oneDay,
      this.timeElapsed);

  @override
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  String hashTag;
  String profileImg;
  String groupInfo = '';
  List tags = [];
  double groupCapacity;
  double numOfMem;
  bool validHashTag = true;

  final formKey = GlobalKey<FormState>();
  TextEditingController hashTagController = TextEditingController();
  TextEditingController infoController = TextEditingController();
  TextEditingController tagController = TextEditingController();

  bool uploading = false;

  PageController controller;

  editGroup() async {
    if (groupCapacity != widget.groupCapacity) {
      DatabaseMethods().updateGroupCapacity(widget.groupId, groupCapacity);
    }

    if (validHashTag && hashTag != widget.hashTag) {
      DatabaseMethods().editGroupHashTag(widget.groupId, hashTag);
    }
  }

  @override
  void dispose() {
    editGroup();
    super.dispose();
  }

  @override
  void initState() {
    setState(() {
      hashTag = widget.hashTag;
      // anon = widget.anon;
      profileImg = widget.profileImg;
      groupCapacity = widget.groupCapacity;
      tags = widget.tags;
      groupInfo = widget.groupInfo;
      numOfMem = widget.numOfMem.toDouble();
    });

    controller = PageController(
        initialPage: groupMIYUs.contains(widget.profileImg)
            ? groupMIYUs.indexOf(widget.profileImg)
            : Random().nextInt(groupMIYUs.length),
        keepPage: false,
        viewportFraction: 0.5);
    hashTagController.text = widget.hashTag;
    infoController.text = widget.groupInfo;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(
          color: Colors.black,
        ),
        elevation: 0.0,
        actions: [
          GestureDetector(
            onTap: () async {
              bool deleted = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DeleteGroupDialog(hashTag, widget.groupId);
                  });

              if (deleted != null && deleted) {
                Navigator.pop(context, true);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: const [
                  Text('Delete Circle', style: TextStyle(color: Colors.red)),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width / 4,
                      width: MediaQuery.of(context).size.width / 4,
                      child: Stack(
                        children: [
                          Center(
                              child: groupProfile(
                                  height: 81,
                                  width: 81,
                                  oneDay: widget.oneDay,
                                  timeElapsed: widget.timeElapsed,
                                  profileImg: profileImg,
                                  avatarSize: 36)),
                          GestureDetector(
                            onTap: () async {
                              if (!uploading) {
                                setState(() {
                                  uploading = true;
                                });
                                String imgUrl = await UploadMethods(
                                        profileImg: profileImg,
                                        groupId: widget.groupId)
                                    .pickAndUploadMedia(
                                        'GROUP_PROFILE_IMG', false);

                                setState(() {
                                  uploading = false;
                                });

                                if (imgUrl != null) {
                                  setState(() {
                                    profileImg = imgUrl;
                                  });
                                  DatabaseMethods()
                                      .replaceGroupPic(imgUrl, widget.groupId);
                                }
                              }
                            },
                            child: Align(
                                alignment: Alignment.bottomRight,
                                child: !uploading
                                    ? imgEditBtt()
                                    : const SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.orange),
                                        ))),
                          )
                        ],
                      ),
                    ),
                    groupStateIndicator(
                        widget.groupState,
                        widget.anon != null && widget.anon,
                        MainAxisAlignment.center),
                    groupInfo.isEmpty
                        ? GestureDetector(
                            onTap: () {
                              showTextBoxDialog(
                                  context: context,
                                  text: 'About Circle',
                                  textEditingController: infoController,
                                  errorText: 'Sorry, this can not be empty',
                                  editQuote: editGroupInfo,
                                  formKey: formKey);
                            },
                            child: infoEditBtt(
                                context: context, text: 'About Circle'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                infoText(
                                    text: groupInfo,
                                    textAlign: TextAlign.center),
                                const SizedBox(
                                  width: 5,
                                ),
                                GestureDetector(
                                    onTap: () {
                                      showTextBoxDialog(
                                          context: context,
                                          text: 'Circle Info',
                                          textEditingController: infoController,
                                          errorText:
                                              'Sorry, your circle info can not be empty',
                                          editQuote: editGroupInfo,
                                          formKey: formKey);
                                    },
                                    child: infoEditIcon())
                              ],
                            ),
                          ),
                    Container(
                        height: 45,
                        // width: MediaQuery.of(context).size.width*0.9,
                        alignment: Alignment.center,
                        child: ProfileTagList(
                          editable: true,
                          tagController: tagController,
                          tags: tags,
                          editTag: addOrEditGroupTag,
                          delTag: delGroupTag,
                          formKey: formKey,
                          tagNum: tags.length < Constants.maxTags
                              ? tags.length + 1
                              : Constants.maxTags,
                        )),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.155,
                      child: memberList(
                          context: context,
                          edit: true,
                          groupId: widget.groupId,
                          hashTag: hashTag,
                          anon: widget.anon),
                    ),
                    TextField(
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.black),
                        controller: hashTagController,
                        onChanged: (val) {
                          if (val.length > 18 || emptyStrChecker(val)) {
                            setState(() {
                              validHashTag = false;
                            });
                            hashTag = widget.hashTag;
                          } else {
                            setState(() {
                              validHashTag = true;
                            });
                            hashTag = val.startsWith('#')
                                ? val.toUpperCase()
                                : '#${val.toUpperCase()}';
                          }
                        },
                        decoration: hashTagFromDec(
                            hashTagController.text.length, validHashTag)),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Slider(
                              activeColor: Colors.orange,
                              value: groupCapacity,
                              min: 5,
                              max: 50,
                              divisions: 9,
                              onChanged: (newCapacity) {
                                setState(() {
                                  groupCapacity = newCapacity >= numOfMem
                                      ? newCapacity
                                      : numOfMem;
                                });
                              },
                              label: '$groupCapacity',
                            ),
                            Text(
                              '$groupCapacity',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400),
                            )
                          ],
                        ),
                        const Text(
                          'Circle Limit (50)',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  editGroupInfo(String newQuote) {
    if (formKey.currentState.validate()) {
      setState(() {
        groupInfo = infoController.text;
      });
      DatabaseMethods().editGroupInfo(newQuote, widget.groupId);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  delGroupTag(String tag) {
    setState(() {
      tags.remove(tag);
    });

    DatabaseMethods().delGroupTag(tag, widget.groupId);
  }

  addOrEditGroupTag(String newTag, int index) {
    if (formKey.currentState.validate()) {
      if (tags.length - 1 < index) {
        tags.add(newTag);
        setState(() {
          tags = tags;
        });
      } else {
        setState(() {
          tags[index] = newTag;
        });
      }
      DatabaseMethods().addGroupTag(newTag, index, widget.groupId);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
