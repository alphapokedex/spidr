import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/groupProfilePage.dart';
import 'package:spidr_app/widgets/widget.dart';

Widget groupTile(
  BuildContext context,
  String groupId,
  String hashTag,
  String admin,
  String profileImg,
  String groupState,
  bool anon,
  String school,
  String program,
) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GroupProfileScreen(
                  groupId: groupId,
                  admin: admin,
                  fromChat: false,
                  preview: true)));
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        profileDisplay(profileImg),
        borderedText(hashTag, Colors.black),
        groupStateIndicator(groupState, anon, MainAxisAlignment.center)
      ],
    ),
  );
}

Widget groupList(String userId) {
  return StreamBuilder(
    stream: DatabaseMethods(uid: userId).getUserChats(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        if (snapshot.data.docs.length > 0) {
          return StaggeredGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 9.0,
            crossAxisSpacing: 9.0,
            children: snapshot.data.docs.map<Widget>(
              (doc) {
                String groupId = doc.id;
                return StreamBuilder(
                  stream: DatabaseMethods()
                      .groupChatCollection
                      .doc(groupId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data.data() != null) {
                      String hashTag = snapshot.data.data()['hashTag'];
                      String admin = snapshot.data.data()['admin'];
                      String profileImg = snapshot.data.data()['profileImg'];
                      String groupState = snapshot.data.data()['chatRoomState'];
                      bool anon = snapshot.data.data()['anon'];
                      String school = snapshot.data.data()['school'];
                      String program = snapshot.data.data()['program'];
                      return groupState != 'invisible'
                          ? groupTile(
                              context,
                              groupId,
                              hashTag,
                              admin,
                              profileImg,
                              groupState,
                              anon != null && anon,
                              school,
                              program,
                            )
                          : const SizedBox.shrink();
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ).toList(),
          );
        } else {
          return const SizedBox.shrink();
        }
      } else {
        return sectionLoadingIndicator();
      }
    },
  );
}
