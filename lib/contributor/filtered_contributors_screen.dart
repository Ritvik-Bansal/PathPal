import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/contributor/tentative/tentative_receiver_screen.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'contributor_detail_screen.dart';
import 'package:pathpal/data/airline_data.dart';

class FilteredContributorsScreen extends StatefulWidget {
  final ReceiverFormState receiverFormState;

  FilteredContributorsScreen({required this.receiverFormState});

  @override
  _FilteredContributorsScreenState createState() =>
      _FilteredContributorsScreenState();
}

class _FilteredContributorsScreenState
    extends State<FilteredContributorsScreen> {
  final AirlineFetcher _airlineFetcher = AirlineFetcher();
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadAirlines();
  }

  Future<void> _loadAirlines() async {
    try {
      await _airlineFetcher.loadAirlines();
    } catch (e) {
      print('Error loading airline data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _hasExistingTentativeRequest() async {
    final userEmail = await _firestoreService.getUserEmail();
    if (userEmail == null) {
      return false;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('tentativeReceivers')
        .where('userEmail', isEqualTo: userEmail)
        .where('startAirport.iata',
            isEqualTo:
                widget.receiverFormState.startAirport!.iata.toUpperCase())
        .where('endAirport.iata',
            isEqualTo: widget.receiverFormState.endAirport!.iata.toUpperCase())
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
              'Search Results from ${widget.receiverFormState.startAirport?.iata.toString() ?? 'Unknown'} to ${widget.receiverFormState.endAirport?.iata.toString() ?? 'Unknown'}'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Volunteers'),
              Tab(text: 'Seekers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContributorsTab(),
            TentativeReceiversScreen(
                receiverFormState: widget.receiverFormState),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTentativeRequestDialog(),
          icon: Icon(Icons.add),
          label: Text('Add Request'),
        ),
      ),
    );
  }

  void _showAddTentativeRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Seeker Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adding a request allows you to indicate interest in connecting with other people looking for help. You will also be notified if a match with a future volunteer is found.',
              ),
              SizedBox(height: 16),
              Text(
                'Do you want to add your request to the Seeker list?',
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Add Request'),
              onPressed: () {
                Navigator.of(context).pop();
                _addOrUpdateTentativeList();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addOrUpdateTentativeList() async {
    final userEmail = await _firestoreService.getUserEmail();
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not fetch user details')));
      return;
    }
    widget.receiverFormState.email = userEmail;

    try {
      bool hasExistingRequest = await _hasExistingTentativeRequest();
      await _firestoreService
          .addOrUpdateTentativeReceiver(widget.receiverFormState);
      if (hasExistingRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeker request updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeker request added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error adding/updating Seeker request: ${e.toString()}')),
      );
      print('Error adding/updating Seeker request: $e');
    }
  }

  Widget _buildContributorsTab() {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.surface))
        : StreamBuilder<QuerySnapshot>(
            stream: _getFilteredContributorsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        backgroundColor:
                            Theme.of(context).colorScheme.surface));
              }
              if (snapshot.hasError) {
                print(snapshot.error);
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final contributorData = doc.data() as Map<String, dynamic>;
                return contributorData['userId'] != currentUserId;
              }).toList();

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty ||
                  filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No matching volunteers found',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  var contributor = filteredDocs[index];
                  var contributorData =
                      contributor.data() as Map<String, dynamic>;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(contributorData['userId'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(title: Text('Loading...'));
                      }
                      if (userSnapshot.hasError) {
                        return const ListTile(
                            title: Text('Error loading user data'));
                      }
                      if (!userSnapshot.hasData ||
                          userSnapshot.data!.data() == null) {
                        return const ListTile(title: Text('User not found'));
                      }
                      var userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;

                      List<String?> layovers = [];
                      if (contributorData['firstLayoverAirport'] != null) {
                        layovers.add(
                            contributorData['firstLayoverAirport']['iata']);
                      }
                      if (contributorData['secondLayoverAirport'] != null) {
                        layovers.add(
                            contributorData['secondLayoverAirport']['iata']);
                      }

                      return ContributorCard(
                        layovers: layovers,
                        airline: contributorData['flightNumberFirstLeg'] ?? '',
                        profilePicture: userData['profile_picture'] ?? '',
                        flightDate: (contributorData['flightDateTimeFirstLeg']
                                as Timestamp)
                            .toDate(),
                        onTap: () {
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContributorDetailScreen(
                                contributorId: contributor.id,
                                userId: contributorData['userId'],
                                airlineFetcher: _airlineFetcher,
                                firestoreService: _firestoreService,
                              ),
                            ),
                          ).then((favoriteChanged) {
                            if (favoriteChanged == true) {
                              setState(() {});
                            }
                          });
                        },
                        airlineFetcher: _airlineFetcher,
                        contributorId: contributor.id,
                        firestoreService: _firestoreService,
                      );
                    },
                  );
                },
              );
            },
          );
  }

  Stream<QuerySnapshot> _getFilteredContributorsStream() {
    if (widget.receiverFormState.startDate == null ||
        widget.receiverFormState.endDate == null ||
        widget.receiverFormState.startAirport == null ||
        widget.receiverFormState.endAirport == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('contributors')
        .where('flightDateTimeFirstLeg',
            isGreaterThanOrEqualTo: widget.receiverFormState.startDate)
        .where('flightDateTimeFirstLeg',
            isLessThanOrEqualTo:
                widget.receiverFormState.endDate!.add(const Duration(days: 1)))
        .where('departureAirport.iata',
            isEqualTo:
                widget.receiverFormState.startAirport!.iata.toUpperCase())
        .where('arrivalAirport.iata',
            isEqualTo: widget.receiverFormState.endAirport!.iata.toUpperCase())
        .snapshots()
        .map((snapshot) {
      return snapshot;
    });
  }
}

