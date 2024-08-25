import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to PathPal. By using our app, you agree to these terms. Please read them carefully.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using PathPal, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildSection(
              title: '2. Use License',
              content:
                  'Permission is granted to temporarily download one copy of PathPal for personal, non-commercial transitory viewing only.',
            ),
            _buildSection(
              title: '3. Disclaimer',
              content:
                  'The materials on PathPal are provided on an \'as is\' basis. PathPal makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            _buildSection(
              title: '4. Limitations',
              content:
                  'In no event shall PathPal or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use PathPal.',
            ),
            _buildSection(
              title: '5. Revisions and Errata',
              content:
                  'The materials appearing on PathPal could include technical, typographical, or photographic errors. PathPal does not warrant that any of the materials on its app are accurate, complete, or current.',
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
