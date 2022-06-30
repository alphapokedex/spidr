import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import "package:spidr_app/widgets/widget.dart";

import 'dialogWidgets.dart';

Widget memberTile(
    {String userId,
    BuildContext context,
    bool editGroup,
    String groupId,
    String hashTag,
    bool admin,
    bool anon}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      children: [
        userProfile(userId: userId, anon: anon),
        Container(
            margin: const EdgeInsets.all(5.0),
            child: anon == null || !anon
                ? userName(userId: userId, fontWeight: FontWeight.w600)
                : const SizedBox.shrink()),
        GestureDetector(
          onTap: () async {
            if (editGroup) {
              String actionType =
                  await showBanMemberDialog(context, hashTag, userId, anon);
              DatabaseMethods(uid: userId)
                  .toggleGroupMembership(groupId, actionType);
            }
          },
          child: Container(
              decoration: BoxDecoration(
                  color: editGroup ? Colors.redAccent : Colors.black,
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                      editGroup
                          ? "Ban"
                          : admin
                              ? "Admin"
                              : "Mem",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  !editGroup && admin
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                          width: 10,
                          height: 10,
                          alignment: Alignment.topCenter,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.orange),
                        )
                      : const SizedBox.shrink()
                ],
              )),
        )
      ],
    ),
  );
}

Widget memberList(
    {BuildContext context,
    bool edit,
    String groupId,
    String hashTag,
    String admin,
    bool anon}) {
  return StreamBuilder(
      stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
      builder: (context, snapshot) {
        List blockList;
        if (snapshot.hasData && snapshot.data.data() != null) {
          blockList = snapshot.data.data()["blockList"];
        }
        return StreamBuilder(
            stream: DatabaseMethods().getGroupMembers(groupId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                if (snapshot.data.docs.length > 0) {
                  return ListView.builder(
                      itemCount: snapshot.data.docs.length,
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        String userId =
                            snapshot.data.docs[index].data()['userId'];
                        if (edit) {
                          return snapshot.data.docs.length > 1
                              ? userId != Constants.myUserId &&
                                      (blockList == null ||
                                          !blockList.contains(userId))
                                  ? memberTile(
                                      userId: userId,
                                      context: context,
                                      editGroup: edit,
                                      hashTag: hashTag,
                                      groupId: groupId,
                                      anon: anon)
                                  : const SizedBox.shrink()
                              : noItems(
                                  icon: Icons.supervised_user_circle_rounded,
                                  text: "no members yet",
                                  mAxAlign: MainAxisAlignment.center);
                        } else {
                          return !Constants.myBlockList.contains(userId)
                              ? memberTile(
                                  userId: userId,
                                  context: context,
                                  editGroup: edit,
                                  groupId: groupId,
                                  admin: admin == userId,
                                  anon: anon)
                              : const SizedBox.shrink();
                        }
                      });
                } else {
                  return const SizedBox.shrink();
                }
              } else {
                return const SizedBox.shrink();
              }
            });
      });
}