class ContributorCard extends StatefulWidget {
  final String profilePicture;
  final DateTime flightDate;
  final List<String?> layovers;
  final String airline;
  final VoidCallback onTap;
  final AirlineFetcher airlineFetcher;
  final String contributorId;
  final FirestoreService firestoreService;

  ContributorCard({
    required this.airline,
    required this.layovers,
    required this.profilePicture,
    required this.flightDate,
    required this.onTap,
    required this.airlineFetcher,
    required this.contributorId,
    required this.firestoreService,
  });

  @override
  State<ContributorCard> createState() => _ContributorCardState();
}

class _ContributorCardState extends State<ContributorCard> {
  String _formatAirlineName(String? airlineName) {
    if (airlineName == null) return 'Unknown';

    airlineName = airlineName
        .replaceAll(
          RegExp(r'\b(airline|airlines|air line|air lines)\b',
              caseSensitive: false),
          '',
        )
        .trim();

    if (airlineName.length > 10) {
      airlineName = airlineName.substring(0, 10).trim() + '..';
    }

    return airlineName;
  }

  String _formatLayoverInfo() {
    if (widget.layovers.isEmpty || widget.layovers.every((l) => l == null)) {
      return 'Direct';
    } else if (widget.layovers.length == 1) {
      return 'via ${widget.layovers[0]}';
    } else {
      return 'via ${widget.layovers[0]} & ${widget.layovers[1]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMM d').format(widget.flightDate);
    String iataCode = widget.airline.substring(0, 2).toUpperCase();
    String? airlineName = widget.airlineFetcher.getAirlineName(iataCode);
    String formattedAirlineName = _formatAirlineName(airlineName);
    String layoverInfo = _formatLayoverInfo();

    String text = '$formattedAirlineName • $formattedDate • $layoverInfo';

    return StreamBuilder<bool>(
      stream: widget.firestoreService
          .streamIsContributorFavorited(widget.contributorId),
      builder: (context, snapshot) {
        bool isFavorite = snapshot.data ?? false;
        return GestureDetector(
          onTap: widget.onTap,
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
                      backgroundImage: widget.profilePicture.isNotEmpty
                          ? NetworkImage(widget.profilePicture)
                          : null,
                      radius: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () => widget.firestoreService
                                    .toggleFavoriteContributor(
                                        widget.contributorId),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 40,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
