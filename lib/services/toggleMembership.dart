import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';

import 'database.dart';

class ToggleMemMethods {
  final String userId;
  final String username;
  final BuildContext context;
  ToggleMemMethods({
    this.userId,
    this.username,
    this.context,
  });

  joinChat(
      String hashTag, String groupId, String username, String admin) async {
    await DatabaseMethods(uid: userId)
        .toggleGroupMembership(groupId, "JOIN_PUB_GROUP_CHAT");

    // Navigator.pushReplacement(context, MaterialPageRoute(
    //     builder: (context) => ConversationScreen(
    //         groupChatId:groupId,
    //         hashTag:hashTag,
    //         admin:admin,
    //         uid:userId,
    //         spectate:false,
    //         preview:false,
    //         initIndex:0)
    // ));
  }

  goOnWaitListAndOrSpectate(
      String groupId, String hashTag, String admin, String groupState) async {
    await DatabaseMethods(uid: userId).putOnWaitList(
        groupId, Constants.myName, Constants.myUserId, Constants.myEmail, null);

    // if(groupState == "public"){
    //   Navigator.pushReplacement(context, MaterialPageRoute(
    //       builder: (context) => ConversationScreen(
    //           groupChatId:groupId,
    //           hashTag:hashTag,
    //           admin:admin,
    //           uid:userId,
    //           spectate:true,
    //           preview:false,
    //           initIndex: 0
    //       )
    //   ));
    // }
  }

  requestJoin(String groupId, int numOfMem, double groupCapacity,
      String groupState, String hashTag, String admin) async {
    if (numOfMem < groupCapacity) {
      await DatabaseMethods(uid: userId).requestJoinGroup(groupId,
          Constants.myName, Constants.myUserId, Constants.myEmail, null);
    } else {
      showAlertDialog(groupState, groupId, hashTag, admin);
    }
  }

  showAlertDialog(
      String groupState, String groupId, String hashTag, String admin) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Hey!", style: TextStyle(color: Colors.orange)),
            content: Text(groupState == 'public'
                ? "This group you are trying to join has reached its full capacity. Do you want to be on the waitlist and spectate?"
                : "This group you are requesting to join has reached its full capacity. Do you want to be on the waitlist?"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    goOnWaitListAndOrSpectate(
                        groupId, hashTag, admin, groupState);
                  },
                  child:
                      const Text("YES", style: TextStyle(color: Colors.green))),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("NO", style: TextStyle(color: Colors.red)))
            ],
          );
        });
  }

  // uploadImg(String hashTag, String groupId, String admin, bool myChat){
  //   DateTime now = DateTime.now();
  //   String formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(now);
  //
  //   String fileName = Path.basename(imgObj["imgFile"].path);
  //   Reference ref = FirebaseStorage.instance
  //       .ref()
  //       .child('groupChats/$userId/$fileName');
  //
  //   ref.putFile(imgObj["imgFile"]).then((value){
  //     value.ref.getDownloadURL().then((val){
  //       Map newImgObj = {
  //         "imgUrl":val,
  //         "imgName": fileName,
  //         "imgPath":imgObj["imgFile"].path,
  //         "caption":imgObj['caption'],
  //         "video":imgObj["video"]
  //       };
  //
  //       sendImgOrJoin(newImgObj, hashTag, groupId, admin, myChat, formattedDate, now.microsecondsSinceEpoch);
  //
  //     });
  //   });
  // }
  //
  // sendImgOrJoin(
  //     Map imgObj,
  //     String hashTag,
  //     String groupId,
  //     String admin,
  //     bool myChat,
  //     String dateTime,
  //     int sendTime
  //     ){
  //
  //   DatabaseMethods(uid: userId).addConversationMessages(
  //       groupChatId:groupId,
  //       hashTag:hashTag,
  //       message:'',
  //       username:Constants.myName,
  //       userId:userId,
  //       dateTime:dateTime,
  //       time:sendTime,
  //       imgObj:imgObj,
  //       profileImg:Constants.myProfileImg
  //   );
  //
  //   if(!myChat){
  //     joinChat(hashTag, groupId, Constants.myName, admin);
  //   }else{
  //     Navigator.pushReplacement(context, MaterialPageRoute(
  //         builder: (context) => ConversationScreen(groupId, hashTag, admin, userId, false, false, false, 0)
  //     ));
  //   }
  // }

}
