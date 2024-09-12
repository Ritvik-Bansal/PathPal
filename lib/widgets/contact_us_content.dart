import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsContent extends StatelessWidget {
  const ContactUsContent({super.key});

  Future<void> _launchSMS() async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: '4259849360',
    );
    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      throw 'Could not launch SMS';
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@pathpal.org',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }

  Widget _buildContactOption(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSocialMediaOption(
      String title, String subtitle, String iconPath, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact Us",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Don't hesitate to contact us whether you have a suggestion on our improvement, a complain to discuss or an issue to solve.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactOption(
                    "Message us",
                    "Our team is on the line\nMon-Fri • 9-5",
                    Icons.chat_bubble_outline,
                    _launchSMS),
                _buildContactOption(
                    "Email us",
                    "Our team is online\nMon-Fri • 9-5",
                    Icons.email_outlined,
                    _launchEmail),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Contact us in Social Media",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSocialMediaOption("Instagram", "4,6K Followers • 118 Posts",
                "assets/images/instagram.png", () {}),
            const SizedBox(height: 12),
            _buildSocialMediaOption("Facebook", "3,8K Followers • 136 Posts",
                "assets/images/facebook.png", () {}),
            const SizedBox(height: 12),
            _buildSocialMediaOption("WhatsUp", "Available Mon-Fri • 9-17",
                "assets/images/whatsapp.png", () {}),
          ],
        ),
      ),
    );
  }
}
