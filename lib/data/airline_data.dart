import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AirlineData {
  final String iataCode;
  final String name;

  AirlineData({required this.iataCode, required this.name});

  factory AirlineData.fromCsvLine(String line) {
    List<String> fields = line.split(',');
    String iataCode = fields[3].replaceAll('"', '');
    String name = fields[1].replaceAll('"', '');
    return AirlineData(iataCode: iataCode, name: name);
  }
}

class AirlineFetcher {
  final Map<String, String> _airlineMap = {};

  Future<void> loadAirlines() async {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat'));

    if (response.statusCode == 200) {
      List<String> lines = LineSplitter.split(response.body).toList();
      for (var line in lines) {
        var airline = AirlineData.fromCsvLine(line);
        if (airline.iataCode.isNotEmpty) {
          _airlineMap[airline.iataCode] = airline.name;
        }
      }
    } else {
      throw Exception('Failed to load airline data');
    }
  }

  String? getAirlineName(String iataCode) {
    return _airlineMap[iataCode];
  }

  bool isValidIataCode(String iataCode) {
    return _airlineMap.containsKey(iataCode.toUpperCase());
  }
}
