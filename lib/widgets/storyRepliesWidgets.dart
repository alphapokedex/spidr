import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/helper/storyFunctions.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/storyFuncWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

Widget buildReplyComposer(
  ScrollController controller,
  TargetPlatform platform,
  BuildContext context,
  String storyId,
  String commentId,
  bool storyExist,
  TextEditingController replyEditingController,
  reFormKey,
) {
  return storyExist != null
      ? Container(
          height: storyExist ? 70 : 45,
          margin: const EdgeInsets.all(10),
          child: storyExist
              ? Row(
                  children: [
                    avatarImg(Constants.myProfileImg, 24, false),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Form(
                        key: reFormKey,
                        child: TextFormField(
                            validator: (val) {
                              return !emptyStrChecker(val)
                                  ? val.length <= 300
                                      ? null
                                      : 'Sorry, reply > 300 characters'
                                  : 'Sorry, reply can not be empty';
                            },
                            textAlign: TextAlign.left,
                            autocorrect: true,
                            style: const TextStyle(color: Colors.orange),
                            maxLines: null,
                            controller: replyEditingController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: msgInputDec(
                                context: context, hintText: 'Reply')),
                      ),
                    ),
                    IconButton(
                      icon: Icon(platform == TargetPlatform.android
                          ? Icons.send
                          : CupertinoIcons.arrow_up_circle_fill),
                      iconSize: 25.0,
                      color: Colors.orange,
                      onPressed: () async {
                        await addReply(reFormKey, replyEditingController,
                            storyId, commentId);
                        controller.jumpTo(controller.position.maxScrollExtent);
                      },
                    )
                  ],
                )
              : noStory(),
        )
      : const SizedBox.shrink();
}

Widget replyList(ScrollController controller, Stream replyStream,
    String storyId, String commentId) {
  return StreamBuilder(
      stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
      builder: (context, snapshot) {
        List blockList;
        if (snapshot.hasData && snapshot.data.data() != null) {
          blockList = snapshot.data.data()['blockList'];
        }
        return StreamBuilder(
          stream: replyStream,
          builder: (context, snapshot) {
            return snapshot.hasData && snapshot.data.docs.length > 0
                ? ListView.builder(
                    itemCount: snapshot.data.docs.length,
                    shrinkWrap: true,
                    controller: controller,
                    itemBuilder: (BuildContext context, index) {
                      String replierId =
                          snapshot.data.docs[index].data()['replierId'];
                      String reply = snapshot.data.docs[index].data()['reply'];
                      String replyId = snapshot.data.docs[index].id;
                      List reportedBy =
                          snapshot.data.docs[index].data()['reportedBy'];
                      return blockList == null || !blockList.contains(replyId)
                          ? listTile(
                              context: context,
                              userId: replierId,
                              text: reply,
                              storyId: storyId,
                              commentId: commentId,
                              replyId: replyId,
                              reportedBy: reportedBy)
                          : const SizedBox.shrink();
                    },
                  )
                : noItems(
                    icon: Icons.reply,
                    text: 'no replies yet',
                    mAxAlign: MainAxisAlignment.center);
          },
        );
      });
}
