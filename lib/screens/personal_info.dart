import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _firebase = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();
  Country? country;

  Future<void> _deleteAccount() async {
    final user = _firebase.currentUser;
    if (user == null) return;

    try {
      if (user.providerData
          .any((userInfo) => userInfo.providerId == 'google.com')) {
        await _reauthenticateWithGoogle();
      } else {
        await _reauthenticateWithPassword();
      }

      await _deleteUserDocuments(user.uid);

      await _firestore.collection('users').doc(user.uid).delete();

      await user.delete();

      await _firebase.signOut();

      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteUserDocuments(String userId) async {
    final collections = [
      'users',
      'receivers',
      'contributors',
      'notifications',
      'tentativeReceivers'
    ];

    for (final collection in collections) {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }

    await _deleteUserChats(userId);

    await _removeUserFromFavorites(userId);
    await _deleteUserNotifications(userId);
  }

  Future<void> _deleteUserChats(String userId) async {
    final chatsSnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    for (final chatDoc in chatsSnapshot.docs) {
      final messagesSnapshot =
          await chatDoc.reference.collection('messages').get();

      for (final messageDoc in messagesSnapshot.docs) {
        await messageDoc.reference.delete();
      }

      await chatDoc.reference.delete();
    }
  }

  Future<void> _removeUserFromFavorites(String userId) async {
    final usersSnapshot = await _firestore.collection('users').get();

    for (final userDoc in usersSnapshot.docs) {
      final favoritedContributors =
          userDoc.data()['favoritedContributors'] as List?;
      if (favoritedContributors != null &&
          favoritedContributors.contains(userId)) {
        await userDoc.reference.update({
          'favoritedContributors': FieldValue.arrayRemove([userId])
        });
      }
    }
  }

  Future<void> _deleteUserNotifications(String userId) async {
    final notificationsSnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in notificationsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _reauthenticateWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    await _firebase.currentUser?.reauthenticateWithCredential(credential);
  }

  Future<void> _reauthenticateWithPassword() async {
    final TextEditingController passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Re-enter your password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () => Navigator.of(context).pop(passwordController.text),
          ),
        ],
      ),
    );

    if (password != null && password.isNotEmpty) {
      final user = _firebase.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      try {
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        throw Exception('Reauthentication failed: ${e.toString()}');
      }
    } else {
      throw Exception('Password not provided');
    }
  }

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "PROFILE INFORMATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        minimumSize:
                                            const Size(double.infinity, 40),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    child: const Text("SAVE"),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "More Options",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showResetPasswordConfirmation(
                                            userData['email']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      minimumSize:
                                          const Size(double.infinity, 40),
                                    ),
                                    child: const Text("RESET PASSWORD"),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 40),
                                    ),
                                    onPressed: () =>
                                        _showDeleteAccountConfirmation(),
                                    child: const Text('DELETE ACCOUNT',
                                        style: TextStyle(fontSize: 14)),
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

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }
}
