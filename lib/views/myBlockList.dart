import 'package:flutter/material.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/widget.dart';

class MyBlockList extends StatefulWidget {
  final ScrollController scrollController;
  const MyBlockList(this.scrollController);

  @override
  _MyBlockListState createState() => _MyBlockListState();
}

class _MyBlockListState extends State<MyBlockList> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.only(top: height * 0.065, right: 10, left: 10),
      child: Column(
        children: [
          const Icon(
            Icons.block_rounded,
            color: Colors.red,
          ),
          Divider(
            height: 27,
            thickness: 1.5,
            color: Colors.red,
            indent: width * 0.1,
            endIndent: width * 0.1,
          ),
          Expanded(
              child: StreamBuilder(
                  stream:
                      DatabaseMethods(uid: Constants.myUserId).getMyStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data.data() != null) {
                      List blockList = snapshot.data.data()["blockList"];
                      // List anonIndices = snapshot.data.data()["anonIndices"];
                      return blockList != null && blockList.isNotEmpty
                          ? ListView.builder(
                              itemCount: blockList.length,
                              controller: widget.scrollController,
                              itemBuilder: (context, index) {
                                String userId = blockList[index];
                                // bool anon = anonIndices[index];
                                return Container(
                                  decoration: const BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      color: Colors.white),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 9),
                                  child: ListTile(
                                    leading: userProfile(
                                        userId: userId, toProfile: false),
                                    title: userName(
                                        userId: userId,
                                        fontWeight: FontWeight.bold),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        DatabaseMethods(uid: Constants.myUserId)
                                            .unBlockUser(userId);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              })
                          : noItems(
                              icon: Icons.block_rounded,
                              text: "no blocked users",
                              mAxAlign: MainAxisAlignment.center);
                    } else {
                      return sectionLoadingIndicator();
                    }
                  })),
        ],
      ),
    );
  }
}
