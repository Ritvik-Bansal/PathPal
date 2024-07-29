import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

//<a href="https://www.flaticon.com/free-icons/instagram-logo" title="instagram logo icons">Instagram logo icons created by Freepik - Flaticon</a>
//<a href="https://www.flaticon.com/free-icons/message" title="message icons">Message icons created by bqlqn - Flaticon</a>//<a href="https://www.flaticon.com/free-icons/whatsapp" title="whatsapp icons">Whatsapp icons created by Freepik - Flaticon</a>
//<a href="https://www.flaticon.com/free-icons/facebook" title="facebook icons">Facebook icons created by Ilham Fitrotul Hayat - Flaticon</a>
//<a href="https://www.flaticon.com/free-icons/email" title="email icons">Email icons created by Uniconlabs - Flaticon</a>
//<a href="https://www.flaticon.com/free-icons/whatsapp" title="whatsapp icons">Whatsapp icons created by Freepik - Flaticon</a>

const Color customBlue = Color.fromARGB(255, 203, 231, 255);

class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBlue,
      appBar: AppBar(
        title: Text(
          'Help',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: customBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                'Contact Us',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Feel free to reach out to us whenever you need assistance, encounter an issue, or would like to provide recommendations or feedback.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: _buildContactOption('Message us',
                          'assets/images/message.png', _launchSMS)),
                  SizedBox(width: 20),
                  Expanded(
                      child: _buildContactOption(
                          'Email us', 'assets/images/email.png', _launchEmail)),
                ],
              ),
              SizedBox(height: 30),
              Text(
                'Contact us in Social Media',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildSocialMediaOption(
                  'Instagram',
                  '@PathPal • Additional Information',
                  'assets/images/instagram.png',
                  () {}),
              _buildSocialMediaOption(
                  'Facebook',
                  '@PathPal • Additional Information',
                  'assets/images/facebook.png',
                  () {}),
              _buildSocialMediaOption('WhatsApp', 'Available 7 days a week',
                  'assets/images/whatsapp.png', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption(
      String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180, // Fixed height for uniformity
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25), // More rounded corners
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 40, height: 40),
            SizedBox(height: 15),
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaOption(
      String title, String subtitle, String imagePath, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Image.asset(imagePath, width: 40, height: 40),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 20),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchSMS() async {
    final Uri smsLaunchUri = Uri(scheme: 'sms', path: '4259849360');
    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      throw 'Could not launch SMS';
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri =
        Uri(scheme: 'mailto', path: 'ritvikbansal08@gmail.com');
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }
}
