import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/screens/chat_screen.dart';

class SeekerDetailScreen extends StatelessWidget {
  final String senderUserId;
  final String? receiverDocId;

  const SeekerDetailScreen({
    Key? key,
    required this.senderUserId,
    this.receiverDocId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Seeker Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSeekerData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data;

          if (userData == null) {
            return const Center(child: Text('User data not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: userData['profile_picture'] != null
                        ? NetworkImage(userData['profile_picture'])
                        : null,
                    child: userData['profile_picture'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    userData['name'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: const Text(
                    "This individual seeks to travel with another person in need for mutual support.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildDetailRow('Email', userData['email'] ?? 'N/A'),
                _buildDetailRow('Phone', userData['phone'] ?? 'N/A'),
                const SizedBox(height: 20),
                const Text(
                  'Additional Seeker Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'From', userData['startAirport']['name'] ?? 'N/A'),
                _buildDetailRow('To', userData['endAirport']['name'] ?? 'N/A'),
                _buildDetailRow(
                    'Start Date', _formatDate(userData['startDate'])),
                _buildDetailRow('End Date', _formatDate(userData['endDate'])),
                _buildDetailRow('Reason', userData['reason'] ?? 'N/A'),
                if (userData['reason'] == 'Other')
                  _buildDetailRow(
                      'Other Reason', userData['otherReason'] ?? 'N/A'),
                _buildDetailRow(
                    'Party Size', userData['partySize']?.toString() ?? 'N/A'),
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _startChat(context, userData),
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
                ),
              ],
            ),
          );
        },
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM d, y').format(date);
  }

  Future<Map<String, dynamic>> _fetchSeekerData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderUserId)
        .get();

    final userData = userDoc.data() ?? {};

    if (receiverDocId != null) {
      final receiverDoc = await FirebaseFirestore.instance
          .collection('receivers')
          .doc(receiverDocId)
          .get();

      final receiverData = receiverDoc.data() ?? {};
      userData.addAll(receiverData);
    }

    return userData;
  }

  void _startChat(BuildContext context, Map<String, dynamic> userData) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatIdParts = [currentUser.uid, senderUserId];
    chatIdParts.sort();
    final chatId = chatIdParts.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserId: senderUserId,
          otherUserName: userData['name'] ?? 'Seeker',
          otherUserProfilePic: userData['profile_picture'],
        ),
      ),
    );
  }
}
