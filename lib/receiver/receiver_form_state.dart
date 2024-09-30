import 'package:pathpal/models/airport_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiverFormState {
  String selectedDateRange = '';
  Airport? startAirport;
  Airport? endAirport;
  String reason = '';
  String otherReason = '';
  int partySize = 1;
  bool _submitted = false;
  bool emailConfirmed = true;
  bool get submitted => _submitted;
  bool dateRangeTouched = false;
  bool startAirportTouched = false;
  bool endAirportTouched = false;
  bool reasonTouched = false;
  bool partySizeTouched = false;
  String email = "";
  String phoneNumber = '';
  DateTime? startDate;
  DateTime? endDate;
  String displayDateRange = '';

  void submit() {
    _submitted = true;
    isFormValid();
  }

  void resetSubmission() {
    _submitted = false;
    isFormValid();
  }

  void updateDateRange(String dateRange) {
    selectedDateRange = dateRange;
    List<String> dates = dateRange.split(' - ');
    startDate = DateTime.parse(dates[0]);
    endDate = DateTime.parse(dates[1]);
  }

  void updateStartAirport(Airport airport) {
    startAirport = airport;
  }

  void updateEndAirport(Airport airport) {
    endAirport = airport;
  }

  void updateReason(String newReason) {
    reason = newReason;
  }

  void updateOtherReason(String newOtherReason) {
    otherReason = newOtherReason;
  }

  void updatePartySize(int size) {
    partySize = size;
  }

  bool isDateRangeValid() {
    return selectedDateRange.isNotEmpty;
  }

  bool areAirportsValid() {
    return startAirport != null && endAirport != null;
  }

  bool isReasonValid() {
    return reason.isNotEmpty;
  }

  bool isPartySizeValid() {
    return partySize > 0;
  }

  bool isFormValid() {
    return isDateRangeValid() &&
        areAirportsValid() &&
        isReasonValid() &&
        isPartySizeValid();
  }

  void touchDateRange() {
    dateRangeTouched = true;
  }

  void touchStartAirport() {
    startAirportTouched = true;
  }

  void touchEndAirport() {
    endAirportTouched = true;
  }

  void touchReason() {
    reasonTouched = true;
  }

  void touchPartySize() {
    partySizeTouched = true;
  }

  void setUserContactInfo(String enteredEmail) {
    email = enteredEmail;
  }

  void updatePhoneNumber(String phoneNumber) {
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) {
      this.phoneNumber =
          '+${digitsOnly.substring(0, digitsOnly.length - 10)} ${digitsOnly.substring(digitsOnly.length - 10)}';
    } else {
      this.phoneNumber = phoneNumber;
    }
  }

  void updateFromExistingForm(DocumentSnapshot existingForm) {
    final data = existingForm.data() as Map<String, dynamic>;
    selectedDateRange = data['dateRange'] ?? '';
    startAirport = _convertToAirport(data['startAirport']);
    endAirport = _convertToAirport(data['endAirport']);
    reason = data['reason'] ?? '';
    otherReason = data['otherReason'] ?? '';
    partySize = data['partySize'] ?? 1;
    email = data['userEmail'] ?? '';
    phoneNumber = data['userPhone'] ?? '';
    startDate = data['startDate']?.toDate();
    endDate = data['endDate']?.toDate();
  }

  void updateFromMap(Map<String, dynamic> data) {
    selectedDateRange =
        '${data['startDate'].toDate().toString().split(' ')[0]} - ${data['endDate'].toDate().toString().split(' ')[0]}';
    startAirport = _convertToAirport(data['startAirport']);
    endAirport = _convertToAirport(data['endAirport']);
    reason = data['reason'] ?? '';
    otherReason = data['otherReason'] ?? '';
    partySize = data['partySize'] ?? 1;
    email = data['userEmail'] ?? '';
    phoneNumber = data['userPhone'] ?? '';
    startDate = data['startDate']?.toDate();
    endDate = data['endDate']?.toDate();
  }

  Airport? _convertToAirport(Map<String, dynamic>? airportData) {
    if (airportData == null) return null;
    return Airport(
      id: airportData['id'] ?? 0,
      iata: airportData['iata'] ?? '',
      name: airportData['name'] ?? '',
      city: airportData['city'] ?? '',
      country: airportData['country'] ?? '',
      latitude: airportData['latitude'] ?? 0.0,
      longitude: airportData['longitude'] ?? 0.0,
    );
  }
}
