import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/contributor/contributor_detail_screen.dart';
import 'package:pathpal/contributor/contributor_form_screen.dart';
import 'package:pathpal/data/airline_data.dart';
import 'package:pathpal/receiver/reciever_form_screen.dart';
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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Trips'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Widget>>(
              future: Future.wait([
                _buildContributorForms(),
                _buildFavoritedContributors(),
                _buildTentativeRequests(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                List<Widget> widgets = snapshot.data ?? [];

                widgets.removeWhere(
                    (widget) => widget is SizedBox && widget.height == 0);

                if (widgets.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'You have no volunteer forms, favorited trips, or tentative requests.',
                        style: TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(children: widgets);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget> _buildContributorForms() async {
    QuerySnapshot snapshot = await _firestore
        .collection('contributors')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      return SizedBox(height: 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.volunteer_activism_rounded, size: 24),
              SizedBox(width: 8),
              Text('My Offerings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('My Offerings'),
                        content: Text(
                            'Your submitted flight information for people in need.'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return ContributorFormCard(
              data: data,
              docId: doc.id,
              onEdit: () => _editForm(doc.id, data),
              onDelete: () => _deleteForm(doc.id),
              airlineFetcher: _airlineFetcher,
              firestoreService: _firestoreService,
            );
          },
        ),
      ],
    );
  }

  Future<Widget> _buildTentativeRequests() async {
    QuerySnapshot snapshot = await _firestore
        .collection('tentativeReceivers')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      return SizedBox(height: 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.travel_explore, size: 24),
              SizedBox(width: 8),
              Text('My Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('My Requests'),
                        content:
                            Text('My tentative flights requests from the past'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return TentativeRequestCard(
              data: data,
              docId: doc.id,
              onDelete: () => _deleteTentativeRequest(doc.id),
              onEdit: () => _editTentativeRequest(doc.id, data),
            );
          },
        ),
      ],
    );
  }

  void _editTentativeRequest(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecieverFormScreen(
          existingData: data,
          docId: docId,
          isEditing: true,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _deleteTentativeRequest(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this tentative request?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await _firestoreService.deleteTentativeRequest(docId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Tentative request deleted successfully')),
                  );
                } catch (e) {
                  print('Error deleting tentative request: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error deleting tentative request')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Widget> _buildFavoritedContributors() async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

    if (!userSnapshot.exists) {
      return SizedBox(height: 0);
    }

    var userData = userSnapshot.data() as Map<String, dynamic>?;
    if (userData == null) {
      return SizedBox(height: 0);
    }

    List<String> favoritedContributors =
        List<String>.from(userData['favoritedContributors'] ?? []);

    if (favoritedContributors.isEmpty) {
      return SizedBox(height: 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 24),
              SizedBox(width: 8),
              Text(
                'My Favorite Matches',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('My Favorite Matches'),
                        content:
                            Text('Flights favorited from previous matches'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
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
        ),
      ],
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
                  await _firestore
                      .collection('contributors')
                      .doc(docId)
                      .delete();

                  await _firestoreService
                      .deleteNotificationsForContributor(docId);

                  await _firestoreService
                      .removeContributorFromAllFavorites(docId);

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
                        content: Text('Error deleting volunteer form')),
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
  final AirlineFetcher airlineFetcher;
  final FirestoreService firestoreService;

  const ContributorFormCard({
    super.key,
    required this.data,
    required this.docId,
    required this.onEdit,
    required this.onDelete,
    required this.airlineFetcher,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    String from = data['departureAirport']?['iata'] ?? 'Unknown';
    String to = data['arrivalAirport']?['iata'] ?? 'Unknown';
    String? via = data['layoverAirport']?['iata'];

    String flightRoute = '$from to $to';
    if (via != null) {
      flightRoute += ' via $via';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                contributorId: docId,
                userId: data['userId'],
                airlineFetcher: airlineFetcher,
                firestoreService: firestoreService,
              ),
            ),
          );
        },
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
                    flightRoute,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat("MMM d, yyyy':' h:mm a").format(
                        (data['flightDateTimeFirstLeg'] as Timestamp).toDate()),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
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
        (contributorData['flightDateTimeFirstLeg'] as Timestamp).toDate();
    String formattedDate = DateFormat('MMM d').format(flightDate);

    String flightInfo = '$from to $to';
    if (via != null) {
      flightInfo += ' via $via';
    }
    flightInfo += ' on $formattedDate';

    String flightNumber = contributorData['flightNumberFirstLeg'] ?? 'N/A';
    String airlineName = _getAirlineName(flightNumber);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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

class TentativeRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TentativeRequestCard({
    Key? key,
    required this.data,
    required this.docId,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String from = data['startAirport']?['iata'] ?? 'Unknown';
    String to = data['endAirport']?['iata'] ?? 'Unknown';
    DateTime startDate = (data['startDate'] as Timestamp).toDate();
    DateTime endDate = (data['endDate'] as Timestamp).toDate();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
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
                  '$from to $to',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat("MMM d, yyyy").format(startDate)} - ${DateFormat("MMM d, yyyy").format(endDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
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
