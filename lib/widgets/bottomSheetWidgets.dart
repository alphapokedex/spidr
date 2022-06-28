import  'package:spidr_app/helper/constants.dart';
import  'package:spidr_app/helper/functions.dart';
import  'package:spidr_app/helper/storyFunctions.dart';
import  'package:spidr_app/services/database.dart';
import  'package:spidr_app/views/camera.dart';
import  'package:spidr_app/views/conversationScreen.dart';
import  'package:spidr_app/views/uploadBttSheetWrapper.dart';
import  'package:spidr_app/views/userProfilePage.dart';
import  'package:spidr_app/widgets/widget.dart';
import  'package:flutter/cupertino.dart';
import  'package:flutter/material.dart';
import  'package:fluttertoast/fluttertoast.dart';
import  'package:spidr_app/views/myBlockList.dart';

openMoreOpsBttSheet({
  BuildContext context,
  platform,
  String groupId,
  String groupType,
  String senderId,
  String mediaId,
  List mediaGallery,
  Map imgObj,
  Map fileObj,
  bool reported,
  bool toChat = true,
  bool anon,
  bool story = false,
  bool explore = false
})async{

  Widget moreOpTile({String label, icon, color = Colors.black}){
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          color: Colors.white
      ),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: ListTile(
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color),),
          trailing: iconContainer(
            icon:icon,
            contColor: color,
            horPad: 5,
            verPad: 5,
          )
      ),
    );
  }

  return await showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0))
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context){
        return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.45,
            builder: (BuildContext context, ScrollController controller){
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                controller: controller,
                child: Column(
                  children: [
                    !story && groupId != null && toChat ?
                    StreamBuilder(
                      stream: DatabaseMethods().groupChatCollection.doc(groupId).snapshots(),
                      builder: (context, snapshot) {
                        if(snapshot.hasData && snapshot.data.data() != null){
                          String hashTag = snapshot.data.data()['hashTag'];
                          String profileImg = snapshot.data.data()['profileImg'];
                          String groupState = snapshot.data.data()['chatRoomState'];
                          bool isMember = snapshot.data.data()['members'].contains(Constants.myUserId);
                          bool oneDay = snapshot.data.data()['oneDay'] != null && snapshot.data.data()['oneDay'];
                          int createdAt = snapshot.data.data()['createdAt'];
                          int timeElapsed = oneDay ? getTimeElapsed(createdAt) : null;
                          return GestureDetector(
                            onTap: (){
                              if(groupState == "public" || isMember){
                                DatabaseMethods()
                                    .getMsgIndex(groupId, mediaId)
                                    .then((val) {
                                  if(val != -1){
                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (context) =>
                                            ConversationScreen(
                                              groupChatId:groupId,
                                              uid:Constants.myUserId,
                                              spectate:false,
                                              preview:true,
                                              initIndex: val,
                                              hideBackButton: false,
                                            )
                                    ));
                                  }else{
                                    Fluttertoast.showToast(msg: "Sorry, this message has been deleted");
                                  }
                                });
                              }else{
                                Fluttertoast.showToast(msg: "Sorry, this circle is private");
                              }
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(30)),
                                  color: Colors.white
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              child: ListTile(
                                  leading: groupProfile(groupId: groupId, profileImg: profileImg,oneDay: oneDay,timeElapsed: timeElapsed),
                                  title: Text(hashTag, style: const TextStyle(fontWeight: FontWeight.w600),),
                                  subtitle: Text(groupState == "public" || isMember ? "view in circle" : "private circle"),
                                  trailing: iconContainer(
                                    icon:groupState == 'private' && !isMember ?
                                    platform == TargetPlatform.android ? Icons.lock_rounded : CupertinoIcons.lock :
                                    Icons.remove_red_eye_rounded,
                                    contColor: Colors.black,
                                    horPad: 5,
                                    verPad: 5,
                                  )
                              ),
                            ),
                          );
                        }else{
                          return const SizedBox.shrink();
                        }
                      }
                    ) : const SizedBox.shrink(),

                    GestureDetector(
                      onTap: (){
                        shareMediaFile(
                            context:context,
                            mediaGallery:mediaGallery,
                            imgObj:imgObj,
                            fileObj: fileObj
                        );
                      },
                      child: moreOpTile(
                          label:"Share",
                          icon:platform == TargetPlatform.android ?
                          Icons.share :
                          CupertinoIcons.share
                      )
                    ),

                    senderId != Constants.myUserId && !reported ?
                    GestureDetector(
                      onTap: ()async{
                        bool reported = await reportContent(
                          context: context,
                          groupId: groupId,
                          senderId: senderId,
                          contentId: mediaId,
                        );
                        if(reported != null && reported) {
                          Navigator.of(context).pop();
                        }
                      },
                      child:moreOpTile(
                          label:"Report",
                          icon:platform == TargetPlatform.android ?
                          Icons.flag_rounded :
                          CupertinoIcons.flag_fill,
                          color: Colors.black
                      )
                    ) : const SizedBox.shrink(),

                    senderId != Constants.myUserId && (story || explore) ?
                    GestureDetector(
                        onTap: (){
                          if(story){
                            storyRemove(
                                owner:false,
                                storyId:mediaId,
                                mediaObj:imgObj,
                                mediaGallery:mediaGallery,
                                groupId:groupId,
                                type:"snippet",
                                seen: true
                            );
                          }else{
                            DatabaseMethods(uid: Constants.myUserId).removeMedia(mediaId);
                          }

                          Navigator.pop(context, true);
                        },
                        child:moreOpTile(
                            label:"Remove",
                            icon:Icons.do_disturb_on_outlined,
                            color: Colors.redAccent
                        )
                    ) : const SizedBox.shrink(),

                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white,),
                        onPressed: (){
                          Navigator.of(context).pop();
                        })
                  ],
                ),
              );

            }
        );
      }
  );
}

