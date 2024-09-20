import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: 08/25/2024',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to PathPal, an app designed to connect travelers in need with volunteers willing to assist them on their journey. Your privacy is important to us, and this Privacy Policy outlines how we collect, use, and protect your personal information when you use our services.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Information We Collect',
              subsections: [
                '1.1 Registration Information\nUsers: When you register for PathPal, we collect your first and last name, email address, and password.\n\nVolunteers: When you continue as a Volunteer, we collect travel itinerary details, including flight numbers, dates, people in the party, and travel routes, along with the already given details from the account creation.\n\nReceivers: When you register as a Receiver, we collect your reason for seeking assistance, travel itinerary details, and the number of people in your party, along with the already given details from the account creation.',
                '1.2 Usage Information\nWe collect information about how you interact with the app and the details you provide during the Volunteer or Receiver flow.',
                '1.3 Communication Information\nWhen Receivers contact Volunteers through the app, we collect and process the email sent to the Volunteer via PathPal, which includes the Receiver\'s contact information.',
              ],
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              subsections: [
                '2.1 Providing Services\nWe use your personal information to facilitate connections between Volunteers and Receivers, display suitable matches, and manage user accounts.\n\nWe ensure that the Volunteer\'s name and personal details remain private and are never disclosed to Receivers.',
                '2.2 Email Verification\nWe use your email address to send verification links during the registration process. Your account must be verified before you can access the app.',
              ],
            ),
            _buildSection(
              title: '3. Information Sharing and Disclosure',
              subsections: [
                '3.1 With Other Users\nVolunteers: Your travel itinerary details (excluding your name, email, and password) are shared with potential Receivers to facilitate matching. Your personal information always remains private.\n\nReceivers: Your contact information is only shared with a Volunteer when you choose to contact them through the app.',
                '3.2 With Third Parties\nWe do not sell, trade, or otherwise transfer your personal information to outside parties, except as required by law or to protect the rights, property, or safety of PathPal, our users, or others.',
              ],
            ),
            _buildSection(
              title: '4. Data Security',
              subsections: [
                'We implement a variety of security measures to maintain the safety of your personal information. Your data is stored securely, and we use encryption where appropriate to protect your information during transmission.',
              ],
            ),
            _buildSection(
              title: '5. Your Rights',
              subsections: [
                'You have the right to access, correct, or delete your personal information. You can also object to or restrict certain types of processing. If you wish to exercise these rights, please contact us at info@pathpal.org.',
              ],
            ),
            _buildSection(
              title: '6. Changes to This Privacy Policy',
              subsections: [
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy and updating the "Last Updated" date.',
              ],
            ),
            _buildSection(
              title: '7. Contact Us',
              subsections: [
                'If you have any questions about this Privacy Policy, please contact us at info@pathpal.org.',
              ],
            ),
            _buildSection(title: '8. Attributions', subsections: [
              'Icons used: Instagram logo by Freepik from Flaticon, Message icon by bqlqn from Flaticon, WhatsApp icon by Freepik from Flaticon, Facebook icon by Ilham Fitrotul Hayat from Flaticon, Email icon by Uniconlabs from Flaticon',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> subsections,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (var subsection in subsections)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                subsection,
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
