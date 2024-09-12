import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:pathpal/screens/auth.dart'; // Import your AuthScreen

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    if (_isMounted) {
      setState(() {
        isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
      });

      if (isEmailVerified) {
        timer?.cancel();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! You can now log in.')),
        );
        await FirebaseAuth.instance.signOut();
        Future.delayed(const Duration(seconds: 2), () {
          if (_isMounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          }
        });
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      if (_isMounted) {
        setState(() => canResendEmail = false);
      }
      await Future.delayed(const Duration(minutes: 5));
      if (_isMounted) {
        setState(() => canResendEmail = true);
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending verification email: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMounted) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Email Verification Required')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              Image.asset('assets/icon/icon_removed_bg.png'),
              const Text('Please verify your email to continue.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: canResendEmail ? sendVerificationEmail : null,
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
