import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/data/airport_database.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final TextEditingController _flightNumberController = TextEditingController();
  final TextEditingController _flightNumberFirstLegController =
      TextEditingController();
  final TextEditingController _flightNumberSecondLegController =
      TextEditingController();
  final TextEditingController _flightNumberThirdLegController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _formState = ContributorFormState();
    if (widget.contributorId != null) {
      _fetchExistingFormData();
    }
  }

  Future<void> _fetchExistingFormData() async {
    try {
      final data =
          await _firestoreService.getContributorFormData(widget.contributorId!);
      if (data != null) {
        setState(() {
          _formState.updateFromMap(data);
          _flightNumberController.text = _formState.flightNumberFirstLeg;
          _flightNumberFirstLegController.text =
              _formState.flightNumberFirstLeg;
          _flightNumberSecondLegController.text =
              _formState.flightNumberSecondLeg;
          _flightNumberThirdLegController.text =
              _formState.flightNumberThirdLeg;
        });
      }
    } catch (e) {
      print('Error fetching existing form data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Become a Volunteer'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildFlightTypeSelection()),
                  const SizedBox(width: 16),
                  _buildPartySizeSelection(),
                ],
              ),
              const SizedBox(height: 24),
              _buildAirportSelection(),
              const SizedBox(height: 24),
              _buildFlightDetailsSection(),
              const SizedBox(height: 10),
              _buildAllowInAppMessagesCheckbox(),
              const SizedBox(height: 10),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllowInAppMessagesCheckbox() {
    return CheckboxListTile(
      title: const Text(
        'Allow seekers to send in-app messages',
        style: TextStyle(fontSize: 13),
      ),
      value: _formState.allowInAppMessages,
      onChanged: (bool? value) {
        setState(() {
          _formState.updateAllowInAppMessages(value ?? true);
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      fillColor:
          WidgetStatePropertyAll(const Color.fromARGB(255, 180, 221, 255)),
      checkColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildAirportSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAirportSearch(
                hint: 'From',
                icon: Icons.flight_takeoff,
                onSelect: _formState.updateDepartureAirport,
                selectedAirport: _formState.departureAirport,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAirportSearch(
                hint: 'To',
                icon: Icons.flight_land,
                onSelect: _formState.updateArrivalAirport,
                selectedAirport: _formState.arrivalAirport,
              ),
            ),
          ],
        ),
        if (_formState.numberOfLayovers > 0) ...[
          const SizedBox(height: 16),
          _buildAirportSearch(
            hint: 'First Layover',
            icon: Icons.airplanemode_active,
            onSelect: _formState.updateFirstLayoverAirport,
            selectedAirport: _formState.firstLayoverAirport,
          ),
        ],
        if (_formState.numberOfLayovers > 1) ...[
          const SizedBox(height: 16),
          _buildAirportSearch(
            hint: 'Second Layover',
            icon: Icons.airplanemode_active,
            onSelect: _formState.updateSecondLayoverAirport,
            selectedAirport: _formState.secondLayoverAirport,
          ),
        ],
      ],
    );
  }

  Widget _buildAirportSearch({
    required String hint,
    required IconData icon,
    required Function(Airport) onSelect,
    Airport? selectedAirport,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color.fromARGB(255, 108, 108, 108), width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SearchAnchor(
        viewBackgroundColor: Theme.of(context).colorScheme.surface,
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            backgroundColor:
                WidgetStatePropertyAll(Theme.of(context).colorScheme.surface),
            elevation: const WidgetStatePropertyAll(0.0),
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0)),
            onTap: () {
              controller.openView();
            },
            onChanged: (_) {
              controller.openView();
            },
            leading: Icon(icon),
            hintText: selectedAirport != null
                ? '${selectedAirport.name} (${selectedAirport.iata})'
                : hint,
            trailing: selectedAirport != null
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(selectedAirport.iata,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]
                : null,
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) async {
          final airports =
              await AirportDatabase.instance.searchAirports(controller.text);
          return airports.map((airport) => ListTile(
                title: Text(airport.name),
                subtitle: Text('${airport.city}, ${airport.country}'),
                trailing: Text(airport.iata),
                onTap: () {
                  onSelect(airport);
                  controller.closeView('${airport.name} (${airport.iata})');
                  setState(() {});
                },
              ));
        },
      ),
    );
  }

  Widget _buildFlightTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 63, 63, 63)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<int>(
            value: _formState.numberOfLayovers,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24,
            elevation: 16,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            dropdownColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Direct')),
              DropdownMenuItem(value: 1, child: Text('1 Layover')),
              DropdownMenuItem(value: 2, child: Text('2 Layovers')),
            ],
            onChanged: (value) {
              setState(() {
                _formState.numberOfLayovers = value ?? 0;
                if (value == 0) {
                  _formState.removeLayovers();
                }
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPartySizeSelection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 63, 63, 63)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 20),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _formState.partySize,
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              items: List.generate(5, (index) => index + 1)
                  .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _formState.updatePartySize(value ?? 1);
                });
              },
              icon: const Icon(Icons.arrow_drop_down),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightDetailsSection() {
    return Column(
      children: [
        _buildFlightLegDetails(
          legNumber: 1,
          flightNumberController: _flightNumberFirstLegController,
          dateTime: _formState.flightDateTimeFirstLeg,
          onDateTimeChanged: (dateTime) =>
              setState(() => _formState.flightDateTimeFirstLeg = dateTime),
        ),
        if (_formState.numberOfLayovers > 0) ...[
          const SizedBox(height: 16),
          _buildFlightLegDetails(
            legNumber: 2,
            flightNumberController: _flightNumberSecondLegController,
            dateTime: _formState.flightDateTimeSecondLeg,
            onDateTimeChanged: (dateTime) =>
                setState(() => _formState.flightDateTimeSecondLeg = dateTime),
          ),
        ],
        if (_formState.numberOfLayovers > 1) ...[
          const SizedBox(height: 16),
          _buildFlightLegDetails(
            legNumber: 3,
            flightNumberController: _flightNumberThirdLegController,
            dateTime: _formState.flightDateTimeThirdLeg,
            onDateTimeChanged: (dateTime) =>
                setState(() => _formState.flightDateTimeThirdLeg = dateTime),
          ),
        ],
      ],
    );
  }

  Widget _buildFlightLegDetails({
    required int legNumber,
    required TextEditingController flightNumberController,
    required DateTime? dateTime,
    required Function(DateTime) onDateTimeChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildFlightNumberInput(
            flightNumberController,
            'Flight # (Leg $legNumber)',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateTimeInput(
            dateTime,
            onDateTimeChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFlightNumberInput(
      TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a flight number';
        }
        if (!RegExp(r'^[A-Za-z]{2,}\d+$').hasMatch(value)) {
          return 'Invalid flight number format';
        }
        return null;
      },
      onChanged: (value) {
        value = value.toUpperCase();
        controller.value = controller.value.copyWith(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
        if (_formState.numberOfLayovers > 0) {
          if (controller == _flightNumberFirstLegController) {
            _formState.updateFlightNumberFirstLeg(value);
          } else if (controller == _flightNumberSecondLegController) {
            _formState.updateFlightNumberSecondLeg(value);
          } else if (controller == _flightNumberThirdLegController) {
            _formState.updateFlightNumberThirdLeg(value);
          }
        } else {
          _formState.updateFlightNumber(value);
        }
      },
    );
  }

  Widget _buildDateTimeInput(
    DateTime? selectedDateTime,
    Function(DateTime) onChanged,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Date & Time',
        hintText: 'Date & Time',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        prefixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: selectedDateTime != null
            ? DateFormat('yyyy-MM-dd h:mm a').format(selectedDateTime)
            : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDateTime ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (date != null) {
          final time = await showTimePicker(
            initialEntryMode: TimePickerEntryMode.input,
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  timePickerTheme: const TimePickerThemeData(
                    dayPeriodColor: Color.fromARGB(255, 180, 221, 255),
                  ),
                ),
                child: child!,
              );
            },
            context: context,
            initialTime:
                TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
          );
          if (time != null) {
            final dateTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
            onChanged(dateTime);
          }
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date and time';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 202, 231, 255),
            foregroundColor: Colors.black),
        onPressed: _submitForm,
        child: const Text('Submit'),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_validateForm()) {
        return;
      }

      try {
        final userEmail = await _firestoreService.getUserEmail();
        if (userEmail == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not fetch email')),
          );
          return;
        }
        _formState.email = userEmail;

        if (widget.contributorId != null) {
          await _firestoreService.updateContributorForm(
              widget.contributorId!, _formState);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form updated successfully')),
          );
        } else {
          await _firestoreService.submitContributorForm(_formState);
          await _sendConfirmationEmail();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Form submitted successfully. Please check your email for details.')),
          );
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      }
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

      String generateFlightTable() {
        String tableContent = '''
  <table style="width:100%; border-collapse: collapse; margin-top: 10px; margin-bottom: 10px;">
    <tr style="background-color: #f1f4f8;">
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Departure</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Arrival</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Flight Number</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Date-Time</th>
    </tr>
  ''';

        tableContent += '''
  <tr>
    <td style="padding: 10px; border: 1px solid #ddd;">${_formState.departureAirport?.city}, ${_formState.departureAirport?.country}</td>
    <td style="padding: 10px; border: 1px solid #ddd;">${_formState.numberOfLayovers > 0 ? _formState.firstLayoverAirport?.city : _formState.arrivalAirport?.city}, ${_formState.numberOfLayovers > 0 ? _formState.firstLayoverAirport?.country : _formState.arrivalAirport?.country}</td>
    <td style="padding: 10px; border: 1px solid #ddd;">${_formState.flightNumberFirstLeg}</td>
    <td style="padding: 10px; border: 1px solid #ddd;">${formatDateTime(_formState.flightDateTimeFirstLeg)}</td>
  </tr>
  ''';

        if (_formState.numberOfLayovers > 0) {
          tableContent += '''
    <tr>
      <td style="padding: 10px; border: 1px solid #ddd;">${_formState.firstLayoverAirport?.city}, ${_formState.firstLayoverAirport?.country}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${_formState.numberOfLayovers > 1 ? _formState.secondLayoverAirport?.city : _formState.arrivalAirport?.city}, ${_formState.numberOfLayovers > 1 ? _formState.secondLayoverAirport?.country : _formState.arrivalAirport?.country}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${_formState.flightNumberSecondLeg}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${formatDateTime(_formState.flightDateTimeSecondLeg)}</td>
    </tr>
    ''';
        }

        if (_formState.numberOfLayovers > 1) {
          tableContent += '''
    <tr>
      <td style="padding: 10px; border: 1px solid #ddd;">${_formState.secondLayoverAirport?.city}, ${_formState.secondLayoverAirport?.country}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${_formState.arrivalAirport?.city}, ${_formState.arrivalAirport?.country}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${_formState.flightNumberThirdLeg}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${formatDateTime(_formState.flightDateTimeThirdLeg)}</td>
    </tr>
    ''';
        }

        tableContent += '</table>';
        return tableContent;
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
        ${generateFlightTable()}
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
      } else {
        throw Exception('Failed to send confirmation email: ${response.body}');
      }
    } catch (e) {
      print('Error sending confirmation email: $e');
    }
  }

  bool _validateForm() {
    if (_formState.departureAirport == null ||
        _formState.arrivalAirport == null ||
        (_formState.numberOfLayovers > 0
            ? _formState.flightNumberFirstLeg.isEmpty
            : _formState.flightNumber.isEmpty) ||
        _formState.flightDateTimeFirstLeg == null ||
        (_formState.numberOfLayovers > 0 &&
            (_formState.firstLayoverAirport == null ||
                _formState.flightNumberSecondLeg.isEmpty ||
                _formState.flightDateTimeSecondLeg == null)) ||
        (_formState.numberOfLayovers > 1 &&
            (_formState.secondLayoverAirport == null ||
                _formState.flightNumberThirdLeg.isEmpty ||
                _formState.flightDateTimeThirdLeg == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return false;
    }
    return true;
  }
}
