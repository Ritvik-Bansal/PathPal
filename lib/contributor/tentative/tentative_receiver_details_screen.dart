import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

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
        title: Text('Seeker Details'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ))
          : SingleChildScrollView(
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
                  _buildTravelRoute(),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _showContactConfirmationDialog(context),
                      child: Text(_hasContacted
                          ? 'Contact This Receiver Again'
                          : 'Contact This Receiver'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTravelRoute() {
    String departureCode = widget.receiverData['startAirport']?['iata'] ?? '';
    String arrivalCode = widget.receiverData['endAirport']?['iata'] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color.fromARGB(255, 180, 221, 255), width: 5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(
            '${widget.receiverData['startAirport']['name']} to ${widget.receiverData['endAirport']['name']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                departureCode,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Transform.rotate(
                angle: 90 * 3.14159 / 180,
                child: const Icon(
                  Icons.flight_outlined,
                  size: 30,
                ),
              ),
              Text(
                arrivalCode,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Range: ${_formatDate(widget.receiverData['startDate'])} - ${_formatDate(widget.receiverData['endDate'])}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                'Reason: ${widget.receiverData['reason']}',
                style: TextStyle(fontSize: 16),
              ),
              if (widget.receiverData['otherReason'] != null &&
                  widget.receiverData['otherReason'].isNotEmpty)
                Text('Other Reason: ${widget.receiverData['otherReason']}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  void _showContactConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Confirmation'),
          content: Text(
            'PathPal will email the Seeker receiver with your contact info and travel details. Do you wish to proceed?',
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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserData =
          await widget.firestoreService.getCurrentUserData();
      if (currentUserData == null) {
        throw Exception('Current user data not found');
      }

      final emailContent = _buildEmailContent(
        recipientName: widget.receiverData['userName'] ?? '',
        title: 'A Seeker Wants to Connect with You',
        introText:
            'A Seeker has expressed interest in your travel request from ${widget.receiverData['startAirport']['name']} to ${widget.receiverData['endAirport']['name']}.',
        flightDetails: '''
        <p style="font-size:16px; line-height:1.5; margin:5px 0;">
          <strong>From:</strong> ${widget.receiverData['startAirport']['name']} (${widget.receiverData['startAirport']['iata']})<br>
          <strong>To:</strong> ${widget.receiverData['endAirport']['name']} (${widget.receiverData['endAirport']['iata']})<br>
          <strong>Date Range:</strong> ${_formatDate(widget.receiverData['startDate'])} - ${_formatDate(widget.receiverData['endDate'])}<br>
          <strong>Reason for Travel:</strong> ${widget.receiverData['reason']}
          ${widget.receiverData['otherReason'] != null && widget.receiverData['otherReason'].isNotEmpty ? '<br><strong>Other Reason:</strong> ${widget.receiverData['otherReason']}' : ''}
        </p>
      ''',
        contactDetails: '''
        <strong>Name:</strong> ${currentUserData['name']}<br>
        <strong>Email:</strong> ${currentUserData['email']}<br>
        <strong>Phone:</strong> ${currentUserData['phone'] ?? 'Not provided'}<br>
      ''',
        contactTitle: "Seeker's Details:",
        callToAction:
            "Please feel free to reach out to the Seeker if you would like their assistance during your journey.",
      );
      print('Sending email');
      final response = await http.post(
        Uri.parse('https://api.mailjet.com/v3.1/send'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${dotenv.env["MAILAPI"] ?? ""}'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Messages': [
            {
              'From': {'Email': 'noreply@pathpal.org', 'Name': 'PathPal'},
              'To': [
                {
                  'Email': widget.receiverData['userEmail'] ?? '',
                  'Name': widget.receiverData['userName'] ?? ''
                }
              ],
              'Subject': 'PathPal: A Seeker Wants to Connect',
              'HTMLPart': emailContent,
              'CustomID': 'PathPalConnectEmail'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        await widget.firestoreService
            .addContactedTentativeReceiver(widget.receiverData['userId'] ?? '');

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('No authenticated user found');

        QuerySnapshot receiverQuery = await FirebaseFirestore.instance
            .collection('receivers')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        String? receiverDocId;
        if (receiverQuery.docs.isNotEmpty) {
          receiverDocId = receiverQuery.docs.first.id;
        } else {}

        String startLocation =
            widget.receiverData['startAirport']?['iata'] ?? 'Unknown';
        String endLocation =
            widget.receiverData['endAirport']?['iata'] ?? 'Unknown';
        String notificationBody =
            'A Seeker has expressed interest in your request from $startLocation to $endLocation.';

        await widget.firestoreService.addNotification(
          widget.receiverData['userId'] ?? '',
          'A Fellow Seeker Contacted You',
          notificationBody,
          receiverDocId: receiverDocId,
        );

        if (mounted) {
          setState(() {
            _hasContacted = true;
            _isLoading = false;
          });
          _showMessage(context, 'Email sent to the Seeker successfully');
        }
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in _sendEmailToReceiver: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showMessage(context, 'An error occurred: ${e.toString()}');
      }
    }
  }

  String _buildEmailContent({
    required String recipientName,
    required String title,
    required String introText,
    required String flightDetails,
    required String contactDetails,
    required String contactTitle,
    required String callToAction,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
</head>
<body style="margin:0; padding:0; background-color:#f7f9fc; font-family: Arial, sans-serif; color:#333;">
  <div style="max-width:600px; margin:20px auto; background-color:#ffffff; border-radius:8px; box-shadow:0 2px 4px rgba(0, 0, 0, 0.1); overflow:hidden;">
    <div style="background-color:#0073e6; color:#ffffff; padding:20px; text-align:center;">
      <h1 style="margin:0; font-size:28px;">$title</h1>
    </div>
    <div style="padding:20px;">
      <p style="font-size:16px; line-height:1.5;">
        Hi <strong>$recipientName</strong>,
      </p>
      <p style="font-size:16px; line-height:1.5;">
        $introText
      </p>
      <div style="background-color:#f1f4f8; padding:15px; border-radius:5px; margin:20px 0;">
        <h3 style="font-size:20px; color:#0073e6; margin-top:0;">Flight Details:</h3>
        $flightDetails
      </div>
      <div style="background-color:#f1f4f8; padding:15px; border-radius:5px; margin:20px 0;">
        <h3 style="font-size:20px; color:#0073e6; margin-top:0;">$contactTitle</h3>
        <p style="font-size:16px; line-height:1.5; margin:5px 0;">
          $contactDetails
        </p>
      </div>
      <p style="font-size:16px; line-height:1.5;">
        $callToAction
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
  }

  void _showMessage(BuildContext context, String message) {
    if (mounted) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
  }
}
