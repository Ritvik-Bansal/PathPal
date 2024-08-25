class Airport {
  final int id;
  final String iata;
  final String name;
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  Airport({
    required this.id,
    required this.iata,
    required this.name,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory Airport.fromMap(Map<String, dynamic> map) {
    var airport = Airport(
      id: map['id'] as int? ?? 0,
      iata: map['iata'] as String? ?? '',
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      country: map['country'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
    return airport;
  }

  Map<String, dynamic> toJson() {
    var json = {
      'id': id,
      'iata': iata,
      'name': name,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
    return json;
  }

  @override
  String toString() => '$iata - $name, $city, $country';
}
