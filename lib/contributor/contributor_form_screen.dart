import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/screens/privacy_policy_screen.dart';
import 'package:pathpal/screens/terms_conditions_screen.dart';
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
          const SnackBar(content: Text('Form submitted successfully')),
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

      final emailContent = 'Thank you for your contribution to PathPal! '
          'Your flight information has been successfully submitted. '
          'Your assistance will help make travel easier for others. '
          'Here\'s a summary of your submitted information:\n\n'
          'Flight Number: ${_formState.flightNumber}\n'
          'Departure: ${_formState.departureAirport?.city}, ${_formState.departureAirport?.country}\n'
          'Arrival: ${_formState.arrivalAirport?.city}, ${_formState.arrivalAirport?.country}\n'
          'Date: ${_formState.flightDateTime?.toLocal().toString().split(' ')[0]}\n\n'
          'If you need to make any changes, please edit your form in the my trips section. '
          'Thank you for being a PathPal contributor!';

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
              'From': {'Email': 'path2pal@gmail.com', 'Name': 'PathPal'},
              'To': [
                {'Email': userEmail, 'Name': user.displayName ?? 'Contributor'}
              ],
              'Subject': 'Thank You for Your PathPal Contribution',
              'TextPart': emailContent,
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
        title: const Text('Become a Contributor'),
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
              onFlightDateTimeUpdated: (dateTime) {
                setState(() {
                  _formState.updateFlightDateTime(dateTime);
                });
              },
              onDepartureAirportSelected: _selectDepartureAirport,
              onArrivalAirportSelected: _selectArrivalAirport,
              onLayoverAirportSelected: _selectLayoverAirport,
              onLayoverToggled: _toggleLayover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                children: [
                  const TextSpan(
                    text: 'By submitting, you agree to our ',
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const TermsAndConditionsScreen()),
                        );
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PrivacyPolicyScreen()),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
          ),
          SizedBox(height: 30)
        ],
      ),
    );
  }
}
