import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/contributor/tentative_receiver_screen.dart';
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
              'Flights from ${widget.receiverFormState.startAirport?.iata.toString() ?? 'Unknown'} to ${widget.receiverFormState.endAirport?.iata.toString() ?? 'Unknown'}'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Volunteers'),
              Tab(text: 'Tentative Receivers'),
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
      ),
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
          SnackBar(content: Text('Tentative request updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tentative request added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error adding/updating tentative request: ${e.toString()}')),
      );
      print('Error adding/updating tentative request: $e');
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
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No matching volunteers found',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 40),
                      FutureBuilder<bool>(
                        future: _hasExistingTentativeRequest(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          bool hasExistingRequest = snapshot.data ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _addOrUpdateTentativeList,
                                child: Text(
                                  hasExistingRequest
                                      ? 'Update Tentative Request'
                                      : 'Add Tentative Request',
                                ),
                              ),
                              SizedBox(width: 8),
                              Tooltip(
                                message:
                                    'The Tentative List allows you to indicate interest in connecting with other people looking for help. You will also be notified if a match with a future volunteer is found',
                                child: IconButton(
                                  icon: Icon(Icons.info_outline),
                                  onPressed: () {
                                    _showTentativeListInfo(context);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
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
                        layover:
                            contributorData['layoverAirport']?['city'] ?? 'N/A',
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

  void _showTentativeListInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tentative List Information'),
          content: Text(
            'The Tentative List is a feature that allows you to express interest in connecting with other receivers (people who need help) because there are no current volunteer matching your criteria. By joining this list, you may also be notified if a potential match with a volunteer is found in the future. This increases your chances of finding a match.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
