import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  Country? country;

  Future<String> fetchCountryCode() async {
    final response = await http.get(Uri.parse('http://ip-api.com/json'));
    final body = json.decode(response.body);
    final countryCode = body['countryCode'];
    return countryCode;
  }

  @override
  void initState() {
    super.initState();
    fetchCountryCode().then((countryCode) {
      setState(() {
        country = CountryParser.parseCountryCode(countryCode);
      });
    });
  }

  var _isLogin = true;
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredName = "";
  var _enteredPhone = "";
  var _enteredAge = "";
  var _isAuthenticating = false;
  var _passwordVisible = false;
  // File? _selectedImage;

  // @override
  // void initState() {
  //   super.initState();
  //   // _initializeSelectedImage();
  // }

  // void _initializeSelectedImage() async {
  //   try {
  //     final file =
  //         await getImageFileFromAssets('images/default_profile_image.png');
  //     setState(() {
  //       _selectedImage = file;
  //     });
  //   } catch (e) {
  //     print('Failed to initialize selected image: $e');
  //     // Handle the error, perhaps by setting _selectedImage to null or a default File
  //   }
  // }

  // Future<File> getImageFileFromAssets(String path) async {
  //   try {
  //     // Load the asset
  //     final byteData = await rootBundle.load('assets/$path');

  //     // Get the temporary directory
  //     final tempDir = await getTemporaryDirectory();

  //     // Create the path for the new file, including necessary subdirectories
  //     final file = File('${tempDir.path}/$path');

  //     // Ensure the directory exists
  //     await file.parent.create(recursive: true);

  //     // Write the file
  //     await file.writeAsBytes(byteData.buffer
  //         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  //     return file;
  //   } catch (e) {
  //     print('Error in getImageFileFromAssets: $e');
  //     rethrow; // or handle the error as appropriate for your app
  //   }
  // }

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid /*|| !_isLogin || _selectedImage == null*/) {
      //show an error message
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        // final storageRef = FirebaseStorage.instance
        //     .ref()
        //     .child('user_images')
        //     .child('${userCredentials.user!.uid}.jpg');

        // await storageRef.putFile(_selectedImage!);
        // final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'name': _enteredName,
          'email': _enteredEmail,
          'age': _enteredAge,
          'phone_number': _enteredPhone
          // 'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void showPicker() {
    showCountryPicker(
      context: context,
      favorite: ['IN', 'US', 'CA'],
      exclude: ['CN'],
      countryListTheme: CountryListThemeData(
        bottomSheetHeight: 600,
        borderRadius: BorderRadius.circular(20),
        inputDecoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search your country here..',
          border: InputBorder.none,
        ),
      ),
      onSelect: (country) {
        setState(() {
          this.country = country;
        });
      },
    );
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
            Card(
              elevation: 1,
              color: Theme.of(context).colorScheme.surface,
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          label: Text('Email Address'),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _enteredEmail = newValue!;
                        },
                      ),
                      if (!_isLogin)
                        TextFormField(
                          decoration: const InputDecoration(
                            label: Text('Full Name'),
                          ),
                          enableSuggestions: true,
                          validator: (value) {
                            if (value == null ||
                                !value.trim().contains(' ') ||
                                value.isEmpty) {
                              return 'Please enter a full name';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredName = value!;
                          },
                        ),
                      if (!_isLogin)
                        country == null
                            ? const CircularProgressIndicator()
                            : TextFormField(
                                onFieldSubmitted: (phoneNumber) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '+${country!.phoneCode}$phoneNumber'),
                                    ),
                                  );
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(top: 15),
                                  hintText: 'Enter phone number',
                                  prefixIcon: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: showPicker,
                                    child: Container(
                                      height: 56,
                                      width: 100,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${country!.flagEmoji} +${country!.phoneCode}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter a phone number';
                                  } else if (!RegExp(
                                          r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredPhone =
                                      "+${country!.phoneCode} ${value!}";
                                },
                              ),
                      if (!_isLogin)
                        TextFormField(
                          decoration: const InputDecoration(
                            label: Text('Age'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty || num.tryParse(value) == null) {
                              return 'Please enter an age';
                            } else if (num.parse(value!) > 120) {
                              return 'Please enter a valid age';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredAge = value!;
                          },
                        ),
                      TextFormField(
                        decoration: InputDecoration(
                          label: Text('Password'),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        obscureText: !_passwordVisible,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return "Password must be at least 6 characters long";
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _enteredPassword = newValue!;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_isAuthenticating) const CircularProgressIndicator(),
                      if (!_isAuthenticating)
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child: Text(_isLogin ? "LOGIN" : "SIGN UP"),
                        ),
                      if (!_isAuthenticating)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_isLogin ? "New User?" : "Have an account?"),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin ? "Sign up" : "Login"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
