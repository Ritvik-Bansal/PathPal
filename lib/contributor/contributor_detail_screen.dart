import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/data/airline_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import 'package:pathpal/services/firestore_service.dart';

class ContributorDetailScreen extends StatefulWidget {
  final String contributorId;
  final String userId;
  final AirlineFetcher airlineFetcher;
  final FirestoreService firestoreService;

  const ContributorDetailScreen({
    super.key,
    required this.contributorId,
    required this.userId,
    required this.airlineFetcher,
    required this.firestoreService,
  });

  @override
  State<ContributorDetailScreen> createState() =>
      _ContributorDetailScreenState();
}

class _ContributorDetailScreenState extends State<ContributorDetailScreen> {
  bool _isFavorite = false;
  bool _hasContacted = false;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService;
    _checkFavoriteStatus();
    _checkContactStatus();
  }

  Future<void> _checkContactStatus() async {
    bool hasContacted =
        await _firestoreService.hasContactedContributor(widget.contributorId);
    setState(() {
      _hasContacted = hasContacted;
    });
  }

  Future<void> _checkFavoriteStatus() async {
    bool isFavorite =
        await _firestoreService.isContributorFavorited(widget.contributorId);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    try {
      await _firestoreService.toggleFavoriteContributor(widget.contributorId);
      setState(() {
        _isFavorite = !_isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _isFavorite ? 'Added to favorites' : 'Removed from favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorite status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('contributors')
            .doc(widget.contributorId)
            .get(),
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold(context, 'Loading...');
        }

        if (!snapshot.hasData || snapshot.data!.length != 2) {
          return _buildLoadingScaffold(context, 'Contributor not found');
        }

        var contributorData = snapshot.data![0].data() as Map<String, dynamic>;
        var userData = snapshot.data![1].data() as Map<String, dynamic>;

        return _buildMainScaffold(context, contributorData, userData);
      },
    );
  }

  Widget _buildLoadingScaffold(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(message)),
      body: Center(
          child: message == 'Loading...'
              ? CircularProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                )
              : Text(message)),
    );
  }

  Widget _buildMainScaffold(BuildContext context,
      Map<String, dynamic> contributorData, Map<String, dynamic> userData) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('MORE DETAILS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_isFavorite),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_hasContacted)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'You have already contacted this contributor',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            _buildFlightRoute(contributorData),
            const SizedBox(height: 10),
            _buildMapWidget(contributorData),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _showContactConfirmationDialog(
                  context, contributorData, userData),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 180, 221, 255),
                textStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(_hasContacted
                  ? 'CONTACT CONTRIBUTOR AGAIN'
                  : 'CONTACT THIS CONTRIBUTOR'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget(Map<String, dynamic> contributorData) {
    return FutureBuilder<List<LatLng>>(
      future: _getAirportCoordinates(contributorData),
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

  List<Polyline> _createCurvedLines(List<LatLng> points) {
    return [
      Polyline(
        points: _generateCurvedPath(points),
        strokeWidth: 3,
        color: Colors.blue,
      )
    ];
  }

  Future<void> _showContactConfirmationDialog(
      BuildContext context,
      Map<String, dynamic> contributorData,
      Map<String, dynamic> userData) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Contact Confirmation'),
          content: const Text(
            'PathPal will email the contributor with your contact info and travel details. They will directly reach out to you. Do you wish to proceed?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _sendEmailToContributor(context, contributorData, userData);
    }
  }

  Future<void> _sendEmailToContributor(
      BuildContext context,
      Map<String, dynamic> contributorData,
      Map<String, dynamic> userData) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in')),
      );
      return;
    }

    try {
      final String contributorUserId = contributorData['userId'];

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(contributorUserId)
          .get();

      if (!userSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Contributor data not found')),
        );
        return;
      }

      final contributorName =
          userSnapshot.data()?['name'] ?? 'PathPal Contributor';

      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('receivers')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (receiverSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: You may not be a registered Receiver')),
        );
        return;
      }

      final receiverData = receiverSnapshot.docs.first.data();
      String reason = receiverData['reason'] == "Other"
          ? receiverData['otherReason']
          : receiverData['reason'];

      final emailContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>A Traveler Wants to Connect with You</title>
