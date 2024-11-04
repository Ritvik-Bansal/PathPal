import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pathpal/screens/contact_us.dart';
import 'package:pathpal/screens/personal_info.dart';
import 'package:pathpal/screens/privacy_policy_screen.dart';
import 'package:pathpal/screens/terms_conditions_screen.dart';
import 'package:pathpal/services/auth_service.dart';
import 'package:pathpal/widgets/build_setting_item.dart';
import 'package:pathpal/widgets/forgot_password_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firebase = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _imageUrl;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final user = _firebase.currentUser;
    if (user != null && mounted) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _imageUrl = userDoc.data()?['profile_picture'] ?? user.photoURL;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    final user = _firebase.currentUser;
    if (user != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}.png');

      try {
        await ref.delete();
      } catch (e) {
        print('No previous image found or error deleting: $e');
      }

      await ref.putFile(File(pickedImage.path));

      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profile_picture': url,
      });

      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose a picture",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "In order to upload a new profile picture, please choose a source",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              Forgetpasswordbtn(
                icon: Icons.camera_alt,
                descText: 'Take a picture',
                titleText: "Camera",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
              Forgetpasswordbtn(
                icon: Icons.photo,
                descText: 'Choose a picture',
                titleText: "Gallery",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _logout() async {
    setState(() {
      _isLoading = true;
    });

    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    try {
      await AuthService().signOut(context);
    } catch (e) {
      print("Error during logout: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _imageUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Please log in'));
        }

        return Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage:
                        _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                    backgroundColor: Colors.grey,
                    child: _imageUrl == null
                        ? const Icon(Icons.person,
                            size: 80, color: Colors.white)
                        : null,
                  ),
                  if (!_isLoading)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: () => _showImageSourceSheet(context),
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                ],
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Account Settings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const BuildSettingItem(
                        Icons.edit,
                        'PERSONAL INFORMATION',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Help and Support',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const BuildSettingItem(
                        Icons.security,
                        'PRIVACY POLICY',
                        nextScreen: PrivacyPolicyScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.description,
                        'TERMS AND CONDITIONS',
                        nextScreen: TermsAndConditionsScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.help,
                        'HELP',
                        nextScreen: ContactUsScreen(),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                          ),
                          onPressed: _logout,
                          child: const Text('LOG OUT',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
