import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/services/auth_service.dart';
import 'package:pathpal/services/google_auth_flow.dart';
import 'package:pathpal/widgets/forget_password_bottom_sheet.dart';
import 'package:pathpal/widgets/auth_form.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pathpal/widgets/loading_overlay.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  var _isAuthenticating = false;
  bool _isMounted = false;
  final GoogleAuthFlow _googleAuthFlow = GoogleAuthFlow();

  bool isPrivateRelayEmail(String? email) {
    if (email == null) return false;
    return email.toLowerCase().contains('privaterelay.appleid.com');
  }

  Future<void> _handleAppleSignIn() async {
    LoadingOverlay.show(context);
    try {
      const charset =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
      final random = Random.secure();
      final rawNonce =
          List.generate(32, (_) => charset[random.nextInt(charset.length)])
              .join();
      final bytes = utf8.encode(rawNonce);
      final digest = sha256.convert(bytes);
      final nonce = digest.toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebase.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          String? displayName;
          if (appleCredential.givenName != null ||
              appleCredential.familyName != null) {
            displayName =
                '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                    .trim();
          }

          final email = appleCredential.email ?? user.email;
          final isPrivateEmail = isPrivateRelayEmail(email);

          if (displayName == null || displayName.isEmpty) {
            LoadingOverlay.hide();
            if (mounted) {
              displayName = await _showNameInputDialog(context) ??
                  'User ${user.uid.substring(0, 5)}';
            }
            if (mounted) LoadingOverlay.show(context);
          }

          String imageUrl = await _uploadDefaultProfilePicture(user.uid);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': email,
            'name': displayName,
            'is_private_email': isPrivateEmail,
            'apple_user_identifier': appleCredential.userIdentifier,
            'email_verified': true,
            'auth_provider': 'apple.com',
            'last_login': FieldValue.serverTimestamp(),
            'first_login_at': FieldValue.serverTimestamp(),
            'given_name': appleCredential.givenName,
            'profile_picture': imageUrl,
          });

          await user.updateDisplayName(displayName);
          await user.updatePhotoURL(imageUrl);

          if (email != null && email != user.email && !isPrivateEmail) {
            try {
              await user.updateEmail(email);
            } catch (e) {
              print('Error updating email: $e');
            }
          }
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'last_login': FieldValue.serverTimestamp(),
            'email_verified': true,
          });

          if (userDoc.data()?['name'] != null && user.displayName == null) {
            await user.updateDisplayName(userDoc.data()?['name']);
          }
        }

        if (mounted) {
          LoadingOverlay.hide();
          await AuthService().handleSuccessfulAuth(context);
        }
      }
    } catch (error) {
      LoadingOverlay.hide();
    }
  }

  Future<String?> _showNameInputDialog(BuildContext context) async {
    String? fullName;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Full Name'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Full Name',
            ),
            onChanged: (value) => fullName = value,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (fullName != null && fullName!.contains(' ')) {
                  Navigator.of(context).pop(fullName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please enter your full name (first and last name)'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _resendVerificationEmail() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    try {
      User? user = _firebase.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to send verification email. Please try again later.'),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'An error occurred while sending the verification email: $error'),
        ),
      );
    }
  }

  void _submit(String email, String password,
      {String? name, String? age}) async {
    _safeSetState(() {
      _isAuthenticating = true;
    });

    try {
      if (_isLogin) {
        await _firebase.signOut();

        final userCredential = await _firebase.signInWithEmailAndPassword(
            email: email, password: password);

        if (!userCredential.user!.emailVerified) {
          await _firebase.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before logging in.',
          );
        }
        await userCredential.user!.reload();
        if (mounted) {
          await AuthService().handleSuccessfulAuth(context);
        }
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: email, password: password);

        String imageUrl =
            await _uploadDefaultProfilePicture(userCredentials.user!.uid);

        await userCredentials.user!.updateDisplayName(name);
        await userCredentials.user!.updatePhotoURL(imageUrl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'name': name,
          'email': email,
          'profile_picture': imageUrl,
          'email_verified': false,
        }, SetOptions(merge: true));

        if (mounted) {
          await AuthService().handleSuccessfulAuth(context);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created. Please verify your email.'),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        String errorMessage;
        switch (error.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many login attempts. Please try again later.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email and password sign-in is not enabled.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email address.';
            break;
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-not-verified':
            errorMessage = 'Please verify your email before logging in.';
            break;
          case 'invalid-credential':
            errorMessage =
                'The credentials entered are invalid. Please enter valid credentials.';
            break;
          default:
            errorMessage =
                error.message ?? 'An error occurred, Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
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

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/images/login_logo.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            Text(
              _isLogin ? 'LOGIN' : 'SIGN UP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            AuthForm(
              isLogin: _isLogin,
              googleAuthFlow: _googleAuthFlow,
              onResendVerificationEmail: _resendVerificationEmail,
              onSubmit: (String email, String password,
                  {String? name, String? age}) {
                _submit(age: age, name: name, email, password);
                setState(() {});
              },
              isAuthenticating: _isAuthenticating,
              onToggleAuthMode: () {
                _safeSetState(() {
                  _isLogin = !_isLogin;
                });
              },
              onForgotPassword: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext bc) {
                    return const Wrap(children: <Widget>[
                      ForgetPasswordBottomSheet(),
                    ]);
                  },
                );
              },
              onAppleSignIn: _handleAppleSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
