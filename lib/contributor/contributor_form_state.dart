import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/models/airport_model.dart';

class ContributorFormState {
  ContributorFormState();
  String flightNumberFirstLeg = '';
  String flightNumberSecondLeg = '';
  String flightNumberThirdLeg = '';
  int partySize = 1;
  Airport? departureAirport;
  Airport? arrivalAirport;
  Airport? firstLayoverAirport;
  Airport? secondLayoverAirport;
  int numberOfLayovers = 0;
  String email = '';
  DateTime? flightDateTimeFirstLeg;
  DateTime? flightDateTimeSecondLeg;
  DateTime? flightDateTimeThirdLeg;
  String userid = '';
  bool allowInAppMessages = true;

  String get flightNumber => flightNumberFirstLeg;
  set flightNumber(String value) {
    flightNumberFirstLeg = value;
  }

  void updateFlightNumber(String number) {
    flightNumberFirstLeg = number.toUpperCase();
  }

  void updateFlightNumberFirstLeg(String number) {
    flightNumberFirstLeg = number.toUpperCase();
  }

  void updateFlightNumberSecondLeg(String number) {
    flightNumberSecondLeg = number.toUpperCase();
  }

  void updateFlightNumberThirdLeg(String number) {
    flightNumberThirdLeg = number.toUpperCase();
  }

  void updatePartySize(int size) {
    partySize = size;
  }

  void updateAllowInAppMessages(bool value) {
    allowInAppMessages = value;
  }

  void updateDepartureAirport(Airport airport) {
    departureAirport = airport;
  }

  void updateArrivalAirport(Airport airport) {
    arrivalAirport = airport;
  }

  void updateFirstLayoverAirport(Airport? airport) {
    firstLayoverAirport = airport;
    numberOfLayovers =
        airport != null ? max(numberOfLayovers, 1) : numberOfLayovers;
  }

  void updateSecondLayoverAirport(Airport? airport) {
    secondLayoverAirport = airport;
    numberOfLayovers = airport != null ? 2 : numberOfLayovers;
  }

  void updateFlightDateTimeFirstLeg(DateTime dateTime) {
    flightDateTimeFirstLeg = dateTime;
  }

  void updateFlightDateTimeSecondLeg(DateTime dateTime) {
    flightDateTimeSecondLeg = dateTime;
  }

  void updateFlightDateTimeThirdLeg(DateTime dateTime) {
    flightDateTimeThirdLeg = dateTime;
  }

  void removeLayovers() {
    firstLayoverAirport = null;
    secondLayoverAirport = null;
    numberOfLayovers = 0;
    flightNumberSecondLeg = '';
    flightNumberThirdLeg = '';
    flightDateTimeSecondLeg = null;
    flightDateTimeThirdLeg = null;
  }

  void setUserContactInfo(String userEmail) {
    email = userEmail;
  }

