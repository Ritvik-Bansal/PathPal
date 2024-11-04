import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pathpal/screens/auth.dart';
import 'package:pathpal/screens/email_verification_screen.dart';
import 'package:pathpal/screens/full_name.dart';
import 'package:pathpal/screens/tabs.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Widget> getInitialScreen() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const AuthScreen();
    }

    await user.reload();

    if (!user.emailVerified) {
      return const EmailVerificationScreen();
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return const AuthScreen();
      }

      final userData = userDoc.data();
      final name = userData?['name'] as String?;

      if (name == null || !name.trim().contains(' ')) {
        return FullNameScreen(user: user);
      }

      return const Tabs();
    } catch (e) {
      print('Error getting user data: $e');
      return const AuthScreen();
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Future<void> handleSuccessfulAuth(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!user.emailVerified) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const EmailVerificationScreen()),
        );
      }
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!context.mounted) return;

    if (!userDoc.exists) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      return;
    }

    final userData = userDoc.data();
    final name = userData?['name'] as String?;

    if (name == null || !name.trim().contains(' ')) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => FullNameScreen(user: user)),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Tabs()),
      (route) => false,
    );
  }
}
