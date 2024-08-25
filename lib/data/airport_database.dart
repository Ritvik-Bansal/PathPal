import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pathpal/models/airport_model.dart';

class AirportDatabase {
  static final AirportDatabase instance = AirportDatabase._init();
  static Database? _database;

  AirportDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('airports.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE airports (
        id INTEGER PRIMARY KEY,
        iata TEXT,
        name TEXT,
        city TEXT,
        country TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');

    await _populateDB(db);
  }

  Future _populateDB(Database db) async {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat'));
    if (response.statusCode == 200) {
      LineSplitter.split(response.body).forEach((line) {
        final fields = line.split(',');
        if (fields.length >= 14) {
          db.insert('airports', {
            'id': int.tryParse(fields[0]) ?? 0,
            'name': fields[1].replaceAll('"', ''),
            'city': fields[2].replaceAll('"', ''),
            'country': fields[3].replaceAll('"', ''),
            'iata': fields[4].replaceAll('"', ''),
            'latitude': double.tryParse(fields[6]) ?? 0.0,
            'longitude': double.tryParse(fields[7]) ?? 0.0,
          });
        }
      });
    }
  }

  Future<List<Airport>> searchAirports(String query) async {
    final db = await instance.database;
    final results = await db.query(
      'airports',
      where: 'name LIKE ? OR city LIKE ? OR country LIKE ? OR iata LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      limit: 20,
    );
    return results
        .map((map) {
          try {
            return Airport.fromMap(map);
          } catch (e) {
            return null;
          }
        })
        .whereType<Airport>()
        .toList();
  }
}
