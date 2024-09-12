import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathpal/contributor/contributor_form_screen.dart';
import 'package:pathpal/receiver/reciever_form_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function onProfileTap;

  const HomeScreen({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final userName = userData?['name'] ?? 'User';
              final profilePicUrl = userData?['profile_picture'];

              return GestureDetector(
                onTap: () {
                  onProfileTap();
                },
                child: Row(
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundImage: profilePicUrl != null
                          ? NetworkImage(profilePicUrl)
                          : null,
                      child: profilePicUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Image.asset('assets/icon/icon_removed_bg.png'),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final userName = userData?['name'] ?? 'User';

                    return Text(
                      'Hello, ${userName.toString().substring(0, userName.toString().indexOf(' '))}.\nWelcome to PathPal.',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  label: Text(
                    'Volunteer to assist travelers',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ContributorFormScreen();
                        },
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.volunteer_activism_rounded,
                    size: 30,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  label: Text(
                    'Look for a travel companion',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const RecieverFormScreen();
                        },
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.contact_support_rounded,
                    size: 30,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
