import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/data/airline_data.dart';
import 'chat_screen.dart';

class ContactRequestDetailScreen extends StatefulWidget {
  final String receiverId;
  final String contributorId;

  const ContactRequestDetailScreen({
    Key? key,
    required this.receiverId,
    required this.contributorId,
  }) : super(key: key);

  @override
  State<ContactRequestDetailScreen> createState() =>
      _ContactRequestDetailScreenState();
}

class _ContactRequestDetailScreenState
    extends State<ContactRequestDetailScreen> {
  final AirlineFetcher _airlineFetcher = AirlineFetcher();

  @override
  void initState() {
    super.initState();
    _loadAirlineData();
  }

  Future<void> _loadAirlineData() async {
    await _airlineFetcher.loadAirlines();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('CONTACT REQUEST'),
      ),
      body: FutureBuilder<Map<String, DocumentSnapshot>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final receiverData = data['receiver']!.data() as Map<String, dynamic>;
          final contributorData =
              data['contributor']!.data() as Map<String, dynamic>;
          final userData = data['user']!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildUserProfile(receiverData, userData['profile_picture']),
                _buildRequestDetails(receiverData),
                _buildFlightDetails(contributorData),
                const SizedBox(height: 10),
                _buildActionButton(
                    context, receiverData, userData['profile_picture']),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlightDetails(Map<String, dynamic> contributorData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Your Flight',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ..._buildFlightLegs(contributorData),
      ],
    );
  }

  List<Widget> _buildFlightLegs(Map<String, dynamic> contributorData) {
    int numberOfLayovers = contributorData['numberOfLayovers'] ?? 0;
    List<Widget> flightLegs = [];

    flightLegs.add(_buildFlightLeg(
      from: contributorData['departureAirport']['iata'],
      to: numberOfLayovers > 0
          ? contributorData['firstLayoverAirport']['iata']
          : contributorData['arrivalAirport']['iata'],
      fromFull: contributorData['departureAirport']['name'],
      toFull: numberOfLayovers > 0
          ? contributorData['firstLayoverAirport']['name']
          : contributorData['arrivalAirport']['name'],
      flightNumber: contributorData['flightNumberFirstLeg'],
      flightDateTime: contributorData['flightDateTimeFirstLeg'],
    ));

    if (numberOfLayovers > 0) {
      flightLegs.add(_buildFlightLeg(
        from: contributorData['firstLayoverAirport']['iata'],
        to: numberOfLayovers > 1
            ? contributorData['secondLayoverAirport']['iata']
            : contributorData['arrivalAirport']['iata'],
        fromFull: contributorData['firstLayoverAirport']['name'],
        toFull: numberOfLayovers > 1
            ? contributorData['secondLayoverAirport']['name']
            : contributorData['arrivalAirport']['name'],
        flightNumber: contributorData['flightNumberSecondLeg'],
        flightDateTime: contributorData['flightDateTimeSecondLeg'],
      ));
    }

    if (numberOfLayovers > 1) {
      flightLegs.add(_buildFlightLeg(
        from: contributorData['secondLayoverAirport']['iata'],
        to: contributorData['arrivalAirport']['iata'],
        fromFull: contributorData['secondLayoverAirport']['name'],
        toFull: contributorData['arrivalAirport']['name'],
        flightNumber: contributorData['flightNumberThirdLeg'],
        flightDateTime: contributorData['flightDateTimeThirdLeg'],
      ));
    }

    return flightLegs;
  }

  Widget _buildFlightLeg({
    required String from,
    required String to,
    required String fromFull,
    required String toFull,
    required String flightNumber,
    required Timestamp flightDateTime,
  }) {
    String airlineIataCode = flightNumber.substring(0, 2).toUpperCase();
    String airlineLogoUrl =
        'https://airlabs.co/img/airline/m/$airlineIataCode.png';
    String airlineName = _getAirlineName(flightNumber);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 180, 221, 255),
          width: 5,
        ),
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
                  '$airlineName (${flightNumber.toUpperCase()})',
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
              Text(
                'Date & Time: ${_formatDate(flightDateTime)}, ${_formatTime(flightDateTime)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  String _getAirlineName(String flightNumber) {
    String iataCode = flightNumber.substring(0, 2).toUpperCase();
    return _airlineFetcher.getAirlineName(iataCode) ?? 'Unknown Airline';
  }

  Widget _buildUserProfile(
      Map<String, dynamic> receiverData, String? profilePicture) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: profilePicture != null
                ? NetworkImage(profilePicture)
                : const AssetImage('assets/default_profile.png')
                    as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            receiverData['userName'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            receiverData['userEmail'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(Map<String, dynamic> receiverData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 180, 221, 255),
          width: 5,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seeker\'s Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Phone', receiverData['userPhone'] ?? 'N/A'),
          _buildDetailRow(
              'Party Size', receiverData['partySize']?.toString() ?? 'N/A'),
          _buildDetailRow('Reason', receiverData['reason'] ?? 'N/A'),
          if (receiverData['reason'] == 'Other')
            _buildDetailRow(
                'Other Reason', receiverData['otherReason'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Map<String, dynamic> receiverData,
    String? receiverProfilePic,
  ) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _startChat(
          context,
          receiverData,
          receiverProfilePic,
        ),
        icon: Icon(
          Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        label: const Text('Start Chatting'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Future<Map<String, DocumentSnapshot>> _fetchData() async {
    final receiverDoc = await FirebaseFirestore.instance
        .collection('receivers')
        .doc(widget.receiverId)
        .get();

    final contributorDoc = await FirebaseFirestore.instance
        .collection('contributors')
        .doc(widget.contributorId)
        .get();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverDoc['userId'])
        .get();

    return {
      'receiver': receiverDoc,
      'contributor': contributorDoc,
      'user': userDoc,
    };
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  void _startChat(
    BuildContext context,
    Map<String, dynamic> receiverData,
    String? receiverProfilePic,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final receiverUserId = receiverData['userId'] as String?;
    if (receiverUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to start chat. Seeker information is incomplete.'),
        ),
      );
      return;
    }

    final chatIdParts = [currentUser.uid, receiverUserId];
    chatIdParts.sort();
    final chatId = chatIdParts.join('_');

    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, receiverUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_${currentUser.uid}': 0,
        'unreadCount_${receiverUserId}': 0,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserId: receiverUserId,
          otherUserName: receiverData['userName'] ?? 'Seeker',
          otherUserProfilePic: receiverProfilePic,
        ),
      ),
    );
  }
}
