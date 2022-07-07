import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spidr_app/helper/authenticate.dart';
import 'package:spidr_app/helper/helperFunctions.dart';
import 'package:spidr_app/services/auth.dart';
import 'package:spidr_app/views/introScreen.dart';
import 'package:spidr_app/views/pageViewsWrapper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize(debug: false);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool seen = prefs.getBool('seen') ?? false;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: seen ? const MyApp() : Intro(),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool userIsLoggedIn;

  @override
  void initState() {
    super.initState();
    markSeen();
    getLoggedInState();
  }

  Future markSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('seen', true);
  }

  getLoggedInState() async {
    await HelperFunctions.getUserLoggedInSharedPreference().then((val) {
      setState(() {
        userIsLoggedIn = val;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Provider<AuthMethods>(
      create: (_) => AuthMethods(),
      child: MaterialApp(
        title: 'Spidr',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xff1F1F1F),
          primaryColor: const Color(0xfffb934d),
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          canvasColor: Colors.transparent,
        ),
        home: userIsLoggedIn != null && userIsLoggedIn
            ? const PageViewsWrapper()
            : const Center(child: Authenticate()),
      ),
    );
  }
}