  bool isFlightInfoValid() {
    if (numberOfLayovers == 2) {
      return flightNumberFirstLeg.isNotEmpty &&
          flightNumberSecondLeg.isNotEmpty &&
          flightNumberThirdLeg.isNotEmpty &&
          departureAirport != null &&
          arrivalAirport != null &&
          firstLayoverAirport != null &&
          secondLayoverAirport != null &&
          flightDateTimeFirstLeg != null &&
          flightDateTimeSecondLeg != null &&
          flightDateTimeThirdLeg != null &&
          partySize > 0;
    } else if (numberOfLayovers == 1) {
      return flightNumberFirstLeg.isNotEmpty &&
          flightNumberSecondLeg.isNotEmpty &&
          departureAirport != null &&
          arrivalAirport != null &&
          firstLayoverAirport != null &&
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
    final numberOfLayovers = map['numberOfLayovers'] ?? 0;

    var state = ContributorFormState()
      ..flightNumber =
          numberOfLayovers > 0 ? '' : (map['flightNumberFirstLeg'] ?? '')
      ..flightNumberFirstLeg =
          numberOfLayovers > 0 ? (map['flightNumberFirstLeg'] ?? '') : ''
      ..flightNumberSecondLeg =
          numberOfLayovers > 1 ? (map['flightNumberSecondLeg'] ?? '') : ''
      ..flightNumberThirdLeg =
          numberOfLayovers > 2 ? (map['flightNumberThirdLeg'] ?? '') : ''
      ..partySize = map['partySize'] ?? 1
      ..departureAirport = map['departureAirport'] != null
          ? Airport.fromMap(map['departureAirport'])
          : null
      ..arrivalAirport = map['arrivalAirport'] != null
          ? Airport.fromMap(map['arrivalAirport'])
          : null
      ..firstLayoverAirport =
          numberOfLayovers > 0 && map['firstLayoverAirport'] != null
              ? Airport.fromMap(map['firstLayoverAirport'])
              : null
      ..secondLayoverAirport =
          numberOfLayovers > 1 && map['secondLayoverAirport'] != null
              ? Airport.fromMap(map['secondLayoverAirport'])
              : null
      ..numberOfLayovers = numberOfLayovers
      ..email = map['userEmail'] ?? ''
      ..flightDateTimeFirstLeg =
          (map['flightDateTimeFirstLeg'] as Timestamp?)?.toDate()
      ..flightDateTimeSecondLeg = numberOfLayovers > 0
          ? (map['flightDateTimeSecondLeg'] as Timestamp?)?.toDate()
          : null
      ..flightDateTimeThirdLeg = numberOfLayovers > 1
          ? (map['flightDateTimeThirdLeg'] as Timestamp?)?.toDate()
          : null
      ..allowInAppMessages = map['allowInAppMessages'] ?? true;

    return state;
  }

  Map<String, dynamic> toMap() {
    final map = {
      'flightNumberFirstLeg':
          numberOfLayovers > 0 ? flightNumberFirstLeg : flightNumber,
      'partySize': partySize,
      'allowInAppMessages': allowInAppMessages,
      'departureAirport': departureAirport?.toJson(),
      'arrivalAirport': arrivalAirport?.toJson(),
      'numberOfLayovers': numberOfLayovers,
      'userEmail': email,
      'flightDateTimeFirstLeg': flightDateTimeFirstLeg != null
          ? Timestamp.fromDate(flightDateTimeFirstLeg!)
          : null,
    };

    if (numberOfLayovers > 0) {
      map['flightNumberSecondLeg'] = flightNumberSecondLeg;
      map['firstLayoverAirport'] = firstLayoverAirport?.toJson();
      map['flightDateTimeSecondLeg'] = flightDateTimeSecondLeg != null
          ? Timestamp.fromDate(flightDateTimeSecondLeg!)
          : null;
    }

    if (numberOfLayovers > 1) {
      map['flightNumberThirdLeg'] = flightNumberThirdLeg;
      map['secondLayoverAirport'] = secondLayoverAirport?.toJson();
      map['flightDateTimeThirdLeg'] = flightDateTimeThirdLeg != null
          ? Timestamp.fromDate(flightDateTimeThirdLeg!)
          : null;
    }

    return map;
  }

  void updateFromMap(Map<String, dynamic> map) {
    numberOfLayovers = map['numberOfLayovers'] ?? 0;
    if (numberOfLayovers > 0) {
      flightNumberSecondLeg = map['flightNumberSecondLeg'] ?? '';
    } else {
      flightNumberFirstLeg = map['flightNumberFirstLeg'] ?? '';
    }

    if (numberOfLayovers > 1) {
      flightNumberThirdLeg = map['flightNumberThirdLeg'] ?? '';
    }

    partySize = map['partySize'] ?? 1;
    departureAirport = map['departureAirport'] != null
        ? Airport.fromMap(map['departureAirport'])
        : null;
    arrivalAirport = map['arrivalAirport'] != null
        ? Airport.fromMap(map['arrivalAirport'])
        : null;
    firstLayoverAirport = map['firstLayoverAirport'] != null
        ? Airport.fromMap(map['firstLayoverAirport'])
        : null;
    allowInAppMessages = map['allowInAppMessages'] ?? true;
    secondLayoverAirport = map['secondLayoverAirport'] != null
        ? Airport.fromMap(map['secondLayoverAirport'])
        : null;
    email = map['userEmail'] ?? '';
    flightDateTimeFirstLeg =
        (map['flightDateTimeFirstLeg'] as Timestamp?)?.toDate();
    flightDateTimeSecondLeg = numberOfLayovers > 0
        ? (map['flightDateTimeSecondLeg'] as Timestamp?)?.toDate()
        : null;
    flightDateTimeThirdLeg = numberOfLayovers > 1
        ? (map['flightDateTimeThirdLeg'] as Timestamp?)?.toDate()
        : null;
  }
}
