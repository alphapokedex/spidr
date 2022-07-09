import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/views/callScreen.dart';
import 'package:spidr_app/widgets/bottomSheetWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

Widget filesPickerBtt(
    {BuildContext context,
    TargetPlatform platform,
    String groupChatId,
    String personalChatId,
    bool friend,
    String contactId,
    bool disabled,
    Color color}) {
  return IconButton(
      icon: Icon(
        Icons.add_circle,
        color: color,
      ),
      onPressed: disabled == null || !disabled
          ? () {
              openUploadBttSheet(
                  context: context,
                  groupId: groupChatId,
                  personalChatId: personalChatId,
                  friend: friend,
                  contactId: contactId,
                  uploadTo: groupChatId != null ? 'GROUP' : 'PERSONAL');
            }
          : null);
}

Widget callBtt({
  BuildContext context,
  TargetPlatform platform,
  String groupId,
  String personalChatId,
  bool anon,
  ClientRole role,
  bool disabled = false,
  Map inCallUsers,
    Color color
  // String loudUser
}) {
  inCallUsers.removeWhere(
      (key, value) => inCallUsers[key]['userId'] == Constants.myUserId);

  toChat() async {
    bool ready = await checkCamPermission(platform) &&
        await checkMicPermission(platform);
    if (ready) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            groupId: groupId,
            personalChatId: personalChatId,
            anon: anon,
            role: role,
          ),
        ),
      );
    }
  }

  return inCallUsers.isEmpty
      ? IconButton(
          icon: Icon(platform == TargetPlatform.android
              ? Icons.phone
                : CupertinoIcons.phone_fill,
            color: color,
          ),
          onPressed: !disabled ? toChat : null,
        )
      : GestureDetector(
          onTap: toChat,
          child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange, blurRadius: 4.5, spreadRadius: 1.5)
                ],
              ),
              child: userProfile(
                  userId: inCallUsers[inCallUsers.keys.elementAt(0)]['userId'],
                  anon: anon,
                  size: 18,
                  toProfile: false)),
        );
}

Widget sendChatBtt(
    {BuildContext context,
    TargetPlatform platform,
    Function sendMessage,
    Map replyInfo,
    bool disabled}) {
  return Container(
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), color: Colors.orange),
    child: IconButton(
      icon: Icon(platform == TargetPlatform.android
          ? Icons.send
          : CupertinoIcons.arrow_up_circle),
      iconSize: 25.0,
      color: Colors.white,
      key: UniqueKey(),
      onPressed: disabled == null || !disabled
          ? () {
              if (replyInfo == null || replyInfo.isEmpty) {
                sendMessage();
              } else {
                sendMessage(inChatReply: replyInfo);
              }
            }
          : null,
    ),
  );
}

Widget newsendChatBtt(
    {BuildContext context,
    TargetPlatform platform,
    Function sendMessage,
    Map replyInfo,
    bool disabled}) {
  return IconButton(
    icon: Icon(
      Platform.isAndroid ? Icons.send : CupertinoIcons.arrow_up_circle_fill,
      color: Colors.orange,
    ),
    iconSize: 25.0,
    color: Colors.white,
    key: UniqueKey(),
    onPressed: disabled == null || !disabled
        ? () {
            if (replyInfo == null || replyInfo.isEmpty) {
              sendMessage();
            } else {
              sendMessage(inChatReply: replyInfo);
            }
          }
        : null,
  );
}
