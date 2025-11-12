import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkzy_beta1/models/friend_request_model.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';

class NotificationHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirestoreService _firestoreService = FirestoreService();

  static Future<void> acceptFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final qs = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    
    if (qs.docs.isEmpty) return;
    
    // Use the proper service method to accept the request
    // This will update the status AND create the friendship
    await _firestoreService.respondToFriendRequest(
      qs.docs.first.id,
      FriendRequestStatus.accepted,
    );
  }

  static Future<void> ignoreFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    final qs = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return;
    await _firestore.collection('friendRequests').doc(qs.docs.first.id).update({'status': 'declined'});
  }
}



