import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spidr_app/decorations/widgetDecorations.dart';
import 'package:spidr_app/helper/constants.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/bottomSheetWidgets.dart';
import 'package:spidr_app/widgets/dialogWidgets.dart';
import 'package:spidr_app/widgets/widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifOff;

  setUpMyInfo() async {
    DocumentSnapshot myDS =
        await DatabaseMethods(uid: Constants.myUserId).getUserById();
    setState(() {
      notifOff = myDS.data().toString().contains("notifOff")
          ? myDS.get("notifOff")
          : false;
    });
  }

  @override
  void initState() {
    setUpMyInfo();
    super.initState();
  }

  Widget notificationTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          color: Colors.white,
          boxShadow: [circleShadow]),
      child: ListTile(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        trailing: notifOff != null
            ? Switch(
                value: !notifOff,
                onChanged: (value) {
                  setState(() {
                    notifOff = !value;
                    debugPrint(notifOff.toString());
                  });
                  if (notifOff) {
                    DatabaseMethods(uid: Constants.myUserId).turnOffNotif();
                  } else {
                    DatabaseMethods(uid: Constants.myUserId).turnOnNotif();
                  }
                },
                activeTrackColor: Colors.black54,
                activeColor: Colors.black,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget clearSearchTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          color: Colors.white,
          boxShadow: [circleShadow]),
      child: ListTile(
        title: const Text(
          "Clear Search History",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        trailing: iconContainer(
          icon: Icons.history_rounded,
          contColor: Colors.black,
          horPad: 5,
          verPad: 5,
        ),
        onTap: () async {
          bool clear = await showClearSearchDialog(context);
          if (clear != null && clear) {
            DatabaseMethods(uid: Constants.myUserId).clearRecentSearch();
            showCenterFlash(
                alignment: Alignment.center, context: context, text: 'Cleared');
          }
        },
      ),
    );
  }

  Widget blockListTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          color: Colors.white,
          boxShadow: [circleShadow]),
      child: ListTile(
        title: const Text(
          "Blocked List",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
        ),
        trailing: iconContainer(
          icon: Icons.block_rounded,
          contColor: Colors.red,
          horPad: 5,
          verPad: 5,
        ),
        onTap: () {
          openBlockListBttSheet(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: const Icon(
            Icons.settings,
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          elevation: 0.0,
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              notificationTile(),
              clearSearchTile(),
              blockListTile(),
            ],
          ),
        ));
  }
}
