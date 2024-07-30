import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      return 'US';
    }
  }

  void _submit(String email, String password,
      {String? name, String? phone, String? age}) async {
    _safeSetState(() {
      _isAuthenticating = true;
    });

    try {
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: email, password: password);

        String imageUrl =
            await _uploadDefaultProfilePicture(userCredentials.user!.uid);

        await userCredentials.user!.updatePhotoURL(imageUrl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'name': name,
          'email': email,
          'age': age,
          'phone_number': phone,
          'profile_picture': imageUrl
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
      _safeSetState(() {
        _isAuthenticating = false;
      });
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
