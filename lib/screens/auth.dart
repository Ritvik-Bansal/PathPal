import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/widgets/forget_password_bottom_sheet.dart';
import 'package:pathpal/widgets/auth_form.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

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
        UserCredential userCredential = await _firebase
            .signInWithEmailAndPassword(email: email, password: password);

        if (!userCredential.user!.emailVerified) {
          await _firebase.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before logging in.',
          );
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
              onResendVerificationEmail: _resendVerificationEmail,
              onSubmit: _submit,
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
            ),
          ],
        ),
      ),
    );
  }
}
