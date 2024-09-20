import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/models/airport_model.dart';

class ContributorFormState {
  ContributorFormState();
  String flightNumberFirstLeg = '';
  String flightNumberSecondLeg = '';
  String _flightNumber = '';
  int partySize = 1;
  Airport? departureAirport;
  Airport? arrivalAirport;
  Airport? layoverAirport;
  bool hasLayover = false;
  String email = '';
  DateTime? flightDateTimeFirstLeg;
  DateTime? flightDateTimeSecondLeg;
  String userid = '';

  String get flightNumber => hasLayover ? flightNumberFirstLeg : _flightNumber;
  set flightNumber(String value) {
    if (hasLayover) {
      flightNumberFirstLeg = value;
    } else {
      _flightNumber = value;
    }
  }

  void updateFlightNumber(String number) {
    if (hasLayover) {
      flightNumberFirstLeg = number.toUpperCase();
    } else {
      _flightNumber = number.toUpperCase();
    }
  }

  void updateFlightNumberFirstLeg(String number) {
    flightNumberFirstLeg = number.toUpperCase();
  }

  void updateFlightNumberSecondLeg(String number) {
    flightNumberSecondLeg = number.toUpperCase();
  }

  void updatePartySize(int size) {
    partySize = size;
  }

  void updateDepartureAirport(Airport airport) {
    departureAirport = airport;
  }

  void updateArrivalAirport(Airport airport) {
    arrivalAirport = airport;
  }

  void updateLayoverAirport(Airport? airport) {
    layoverAirport = airport;
    hasLayover = true;
  }

  void updateFlightDateTimeFirstLeg(DateTime dateTime) {
    flightDateTimeFirstLeg = dateTime;
  }

  void updateFlightDateTimeSecondLeg(DateTime dateTime) {
    flightDateTimeSecondLeg = dateTime;
  }

  void removeLayover() {
    layoverAirport = null;
    hasLayover = false;
    flightNumberSecondLeg = '';
    flightDateTimeSecondLeg = null;
  }

  void setUserContactInfo(String userEmail) {
    email = userEmail;
  }

  bool isFlightInfoValid() {
    if (hasLayover) {
      return flightNumberFirstLeg.isNotEmpty &&
          flightNumberSecondLeg.isNotEmpty &&
          departureAirport != null &&
          arrivalAirport != null &&
          layoverAirport != null &&
          flightDateTimeFirstLeg != null &&
          flightDateTimeSecondLeg != null &&
          partySize > 0;
    } else {
      return flightNumber.isNotEmpty &&
          departureAirport != null &&
          arrivalAirport != null &&
          flightDateTimeFirstLeg != null &&
          partySize > 0;
    }
  }

  bool isValidFlightNumber(String number) {
    return RegExp(r'[a-zA-Z]').hasMatch(number);
  }

  factory ContributorFormState.fromMap(Map<String, dynamic> map) {
    final hasLayover = map['hasLayover'] ?? false;

    var state = ContributorFormState()
      ..flightNumber = hasLayover ? '' : (map['flightNumberFirstLeg'] ?? '')
      ..flightNumberFirstLeg =
          hasLayover ? (map['flightNumberFirstLeg'] ?? '') : ''
      ..flightNumberSecondLeg =
          hasLayover ? (map['flightNumberSecondLeg'] ?? '') : ''
      ..partySize = map['partySize'] ?? 1
      ..departureAirport = map['departureAirport'] != null
          ? Airport.fromMap(map['departureAirport'])
          : null
      ..arrivalAirport = map['arrivalAirport'] != null
          ? Airport.fromMap(map['arrivalAirport'])
          : null
      ..layoverAirport = hasLayover && map['layoverAirport'] != null
          ? Airport.fromMap(map['layoverAirport'])
          : null
      ..hasLayover = hasLayover
      ..email = map['userEmail'] ?? ''
      ..flightDateTimeFirstLeg =
          (map['flightDateTimeFirstLeg'] as Timestamp?)?.toDate()
      ..flightDateTimeSecondLeg = hasLayover
          ? (map['flightDateTimeSecondLeg'] as Timestamp?)?.toDate()
          : null;

    return state;
  }

  Map<String, dynamic> toMap() {
    final map = {
      'flightNumberFirstLeg': hasLayover ? flightNumberFirstLeg : flightNumber,
      'partySize': partySize,
      'departureAirport': departureAirport?.toJson(),
      'arrivalAirport': arrivalAirport?.toJson(),
      'hasLayover': hasLayover,
      'userEmail': email,
      'flightDateTimeFirstLeg': flightDateTimeFirstLeg != null
          ? Timestamp.fromDate(flightDateTimeFirstLeg!)
          : null,
    };

    if (hasLayover) {
      map['flightNumberSecondLeg'] = flightNumberSecondLeg;
      map['layoverAirport'] = layoverAirport?.toJson();
      map['flightDateTimeSecondLeg'] = flightDateTimeSecondLeg != null
          ? Timestamp.fromDate(flightDateTimeSecondLeg!)
          : null;
    }
    return map;
  }

  void updateFromMap(Map<String, dynamic> map) {
    hasLayover = map['hasLayover'] ?? false;
    if (hasLayover) {
      flightNumberFirstLeg = map['flightNumberFirstLeg'] ?? '';
      flightNumberSecondLeg = map['flightNumberSecondLeg'] ?? '';
    } else {
      _flightNumber = map['flightNumberFirstLeg'] ?? '';
    }

    flightNumber = map['flightNumberFirstLeg'] ?? '';
    flightNumberFirstLeg = map['flightNumberFirstLeg'] ?? '';
    flightNumberSecondLeg = map['flightNumberSecondLeg'] ?? '';
    partySize = map['partySize'] ?? 1;
    departureAirport = map['departureAirport'] != null
        ? Airport.fromMap(map['departureAirport'])
        : null;
    arrivalAirport = map['arrivalAirport'] != null
        ? Airport.fromMap(map['arrivalAirport'])
        : null;
    layoverAirport = map['layoverAirport'] != null
        ? Airport.fromMap(map['layoverAirport'])
        : null;
    hasLayover = map['hasLayover'] ?? false;
    email = map['userEmail'] ?? '';
    flightDateTimeFirstLeg =
        (map['flightDateTimeFirstLeg'] as Timestamp?)?.toDate();
    flightDateTimeSecondLeg = hasLayover
        ? (map['flightDateTimeSecondLeg'] as Timestamp?)?.toDate()
        : null;
  }
}
