import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:pathpal/screens/auth.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool isEmailVerified = false;
  Timer? timer;
  bool _isMounted = false;
  late String userEmail;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);
    final user = FirebaseAuth.instance.currentUser;
    isEmailVerified = user?.emailVerified ?? false;
    userEmail = user?.email ?? 'your email';

    if (!isEmailVerified) {
      sendVerificationEmail();
      startEmailVerificationTimer();
    }
  }

  void startEmailVerificationTimer() {
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkEmailVerified(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkEmailVerified();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isMounted = false;
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    if (!_isMounted) return;

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        timer?.cancel();
        if (_isMounted) {
          setState(() {
            isEmailVerified = true;
          });

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Email verified! You can now log in.')),
          );

          await FirebaseAuth.instance.signOut();
          if (_isMounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending verification email: $e')),
        );
      }
    }
  }

  Future<void> _handleChangeEmail() async {
    await FirebaseAuth.instance.signOut();
    if (_isMounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
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
      appBar: AppBar(
        title: const Text('Email Verification Required'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleChangeEmail,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 120),
                Image.asset('assets/icon/icon_removed_bg.png'),
                const SizedBox(height: 20),
                Text(
                  'A verification email has been sent to:',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  userEmail,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'If you don\'t see the email in your inbox, please check your spam folder.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: sendVerificationEmail,
                  child: const Text('Resend Verification Email'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _handleChangeEmail,
                  child: const Text('Change Email Address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
