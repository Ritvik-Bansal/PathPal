// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// //TODO after getting apple dev license
// class AppleAuthFlow {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       'https://www.googleapis.com/auth/userinfo.profile',
//     ],
//   );
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Future<void> startAuthFlow(BuildContext context) async {
//     try {
//       final appleCredential = await SignInWithApple.getAppleIDCredential(
//         scopes: [
//           AppleIDAuthorizationScopes.email,
//           AppleIDAuthorizationScopes.fullName,
//         ],
//       );
//       final credential = OAuthProvider("apple.com").credential(
//         idToken: appleCredential.identityToken,
//         accessToken: appleCredential.authorizationCode,
//       );
//       final UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       final User user = userCredential.user!;
//       if (user == null) {
//         _handleFailedSignIn();
//         return;
//       }
//       DocumentSnapshot doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       if (!doc.exists) {
//         await _firestore.collection('users').doc(user.uid).set({
//           'name': user.displayName,
//           'email': user.email,
//         });
//       }
//     } catch (error) {
//       print('Error during authentication: $error');
//       _handleFailedSignIn();
//     }
//   }

//   void _handleSuccessfulSignIn(Map<String, String?> userInfo) {
//     print('Signed in successfully: $userInfo');
//   }

//   void _handleCancelledSignIn() {
//     print('Sign-in cancelled by user');
//   }

//   void _handleFailedSignIn() {
//     print('Sign-in failed');
//   }
// }
