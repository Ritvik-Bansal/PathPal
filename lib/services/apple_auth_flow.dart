import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:pathpal/screens/full_name.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

class AppleAuthFlow {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _uploadDefaultProfilePicture(String userId) async {
    ByteData data =
        await rootBundle.load('assets/images/default_profile_image.png');
    List<int> bytes = data.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    File file =
        await File('${tempDir.path}/default_profile_image.png').create();
    await file.writeAsBytes(bytes);

    final ref = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('$userId.png');
    await ref.putFile(file);

    final url = await ref.getDownloadURL();
    return url;
  }

  Future<User?> startAuthFlow(BuildContext context) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.pathpal.app',
          redirectUri: Uri.parse(
            'https://pathpal-9f126.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      // Check for private relay email
      if (appleCredential.email != null &&
          appleCredential.email!.contains('privaterelay.appleid.com')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please share your real email address. Private relay emails are not supported. '
                'To change this, sign out of your Apple ID in device settings, '
                'sign back in, and try again.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return null;
      }

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        print("Firebase sign-in failed: user is null");
        return null;
      }

      String? fullName;
      if (appleCredential.givenName != null &&
          appleCredential.familyName != null) {
        fullName = '${appleCredential.givenName} ${appleCredential.familyName}';
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        String profilePictureUrl = await _uploadDefaultProfilePicture(user.uid);

        final userData = {
          'name': fullName ?? user.displayName ?? '',
          'email': appleCredential.email ?? user.email ?? '',
          'profile_picture': profilePictureUrl,
          'email_verified': true,
          'auth_provider': 'apple.com',
        };

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));

        await user.updatePhotoURL(profilePictureUrl);
        if (fullName != null) {
          await user.updateDisplayName(fullName);
        }

        if (context.mounted && (fullName == null || fullName.isEmpty)) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullNameScreen(user: user),
            ),
          );
        }
      }

      return user;
    } catch (error) {
      print('Error during Apple Sign-In: $error');
      if (context.mounted) {}
      return null;
    }
  }
}
