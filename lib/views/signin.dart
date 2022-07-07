import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:spidr_app/helper/helperFunctions.dart';
import 'package:spidr_app/services/auth.dart';
import 'package:spidr_app/services/database.dart';
import 'package:spidr_app/views/pageViewsWrapper.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

import 'forgotpassword.dart';

class SignIn extends StatefulWidget {
  final Function toggle;
  const SignIn(this.toggle);
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();

  final flatButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 8),
  );

  AuthMethods authMethods = AuthMethods();
  DatabaseMethods databaseMethods = DatabaseMethods();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  bool isLoading = false;
  bool invalidPassword = false;
  bool invalidEmail = false;
  bool hidePass = true;

  QuerySnapshot snapshotUserInfo;

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final authService = Provider.of<AuthMethods>(context, listen: false);

      final user = await authService
          .signInWithApple(scopes: [Scope.email, Scope.fullName]);

      // final firebaseUser = user;
      Map<String, dynamic> userInfoMap =
          authMethods.genUserInfo(user.displayName, user.email);

      authMethods.appleSignIn(user).then((val) async {
        DocumentSnapshot userSnapshot =
            await DatabaseMethods(uid: val.uid).getUserById();

        if (!userSnapshot.exists) {
          await DatabaseMethods(uid: val.uid).uploadUserInfo(userInfoMap);
        }

        HelperFunctions.saveUserLoggedInSharedPreference(true);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PageViewsWrapper()));
      });
    } catch (e) {
      print(e);
    }
  }

  googleSignIn() async {
    try {
      //TODO understand errors and adjust error messages - franky
      GoogleSignInAccount googleSignInAccount =
          await _googleSignIn.signIn().catchError((onError) {
        // print("1");
        // print(onError);
        // print(onError.toString());
        Fluttertoast.showToast(
            msg: 'Google account error. Please try signing in without google.');
      });

      GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication.catchError((onError) {
        // print("2");
        // print(onError.toString());
        Fluttertoast.showToast(
            msg: 'Google account error. Please try signing in without google.');
      });

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential result =
          await _auth.signInWithCredential(credential).catchError((onError) {
        // print("3");
        // print(onError.toString());
        Fluttertoast.showToast(
            msg: 'Google account error. Please try signing in without google.');
      });
      User firebaseUser = result.user;

      Map<String, dynamic> userInfoMap =
          authMethods.genUserInfo(firebaseUser.displayName, firebaseUser.email);

      authMethods.googleSignIn(firebaseUser).then((val) async {
        DocumentSnapshot userSnapshot =
            await DatabaseMethods(uid: val.uid).getUserById();
        if (!userSnapshot.exists) {
          await DatabaseMethods(uid: val.uid).uploadUserInfo(userInfoMap);
        }
        HelperFunctions.saveUserLoggedInSharedPreference(true);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PageViewsWrapper()));
      });
    } catch (e) {
      print(e);
    }
  }

  signIn() async {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await authMethods
            .signInWithEmailAndPassword(emailTextEditingController.text,
                passwordTextEditingController.text)
            .then((result) async {
          if (result != null) {
            QuerySnapshot userInfoSnapshot = await databaseMethods
                .getUserByUserEmail(emailTextEditingController.text);

            HelperFunctions.saveUserLoggedInSharedPreference(true);
            HelperFunctions.saveUserNameSharedPreference(
                userInfoSnapshot.docs[0].get('name'));

            HelperFunctions.saveUserEmailSharedPreference(
                userInfoSnapshot.docs[0].get('email'));

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const PageViewsWrapper()));
          } else {
            setState(() {
              isLoading = false;
            });
          }
        });
      } catch (e) {
        if (e ==
            '[firebase_auth/wrong-password] The password is invalid or the user does not have a password.') {
          setState(() {
            invalidPassword = true;
          });
        } else if (e ==
            '[firebase_auth/user-not-found] There is no user record corresponding to this identifier. The user may have been deleted.') {
          setState(() {
            invalidEmail = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF6D00),
                  Color(0xFFFF6D00),
                ],
              ),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Image.asset(
                      'assets/icon/Groups.png',
                      width: MediaQuery.of(context).size.width / 2.0,
                      height: MediaQuery.of(context).size.width / 2.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: (val) {
                            return RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(val)
                                ? null
                                : 'Invalid Email';
                          },
                          controller: emailTextEditingController,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.orange,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(
                                20.0, 15.0, 20.0, 15.0),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.white),
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(color: Colors.black),
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white),
                            errorText: invalidEmail
                                ? 'Email is not registered :('
                                : null,
                            errorStyle: const TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          obscureText: hidePass,
                          validator: (val) {
                            return val.length > 6 ? null : 'Invalid password';
                          },
                          controller: passwordTextEditingController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          cursorColor: Colors.orange,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(
                                20.0, 15.0, 20.0, 15.0),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.white),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  hidePass = !hidePass;
                                });
                              },
                              child: const Icon(Icons.visibility,
                                  color: Colors.white),
                            ),
                            hintText: 'Enter your Password',
                            hintStyle: const TextStyle(color: Colors.black),
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white),
                            errorText: invalidPassword
                                ? 'Password incorrect :('
                                : null,
                            errorStyle: const TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height:20,),
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          style: flatButtonStyle,
                          child: const Text('Forgot password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              )),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen()));
                          }),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      signIn();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xDD000000), Color(0xDD000000)]),
                          borderRadius: BorderRadius.circular(15)),
                      child: const Text(
                        'Hop On',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(children: const <Widget>[
                    Expanded(
                      child: Divider(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'OR',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                        child: Divider(
                      color: Colors.white70,
                    )),
                  ]),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      platform == TargetPlatform.android
                          ? GestureDetector(
                              onTap: () {
                                googleSignIn();
                              },
                              child: Center(
                                child: Image.asset(
                                  'assets/images/GoogleSignIn.png',
                                  width:
                                      MediaQuery.of(context).size.width / 4.5,
                                ),
                              ),
                            )
                          : AppleSignInButton(
                              type: ButtonType.continueButton,
                              onPressed: () {
                                _signInWithApple(context);
                              },
                            ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.toggle();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: const Text(
                            "Don't have an account? Join now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
