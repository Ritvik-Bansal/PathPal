import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathpal/contributor/contributor_detail_screen.dart';
import 'package:pathpal/screens/receiver_info_dialog.dart';
import 'package:pathpal/services/firestore_service.dart';
import 'package:pathpal/data/airline_data.dart';

class NotificationsScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final AirlineFetcher airlineFetcher;
  final VoidCallback onOpen;

  const NotificationsScreen({
    Key? key,
    required this.firestoreService,
    required this.airlineFetcher,
    required this.onOpen,
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadAirlines();
    widget.onOpen();
  }

  Future<void> _loadAirlines() async {
    try {
      await widget.airlineFetcher.loadAirlines();
    } catch (e) {
      print('Error loading airline data: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var notification = docs[index];
              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNotification(notification.id);
                },
                child: Column(
                  children: [
                    ListTile(
                      title: Text(notification['title'] ?? 'No title'),
                      subtitle: Text(notification['body'] ?? 'No body'),
                      trailing: Text(
                        _formatDate(notification['createdAt'] as Timestamp? ??
                            Timestamp.now()),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onTap: () =>
                          _handleNotificationTap(context, notification),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Divider(height: 1, thickness: 1),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  void _handleNotificationTap(
      BuildContext context, DocumentSnapshot notification) {
    final title = notification['title'] as String?;

    if (title == 'Potential Contributor Found') {
      _showContributorDetails(context, notification);
    } else if (title == 'New Contact Request' ||
        title == 'A Fellow Receiver Contacted You') {
      _showReceiverInfo(context, notification);
    }
  }

  void _showContributorDetails(
      BuildContext context, DocumentSnapshot notification) async {
    final contributorId = notification['contributorId'] as String?;
    if (contributorId != null) {
      final contributorDoc = await FirebaseFirestore.instance
          .collection('contributors')
          .doc(contributorId)
          .get();

      if (contributorDoc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContributorDetailScreen(
              contributorId: contributorId,
              userId: FirebaseAuth.instance.currentUser!.uid,
              airlineFetcher: widget.airlineFetcher,
              firestoreService: widget.firestoreService,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contributor details not found')),
        );
      }
    }
  }

  void _showReceiverInfo(BuildContext context, DocumentSnapshot notification) {
    final userId = notification['receiverId'] as String?;
    if (userId != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) => ReceiverInfoDialog(
          userId: userId,
          isContributor: notification['title'] == 'New Contact Request',
        ),
      );
    }
  }
}
