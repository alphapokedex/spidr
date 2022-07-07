import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:spidr_app/helper/helperFunctions.dart';
import 'package:spidr_app/model/chatUser.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatUser _userFromFirebaseUser(User user) {
    return user != null ? ChatUser(uid: user.uid) : null;
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User firebaseUser = result.user;
      return _userFromFirebaseUser(firebaseUser);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      } else {
        print(e.code);
      }
    }
  }

  Future signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User firebaseUser = result.user;

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      print(e.toString());
    }
  }

  Future resetPass(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }

  Future signOut() async {
    try {
      await HelperFunctions.saveUserLoggedInSharedPreference(false);
      await HelperFunctions.saveUserNameSharedPreference('');
      await HelperFunctions.saveUserEmailSharedPreference('');
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }

  Future googleSignIn(firebaseUser) async {
    try {
      if (firebaseUser != null) {
        // Checking if email and name is null
        assert(firebaseUser.email != null);
        assert(firebaseUser.displayName != null);

        assert(!firebaseUser.isAnonymous);
        assert(await firebaseUser.getIdToken() != null);

        final User currentUser = _auth.currentUser;
        assert(firebaseUser.uid == currentUser.uid);
      }

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      throw (e.toString());
    }
  }

  Future<User> signInWithApple({List<Scope> scopes = const []}) async {
    // 1. perform the sign-in request
    final result = await TheAppleSignIn.performRequests(
        [AppleIdRequest(requestedScopes: scopes)]);
    // 2. check the result
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken),
          accessToken:
              String.fromCharCodes(appleIdCredential.authorizationCode),
        );
        final authResult = await _auth.signInWithCredential(credential);
        final firebaseUser = authResult.user;

        if (scopes.contains(Scope.fullName)) {
          final displayName =
              '${appleIdCredential.fullName.givenName} ${appleIdCredential.fullName.familyName}';
          await firebaseUser.updateDisplayName(displayName);
        }

        return firebaseUser;

      case AuthorizationStatus.error:
        throw PlatformException(
          code: 'ERROR_AUTHORIZATION_DENIED',
          message: result.error.toString(),
        );

      case AuthorizationStatus.cancelled:
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      default:
        throw UnimplementedError();
    }
  }

  Future appleSignIn(firebaseUser) async {
    try {
      if (firebaseUser != null) {
        // Checking if email and name is null
        assert(firebaseUser.email != null);
        assert(firebaseUser.displayName != null);

        assert(!firebaseUser.isAnonymous);
        assert(await firebaseUser.getIdToken() != null);

        final User currentUser = _auth.currentUser;
        assert(firebaseUser.uid == currentUser.uid);
      }

      return _userFromFirebaseUser(firebaseUser);
    } catch (e) {
      throw (e.toString());
    }
  }

// TODO please create a user and do a to json funtion over there
  Map<String, dynamic> genUserInfo(name, email) {
    Random random = Random();
    int randNum = random.nextInt(33);
    String imgPath = 'assets/images/userPic/SpidrProfImg.png';

    Map<String, dynamic> userInfoMap = {
      'name': name,
      'email': email,
      'profileImg': imgPath,
      'anonImg': randNum,
      'pushToken': '',
      'quote': '',
      'tags': [],
      'blockList': [],
      'getStarted': true
    };

    HelperFunctions.saveUserEmailSharedPreference(email);
    HelperFunctions.saveUserNameSharedPreference(name);

    return userInfoMap;
  }

  Future verifyEmail() async {
    final User user = _auth.currentUser;
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
