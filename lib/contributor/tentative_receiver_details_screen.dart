import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

class TentativeReceiverDetailScreen extends StatefulWidget {
  final Map<String, dynamic> receiverData;
  final FirestoreService firestoreService;

  TentativeReceiverDetailScreen({
    Key? key,
    required this.receiverData,
    required this.firestoreService,
  }) : super(key: key);

  @override
  _TentativeReceiverDetailScreenState createState() =>
      _TentativeReceiverDetailScreenState();
}

class _TentativeReceiverDetailScreenState
    extends State<TentativeReceiverDetailScreen> {
  bool _hasContacted = false;

  @override
  void initState() {
    super.initState();
    _checkContactStatus();
  }

  Future<void> _checkContactStatus() async {
    bool hasContacted = await widget.firestoreService
        .hasContactedTentativeReceiver(widget.receiverData['userId']);
    setState(() {
      _hasContacted = hasContacted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Tentative Receiver Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasContacted)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'You have already contacted this receiver',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            _buildInfoSection('Personal Information', [
              'Name: ${widget.receiverData['userName']}',
              'Email: ${widget.receiverData['userEmail']}',
              'Phone: ${widget.receiverData['userPhone']}',
            ]),
            SizedBox(height: 20),
            _buildInfoSection('Travel Details', [
              'Start Date: ${DateFormat('MMM d, yyyy').format(widget.receiverData['startDate'].toDate())}',
              'End Date: ${DateFormat('MMM d, yyyy').format(widget.receiverData['endDate'].toDate())}',
              'Party Size: ${widget.receiverData['partySize']}',
            ]),
            SizedBox(height: 20),
            _buildInfoSection('Assistance Details', [
              'Reason: ${widget.receiverData['reason']}',
              if (widget.receiverData['otherReason'] != null &&
                  widget.receiverData['otherReason'].isNotEmpty)
                'Other Reason: ${widget.receiverData['otherReason']}',
            ]),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => _showContactConfirmationDialog(context),
                child: Text(_hasContacted
                    ? 'Contact This Receiver Again'
                    : 'Contact This Receiver'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(item),
            )),
      ],
    );
  }

  void _showContactConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Confirmation'),
          content: Text(
            'PathPal will email the tentative receiver with your contact info and travel details. Do you wish to proceed?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendEmailToReceiver(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEmailToReceiver(BuildContext context) async {
    try {
      final currentUserData =
          await widget.firestoreService.getCurrentUserData();
      if (currentUserData == null) {
        throw Exception('Current user data not found');
      }

      final emailContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>A Receiver Wants to Connect with You</title>
</head>
<body style="margin:0; padding:0; background-color:#f7f9fc; font-family: Arial, sans-serif; color:#333;">
  <div style="max-width:600px; margin:20px auto; background-color:#ffffff; border-radius:8px; box-shadow:0 2px 4px rgba(0, 0, 0, 0.1); overflow:hidden;">
    <div style="background-color:#0073e6; color:#ffffff; padding:20px; text-align:center;">
      <h1 style="margin:0; font-size:28px;">A Receiver Wants to Connect with You</h1>
    </div>
    <div style="padding:20px;">
      <p style="font-size:16px; line-height:1.5;">
        Hi ${widget.receiverData['userName']},
      </p>
      <p style="font-size:16px; line-height:1.5;">
        A Receiver has expressed interest in assisting you during your travel from ${widget.receiverData['startAirport']['name']} to ${widget.receiverData['endAirport']['name']}.
      </p>
      <div style="background-color:#f1f4f8; padding:15px; border-radius:5px; margin:20px 0;">
        <h2 style="font-size:20px; color:#0073e6; margin-top:0;">Receiver's Details:</h2>
        <p style="font-size:16px; line-height:1.5; margin:5px 0;">
          <strong>Name:</strong> ${currentUserData['name']}<br>
          <strong>Email:</strong> ${currentUserData['email']}<br>
          <strong>Phone:</strong> ${currentUserData['phone'] ?? 'Not provided'}<br>
        </p>
      </div>
      <p style="font-size:16px; line-height:1.5;">
        Please feel free to reach out to the receiver if you would like their assistance during your journey.
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Thank you for being a part of the PathPal community. We hope this connection enhances your travel experience!
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Safe travels,<br>
        <strong>The PathPal Team</strong>
      </p>
    </div>
    <div style="background-color:#f7f9fc; text-align:center; padding:15px;">
      <p style="font-size:14px; color:#555; margin:5px 0;">
        <a href="https://pathpal.org" style="color:#0073e6; text-decoration:none;">Visit our website</a> | 
        <a href="mailto:info@pathpal.org" style="color:#0073e6; text-decoration:none;">Contact Support</a>
      </p>
      <p style="font-size:12px; color:#999; margin:5px 0;">
        © ${DateTime.now().year} PathPal. All rights reserved.
      </p>
    </div>
  </div>
</body>
</html>
''';

      final response = await http.post(
        Uri.parse('https://api.mailjet.com/v3.1/send'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${dotenv.env["MAILAPI"]}'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Messages': [
            {
              'From': {'Email': 'noreply@pathpal.org', 'Name': 'PathPal'},
              'To': [
                {
                  'Email': widget.receiverData['userEmail'],
                  'Name': widget.receiverData['userName']
                }
              ],
              'Subject': 'PathPal: A Receiver Wants to Connect',
              'HTMLPart': emailContent,
              'CustomID': 'PathPalConnectEmail'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        await widget.firestoreService
            .addContactedTentativeReceiver(widget.receiverData['userId']);

        final user = _auth.currentUser;
        if (user == null) throw Exception('No authenticated user found');

        QuerySnapshot receiverQuery = await _firestore
            .collection('receivers')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        String? receiverDocId;
        if (receiverQuery.docs.isNotEmpty) {
          receiverDocId = receiverQuery.docs.first.id;
        }

        String startLocation =
            widget.receiverData['startAirport']['iata'] ?? 'Unknown';
        String endLocation =
            widget.receiverData['endAirport']['iata'] ?? 'Unknown';
        String notificationBody =
            'A receiver has expressed interest in your tentative request from $startLocation to $endLocation.';

        await widget.firestoreService.addNotification(
          widget.receiverData['userId'],
          'A Fellow Receiver Contacted You',
          notificationBody,
          receiverDocId: receiverDocId,
        );

        setState(() {
          _hasContacted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Email sent to the tentative receiver successfully')),
        );
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error sending email to the tentative receiver')),
      );
    }
  }
}
