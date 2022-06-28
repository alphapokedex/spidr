import  'package:spidr_app/helper/constants.dart';
import  'package:spidr_app/services/database.dart';
import  'package:flutter/material.dart';
import  "package:spidr_app/widgets/widget.dart";


Widget seenTile(
    BuildContext context,
    String userId,
    ){
  return ListTile(
    leading: userProfile(userId:userId),
    title: userName(userId: userId, fontWeight: FontWeight.bold, color: Colors.white),
  );
}

Widget seenList(controller, List seenLS){
  return seenLS.isNotEmpty ?
  StreamBuilder(
    stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
    builder: (context, snapshot) {
      List blockList;
      if(snapshot.hasData && snapshot.data.data() != null){
        blockList = snapshot.data.data()["blockList"];
      }
      return ListView.builder(
          itemCount: seenLS.length,
          shrinkWrap: true,
          controller: controller,
          itemBuilder: (BuildContext context, index){
            return blockList == null || !blockList.contains(seenLS[index]) ?
            seenTile(context, seenLS[index]) :
            const SizedBox.shrink();
          });
    }
  ) : noItems(icon: Icons.remove_red_eye_rounded, text: "no viewers yet");
}