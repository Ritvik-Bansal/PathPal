import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/screens/full_name.dart';

class GoogleAuthFlow {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
    serverClientId:
        '742216978719-nctpfhlai5veg4307qg5e7d3b6it0ltm.apps.googleusercontent.com',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> startAuthFlow(BuildContext context) async {
    try {
      print("Starting Google Sign-In process");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In was canceled by the user");
        return null;
      }

      print("Google Sign-In successful, getting auth details");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("Creating credential");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Signing in to Firebase");
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        print("Firebase sign-in failed: user is null");
        return null;
      }

      final hasFullName = await _checkAndUpdateUserData(user);

      if (!hasFullName) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullNameScreen(user: user),
          ),
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
    } on PlatformException catch (e) {
      print('PlatformException: ${e.code} - ${e.message}');
    } catch (error) {
      print('Error during Google Sign-In: $error');
    }
    return null;
  }

  Future<bool> _checkAndUpdateUserData(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final name = userData['name'] as String?;
      return name != null && name.trim().contains(' ');
    }

    final initialData = {
      'name': user.displayName ?? '',
      'email': user.email,
      'profile_picture': user.photoURL,
      'email_verified': true,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(initialData, SetOptions(merge: true));
    return user.displayName != null && user.displayName!.trim().contains(' ');
  }
}
