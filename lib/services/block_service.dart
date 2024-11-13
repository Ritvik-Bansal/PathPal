import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> blockUser(String blockedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).set({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser(String blockedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).set({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    }, SetOptions(merge: true));
  }

  Stream<bool> isUserBlocked(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final List<dynamic> blockedUsers = snapshot.data()?['blockedUsers'] ?? [];
      return blockedUsers.contains(otherUserId);
    });
  }

  Stream<bool> amIBlocked(String byUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(byUserId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final List<dynamic> blockedUsers = snapshot.data()?['blockedUsers'] ?? [];
      return blockedUsers.contains(currentUserId);
    });
  }
}
