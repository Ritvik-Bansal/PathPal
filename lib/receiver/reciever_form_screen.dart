import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pathpal/contributor/filtered_contributors_screen.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';
import 'package:pathpal/receiver/date_selection_page.dart';
import 'package:pathpal/receiver/airport_selection_page.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:country_picker/country_picker.dart';

class RecieverFormScreen extends StatefulWidget {
  const RecieverFormScreen({super.key});

  @override
  _RecieverFormScreenState createState() => _RecieverFormScreenState();
}

class _RecieverFormScreenState extends State<RecieverFormScreen> {
  final PageController _pageController = PageController();
  final ReceiverFormState _formState = ReceiverFormState();
  final FirestoreService _firestoreService = FirestoreService();

  int _currentPage = 0;
  final int _numPages = 2;

  bool _agreeTerms = false;
  String _phone = "";
  Country? _country;

  @override
  void initState() {
    super.initState();
    _initializeCountry();
    _loadExistingForm();
    _formState.updateReason('I am elderly');
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

  void _loadExistingForm() async {
    final existingForm = await _firestoreService.getExistingReceiverForm();
    if (existingForm != null) {
      setState(() {
        _formState.updateFromExistingForm(existingForm);
        _phone = _formState.phoneNumber;
        _agreeTerms = true;
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
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                Column(
                  children: [
                    AirportSelectionPage(
                      formState: _formState,
                      onStartAirportSelected: (airport) {
                        setState(() {
                          _formState.updateStartAirport(airport);
                        });
                      },
                      onEndAirportSelected: (airport) {
                        setState(() {
                          _formState.updateEndAirport(airport);
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    DateSelectionPage(
                      formState: _formState,
                      onDateRangeSelected: (dateRange) {
                        setState(() {
                          _formState.updateDateRange(dateRange);
                        });
                      },
                    ),
                  ],
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reason for assistance',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        DropdownButtonFormField<String>(
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          value: _formState.reason.isEmpty
                              ? 'I am elderly'
                              : _formState.reason,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            errorText: (_formState.submitted ||
                                        _formState.reasonTouched) &&
                                    !_formState.isReasonValid()
                                ? 'Reason is required'
                                : null,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'I am elderly',
                                child: Text('I am elderly')),
                            DropdownMenuItem(
                                value: 'I am a single parent flying with kids',
                                child: Text(
                                    'I am a single parent flying with kids')),
                            DropdownMenuItem(
                                value: 'I need company',
                                child: Text('I need company')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _formState.updateReason(value ?? '');
                            });
                          },
                        ),
                        if (_formState.reason == 'Other')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextFormField(
                              initialValue: _formState.otherReason,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Please provide a short description',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _formState.updateOtherReason(value);
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text('Number of people in your party',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        TextFormField(
                          initialValue: _formState.partySize.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter the number of people',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _formState
                                .updatePartySize(int.tryParse(value) ?? 1);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter a phone number',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: _country != null
                                      ? GestureDetector(
                                          onTap: () {
                                            showCountryPicker(
                                              context: context,
                                              onSelect: (Country country) {
                                                setState(() {
                                                  _country = country;
                                                });
                                              },
                                              favorite: ['US', 'IN'],
                                            );
                                          },
                                          child: Container(
                                            height: 56,
                                            width: 70,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${_country?.flagEmoji ?? ''} +${_country?.phoneCode ?? ''}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter a phone number';
                                  } else if (!RegExp(
                                          r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _phone = "+${_country!.phoneCode} $value";
                                    _formState.updatePhoneNumber(_phone);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'Confirm Email',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder<String?>(
                          future: _firestoreService.getUserEmail(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              );
                            }
                            final email = snapshot.data ?? 'Email not found';
                            _formState.setUserContactInfo(email);
                            return Text('Email: $email',
                                style: const TextStyle(fontSize: 16));
                          },
                        ),
                        CheckboxListTile(
                          title: const Text(
                              'I confirm my email address is correct and up to date'),
                          value: _formState.emailConfirmed,
                          onChanged: (value) {
                            setState(() {
                              _formState.emailConfirmed = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Terms and Conditions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'As a Receiver, I acknowledge that I am seeking assistance from fellow travelers through PathPal. I understand that the responsibility for any risks or issues during travel arrangements lies with me, and I absolve PathPal from any liability or claims arising from such incidents. By using this platform, I agree to be contacted by potential Contributors who may offer assistance during my journey. I also understand the importance of maintaining privacy and confidentiality, particularly regarding personal details, and I commit to respecting the privacy of all users involved in this collaborative travel community.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title:
                              const Text('I accept the terms and conditions'),
                          value: _agreeTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeTerms = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildPageIndicator(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _numPages,
        (index) => _buildIndicator(index == _currentPage),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color:
            isActive ? const Color.fromARGB(255, 147, 201, 246) : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Previous'),
            )
          else
            const SizedBox(),
          if (_currentPage < _numPages - 1)
            ElevatedButton(
              onPressed: _validateAndProceed,
              child: const Text('Next'),
            )
          else
            ElevatedButton(
              onPressed:
                  _agreeTerms && _formState.emailConfirmed ? _submitForm : null,
              child: const Text('Submit'),
            ),
        ],
      ),
    );
  }

  void _validateAndProceed() {
    setState(() {});

    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      return _formState.selectedDateRange.isNotEmpty &&
          _formState.startAirport != null &&
          _formState.endAirport != null;
    }
    return true;
  }

  void _submitForm() async {
    if (!_validateCurrentPage()) {
      setState(() {});
      return;
    }

    if (_formState.phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required')),
      );
      return;
    }

    if (!_validatePhoneNumber(_formState.phoneNumber)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    try {
      await _firestoreService.submitReceiverForm(_formState);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              FilteredContributorsScreen(receiverFormState: _formState),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    }
  }

  bool _validatePhoneNumber(String phoneNumber) {
    final phoneNumberRegex = RegExp(
      r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$',
    );
    return phoneNumberRegex.hasMatch(phoneNumber);
  }
}
