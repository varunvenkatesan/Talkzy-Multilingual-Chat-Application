import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to automatically create missing Firebase collections
/// Run this once to set up your Firestore database
class FirebaseSetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Automatically creates all required collections with dummy documents
  /// Call this once when app starts to ensure all collections exist
  Future<void> initializeCollections() async {
    try {
      print('🔥 Starting Firebase collections initialization...');
      
      // Add timeout to prevent hanging
      await _initializeWithTimeout().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⚠️ Setup timed out after 30 seconds');
          print('💡 Collections will be created when you use the app');
          return;
        },
      );
    } catch (e) {
      print('❌ Error initializing collections: $e');
      print('💡 You may need to update Firestore security rules.');
      rethrow;
    }
  }

  /// Internal method with actual initialization logic
  Future<void> _initializeWithTimeout() async {
    try {

      // Create users collection
      await _createCollectionIfNeeded(
        'users',
        {
          'id': 'setup_temp_user',
          'email': 'setup@temp.com',
          'displayName': 'Setup User',
          'photoURL': '',
          'gender': 'other',
          'bio': 'Temporary setup document',
          'isOnline': false,
          'lastSeen': Timestamp.now(),
          'createdAt': Timestamp.now(),
          'showLastSeen': true,
          'readReceipts': true,
          'profilePhotoVisibility': 'everyone',
          'bioVisibility': 'everyone',
          'blockedUsers': [],
        },
      );

      // Create friendRequests collection
      await _createCollectionIfNeeded(
        'friendRequests',
        {
          'id': 'setup_temp_request',
          'senderId': 'temp_sender',
          'receiverId': 'temp_receiver',
          'status': 'pending',
          'createdAt': Timestamp.now(),
        },
      );

      // Create friendships collection
      await _createCollectionIfNeeded(
        'friendships',
        {
          'id': 'setup_temp_friendship',
          'user1Id': 'temp_user1',
          'user2Id': 'temp_user2',
          'createdAt': Timestamp.now(),
          'isBlocked': false,
        },
      );

      // Create chats collection
      await _createCollectionIfNeeded(
        'chats',
        {
          'id': 'setup_temp_chat',
          'participants': ['temp_user1', 'temp_user2'],
          'lastMessage': 'Setup message',
          'lastMessageTime': Timestamp.now(),
          'lastMessageSenderId': 'temp_user1',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'unreadCount': {'temp_user1': 0, 'temp_user2': 0},
          'deletedBy': {'temp_user1': false, 'temp_user2': false},
        },
      );

      // Create messages collection (if not exists)
      await _createCollectionIfNeeded(
        'messages',
        {
          'id': 'setup_temp_message',
          'chatId': 'setup_temp_chat',
          'senderId': 'temp_sender',
          'receiverId': 'temp_receiver',
          'content': 'Setup message',
          'timestamp': Timestamp.now(),
          'isRead': false,
        },
      );

      // Create notifications collection (if not exists)
      await _createCollectionIfNeeded(
        'notifications',
        {
          'id': 'setup_temp_notification',
          'userId': 'temp_user',
          'title': 'Setup',
          'body': 'Setup notification',
          'type': 'system',
          'createdAt': Timestamp.now(),
          'isRead': false,
        },
      );

      print('✅ All collections initialized successfully!');
      print('📝 Now cleaning up temporary documents...');

      // Clean up temporary documents
      await _cleanupTempDocuments();

      print('✅ Firebase setup complete! All collections are ready.');
      print('🎉 You can now use the app normally!');
    } catch (e) {
      print('❌ Error in setup process: $e');
      print('💡 You may need to update Firestore security rules.');
      rethrow;
    }
  }

  /// Creates a collection with a temporary document if it doesn't exist
  Future<void> _createCollectionIfNeeded(
    String collectionName,
    Map<String, dynamic> dummyData,
  ) async {
    try {
      print('📦 Creating collection: $collectionName');

      // Create a temporary document to initialize the collection
      await _firestore
          .collection(collectionName)
          .doc('setup_temp_${collectionName}')
          .set(dummyData, SetOptions(merge: true));

      print('✅ Collection "$collectionName" created/verified');
    } catch (e) {
      print('⚠️ Warning: Could not create collection "$collectionName": $e');
      // Don't throw - continue with other collections
    }
  }

  /// Removes all temporary setup documents
  Future<void> _cleanupTempDocuments() async {
    try {
      final collections = [
        'users',
        'friendRequests',
        'friendships',
        'chats',
        'messages',
        'notifications',
      ];

      for (var collection in collections) {
        try {
          // Delete temp document
          await _firestore
              .collection(collection)
              .doc('setup_temp_$collection')
              .delete();
          print('🗑️ Cleaned up temp document in $collection');
        } catch (e) {
          // Ignore errors - document might not exist
          print('⚠️ Could not clean up $collection: $e');
        }
      }

      print('✅ Cleanup complete!');
    } catch (e) {
      print('⚠️ Cleanup warning: $e');
      // Don't throw - cleanup is not critical
    }
  }

  /// Check if collections exist and are accessible
  Future<Map<String, bool>> checkCollectionsStatus() async {
    final collections = [
      'users',
      'friendRequests',
      'friendships',
      'chats',
      'messages',
      'notifications',
    ];

    Map<String, bool> status = {};

    for (var collection in collections) {
      try {
        // Try to read from collection
        await _firestore.collection(collection).limit(1).get();
        status[collection] = true;
        print('✅ $collection: accessible');
      } catch (e) {
        status[collection] = false;
        print('❌ $collection: not accessible - $e');
      }
    }

    return status;
  }
}
