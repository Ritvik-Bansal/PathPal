import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';
import 'package:pathpal/contributor/flight_info_page.dart';
import 'package:http/http.dart' as http;

class ContributorFormScreen extends StatefulWidget {
  final String? contributorId;

  const ContributorFormScreen({super.key, this.contributorId});

  @override
  _ContributorFormScreenState createState() => _ContributorFormScreenState();
}

class _ContributorFormScreenState extends State<ContributorFormScreen> {
  late ContributorFormState _formState;
  final FirestoreService _firestoreService = FirestoreService();
  late TextEditingController _flightNumberController;
  late TextEditingController _flightNumberFirstLegController;
  late TextEditingController _flightNumberSecondLegController;

  @override
  void initState() {
    super.initState();
    _formState = ContributorFormState();
    _flightNumberController = TextEditingController();
    _flightNumberFirstLegController = TextEditingController();
    _flightNumberSecondLegController = TextEditingController();
    if (widget.contributorId != null) {
      _fetchExistingFormData().then((_) {
        setState(() {
          _flightNumberController.text = _formState.flightNumber;
          _flightNumberFirstLegController.text =
              _formState.flightNumberFirstLeg;
          _flightNumberSecondLegController.text =
              _formState.flightNumberSecondLeg;
        });
      });
    }
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    _flightNumberFirstLegController.dispose();
    _flightNumberSecondLegController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingFormData() async {
    try {
      final data =
          await _firestoreService.getContributorFormData(widget.contributorId!);
      if (data != null) {
        setState(() {
          _formState.updateFromMap(data);
          _formState.departureAirport = data['departureAirport'] != null
              ? Airport.fromMap(data['departureAirport'])
              : null;
          _formState.arrivalAirport = data['arrivalAirport'] != null
              ? Airport.fromMap(data['arrivalAirport'])
              : null;
          _formState.layoverAirport = data['layoverAirport'] != null
              ? Airport.fromMap(data['layoverAirport'])
              : null;

          _flightNumberController.text = _formState.flightNumber;
          _flightNumberFirstLegController.text =
              _formState.flightNumberFirstLeg;
          _flightNumberSecondLegController.text =
              _formState.flightNumberSecondLeg;
        });
      }
    } catch (e) {
      print('Error fetching existing form data: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formState.isFlightInfoValid()) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final userEmail = await _firestoreService.getUserEmail();
      if (userEmail == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not fetch email')));
        return;
      }
      _formState.email = userEmail;

      if (widget.contributorId != null) {
        await _firestoreService.updateContributorForm(
            widget.contributorId!, _formState);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form updated successfully')),
        );
      } else {
        await _firestoreService.submitContributorForm(_formState);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Form submitted successfully. Please check your email for details. If you do not see the email in your inbox, please check your junk mail folder and add "info@pathpal.org" to your Safe Sender List.')),
        );
        await _sendConfirmationEmail();
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    }
  }

  Future<void> _sendConfirmationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return;
      }

      final userEmail = await _firestoreService.getUserEmail();
      if (userEmail == null) {
        print('Error: User email not found');
        return;
      }

      String formatDateTime(DateTime? dateTime) {
        if (dateTime == null) return 'N/A';
        return '${dateTime.toLocal().month}/${dateTime.toLocal().day}/${dateTime.toLocal().year} at ${dateTime.toLocal().hour % 12 == 0 ? 12 : dateTime.toLocal().hour % 12}:${dateTime.toLocal().minute.toString().padLeft(2, '0')} ${dateTime.toLocal().hour < 12 ? 'AM' : 'PM'}';
      }

