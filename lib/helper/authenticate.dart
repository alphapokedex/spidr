import 'package:flutter/material.dart';
import 'package:spidr_app/views/signin.dart';
import 'package:spidr_app/views/signup.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({Key key}) : super(key: key);
  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return SignIn(toggleView);
    } else {
      return SignUp(toggleView);
    }
  }
}
