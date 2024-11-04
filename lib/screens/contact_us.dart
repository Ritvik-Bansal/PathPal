import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color customBlue = Color.fromARGB(255, 203, 231, 255);

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Help',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Contact Us',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Feel free to reach out to us whenever you need assistance, encounter an issue, or would like to provide recommendations or feedback.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: _buildContactOption('Message us',
                          'assets/images/message.png', _launchSMS, context)),
                  const SizedBox(width: 20),
                  Expanded(
                      child: _buildContactOption('Email us',
                          'assets/images/email.png', _launchEmail, context)),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Contact us in Social Media',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildSocialMediaOption('Instagram', '@path_pal • Account Tag',
                  'assets/images/instagram.png', _launchInstagram, context),
              _buildSocialMediaOption('Facebook', '@PathPal • Facebook Page',
                  'assets/images/facebook.png', _launchFacebook, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption(String title, String imagePath, VoidCallback onTap,
      BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 180, 221, 255),
            width: 5,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 40,
              height: 40,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 15),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaOption(String title, String subtitle,
      String imagePath, VoidCallback onTap, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 180, 221, 255),
          width: 5,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Image.asset(
          imagePath,
          width: 40,
          height: 40,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchSMS() async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: '4259849360',
      queryParameters: <String, String>{
        'body': Uri.encodeComponent(''),
      },
    );

    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      throw 'Could not launch SMS';
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri.parse(
        'mailto:info@pathpal.org?subject=${Uri.encodeComponent('Contact from PathPal app')}&body=${Uri.encodeComponent('')}');

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }

  Future<void> _launchInstagram() async {
    final Uri instagramAppUrl = Uri.parse('instagram://user?username=path_pal');
    final Uri instagramWebUrl = Uri.parse('https://www.instagram.com/path_pal');

    try {
      if (await canLaunchUrl(instagramAppUrl)) {
        await launchUrl(instagramAppUrl);
      } else {
        if (await canLaunchUrl(instagramWebUrl)) {
          await launchUrl(instagramWebUrl,
              mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Instagram';
        }
      }
    } catch (e) {
      if (await canLaunchUrl(instagramWebUrl)) {
        await launchUrl(instagramWebUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Instagram';
      }
    }
  }

  Future<void> _launchFacebook() async {
    final Uri fbAppUrl = Uri.parse('fb://page/61563851220198');
    final Uri fbWebUrl = Uri.parse('https://www.facebook.com/61563851220198');

    try {
      if (await canLaunchUrl(fbAppUrl)) {
        await launchUrl(fbAppUrl);
      } else {
        if (await canLaunchUrl(fbWebUrl)) {
          await launchUrl(fbWebUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Facebook';
        }
      }
    } catch (e) {
      if (await canLaunchUrl(fbWebUrl)) {
        await launchUrl(fbWebUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Facebook';
      }
    }
  }
}