      final emailContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Thank You for Your Contribution</title>
</head>
<body style="margin:0; padding:0; background-color:#f7f9fc; font-family: Arial, sans-serif; color:#333;">
  <div style="max-width:600px; margin:20px auto; background-color:#ffffff; border-radius:8px; box-shadow:0 2px 4px rgba(0, 0, 0, 0.1); overflow:hidden;">
    <div style="background-color:#0073e6; color:#ffffff; padding:20px; text-align:center;">
      <h1 style="margin:0; font-size:28px;">Thank You for your contribution!</h1>
    </div>
    <div style="padding:20px;">
      <p style="font-size:16px; line-height:1.5;">
        Hi <strong>${user.displayName ?? 'PathPal Volunteer'}</strong>,
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Your flight details have been successfully submitted! ✈️
      </p>
      <div style="background-color:#f1f4f8; padding:15px; border-radius:5px; margin:20px 0;">
        <h2 style="font-size:20px; color:#0073e6; margin-top:0;">Here are your trip details:</h2>
        ${_formState.hasLayover ? '''
        <table style="width:100%; border-collapse: collapse; margin-top: 10px; margin-bottom: 10px;">
          <tr style="background-color: #f1f4f8;">
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Departure</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Arrival</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Flight Number</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Date-Time</th>
          </tr>
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.departureAirport?.city}, ${_formState.departureAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.layoverAirport?.city}, ${_formState.layoverAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.flightNumberFirstLeg}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formatDateTime(_formState.flightDateTimeFirstLeg)}</td>
          </tr>
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.layoverAirport?.city}, ${_formState.layoverAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.arrivalAirport?.city}, ${_formState.arrivalAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.flightNumberSecondLeg}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formatDateTime(_formState.flightDateTimeSecondLeg)}</td>
          </tr>
        </table>
        ''' : '''
        <table style="width:100%; border-collapse: collapse; margin-top: 10px; margin-bottom: 10px;">
          <tr style="background-color: #f1f4f8;">
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Departure</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Arrival</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Flight Number</th>
            <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Date-Time</th>
          </tr>
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.departureAirport?.city}, ${_formState.departureAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.arrivalAirport?.city}, ${_formState.arrivalAirport?.country}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${_formState.flightNumber}</td>
            <td style="padding: 10px; border: 1px solid #ddd;">${formatDateTime(_formState.flightDateTimeFirstLeg)}</td>
          </tr>
        </table>
        '''}
      </div>
      <p style="font-size:16px; line-height:1.5;">
        If you need to make any changes, feel free to update your info in the <strong>"My Trips"</strong> section of our app.
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Thanks a million for being part of the PathPal family. Together, we're making travel smoother and more enjoyable for everyone! 🌟
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
                {'Email': userEmail, 'Name': user.displayName ?? 'Volunteer'}
              ],
              'Subject': 'Thank You for Your PathPal Contribution!',
              'HTMLPart': emailContent,
              'CustomID': 'PathPalContributionEmail'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        print('Confirmation email sent successfully');
      } else {
        throw Exception('Failed to send confirmation email: ${response.body}');
      }
    } catch (e) {
      print('Error sending confirmation email: $e');
    }
  }

  void _selectDepartureAirport(Airport airport) {
    setState(() {
      _formState.updateDepartureAirport(airport);
    });
  }

  void _selectArrivalAirport(Airport airport) {
    setState(() {
      _formState.updateArrivalAirport(airport);
    });
  }

  void _selectLayoverAirport(Airport airport) {
    setState(() {
      _formState.updateLayoverAirport(airport);
    });
  }

  void _toggleLayover(bool hasLayover) {
    setState(() {
      if (hasLayover) {
        _formState.updateLayoverAirport(null);
      } else {
        _formState.removeLayover();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Become a Volunteer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlightInfoPage(
              formState: _formState,
              onFlightNumberUpdated: (flightNumber) {
                setState(() {
                  _formState.updateFlightNumber(flightNumber);
                });
              },
              onPartySizeUpdated: (partySize) {
                setState(() {
                  _formState.updatePartySize(partySize);
                });
              },
              onFlightNumberFirstLegUpdated: (flightNumber) {
                setState(() {
                  _formState.updateFlightNumberFirstLeg(flightNumber);
                });
              },
              onFlightNumberSecondLegUpdated: (flightNumber) {
                setState(() {
                  _formState.updateFlightNumberSecondLeg(flightNumber);
                });
              },
              onFlightDateTimeFirstLegUpdated: (dateTime) {
                setState(() {
                  _formState.updateFlightDateTimeFirstLeg(dateTime);
                });
              },
              onFlightDateTimeSecondLegUpdated: (dateTime) {
                setState(() {
                  _formState.updateFlightDateTimeSecondLeg(dateTime);
                });
              },
              onDepartureAirportSelected: _selectDepartureAirport,
              onArrivalAirportSelected: _selectArrivalAirport,
              onLayoverAirportSelected: _selectLayoverAirport,
              onLayoverToggled: _toggleLayover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
