import 'package:flutter/material.dart';
import 'package:spidr_app/helper/functions.dart';
import 'package:spidr_app/helper/helperFunctions.dart';
import 'package:spidr_app/services/auth.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/widgets/widget.dart';
import 'package:url_launcher/url_launcher.dart';

import './pageViewsWrapper.dart';

class SignUp extends StatefulWidget {
  final Function toggle;
  const SignUp(this.toggle);
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool isLoading = false;
  bool _checkbox = false;

  AuthMethods authMethods = AuthMethods();

  final formKey = GlobalKey<FormState>();

  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  signMeUp() {
    if (formKey.currentState.validate()) {
      Map<String, dynamic> userInfoMap = authMethods.genUserInfo(
          userNameTextEditingController.text, emailTextEditingController.text);

      HelperFunctions.saveUserEmailSharedPreference(
          emailTextEditingController.text);
      HelperFunctions.saveUserNameSharedPreference(
          userNameTextEditingController.text);

      setState(() {
        isLoading = true;
      });
      authMethods
          .signUpWithEmailAndPassword(emailTextEditingController.text,
              passwordTextEditingController.text)
          .then((val) {
        DatabaseMethods(uid: val.uid).uploadUserInfo(userInfoMap);
        HelperFunctions.saveUserLoggedInSharedPreference(true);
        authMethods.verifyEmail();
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PageViewsWrapper()));
      });
    }
  }

  void _launchURL(url) async => await canLaunchUrl(url)
      ? await launchUrl(url)
      : throw 'Could not launch $url';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black54,
        body: isLoading
            ? sectionLoadingIndicator()
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.bottomCenter,
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height / 20),
                          child: Image.asset(
                            'assets/icon/Yeezy.png',
                            width: MediaQuery.of(context).size.width / 2.0,
                            height: MediaQuery.of(context).size.width / 2.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                validator: (val) {
                                  return val.length > 18
                                      ? "Max length 18"
                                      : emptyStrChecker(val)
                                          ? "Sorry, Spidr ID can not be empty"
                                          : null;
                                },
                                controller: userNameTextEditingController,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.orangeAccent,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                      color: Colors.white),
                                  hintText: "Enter a Username",
                                  hintStyle: TextStyle(color: Colors.white),
                                  labelText: "Spidr ID",
                                  labelStyle: TextStyle(color: Colors.orange),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                ),
                              ),
                              TextFormField(
                                validator: (val) {
                                  return RegExp(
                                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                          .hasMatch(val)
                                      ? null
                                      : "Please provide a valid email";
                                },
                                controller: emailTextEditingController,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.orangeAccent,
                                decoration: const InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.email, color: Colors.grey),
                                  hintText: "Enter an email",
                                  hintStyle: TextStyle(color: Colors.white),
                                  labelText: "Email",
                                  labelStyle: TextStyle(color: Colors.orange),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                ),
                              ),
                              TextFormField(
                                obscureText: true,
                                validator: (val) {
                                  return val.length > 6
                                      ? null
                                      : "Password is not valid";
                                },
                                controller: passwordTextEditingController,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.orangeAccent,
                                decoration: const InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.lock, color: Colors.grey),
                                  hintText: "Enter a Password",
                                  hintStyle: TextStyle(color: Colors.white),
                                  labelText: "Password",
                                  labelStyle: TextStyle(color: Colors.orange),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.orange),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 27),
                          child: Row(
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: Colors.white,
                                ),
                                child: Checkbox(
                                  checkColor: Colors.orange,
                                  activeColor: Colors.white,
                                  value: _checkbox,
                                  onChanged: (value) {
                                    setState(() {
                                      _checkbox = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: GestureDetector(
                                  onTap: () {
                                    _launchURL(
                                        'https://www.iubenda.com/terms-and-conditions/80156886');
                                  },
                                  child: Text(
                                    _checkbox
                                        ? "You have agreed to our EULA Agreement"
                                        : "Review our EULA Agreement",
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _checkbox ? signMeUp() : null;
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: _checkbox
                                ? BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFFF9800),
                                      Color(0xFFEA80FC)
                                    ]),
                                    borderRadius: BorderRadius.circular(30))
                                : BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(30)),
                            child: const Text(
                              "Join",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () {
                                widget.toggle();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 25),
                                child: const Text(
                                  " Hop on now",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ));
  }
}
