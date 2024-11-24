import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';
import 'package:pathpal/services/fcm_service.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService;
  final FCMService _fcmService = FCMService();

  EmailService(this._firestoreService) {
    _fcmService.initialize();
  }

  Future<void> sendPushNotification(
      String userId, String title, String body) async {
    final fcmToken = await _fcmService.getFCMToken(userId);

    if (fcmToken != null) {
      try {
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=${dotenv.env["FCM_SERVER_KEY"]}',
          },
          body: json.encode({
            'notification': {
              'title': title,
              'body': body,
              'sound': 'default',
            },
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
            },
            'to': fcmToken,
          }),
        );
      } catch (e) {
        print('Error sending push notification: $e');
      }
    }
  }

  Future<void> sendEmailToTentativeReceiver(
    String userEmail,
    String userName,
    String userId,
    ContributorFormState formState,
    String contributorDocId,
    String contributorId,
  ) async {
    try {
      final emailContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Potential Volunteer Found!</title>
</head>
<body style="margin:0; padding:0; background-color:#f7f9fc; font-family: Arial, sans-serif; color:#333;">
  <div style="max-width:600px; margin:20px auto; background-color:#ffffff; border-radius:8px; box-shadow:0 2px 4px rgba(0, 0, 0, 0.1); overflow:hidden;">
    <div style="background-color:#0073e6; color:#ffffff; padding:20px; text-align:center;">
      <h1 style="margin:0; font-size:28px;">Potential Volunteer Found!</h1>
    </div>
    <div style="padding:20px;">
      <p style="font-size:16px; line-height:1.5;">
        Hi <strong>${userName}</strong>,
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Great news! A Volunteer has submitted a flight that matches your seeker request.
      </p>
      <div style="background-color:#f1f4f8; padding:15px; border-radius:5px; margin:20px 0;">
        <h2 style="font-size:20px; color:#0073e6; margin-top:0;">Flight Details:</h2>
        <table style="width:100%; border-collapse: collapse; margin-top: 10px; margin-bottom: 10px;">
          <tr style="background-color: #f1f4f8;">
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Departure</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Arrival</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Flight Number</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Date-Time</th>
          </tr>
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.departureAirport?.city}, ${formState.departureAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.numberOfLayovers > 0 ? formState.firstLayoverAirport?.city : formState.arrivalAirport?.city}, ${formState.numberOfLayovers > 0 ? formState.firstLayoverAirport?.country : formState.arrivalAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.flightNumberFirstLeg}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.flightDateTimeFirstLeg?.toLocal().toString().split(' ')[0]} ${formState.flightDateTimeFirstLeg?.toLocal().toString().split(' ')[1].substring(0, 5)}</td>
          </tr>
          ${formState.numberOfLayovers > 0 ? '''
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.firstLayoverAirport?.city}, ${formState.firstLayoverAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.numberOfLayovers > 1 ? formState.secondLayoverAirport?.city : formState.arrivalAirport?.city}, ${formState.numberOfLayovers > 1 ? formState.secondLayoverAirport?.country : formState.arrivalAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.flightNumberSecondLeg}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.flightDateTimeSecondLeg?.toLocal().toString().split(' ')[0]} ${formState.flightDateTimeSecondLeg?.toLocal().toString().split(' ')[1].substring(0, 5)}</td>
          </tr>
          ''' : ''}
          ${formState.numberOfLayovers > 1 ? '''
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.secondLayoverAirport?.city}, ${formState.secondLayoverAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.arrivalAirport?.city}, ${formState.arrivalAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.flightNumberThirdLeg}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formState.flightDateTimeThirdLeg?.toLocal().toString().split(' ')[0]} ${formState.flightDateTimeThirdLeg?.toLocal().toString().split(' ')[1].substring(0, 5)}</td>
          </tr>
          ''' : ''}
        </table>
      </div>
      <p style="font-size:16px; line-height:1.5;">
        Log in to the PathPal app to view more details and contact the Volunteer if you're interested in connecting.
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
                {'Email': userEmail, 'Name': userName}
              ],
              'Subject': 'PathPal: Potential Volunteer Found!',
              'HTMLPart': emailContent,
              'CustomID': 'PathPalVolunteerFoundEmail'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully');
      } else {
        print('Failed to send email: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      DocumentSnapshot contributorDoc = await _firestore
          .collection('contributors')
          .doc(contributorDocId)
          .get();

      if (!contributorDoc.exists) {
        throw Exception('Contributor document not found');
      }

      String contributorId = contributorDoc.get('userId') as String;

      await _firestoreService.addNotification(
        userId,
        'Potential Volunteer Found',
        'A Volunteer has submitted a flight that matches your seeker request.',
        contributorDocId: contributorDocId,
        contributorId: contributorId,
      );

      await sendPushNotification(
        userId,
        'Potential Volunteer Found',
        'A Volunteer has submitted a flight that matches your seeker request.',
      );

      print('Email notification data saved to Firestore');
    } catch (e) {
      print('Error saving email notification data: $e');
      throw Exception('Failed to save email notification data');
    }
  }

  Future<void> checkTentativeReceivers(
      ContributorFormState formState, String contributorDocId) async {
    QuerySnapshot tentativeReceivers = await _firestore
        .collection('tentativeReceivers')
        .where('startAirport.iata', isEqualTo: formState.departureAirport?.iata)
        .where('endAirport.iata', isEqualTo: formState.arrivalAirport?.iata)
        .get();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final contributorId = user.uid;

    for (QueryDocumentSnapshot doc in tentativeReceivers.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DateTime startDate = (data['startDate'] as Timestamp).toDate();
      DateTime endDate = (data['endDate'] as Timestamp).toDate();
      if (formState.flightDateTimeFirstLeg != null &&
          formState.flightDateTimeFirstLeg!.isAfter(startDate) &&
          formState.flightDateTimeFirstLeg!.isBefore(endDate)) {
        String userEmail = data['userEmail'];
        String userName = data['userName'];
        String userId = data['userId'];
        await sendEmailToTentativeReceiver(
          userEmail,
          userName,
          userId,
          formState,
          contributorDocId,
          contributorId,
        );
      }
    }
  }
}
