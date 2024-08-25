import 'package:flutter/material.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';
import 'package:pathpal/contributor/flight_info_page.dart';
import 'package:pathpal/contributor/contact_confirmation_page.dart';

class ContributorFormScreen extends StatefulWidget {
  final String? contributorId;

  const ContributorFormScreen({super.key, this.contributorId});

  @override
  _ContributorFormScreenState createState() => _ContributorFormScreenState();
}

class _ContributorFormScreenState extends State<ContributorFormScreen> {
  final PageController _pageController = PageController();
  late ContributorFormState _formState;
  final FirestoreService _firestoreService = FirestoreService();
  int _currentPage = 0;
  final int _numPages = 2;

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

  void _submitForm() async {
    if (!_validateCurrentPage() || !_formState.isFormValid()) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill in all required fields and accept the terms')),
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
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
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

  void _validateAndProceed() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      print("Current page validation failed.");
    }
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      bool isValid = _formState.isFlightInfoValid();
      return isValid;
    }
    return true;
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
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                FlightInfoPage(
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
                ContactConfirmationPage(
                  formState: _formState,
                  onEmailConfirmationUpdated: (confirmed) {
                    setState(() {
                      _formState.updateEmailConfirmation(confirmed);
                    });
                  },
                  onTermsAccepted: (accepted) {
                    setState(() {
                      _formState.updateTermsAcceptance(accepted);
                    });
                  },
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
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
        ],
      ),
    );
  }
}
