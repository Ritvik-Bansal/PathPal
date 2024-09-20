import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class MapWidget extends StatelessWidget {
  final Map<String, dynamic> contributorData;

  const MapWidget({Key? key, required this.contributorData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LatLng>>(
      future: _getAirportCoordinates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surface,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No map data available');
        }

        List<LatLng> points = snapshot.data!;
        LatLngBounds bounds = LatLngBounds.fromPoints(points);

        return Container(
          height: 200,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color.fromARGB(255, 180, 221, 255), width: 4),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(20),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.pinchMove |
                      InteractiveFlag.doubleTapZoom,
                  enableMultiFingerGestureRace: true,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                PolylineLayer(
                  polylines: _createCurvedLines(points),
                ),
                MarkerLayer(
                  markers: points
                      .map((point) => Marker(
                            point: point,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                            alignment: Alignment(0.0, -0.8),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<LatLng>> _getAirportCoordinates() async {
    List<LatLng> coordinates = [];

    void addCoordinate(Map<String, dynamic>? airport) {
      if (airport != null &&
          airport['latitude'] != null &&
          airport['longitude'] != null) {
        coordinates.add(LatLng(airport['latitude'], airport['longitude']));
      }
    }

    addCoordinate(contributorData['departureAirport']);
    addCoordinate(contributorData['layoverAirport']);
    addCoordinate(contributorData['arrivalAirport']);

    return coordinates
        .where((coord) => coord.latitude != 0 && coord.longitude != 0)
        .toList();
  }

  List<Polyline> _createCurvedLines(List<LatLng> points) {
    return [
      Polyline(
        points: _generateCurvedPath(points),
        strokeWidth: 3,
        color: Colors.blue,
      )
    ];
  }

  List<LatLng> _generateCurvedPath(List<LatLng> points) {
    if (points.length < 2) return points;

    List<LatLng> curvedPath = [];
    for (int i = 0; i < points.length - 1; i++) {
      LatLng start = points[i];
      LatLng end = points[i + 1];

      double distance = _calculateDistance(start, end);

      double curveHeight = distance * 0.0007;

      LatLng controlPoint = _intermediatePoint(start, end, 0.5, curveHeight);

      int numPoints = 100;
      for (int j = 0; j <= numPoints; j++) {
        double t = j / numPoints;
        LatLng point = _quadraticBezier(start, controlPoint, end, t);
        curvedPath.add(point);
      }
    }

    return curvedPath;
  }

  LatLng _intermediatePoint(
      LatLng start, LatLng end, double fraction, double distance) {
    double lat = _interpolate(start.latitude, end.latitude, fraction);
    double lng = _interpolate(start.longitude, end.longitude, fraction);

    lat += distance.abs();

    return LatLng(lat, lng);
  }

  LatLng _quadraticBezier(LatLng p0, LatLng p1, LatLng p2, double t) {
    double lat = (1 - t) * (1 - t) * p0.latitude +
        2 * (1 - t) * t * p1.latitude +
        t * t * p2.latitude;
    double lng = (1 - t) * (1 - t) * p0.longitude +
        2 * (1 - t) * t * p1.longitude +
        t * t * p2.longitude;
    return LatLng(lat, lng);
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) *
            c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  double _interpolate(double start, double end, double fraction) {
    return start + (end - start) * fraction;
  }
}
