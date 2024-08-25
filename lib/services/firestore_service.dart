import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitReceiverForm(ReceiverFormState formState) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final existingForm = await getExistingReceiverForm();
      final formData = {
        'userId': user.uid,
        'userName': user.displayName,
        'userPhone': formState.phoneNumber,
        'userEmail': formState.email,
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

  Future submitContributorForm(ContributorFormState formState) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final contributorData = {
        'userId': user.uid,
        'userEmail': formState.email,
        'partySize': formState.partySize,
        'emailConfirmed': formState.emailConfirmed,
        'termsAccepted': formState.termsAccepted,
        'departureAirport': formState.departureAirport?.toJson(),
        'arrivalAirport': formState.arrivalAirport?.toJson(),
        'hasLayover': formState.hasLayover,
        'flightDateTime': Timestamp.fromDate(formState.flightDateTime!),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (formState.hasLayover) {
        contributorData['flightNumberFirstLeg'] =
            formState.flightNumberFirstLeg;
        contributorData['flightNumberSecondLeg'] =
            formState.flightNumberSecondLeg;
        contributorData['layoverAirport'] = formState.layoverAirport?.toJson();
      } else {
        contributorData['flightNumberFirstLeg'] = formState.flightNumber;
      }

      await _firestore.collection('contributors').add(contributorData);
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
        var data = doc.data() as Map<String, dynamic>;
        return data;
      }
    } catch (e) {
      print('Error fetching contributor form data: $e');
    }
    return null;
  }
}
