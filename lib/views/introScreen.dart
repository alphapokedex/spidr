import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:spidr_app/main.dart';

class Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: 'Introduction screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OnBoardingPage(),
    );
  }
}

class OnBoardingPage extends StatefulWidget {
  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    const bodyStyle = TextStyle(fontSize: 18.0, color: Colors.black);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 27.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "Welcome to the Spidr Community",
          body:
              "The easiest way to be a part of the happ(ening)iness around you.",
          image: Center(
              child: Image.asset(
            "assets/icon/1.PNG",
            width: MediaQuery.of(context).size.width / 1.4,
            height: MediaQuery.of(context).size.width / 1.4,
          )),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Join a Circle",
          body:
              "Scroll through and join anonymous conversations at your school, work and city. Exchange and receive the latest happenings around you",
          image: Center(
              child: Image.asset(
            "assets/icon/Joinacircle2.png",
            width: MediaQuery.of(context).size.width / 1.4,
            height: MediaQuery.of(context).size.width / 1.4,
          )),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Broadcast your message",
          body:
              "Take a Broadcast, add a hashtag, send and every group and user with that hashtag in their profile gets to see ¥our creation.",
          image: Center(
              child: Image.asset(
            "assets/images/CarPurp.png",
            width: MediaQuery.of(context).size.width / 1.4,
            height: MediaQuery.of(context).size.width / 1.4,
          )),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Receive A Broadcast",
          bodyWidget: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(children: [
              TextSpan(
                  text:
                      "Add Spidr Tags to your bio to receive special broadcasts on the latest happenings around you.",
                  style: bodyStyle),
              WidgetSpan(
                child: Icon(Icons.donut_large_rounded),
              )
            ]),
          ),
          image: Center(
              child: Image.asset(
            "assets/icon/Untitled_design-3.png",
            width: MediaQuery.of(context).size.width / 1.4,
            height: MediaQuery.of(context).size.width / 1.4,
          )),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Add Your Spidr Tags",
          body:
              "Add Spidr Tags relating to topics that interest you to receive broadcasts and suggestions for group-chats",
          image: Center(
              child: Image.asset(
            "assets/images/TagGirl.png",
            width: MediaQuery.of(context).size.width / 1.2,
            height: MediaQuery.of(context).size.width / 1.2,
          )),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      //onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      nextFlex: 0,
      skip: const Text('Skip',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
      next: Icon(
        platform == TargetPlatform.android
            ? Icons.arrow_forward
            : CupertinoIcons.arrow_right,
        color: Colors.black,
      ),
      done: const Text('Done',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      dotsDecorator: const DotsDecorator(
        size: Size(5.0, 5.0),
        color: Colors.grey,
        activeColor: Colors.orange,
        activeSize: Size(15.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
