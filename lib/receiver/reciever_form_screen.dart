import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/data/airport_database.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:pathpal/contributor/filtered_contributors_screen.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;

class RecieverFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;
  final bool isEditing;

  const RecieverFormScreen({
    Key? key,
    this.existingData,
    this.docId,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _RecieverFormScreenState createState() => _RecieverFormScreenState();
}

class _RecieverFormScreenState extends State<RecieverFormScreen> {
  final ReceiverFormState _formState = ReceiverFormState();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _phoneController = TextEditingController();
  Country? _country;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeCountry();
    if (widget.isEditing && widget.existingData != null) {
      _loadExistingData(widget.existingData!);
    } else {
      _loadExistingForm();
    }
    _formState.updateReason('I am elderly');
    _country = Country(
      phoneCode: '1',
      countryCode: 'US',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'United States',
      example: '2012345678',
      displayName: 'United States (US) [+1]',
      displayNameNoCountryCode: 'United States (US)',
      e164Key: '1-US-0',
      fullExampleWithPlusSign: '+12012345678',
    );
  }

  void _initializeCountry() async {
    final countryCode = await fetchCountryCode();
    setState(() {
      _country = CountryParser.parseCountryCode(countryCode);
    });
  }

  Future<String> fetchCountryCode() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['countryCode'];
      } else {
        throw Exception('Failed to load country code');
      }
    } catch (e) {
      return 'US';
    }
  }

  void _loadExistingData(Map<String, dynamic> data) {
    setState(() {
      _formState.updateFromMap(data);
      _phoneController.text = _formState.phoneNumber.split(' ').last;

      if (_formState.startDate != null && _formState.endDate != null) {
        final DateFormat displayFormatter = DateFormat('MMM d');
        _formState.displayDateRange =
            '${displayFormatter.format(_formState.startDate!)} - ${displayFormatter.format(_formState.endDate!)}';
      }
    });
  }

  void _loadExistingForm() async {
    final existingForm = await _firestoreService.getExistingReceiverForm();
    if (existingForm != null) {
      setState(() {
        _formState.updateFromExistingForm(existingForm);
        _phoneController.text = _formState.phoneNumber.split(' ').last;

        if (_formState.startDate != null && _formState.endDate != null) {
          final DateFormat displayFormatter = DateFormat('MMM d');
          _formState.displayDateRange =
              '${displayFormatter.format(_formState.startDate!)} - ${displayFormatter.format(_formState.endDate!)}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Seeking help'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAirportSelection(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildDateSelection()),
                    const SizedBox(width: 16),
                    _buildPartySizeSelection(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildReasonSelection(),
                const SizedBox(height: 24),
                _buildPhoneNumberInput(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAirportSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAirportSearch(
          hint: 'From',
          icon: Icons.flight_takeoff,
          onSelect: _formState.updateStartAirport,
          selectedAirport: _formState.startAirport,
        ),
        const SizedBox(height: 16),
        _buildAirportSearch(
          hint: 'To',
          icon: Icons.flight_land,
          onSelect: _formState.updateEndAirport,
          selectedAirport: _formState.endAirport,
        ),
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

  void _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(context).colorScheme.primaryContainer,
            colorScheme: Theme.of(context).colorScheme,
            scaffoldBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String formattedStartDate = formatter.format(picked.start);
      final String formattedEndDate = formatter.format(picked.end);
      final String formattedRange = '$formattedStartDate - $formattedEndDate';

      setState(() {
        _formState.updateDateRange(formattedRange);
      });

      final DateFormat displayFormatter = DateFormat('MMM d');
      final String displayRange =
          '${displayFormatter.format(picked.start)} - ${displayFormatter.format(picked.end)}';
      setState(() {
        _formState.displayDateRange = displayRange;
      });
    }
  }

  Widget _buildDateSelection() {
    return InkWell(
      onTap: () => _pickDateRange(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Travel Dates',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formState.displayDateRange.isEmpty
                ? 'Select dates'
                : _formState.displayDateRange),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: _formState.reason,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                dropdownColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.all(Radius.circular(20)),
                items: const [
                  DropdownMenuItem(
                      value: 'I am elderly', child: Text('I am elderly')),
                  DropdownMenuItem(
                      value: 'I am a single parent flying with kids',
                      child: Text('Single parent with kids')),
                  DropdownMenuItem(
                      value: 'I need company', child: Text('Need company')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _formState.updateReason(value ?? '');
                  });
                },
              ),
            ),
          ),
        ),
        if (_formState.reason == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (value) {
                _formState.updateOtherReason(value);
              },
              validator: (value) {
                if (_formState.reason == 'Other' &&
                    (value == null || value.isEmpty)) {
                  return 'Please specify your reason';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPartySizeSelection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
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
              items: List.generate(5, (index) => index + 1)
                  .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _formState.updatePartySize(value ?? 1);
                });
              },
              borderRadius: BorderRadius.all(Radius.circular(20)),
              icon: const Icon(Icons.arrow_drop_down),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberInput() {
    return TextFormField(
      controller: _phoneController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.length < 10 || digitsOnly.length > 15) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        prefixIcon: GestureDetector(
          onTap: () {
            showCountryPicker(
              context: context,
              onSelect: (Country country) {
                setState(() {
                  _country = country;
                });
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_country?.flagEmoji ?? ''} +${_country?.phoneCode ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
      keyboardType: TextInputType.phone,
      onChanged: (value) {
        _formState.updatePhoneNumber('+${_country!.phoneCode} $value');
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 202, 231, 255)),
        onPressed: _submitForm,
        child: Text(
          widget.isEditing ? 'Save' : 'Search',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_validateForm()) {
        return;
      }

      try {
        if (widget.isEditing) {
          await _firestoreService.updateTentativeReceiver(
              widget.docId!, _formState);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Seeker request updated successfully')),
          );
          Navigator.of(context).pop();
        } else {
          await _firestoreService.submitReceiverForm(_formState);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  FilteredContributorsScreen(receiverFormState: _formState),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      }
    }
  }

  bool _validateForm() {
    if (_formState.startAirport == null ||
        _formState.endAirport == null ||
        _formState.selectedDateRange.isEmpty ||
        _formState.phoneNumber.isEmpty ||
        (_formState.reason == 'Other' && _formState.otherReason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return false;
    }
    return true;
  }
}
