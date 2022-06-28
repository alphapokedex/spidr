// import  'dart:async';
// import  'dart:io';
//
// import  'package:spidr_app/helper/constants.dart';
// import  'package:spidr_app/helper/storyFunctions.dart';
// import  'package:spidr_app/services/database.dart';
// import  'package:spidr_app/widgets/widget.dart';
// import  'package:firebase_storage/firebase_storage.dart';
// import  'package:flutter/material.dart';
// import  'package:spidr_app/views/sendSnippetDialog.dart';
//
// class SendMediaDialog extends StatefulWidget {
//   final List mediaList;
//   final String mediaPath;
//   // final List tags;
//   final String caption;
//   final List gifs;
//   // final bool anon;
//   final bool video;
//   bool mature;
//
//   SendMediaDialog({
//     this.mediaList,
//     this.mediaPath,
//     // this.tags,
//     this.caption,
//     this.gifs,
//     // this.anon,
//     this.video,
//     this.mature
//   });
//   @override
//   _SendMediaDialogState createState() => _SendMediaDialogState();
// }
//
// class _SendMediaDialogState extends State<SendMediaDialog> {
//
//   final TextStyle textStyle = TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600);
//   final TextStyle sectTxtStyle = TextStyle(
//     fontSize: 16,
//     color: Colors.white,
//     fontWeight: FontWeight.bold,
//     shadows: [
//       Shadow(
//         color: Colors.black54,
//         offset: Offset(1, 1.5),
//         blurRadius: 1,
//       ),
//     ],
//   );
//
//   final TextStyle nameTxtStyle = TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold);
//
//   Map sendTo = {};
//   ScrollController sendToController = ScrollController();
//
//   Stream fdStream;
//   Stream gcStream;
//
//
//   Widget friendList(){
//     return StreamBuilder(
//         stream: fdStream,
//         builder: (context, snapshot) {
//           return snapshot.hasData && snapshot.data != null ? snapshot.data.docs.length > 0 ?
//           ListView.builder(
//               itemCount: snapshot.data.docs.length,
//               scrollDirection: Axis.horizontal,
//               itemBuilder: (context, index) {
//                 String friendId = snapshot.data.docs[index].id;
//                 String profileImg = snapshot.data.docs[index].data()["profileImg"];
//                 String name = snapshot.data.docs[index].data()["name"];
//                 return GestureDetector(
//                   onTap: (){
//                     if(!sendTo.containsKey(friendId)){
//                       sendTo[friendId] = {"type":"user", "profileImg":profileImg, "label":name};
//                       Timer(
//                         Duration(seconds: 1),
//                             () => sendToController.jumpTo(sendToController.position.maxScrollExtent),
//                       );
//                     }else{
//                       sendTo.remove(friendId);
//                     }
//                     setState(() {});
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Stack(
//                           children: [
//                             avatarImg(profileImg, 24),
//                             sendTo.containsKey(friendId) ?
//                             Icon(Icons.check_circle,color: Colors.black) :
//                             SizedBox.shrink()
//                           ],
//                         ),
//                         SizedBox(height: 4.5,),
//                         Text(name, style: nameTxtStyle,)
//                       ],
//                     ),
//                   ),
//                 );
//               }) : noItems(
//               icon:Icons.auto_awesome,
//               text:"no friends yet",
//               mAxAlign:MainAxisAlignment.center) : sectionLoadingIndicator();
//         }
//     );
//   }
//
//   Widget groupList(){
//     return StreamBuilder(
//         stream: gcStream,
//         builder: (context, snapshot) {
//           return snapshot.hasData && snapshot.data != null ? snapshot.data.docs.length > 0 ?
//           ListView.builder(
//             itemCount: snapshot.data.docs.length,
//             scrollDirection: Axis.horizontal,
//             itemBuilder: (context, index) {
//               String groupId = snapshot.data.docs[index].id;
//               String hashTag = snapshot.data.docs[index].data()["hashTag"];
//               String profileImg = snapshot.data.docs[index].data()["profileImg"];
//               bool anon = snapshot.data.docs[index].data()["anon"];
//               return GestureDetector(
//                 onTap:(){
//                   if(!sendTo.containsKey(groupId)){
//                     sendTo[groupId] = {"type":"group", "profileImg":profileImg, "label":hashTag, "anon":anon};
//
//                     Timer(
//                       Duration(seconds: 1),
//                           () => sendToController.jumpTo(sendToController.position.maxScrollExtent),
//                     );
//                   }else{
//                     sendTo.remove(groupId);
//                   }
//                   setState(() {});
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Stack(
//                         children: [
//                           avatarImg(profileImg, 24),
//                           sendTo.containsKey(groupId) ?
//                           Icon(Icons.check_circle,color: Colors.black) :
//                           SizedBox.shrink()
//                         ],
//                       ),
//                       SizedBox(height: 4.5,),
//                       Text(hashTag,style: nameTxtStyle,)
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ) : noItems(
//               icon:Icons.donut_large_rounded,
//               text:"no circles yet",
//               mAxAlign:MainAxisAlignment.center,
//               color: Colors.black
//           ) :
//           sectionLoadingIndicator();
//         }
//     );
//   }
//
//   getFdChats() {
//     fdStream = DatabaseMethods().userCollection
//         .where('friends', arrayContains: Constants.myUserId)
//         .snapshots();
//   }
//
//   getGCChats(){
//     gcStream = DatabaseMethods().groupChatCollection
//         .where('deleted', isNotEqualTo: true)
//         .where('members', arrayContains: Constants.myUserId)
//         .snapshots();
//   }
//
//   sendRegular(){
//     DateTime now = DateTime.now();
//
//     storyUpload(
//         mediaPath: widget.mediaPath,
//         mediaList: widget.mediaList,
//         caption: widget.caption,
//         gifs: widget.gifs,
//         video: widget.video,
//         sendTime: now.microsecondsSinceEpoch,
//         type: "regular",
//         sendTo: sendTo,
//         mature: widget.mature
//     );
//
//     Navigator.pop(context, true);
//   }
//
//   sendFriends(){
//     DateTime now = DateTime.now();
//
//     storyUpload(
//         mediaPath: widget.mediaPath,
//         mediaList: widget.mediaList,
//         caption: widget.caption,
//         gifs: widget.gifs,
//         video: widget.video,
//         sendTime: now.microsecondsSinceEpoch,
//         type: "friends",
//         mature: widget.mature
//     );
//
//     Navigator.pop(context, true);
//   }
//
//   sendSnippet() async{
//     bool sent = await showDialog(
//         context: context,
//         builder: (BuildContext context){
//           return SendSnippetDialog(
//             mediaList: widget.mediaList,
//             mediaPath: widget.mediaPath,
//             caption: widget.caption,
//             gifs: widget.gifs,
//             video: widget.video,
//           );
//         }
//     );
//
//     if(sent != null && sent) Navigator.pop(context, sent);
//   }
//
//   @override
//   void initState() {
//     
//     getGCChats();
//     getFdChats();
//     setState(() {});
//     super.initState();
//   }
//
//   Widget sendToTile(String sendToId, String profileImg, String label){
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [BoxShadow(blurRadius: 4.5, color: Colors.black, spreadRadius: 4.5)],
//               ),
//               child: avatarImg(profileImg, 18)
//           ),
//           SizedBox(height: 4.5,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(label, style: nameTxtStyle,),
//               SizedBox(width: 5),
//               GestureDetector(
//                 onTap: (){
//                   setState(() {
//                     sendTo.remove(sendToId);
//                   });
//                 },
//                 child: iconContainer(
//                     Icons.cancel_rounded,
//                     Colors.red
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final TargetPlatform platform = Theme.of(context).platform;
//
//     ButtonStyle bttStyle(borderRad){
//       return ElevatedButton.styleFrom(
//         primary: Colors.black,
//         elevation: 3,
//         shape: RoundedRectangleBorder(
//             borderRadius: borderRad
//         ),
//       );
//     }
//     Widget snippetElBtt = ElevatedButton(
//       style: bttStyle(BorderRadius.horizontal(right:Radius.circular(30))),
//       onPressed: sendTo.length == 0 ? (){
//         sendSnippet();
//       } : null,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text("Broadcast", style: textStyle,),
//           Icon(Icons.settings_input_antenna, size: 18)
//         ],
//       ),
//     );
//     Widget friendElBtt = ElevatedButton(
//       style: bttStyle(BorderRadius.horizontal(left:Radius.circular(30))),
//       onPressed: sendTo.length == 0 ? (){
//         sendFriends();
//       } : null,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text("All Friends", style: textStyle,),
//           Icon(Icons.auto_awesome, size: 18,)
//         ],
//       ),
//     );
//     return Dialog(
//       insetPadding: EdgeInsets.all(15),
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(30))
//       ),
//       backgroundColor: Colors.white54,
//       child: Container(
//         height: MediaQuery.of(context).size.height*0.65,
//         child: SingleChildScrollView(
//           physics: NeverScrollableScrollPhysics(),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 height: MediaQuery.of(context).size.height*0.135,
//                 padding: EdgeInsets.symmetric(horizontal: 5),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Expanded(
//                       child: ListView(
//                         reverse: true,
//                         physics: BouncingScrollPhysics(),
//                         controller: sendToController,
//                         scrollDirection: Axis.horizontal,
//                         children: sendTo.keys.map(
//                                 (e) => sendToTile(e, sendTo[e]['profileImg'], sendTo[e]['label'])
//                         ).toList(),
//                       ),
//                     ),
//                     Container(
//                       width: MediaQuery.of(context).size.width*0.225,
//                       alignment: Alignment.center,
//                       margin: EdgeInsets.symmetric(horizontal: 5),
//                       child: GestureDetector(
//                         onTap: () {
//                           if(sendTo.length > 0)
//                             sendRegular();
//                         },
//                         child: mediaSendBtt(
//                           icon:Icons.send_rounded,
//                           labelColor:sendTo.length == 0 ? Colors.orange : Colors.white,
//                           off:sendTo.length == 0,
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal:18.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Text("My Circles", style: sectTxtStyle),
//                     Container(
//                       height: MediaQuery.of(context).size.height*0.18,
//                       child: groupList(),
//                     ),
//                     Text("My Friends", style: sectTxtStyle),
//                     Container(
//                       height: MediaQuery.of(context).size.height*0.18,
//                       child: friendList(),
//                     ),
//                   ],
//                 ),
//               ),
//
//               StreamBuilder(
//                   stream: DatabaseMethods(uid: Constants.myUserId).getMyStream(),
//                   builder: (context, snapshot) {
//                     return snapshot.hasData && snapshot.data != null ?
//                     snapshot.data.data()['friends'] != null && snapshot.data.data()['friends'].length > 0 ?
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         friendElBtt,
//                         VerticalDivider(color: Colors.black,),
//                         snippetElBtt
//                       ],
//                     ) : snippetElBtt :
//                     SizedBox.shrink();
//                   }
//               ),
//             ],
//           ),
//         ),
//       ),
//
//     );
//   }
// }
