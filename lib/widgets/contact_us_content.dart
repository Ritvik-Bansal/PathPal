import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsContent extends StatelessWidget {
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
      path: 'ritvikbansal08@gmail.com',
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSocialMediaOption(
      String title, String subtitle, String iconPath, VoidCallback onTap) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contact Us",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Don't hesitate to contact us whether you have a suggestion on our improvement, a complain to discuss or an issue to solve.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactOption(
                    "Message us",
                    "Our team is on the line\nMon-Fri • 9-17",
                    Icons.chat_bubble_outline,
                    _launchSMS),
                _buildContactOption(
                    "Email us",
                    "Our team is online\nMon-Fri • 9-17",
                    Icons.email_outlined,
                    _launchEmail),
              ],
            ),
            SizedBox(height: 24),
            Text(
              "Contact us in Social Media",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildSocialMediaOption("Instagram", "4,6K Followers • 118 Posts",
                "assets/images/instagram.png", () {}),
            SizedBox(height: 12),
            _buildSocialMediaOption("Facebook", "3,8K Followers • 136 Posts",
                "assets/images/facebook.png", () {}),
            SizedBox(height: 12),
            _buildSocialMediaOption("WhatsUp", "Available Mon-Fri • 9-17",
                "assets/images/whatsapp.png", () {}),
          ],
        ),
      ),
    );
  }
}
