import  'package:spidr_app/decorations/widgetDecorations.dart';
import  'package:spidr_app/helper/storyFunctions.dart';
import  'package:spidr_app/services/database.dart';
import  'package:spidr_app/helper/constants.dart';
import  'package:spidr_app/widgets/storyFuncWidgets.dart';
import  'package:flutter/cupertino.dart';
import  'package:flutter/material.dart';
import  "package:spidr_app/helper/functions.dart";
import  "package:spidr_app/widgets/widget.dart";

Widget buildCommentComposer(
    ScrollController controller,
    TargetPlatform platform,
    BuildContext context,
    String storyId,
    String storySenderId,
    bool storyExist,
    TextEditingController commentEditingController,
    comFormKey,
    ){
  return storyExist != null ? Container(
    height: storyExist ? 70 : 45,
    margin: const EdgeInsets.all(10),
    child: storyExist ? Row(
      children: [
        avatarImg(Constants.myProfileImg, 24, false),
        const SizedBox(width:5),
        Expanded(
          child: Form(
            key: comFormKey,
            child: TextFormField(
                validator: (val){
                  return !emptyStrChecker(val) ? val.length <= 300 ? null : "Sorry, comment > 300 characters"  : "Sorry, comment can not be empty";
                },
                textAlign: TextAlign.left,
                autocorrect: true,
                style: const TextStyle(color: Colors.orange),
                maxLines: null,
                controller: commentEditingController,
                textCapitalization: TextCapitalization.sentences,
                decoration: msgInputDec(context:context, hintText: "Comment")
            ),
          ),
        ),
        IconButton(
          icon: Icon(platform == TargetPlatform.android ? Icons.send : CupertinoIcons.arrow_up_circle_fill),
          iconSize: 25.0,
          color: Colors.orange,
          onPressed: () async{
            await addComment(comFormKey, commentEditingController, storyId, storySenderId);
            controller.jumpTo(controller.position.maxScrollExtent);
          },
        )
      ],
    ) : noStory(),
  ) : const SizedBox.shrink();
}

Widget commentList(
    ScrollController controller,
    Stream comStream,
    String storyId,
    bool storyExist,
    TextEditingController replyEditingController,
    reFormKey
    ){
  return StreamBuilder(
    stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
    builder: (context, snapshot) {
      List blockList;
      if(snapshot.hasData && snapshot.data.data() != null){
        blockList = snapshot.data.data()["blockList"];
      }
      return StreamBuilder(
          stream: comStream,
          builder: (context, snapshot) {
            return snapshot.hasData && snapshot.data.docs.length > 0 ?
            ListView.builder(
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                controller: controller,
                itemBuilder: (BuildContext context, index){
                  String senderId = snapshot.data.docs[index].data()["senderId"];
                  String comment = snapshot.data.docs[index].data()["comment"];
                  String commentId = snapshot.data.docs[index].id;
                  List reportedBy = snapshot.data.docs[index].data()["reportedBy"];

                  return blockList == null || !blockList.contains(senderId) ?
                  listTile(
                      context: context,
                      userId:senderId,
                      text: comment,
                      storyId: storyId,
                      commentId: commentId,
                      storyExist: storyExist,
                      replyEditingController:replyEditingController,
                      reFormKey:reFormKey,
                      reportedBy: reportedBy
                  ) : const SizedBox.shrink();
                }

            ) : noItems(icon:Icons.comment_rounded, text: "no comments yet", mAxAlign: MainAxisAlignment.center);
          }
      );
    }
  );
}

Widget commentBtt(
    BuildContext context,
    Stream comStream,
    String storyId,
    String storySenderId,
    bool storyExist,
    TextEditingController commentEditingController,
    TextEditingController replyEditingController,
    comFormKey,
    reFormKey,
    tutorialKey,
    ){
  final TargetPlatform platform = Theme.of(context).platform;
  return StreamBuilder(
    stream: DatabaseMethods().getStoryComments(storyId),
    builder: (context, snapshot) {
      int numOfCom = 0;
      if(snapshot.hasData && snapshot.data != null) {
        numOfCom = snapshot.data.docs.fold(0, (sum, e) => !Constants.myBlockList.contains(e.data()["senderId"]) ? sum + 1 : sum + 0);
      }
      return SizedBox(
        key: tutorialKey,
        width: 55,
        height: 45,
        child: FloatingActionButton(
          heroTag: 'comment',
          backgroundColor: Colors.black45,
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                    platform == TargetPlatform.android ?
                    Icons.comment_rounded :
                    CupertinoIcons.chat_bubble_text_fill,
                    color: Colors.orange
                ),

                onPressed:(){
                  storyBttSheet(
                      context: context,
                      comStream: comStream,
                      storyId: storyId,
                      storySenderId: storySenderId,
                      storyExist: storyExist,
                      commentEditingController: commentEditingController,
                      replyEditingController: replyEditingController,
                      comFormKey: comFormKey,
                      reFormKey: reFormKey
                  );

                },
              ),
              numOfCom > 0 ?
              notifIcon(numOfCom, false) :
              const SizedBox.shrink(),
            ],
          ),
        ),
      );
    }
  );
}