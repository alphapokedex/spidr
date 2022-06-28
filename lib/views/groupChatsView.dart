import 'package:flutter/material.dart';
import 'package:spidr_app/views/conversationScreen.dart';

class GroupChatsScreen extends StatefulWidget {
  final String uid;
  final int page;
  final snapshot;
  GroupChatsScreen(this.uid, this.page, this.snapshot);
  @override
  _GroupChatsScreenState createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends State<GroupChatsScreen> {
  PageController pageController;

  Widget groupChatsList() {
    return PageView.builder(
        controller: pageController,
        itemCount: widget.snapshot.data.hits.length as int,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          return ConversationScreen(
            groupChatId: widget.snapshot.data.hits[index].objectID,
            uid: widget.uid,
            spectate: false,
            preview: true,
            initIndex: 0,
            hideBackButton: false,
          );
        });
  }

  @override
  void initState() {
    pageController = PageController(initialPage: widget.page);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, body: groupChatsList());
  }
}