openCameraBttSheet({
  BuildContext context,
  String groupId,
  String hashTag,
  String personalChatId,
  bool friend,
  String contactId,
  String contactName
}){
  showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0))
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context){
        return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 1,
            minChildSize: 0.65,
            builder: (BuildContext context, ScrollController controller){
              return AppCameraScreen(
                camScrollController: controller,
                groupChatId: groupId,
                personalChatId: personalChatId,
                contactId: contactId,
                friend: friend,
                backButton: true,
              );
            }
        );
      }
  );
}

openUploadBttSheet({
  BuildContext context,
  String groupId,
  String personalChatId,
  bool friend,
  String contactId,
  int numOfAvlUpl,
  String uploadTo,
  bool singleFile
}) async{
  return await showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0))
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context){
        return DraggableScrollableSheet(
            expand: false,
            maxChildSize: 1,
            initialChildSize: 0.65,
            minChildSize: 0.65,
            builder: (BuildContext context, ScrollController controller){
              return UploadBttSheetWrapper(
                  controller,
                  groupId,
                  personalChatId,
                  friend,
                  contactId,
                  numOfAvlUpl,
                  uploadTo,
                  singleFile
              );
            }
        );
      }
  );
}


openUserProfileBttSheet(BuildContext context, String userId, String username, String profileImg){
  showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0))
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context){
        return DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.65,
            initialChildSize: 0.5,
            minChildSize: 0.5,
            builder: (BuildContext context, ScrollController controller){
              return UserProfileScreen(
                userId:userId,
                blockAble:false,
                scrollController: controller,
              );
            }
        );
      }
  );
}

// openBackpackBttSheet(BuildContext context){
//   showModalBottomSheet(
//       clipBehavior: Clip.antiAlias,
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(15.0))
//       ),
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context){
//         return DraggableScrollableSheet(
//             expand: false,
//             initialChildSize: 1,
//             minChildSize: 0.65,
//             builder: (BuildContext context, ScrollController controller){
//               return BackPackScreen(controller);
//             }
//         );
//       }
//   );
// }

openBlockListBttSheet(BuildContext context){
  showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0))
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context){
        return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 1,
            minChildSize: 0.65,
            builder: (BuildContext context, ScrollController controller){
              return MyBlockList(controller);
            }
        );
      }
  );
}