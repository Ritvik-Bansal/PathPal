import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
            'Flights from ${widget.receiverFormState.startAirport?.iata.toString() ?? 'Unknown'} to ${widget.receiverFormState.endAirport?.iata.toString() ?? 'Unknown'}'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ))
          : StreamBuilder<QuerySnapshot>(
              stream: _getFilteredContributorsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ));
                }
                if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No matching contributors found'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var contributor = snapshot.data!.docs[index];
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
                        if (!userSnapshot.hasData) {
                          return const ListTile(title: Text('User not found'));
                        }
                        var userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        return ContributorCard(
                          layover: contributorData['layoverAirport']?['city'] ??
                              'N/A',
                          airline:
                              contributorData['flightNumberFirstLeg'] ?? '',
                          profilePicture: userData['profile_picture'] ?? '',
                          flightDate:
                              (contributorData['flightDateTime'] as Timestamp)
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
                                setState(
                                    () {}); // This will rebuild the widget tree
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
            ),
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
        .where('flightDateTime',
            isGreaterThanOrEqualTo: widget.receiverFormState.startDate)
        .where('flightDateTime',
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
  final String? layover;
  final String airline;
  final VoidCallback onTap;
  final AirlineFetcher airlineFetcher;
  final String contributorId;
  final FirestoreService firestoreService;

  ContributorCard({
    required this.airline,
    this.layover,
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
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    bool isFavorite = await widget.firestoreService
        .isContributorFavorited(widget.contributorId);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMM d').format(widget.flightDate);
    String formattedTime = DateFormat('h:mm a').format(widget.flightDate);
    String iataCode = widget.airline.substring(0, 2).toUpperCase();
    String? airlineName = widget.airlineFetcher.getAirlineName(iataCode);
    String formattedAirlineName = _formatAirlineName(airlineName);

    String text = widget.layover == "N/A"
        ? '$formattedAirlineName• $formattedDate • $formattedTime'
        : '$formattedAirlineName • $formattedDate • via ${widget.layover}';

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
