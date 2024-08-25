import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';

final _firebase = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

class ContactConfirmationPage extends StatefulWidget {
  final ContributorFormState formState;
  final Function(bool) onEmailConfirmationUpdated;
  final Function(bool) onTermsAccepted;

  const ContactConfirmationPage({
    super.key,
    required this.formState,
    required this.onEmailConfirmationUpdated,
    required this.onTermsAccepted,
  });

  @override
  _ContactConfirmationPageState createState() =>
      _ContactConfirmationPageState();
}

class _ContactConfirmationPageState extends State<ContactConfirmationPage> {
  Future<String?> _getUserEmail() async {
    final user = _firebase.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['email'] as String?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Confirmation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<String?>(
              future: _getUserEmail(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  );
                }

                final email = snapshot.data ?? 'Email not found';
                widget.formState.setUserContactInfo(email);
                return Text('Email: $email',
                    style: const TextStyle(fontSize: 16));
              },
            ),
            CheckboxListTile(
              title: const Text(
                  'I confirm my email address is correct and up to date'),
              value: widget.formState.emailConfirmed,
              onChanged: (value) =>
                  widget.onEmailConfirmationUpdated(value ?? false),
            ),
            const SizedBox(height: 24),
            const Text('Terms and Conditions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'I acknowledge that, as a Contributor, I willingly offer assistance to fellow travelers in need. I understand that the responsibility for any risks or issues arising during travel arrangements rests solely with me, and I absolve PathPal from any liability or claims related to such incidents. Additionally. I recognize the importance of maintaining privacy and confidentiality, especially regarding personal details, and I commit to respecting the privacy of all users involved in this collaborative travel platform when contacting matched receivers.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('I accept the terms and conditions'),
              value: widget.formState.termsAccepted,
              onChanged: (value) => widget.onTermsAccepted(value ?? false),
            ),
          ],
        ),
      ),
    );
  }
}
