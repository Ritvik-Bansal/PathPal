import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/screens/full_name.dart';
import 'package:pathpal/services/auth_service.dart';
import 'package:pathpal/widgets/loading_overlay.dart';

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
    LoadingOverlay.show(context);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        LoadingOverlay.hide();
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        print("Firebase sign-in failed: user is null");
        LoadingOverlay.hide();
        return null;
      }

      _dismissKeyboard(context);

      final hasFullName = await _checkAndUpdateUserData(user);

      LoadingOverlay.hide();

      if (!hasFullName) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullNameScreen(user: user),
          ),
        );
      }

      if (context.mounted) {
        await AuthService().handleSuccessfulAuth(context);
      }

      return user;
    } catch (error) {
      LoadingOverlay.hide();
      _handleError(context, error);
      return null;
    }
  }

  void _handleError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is FirebaseAuthException) {
      message = error.message ?? 'Authentication failed';
      print('FirebaseAuthException: ${error.code} - ${error.message}');
    } else if (error is PlatformException) {
      message = error.message ?? 'Platform error occurred';
      print('PlatformException: ${error.code} - ${error.message}');
    } else {
      print('Error during Google Sign-In: $error');
    }

    _showErrorSnackbar(context, message);
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  Future<bool> _checkAndUpdateUserData(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });

      final userData = userDoc.data() as Map<String, dynamic>;
      final name = userData['name'] as String?;
      return name != null && name.trim().contains(' ');
    }

    final initialData = {
      'name': user.displayName ?? '',
      'email': user.email,
      'profile_picture': user.photoURL,
      'email_verified': true,
      'auth_provider': 'google.com',
      'first_login_at': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(initialData, SetOptions(merge: true));
    return user.displayName != null && user.displayName!.trim().contains(' ');
  }
}