</head>
<body style="margin:0; padding:0; background-color:#f7f9fc; font-family: Arial, sans-serif; color:#333;">
  <div style="max-width:600px; margin:20px auto; background-color:#ffffff; border-radius:8px; box-shadow:0 2px 4px rgba(0, 0, 0, 0.1); overflow:hidden;">
    <div style="background-color:#0073e6; color:#ffffff; padding:20px; text-align:center;">
      <h1 style="margin:0; font-size:28px;">A Traveler Wants to Connect with You</h1>
    </div>
    <div style="padding:20px;">
      <p style="font-size:16px; line-height:1.5;">
        Hi <strong>${contributorName}</strong>,
      </p>
      <p style="font-size:16px; line-height:1.5;">
        A traveler has expressed interest in connecting with you for travel assistance on your flight from ${contributorData['departureAirport']['iata']} to ${contributorData['arrivalAirport']['iata']}.
      </p>
      <div style="background-color:#f1f4f8; padding:15px; border-radius:5px; margin:20px 0;">
        <h2 style="font-size:20px; color:#0073e6; margin-top:0;">Traveler's Details:</h2>
        <p style="font-size:16px; line-height:1.5; margin:5px 0;">
          <strong>Name:</strong> ${receiverData['userName']}<br>
          <strong>Email:</strong> ${receiverData['userEmail']}<br>
          <strong>Phone:</strong> ${receiverData['userPhone']}<br>
          <strong>Reason for Assistance:</strong> ${reason}<br>
          <strong>Party Size:</strong> ${receiverData['partySize']}
        </p>
      </div>
      <p style="font-size:16px; line-height:1.5;">
        Please reach out to the traveler if you are willing to assist them during their journey. Your help can make a big difference in their travel experience.
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Thank you for being a part of the PathPal community. Together, we're making travel smoother and more enjoyable for everyone! 🌟
      </p>
      <p style="font-size:16px; line-height:1.5;">
        Safe travels,<br>
        <strong>The PathPal Team</strong>
      </p>
    </div>
    <div style="background-color:#f7f9fc; text-align:center; padding:15px;">
      <p style="font-size:14px; color:#555; margin:5px 0;">
        <a href="https://pathpal.org" style="color:#0073e6; text-decoration:none;">Visit our website</a> | 
        <a href="mailto:info@pathpal.org" style="color:#0073e6; text-decoration:none;">Contact Support</a>
      </p>
      <p style="font-size:12px; color:#999; margin:5px 0;">
        © ${DateTime.now().year} PathPal. All rights reserved.
      </p>
    </div>
  </div>
</body>
</html>
''';

      final response = await http.post(
        Uri.parse('https://api.mailjet.com/v3.1/send'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${dotenv.env["MAILAPI"]}'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Messages': [
            {
              'From': {'Email': 'noreply@pathpal.org', 'Name': 'PathPal'},
              'To': [
                {'Email': contributorData['userEmail'], 'Name': contributorName}
              ],
              'Subject': 'PathPal: A Traveler Wants to Connect',
              'HTMLPart': emailContent,
              'CustomID': 'PathPalConnectEmail'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        await _firestoreService.addContactedContributor(widget.contributorId);
        setState(() {
          _hasContacted = true;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email sent to the contributor successfully')),
        );
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending email to the contributor')),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  String _formatTime(Timestamp timestamp) {
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  String _getAirlineName(String flightNumber) {
    String iataCode = flightNumber.substring(0, 2).toUpperCase();
    return widget.airlineFetcher.getAirlineName(iataCode) ??
        'Airline $iataCode';
  }

  String _getAirportInfo(Map<String, dynamic>? airport) {
    if (airport == null) return 'N/A';
    return '${airport['city']}, ${airport['country']}';
  }

  Widget _buildFlightRoute(Map<String, dynamic> contributorData) {
    String departureCode = contributorData['departureAirport']?['iata'] ?? '';
    String arrivalCode = contributorData['arrivalAirport']?['iata'] ?? '';
    String? layoverCode = contributorData['layoverAirport']?['iata'];
    String airline1 = _getAirlineName(contributorData['flightNumberFirstLeg']);
    String? airline2 = contributorData['flightNumberSecondLeg'] != null
        ? _getAirlineName(contributorData['flightNumberSecondLeg'])
        : null;
    String flightDate =
        _formatDate(contributorData['flightDateTime'] as Timestamp);
    String flightTime =
        _formatTime(contributorData['flightDateTime'] as Timestamp);

    return Column(
      children: [
        const Text(
          'Flight Route and Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (layoverCode != null) ...[
          _buildFlightLeg(
            departureCode,
            layoverCode,
            airline1,
            contributorData['flightNumberFirstLeg'],
            flightDate,
            flightTime,
            isFirstLeg: true,
          ),
          const SizedBox(height: 10),
          _buildFlightLeg(
            layoverCode,
            arrivalCode,
            airline2 ?? airline1,
            contributorData['flightNumberSecondLeg'] ?? '',
            '',
            '',
            isFirstLeg: false,
            layoverInfo: _getAirportInfo(contributorData['layoverAirport']),
          ),
        ] else
          _buildFlightLeg(
            departureCode,
            arrivalCode,
            airline1,
            contributorData['flightNumberFirstLeg'],
            flightDate,
            flightTime,
            isFirstLeg: true,
          ),
      ],
    );
  }

  Widget _buildFlightLeg(String from, String to, String airline,
      String flightNumber, String date, String time,
      {required bool isFirstLeg, String? layoverInfo}) {
    String airlineIataCode = flightNumber.substring(0, 2).toUpperCase();
    String airlineLogoUrl =
        'https://airlabs.co/img/airline/m/$airlineIataCode.png';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color.fromARGB(255, 180, 221, 255), width: 5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                from,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Transform.rotate(
                angle: 90 * 3.14159 / 180,
                child: const Icon(
                  Icons.flight_outlined,
                  size: 30,
                ),
              ),
              Text(
                to,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                airlineLogoUrl,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(width: 24, height: 24),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$airline (${flightNumber.toUpperCase()})',
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (layoverInfo != null)
                Text(
                  'Layover: $layoverInfo',
                  style: const TextStyle(fontSize: 16),
                ),
              if (isFirstLeg) ...[
                Text(
                  'Date: $date',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Time: $time',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<List<LatLng>> _getAirportCoordinates(
      Map<String, dynamic> contributorData) async {
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
}
