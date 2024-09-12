import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiverInfoDialog extends StatelessWidget {
  final String userId;
  final bool isContributor;

  const ReceiverInfoDialog({
    Key? key,
    required this.userId,
    this.isContributor = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(isContributor ? 'contributors' : 'receivers')
          .doc(userId)
          .get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: ${snapshot.error}'),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return AlertDialog(
            title: const Text('Not Found'),
            content: const Text('User information not found.'),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return AlertDialog(
          title: Text(isContributor
              ? 'Contributor Information'
              : 'Receiver Information'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildInfoRow('Name', data['userName'] ?? 'N/A'),
                _buildInfoRow('Email', data['userEmail'] ?? 'N/A'),
                _buildInfoRow('Phone', data['userPhone'] ?? 'N/A'),
                _buildInfoRow(
                    'Party Size', data['partySize']?.toString() ?? 'N/A'),
                if (!isContributor) ...[
                  _buildInfoRow('Reason', data['reason'] ?? 'N/A'),
                  if (data['reason'] == 'Other')
                    _buildInfoRow('Other Reason', data['otherReason'] ?? 'N/A'),
                ],
                if (isContributor) ...[
                  _buildInfoRow('Departure Airport',
                      data['departureAirport']?['name'] ?? 'N/A'),
                  _buildInfoRow('Arrival Airport',
                      data['arrivalAirport']?['name'] ?? 'N/A'),
                  _buildInfoRow(
                      'Flight Date', _formatDate(data['flightDateTime'])),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
