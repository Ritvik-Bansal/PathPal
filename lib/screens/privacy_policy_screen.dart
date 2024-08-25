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
              'Your privacy is important to us. This Privacy Policy explains how PathPal collects, uses, and protects your personal information.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Information We Collect',
              content:
                  'We collect information you provide directly to us, such as your name, email address, and travel data when you use our app.',
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content:
                  'We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to comply with legal obligations.',
            ),
            _buildSection(
              title: '3. Data Security',
              content:
                  'We implement appropriate technical and organizational measures to protect your personal data against unauthorized or unlawful processing, accidental loss, destruction, or damage.',
            ),
            _buildSection(
              title: '4. Data Sharing and Disclosure',
              content:
                  'We do not sell your personal information. We may share your information with third-party service providers who perform services on our behalf, subject to confidentiality agreements.',
            ),
            _buildSection(
              title: '5. Your Rights',
              content:
                  'You have the right to access, correct, or delete your personal information. You can also object to processing of your personal information or request portability of your personal information.',
            ),
            _buildSection(
              title: '6. Changes to This Policy',
              content:
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
