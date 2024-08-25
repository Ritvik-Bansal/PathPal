// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class GoogleAuthFlow {
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
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         _handleCancelledSignIn();
//         return;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       final User? user = userCredential.user;

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
