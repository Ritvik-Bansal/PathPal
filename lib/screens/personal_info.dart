import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final _firebase = FirebaseAuth.instance;

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  var _enteredName = "";
  var _isAuthenticating = false;
  final _form = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

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

  // void showPicker() {
  //   showCountryPicker(
  //     context: context,
  //     favorite: ['IN', 'US', 'CA'],
  //     exclude: ['CN'],
  //     countryListTheme: CountryListThemeData(
  //       bottomSheetHeight: 600,
  //       borderRadius: BorderRadius.circular(20),
  //       inputDecoration: const InputDecoration(
  //         prefixIcon: Icon(Icons.search),
  //         hintText: 'Search your country here..',
  //         border: InputBorder.none,
  //       ),
  //     ),
  //     onSelect: (selectedCount) {
  //       setState(() {
  //         country = selectedCount;
  //       });
  //     },
  //   );
  // }

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebase.currentUser!.uid)
          .update({
        'name': _enteredName,
      });

      await _firebase.currentUser!.updateDisplayName(_enteredName);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully.'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${error.toString()}'),
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

  Future<void> _resetPassword(String email) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    try {
      await _firebase.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to send password reset email: ${error.toString()}'),
        ),
      );
    }
  }

  void _showResetPasswordConfirmation(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Reset Password'),
          content: Text(
              'Are you sure you want to reset your password? An email will be sent to $email.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetPassword(email);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PROFILE INFORMATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      body: user != null
          ? Container(
              height: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("No data available"));
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  return _isAuthenticating
                      ? Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Personal Information",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    label: Text('First and Last Name'),
                                  ),
                                  initialValue: userData['name'],
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
                                // SizedBox(height: 10),
                                // TextFormField(
                                //   decoration: const InputDecoration(
                                //     label: Text('Age'),
                                //   ),
                                //   initialValue: userData['age'],
                                //   keyboardType: TextInputType.number,
                                //   validator: (value) {
                                //     if (value!.isEmpty ||
                                //         num.tryParse(value) == null) {
                                //       return 'Please enter an age';
                                //     } else if (num.parse(value) > 120) {
                                //       return 'Please enter a valid age';
                                //     }
                                //     return null;
                                //   },
                                //   onSaved: (value) {
                                //     _enteredAge = value!;
                                //   },
                                // ),
                                const SizedBox(height: 30),
                                const Text(
                                  "Account Information",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    label: Text('Email'),
                                  ),
                                  initialValue: userData['email'],
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  readOnly: true,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                  onSaved: (newValue) {},
                                ),
                                // SizedBox(height: 10),
                                // TextFormField(
                                //   onFieldSubmitted: (phoneNumber) {
                                //     if (country != null) {
                                //       ScaffoldMessenger.of(context)
                                //           .showSnackBar(
                                //         SnackBar(
                                //           content: Text(
                                //               '+${country!.phoneCode}$phoneNumber'),
                                //         ),
                                //       );
                                //     }
                                //   },
                                //   initialValue: number,
                                //   keyboardType: TextInputType.number,
                                //   decoration: InputDecoration(
                                //     contentPadding: EdgeInsets.only(top: 15),
                                //     hintText: 'Enter phone number',
                                //     prefixIcon: GestureDetector(
                                //       behavior: HitTestBehavior.opaque,
                                //       onTap: showPicker,
                                //       child: Container(
                                //         height: 56,
                                //         width: 100,
                                //         alignment: Alignment.center,
                                //         child: country != null
                                //             ? Text(
                                //                 '${country!.flagEmoji} +${country!.phoneCode}',
                                //                 style: TextStyle(
                                //                   fontSize: 18,
                                //                   color: Theme.of(context)
                                //                       .colorScheme
                                //                       .onSurface,
                                //                   fontWeight: FontWeight.bold,
                                //                 ),
                                //               )
                                //             : const Text('Select Country'),
                                //       ),
                                //     ),
                                //   ),
                                //   validator: (value) {
                                //     if (value!.isEmpty) {
                                //       return 'Please enter a phone number';
                                //     } else if (!RegExp(
                                //             r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$')
                                //         .hasMatch(value)) {
                                //       return 'Please enter a valid phone number';
                                //     }
                                //     return null;
                                //   },
                                //   onSaved: (value) {
                                //     if (country != null) {
                                //       _enteredPhone =
                                //           "+${country!.phoneCode} ${value!}";
                                //     }
                                //   },
                                // ),
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                        minimumSize:
                                            const Size(double.infinity, 50),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    child: const Text("SAVE"),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        _showResetPasswordConfirmation(
                                            userData['email']),
                                    child: const Text("RESET PASSWORD"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                },
              ),
            )
          : const Center(child: Text("User not logged in")),
    );
  }
}
