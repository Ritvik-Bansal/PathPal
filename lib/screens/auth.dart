import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pathpal/widgets/forget_password_bottom_sheet.dart';
import 'package:pathpal/widgets/auth_form.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  var _isAuthenticating = false;

  Future<String> fetchCountryCode() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['countryCode'];
      } else {
        throw Exception('Failed to load country code');
      }
    } catch (e) {
      print('Error fetching country code: $e');
      return 'US'; // Default to US if there's an error
    }
  }

  void _submit(String email, String password,
      {String? name, String? phone, String? age}) async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: email, password: password);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'name': name,
          'email': email,
          'age': age,
          'phone_number': phone
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
        ),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
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
              onSubmit: _submit,
              isAuthenticating: _isAuthenticating,
              onToggleAuthMode: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              onForgotPassword: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext bc) {
                    return Wrap(children: <Widget>[
                      Container(
                        child: ForgetPasswordBottomSheet(),
                      ),
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
