import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';
import 'package:pathpal/services/fcm_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late EmailService _emailService;

  FirestoreService() {
    _emailService = EmailService(this);
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('User document does not exist for uid: ${user.uid}');
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      return {
        'name': userData['name'] ?? user.displayName ?? 'Unknown',
        'email': userData['email'] ?? user.email ?? 'No email provided',
        'phone': userData['phone'] ?? 'No phone number provided',
      };
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  Future<void> submitReceiverForm(ReceiverFormState formState) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final existingForm = await getExistingReceiverForm();
      final formData = {
        'userId': user.uid,
        'userName': user.displayName,
        'userPhone': formState.phoneNumber,
        'userEmail': user.email,
        'dateRange': formState.selectedDateRange,
        'startDate': formState.startDate,
        'endDate': formState.endDate,
        'startAirport': formState.startAirport?.toJson(),
        'endAirport': formState.endAirport?.toJson(),
        'reason': formState.reason,
        'otherReason': formState.otherReason,
        'partySize': formState.partySize,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingForm != null) {
        await _firestore
            .collection('receivers')
            .doc(existingForm.id)
            .update(formData);
      } else {
        formData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('receivers').add(formData);
      }
    } catch (e) {
      print('Error submitting receiver form: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getExistingReceiverForm() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('receivers')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    } catch (e) {
      print('Error fetching existing form: $e');
      final querySnapshot = await _firestore
          .collection('receivers')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    }
    return null;
  }

  Future<String?> getUserEmail() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      return userDoc.data()?['email'] as String?;
    }
    return null;
  }

  Future<void> submitContributorForm(ContributorFormState formState) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final contributorData = {
        'userId': user.uid,
        'userEmail': formState.email,
        'partySize': formState.partySize,
        'departureAirport': formState.departureAirport?.toJson(),
        'arrivalAirport': formState.arrivalAirport?.toJson(),
        'hasLayover': formState.hasLayover,
        'flightDateTime': Timestamp.fromDate(formState.flightDateTime!),
        'flightNumberFirstLeg': formState.flightNumber.toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (formState.hasLayover) {
        contributorData['flightNumberSecondLeg'] =
            formState.flightNumberSecondLeg.toUpperCase();
        contributorData['layoverAirport'] = formState.layoverAirport?.toJson();
      }

      DocumentReference contributorRef =
          await _firestore.collection('contributors').add(contributorData);
      String contributorDocId = contributorRef.id;

      await _emailService.checkTentativeReceivers(formState, contributorDocId);
    } catch (e) {
      print('Error submitting contributor form: $e');
      rethrow;
    }
  }

  Future<void> addContactedContributor(String contributorId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    await _firestore.collection('users').doc(user.uid).update({
      'contactedContributors': FieldValue.arrayUnion([contributorId])
    });

    final contributorDoc =
        await _firestore.collection('contributors').doc(contributorId).get();

    if (!contributorDoc.exists) {
      throw Exception('Contributor document not found');
    }

    final contributorData = contributorDoc.data() as Map<String, dynamic>;
    final contributorUserId = contributorData['userId'] as String?;

    if (contributorUserId == null) {
      throw Exception('Contributor userId not found');
    }

    QuerySnapshot receiverQuery = await _firestore
        .collection('receivers')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    String? receiverDocId;
    if (receiverQuery.docs.isNotEmpty) {
      receiverDocId = receiverQuery.docs.first.id;
    }

    await addNotification(
      contributorUserId,
      'New Contact Request',
      'A traveler has requested to connect with you.',
      receiverDocId: receiverDocId,
    );
  }

  Future<bool> hasContactedContributor(String contributorId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final contactedContributors =
        doc.data()?['contactedContributors'] as List<dynamic>? ?? [];
    return contactedContributors.contains(contributorId);
  }

  Future<void> removeContributorFromAllFavorites(String contributorId) async {
    try {
      QuerySnapshot usersWithFavorite = await _firestore
          .collection('users')
          .where('favoritedContributors', arrayContains: contributorId)
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot userDoc in usersWithFavorite.docs) {
        List<String> favorites =
            List<String>.from(userDoc['favoritedContributors']);
        favorites.remove(contributorId);
        batch.update(userDoc.reference, {'favoritedContributors': favorites});
      }

      await batch.commit();
    } catch (e) {
      print('Error removing contributor from favorites: $e');
      rethrow;
    }
  }

  Future<void> toggleFavoriteContributor(String contributorId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final userDoc = _firestore.collection('users').doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) {
        throw Exception('User document does not exist');
      }

      List<String> favorites =
          List<String>.from(snapshot.data()?['favoritedContributors'] ?? []);

      if (favorites.contains(contributorId)) {
        favorites.remove(contributorId);
      } else {
        favorites.add(contributorId);
      }

      transaction.update(userDoc, {'favoritedContributors': favorites});
    });
  }

  Future<bool> isContributorFavorited(String contributorId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return false;

    List<String> favorites =
        List<String>.from(userDoc.data()?['favoritedContributors'] ?? []);
    return favorites.contains(contributorId);
  }

  Stream<bool> streamIsContributorFavorited(String contributorId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      List<String> favorites =
          List<String>.from(snapshot.data()?['favoritedContributors'] ?? []);
      return favorites.contains(contributorId);
    });
  }

  Future<void> updateContributorForm(
      String contributorId, ContributorFormState formState) async {
    try {
      final updateData = formState.toMap();
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      if (!formState.hasLayover) {
        updateData.remove('layoverAirport');
        updateData.remove('flightNumberSecondLeg');
      }

      await _firestore
          .collection('contributors')
          .doc(contributorId)
          .update(updateData);
    } catch (e) {
      print('Error updating contributor form: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getContributorFormData(
      String contributorId) async {
    try {
      final doc =
          await _firestore.collection('contributors').doc(contributorId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching contributor form data: $e');
    }
    return null;
  }

  Future<bool> hasContactedTentativeReceiver(String receiverId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      List<String> contactedTentativeReceivers = List<String>.from(
          userDoc.data()?['contactedTentativeReceivers'] ?? []);
      return contactedTentativeReceivers.contains(receiverId);
    } catch (e) {
      print('Error checking if receiver has been contacted: $e');
      return false;
    }
  }

  Future<void> addContactedTentativeReceiver(String receiverId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      await _firestore.collection('users').doc(user.uid).update({
        'contactedTentativeReceivers': FieldValue.arrayUnion([receiverId])
      });
    } catch (e) {
      print('Error adding contacted receiver: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getTentativeReceivers({
    required DateTime startDate,
    required DateTime endDate,
    required String startAirportIata,
    required String endAirportIata,
  }) {
    return _firestore
        .collection('tentativeReceivers')
        .where('startDate', isLessThanOrEqualTo: endDate)
        .where('endDate', isGreaterThanOrEqualTo: startDate)
        .where('startAirport.iata', isEqualTo: startAirportIata)
        .where('endAirport.iata', isEqualTo: endAirportIata)
        .snapshots();
  }

  Future<void> addOrUpdateTentativeReceiver(ReceiverFormState formState) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final existingRequest = await getTentativeReceiverRequest(
        formState.startAirport!.iata,
        formState.endAirport!.iata,
      );

      // String? fcmToken = await FirebaseMessaging.instance.getToken();

      final tentativeReceiverData = {
        'userId': user.uid,
        'userName': user.displayName,
        'userPhone': formState.phoneNumber,
        'userEmail': formState.email,
        'startDate': formState.startDate,
        'endDate': formState.endDate,
        'startAirport': formState.startAirport?.toJson(),
        'endAirport': formState.endAirport?.toJson(),
        'reason': formState.reason,
        'otherReason': formState.otherReason,
        'partySize': formState.partySize,
        // 'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingRequest != null) {
        await _firestore
            .collection('tentativeReceivers')
            .doc(existingRequest.id)
            .update(tentativeReceiverData);
      } else {
        tentativeReceiverData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('tentativeReceivers')
            .add(tentativeReceiverData);
      }
    } catch (e) {
      print('Error adding/updating tentative receiver: $e');
      rethrow;
    }
  }

  Future<void> deleteTentativeRequest(String requestId) async {
    try {
      await _firestore.collection('tentativeReceivers').doc(requestId).delete();
    } catch (e) {
      print('Error deleting tentative request: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getTentativeReceiverRequest(
      String startAirportIata, String endAirportIata) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('tentativeReceivers')
          .where('userId', isEqualTo: user.uid)
          .where('startAirport.iata', isEqualTo: startAirportIata)
          .where('endAirport.iata', isEqualTo: endAirportIata)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    } catch (e) {
      print('Error fetching existing tentative receiver request: $e');
    }
    return null;
  }

  Future<void> addNotification(String userId, String title, String body,
      {String? contributorDocId, String? receiverDocId}) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        if (contributorDocId != null) 'contributorId': contributorDocId,
        if (receiverDocId != null) 'receiverId': receiverDocId,
      });
    } catch (e) {
      print('Error adding notification: $e');
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in notificationsQuery.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
