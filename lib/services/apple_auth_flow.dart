import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

//TODO after getting apple dev license
class AppleAuthFlow {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> startAuthFlow(BuildContext context) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    print(credential);
  }

  // ... rest of the class methods remain the sam

  void _handleSuccessfulSignIn(Map<String, String?> userInfo) {
    // Handle successful sign-in, e.g., navigate to home screen
    print('Signed in successfully: $userInfo');
  }

  void _handleCancelledSignIn() {
    // Handle case where user cancelled during AgePhone screen
    print('Sign-in cancelled by user');
  }

  void _handleFailedSignIn() {
    // Handle failed sign-in, e.g., show error message
    print('Sign-in failed');
  }
}
