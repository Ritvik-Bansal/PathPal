import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/contributor/contributor_detail_screen.dart';
import 'package:pathpal/contributor/contributor_form_screen.dart';
import 'package:pathpal/data/airline_data.dart';
import 'package:pathpal/services/firestore_service.dart';

class MyStuffScreen extends StatefulWidget {
  const MyStuffScreen({super.key});

  @override
  State<MyStuffScreen> createState() => _MyStuffScreenState();
}

class _MyStuffScreenState extends State<MyStuffScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AirlineFetcher _airlineFetcher;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _airlineFetcher = AirlineFetcher();
    _initializeAirlineFetcher();
  }

  Future<void> _initializeAirlineFetcher() async {
    await _airlineFetcher.loadAirlines();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('My Stuff'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Form Submissions'),
              Tab(text: 'Favorited Trips'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContributorForms(),
            _buildFavoritedContributors(),
          ],
        ),
      ),
    );
  }

  Widget _buildContributorForms() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('contributors')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No trip forms found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return ContributorFormCard(
              data: data,
              docId: doc.id,
              onEdit: () => _editForm(doc.id, data),
              onDelete: () => _deleteForm(doc.id),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritedContributors() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No favorited trips found.'));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const Center(child: Text('Trip data is not available.'));
        }

        List<String> favoritedContributors =
            List<String>.from(userData['favoritedContributors'] ?? []);

        if (favoritedContributors.isEmpty) {
          return const Center(child: Text('No favorited trips found.'));
        }

        return ListView.builder(
          itemCount: favoritedContributors.length,
          itemBuilder: (context, index) {
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('contributors')
                  .doc(favoritedContributors[index])
                  .get(),
              builder: (context, contributorSnapshot) {
                if (contributorSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const ListTile(title: Text('Loading...'));
                }

                if (contributorSnapshot.hasError ||
                    !contributorSnapshot.hasData) {
                  return const ListTile(title: Text('Error loading trip'));
                }

                var contributorData =
                    contributorSnapshot.data!.data() as Map<String, dynamic>?;
                if (contributorData == null) {
                  return const ListTile(title: Text('Trip data not available'));
                }

                return FavoritedContributorCard(
                  contributorData: contributorData,
                  onUnfavorite: () =>
                      _unfavoriteContributor(favoritedContributors[index]),
                  contributorId: favoritedContributors[index],
                  airlineFetcher: _airlineFetcher,
                  firestoreService: _firestoreService,
                );
              },
            );
          },
        );
      },
    );
  }

  void _editForm(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContributorFormScreen(contributorId: docId),
      ),
    ).then((_) => setState(() {}));
  }

  void _deleteForm(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this form?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await _firestoreService
                      .removeContributorFromAllFavorites(docId);

                  await _firestore
                      .collection('contributors')
                      .doc(docId)
                      .delete();

                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Trip form deleted successfully')),
                  );
                } catch (e) {
                  print('Error deleting form: $e');
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error deleting contributor form')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _unfavoriteContributor(String contributorId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Confirm Unfavorite'),
          content: const Text('Are you sure you want to unfavorite this trip?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Unfavorite'),
              onPressed: () async {
                try {
                  await _firestoreService
                      .toggleFavoriteContributor(contributorId);
                  Navigator.of(context).pop();
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error unfavoriting trip')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class ContributorFormCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContributorFormCard({
    super.key,
    required this.data,
    required this.docId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 180, 221, 255),
          width: 5,
        ),
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          const SizedBox(width: 5),
          const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 180, 221, 255),
            child: Icon(Icons.flight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight: ${data['flightNumberFirstLeg'].toString().toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat("MMM d, yyyy':' h:mm a")
                      .format((data['flightDateTime'] as Timestamp).toDate()),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritedContributorCard extends StatelessWidget {
  final Map<String, dynamic> contributorData;
  final VoidCallback onUnfavorite;
  final String contributorId;
  final AirlineFetcher airlineFetcher;
  final FirestoreService firestoreService;

  const FavoritedContributorCard({
    super.key,
    required this.contributorData,
    required this.onUnfavorite,
    required this.contributorId,
    required this.airlineFetcher,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    String from = contributorData['departureAirport']?['iata'] ?? 'Unknown';
    String to = contributorData['arrivalAirport']?['iata'] ?? 'Unknown';
    String? via = contributorData['layoverAirport']?['iata'];
    DateTime flightDate =
        (contributorData['flightDateTime'] as Timestamp).toDate();
    String formattedDate = DateFormat('MMM d').format(flightDate);

    String flightInfo = '$from to $to';
    if (via != null) {
      flightInfo += ' via $via';
    }
    flightInfo += ' on $formattedDate';

    String flightNumber = contributorData['flightNumberFirstLeg'] ?? 'N/A';
    String airlineName = _getAirlineName(flightNumber);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 180, 221, 255),
          width: 5,
        ),
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContributorDetailScreen(
                contributorId: contributorId,
                userId: contributorData['userId'],
                airlineFetcher: airlineFetcher,
                firestoreService: firestoreService,
              ),
            ),
          );
        },
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.flight),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flightInfo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$airlineName - Flight: $flightNumber',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: onUnfavorite,
            ),
          ],
        ),
      ),
    );
  }

  String _getAirlineName(String flightNumber) {
    String iataCode = flightNumber.substring(0, 2).toUpperCase();
    return airlineFetcher.getAirlineName(iataCode) ?? 'Unknown Airline';
  }
}
