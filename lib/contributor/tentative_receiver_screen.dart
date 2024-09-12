import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/contributor/tentative_receiver_details_screen.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';
import 'package:pathpal/services/firestore_service.dart';

class TentativeReceiversScreen extends StatelessWidget {
  final ReceiverFormState receiverFormState;
  final FirestoreService _firestoreService = FirestoreService();

  TentativeReceiversScreen({required this.receiverFormState});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTentativeReceiversStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No tentative receivers found'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var receiver = snapshot.data!.docs[index];
            var receiverData = receiver.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(receiverData['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return TentativeReceiverCard(
                    receiverData: receiverData,
                    profilePicture: null,
                    onTap: () => _showDetailedView(context, receiverData),
                  );
                }
                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                return TentativeReceiverCard(
                  receiverData: receiverData,
                  profilePicture: userData['profile_picture'],
                  onTap: () => _showDetailedView(context, receiverData),
                );
              },
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getTentativeReceiversStream() {
    return _firestoreService.getTentativeReceivers(
      startDate: receiverFormState.startDate!,
      endDate: receiverFormState.endDate!,
      endAirportIata: receiverFormState.endAirport!.iata.toUpperCase(),
      startAirportIata: receiverFormState.startAirport!.iata.toUpperCase(),
    );
  }

  void _showDetailedView(
      BuildContext context, Map<String, dynamic> receiverData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TentativeReceiverDetailScreen(
          receiverData: receiverData,
          firestoreService: _firestoreService,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('An error occurred:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SelectableText(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                (context as Element).markNeedsBuild();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class TentativeReceiverCard extends StatelessWidget {
  final Map<String, dynamic> receiverData;
  final String? profilePicture;
  final VoidCallback onTap;

  TentativeReceiverCard({
    required this.receiverData,
    required this.profilePicture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formattedStartDate =
        DateFormat('MMM d').format(receiverData['startDate'].toDate());
    String formattedEndDate =
        DateFormat('MMM d').format(receiverData['endDate'].toDate());
    String dateRange = '$formattedStartDate - $formattedEndDate';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.elliptical(20, 20)),
          side: BorderSide(
            color: Color.fromARGB(255, 132, 196, 249),
            width: 2,
          ),
        ),
        child: Container(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      profilePicture != null && profilePicture!.isNotEmpty
                          ? NetworkImage(profilePicture!)
                          : null,
                  child: profilePicture == null || profilePicture!.isEmpty
                      ? Text(receiverData['userName'][0].toUpperCase())
                      : null,
                  radius: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiverData['userName'],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        dateRange,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Party size: ${receiverData['partySize']}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
