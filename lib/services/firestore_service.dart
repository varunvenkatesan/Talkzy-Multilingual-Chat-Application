import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:talkzy_beta1/models/chat_model.dart';
import 'package:talkzy_beta1/models/friend_request_model.dart';
import 'package:talkzy_beta1/models/friendship_model.dart';
import 'package:talkzy_beta1/models/message_model.dart';
import 'package:talkzy_beta1/models/notification_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/config/performance_config.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Collection Operations ---

  Future<void> createUser(UserModel user) async {
    try {
      print('🔥 Firestore: Attempting to create user document for ${user.id}');
      
      // Add timeout to prevent hanging
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore operation timed out. Please check your internet connection and Firestore rules.');
            },
          );
      
      print('✅ Firestore: User document created successfully');
    } catch (e) {
      print('❌ Firestore Error: ${e.toString()}');
      
      // Check if it's a permission error
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Please deploy Firestore rules. Check FIX_FRIEND_REQUEST_ISSUE.md');
      }
      
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['lastSeen'] is Timestamp) {
          data['lastSeen'] =
              (data['lastSeen'] as Timestamp).millisecondsSinceEpoch;
        }
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to update user online status: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        final data = doc.data() as Map<String, dynamic>;
        if (data['lastSeen'] is Timestamp) {
          data['lastSeen'] =
              (data['lastSeen'] as Timestamp).millisecondsSinceEpoch;
        }
        return UserModel.fromMap(data);
      },
    );
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Stream<List<UserModel>> getAllUserStream() {
    return _firestore.collection('users').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            if (data['lastSeen'] is Timestamp) {
              data['lastSeen'] =
                  (data['lastSeen'] as Timestamp).millisecondsSinceEpoch;
            }
            return UserModel.fromMap(data);
          }).toList(),
        );
  }

  // --- Friend Request Collection Operations ---

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(request.id)
          .set(request.toMap());

      String notificationId =
          'friend_request_${request.senderId}_${request.receiverId}_${DateTime.now().millisecondsSinceEpoch}';

      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          title: 'New Friend Request',
          body: 'You have received a new friend request',
          type: NotificationType.friendRequest,
          data: {'senderId': request.senderId, 'requestId': request.id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to send friend request: ${e.toString()}');
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      DocumentSnapshot requestDoc =
          await _firestore.collection('friendRequests').doc(requestId).get();

      if (requestDoc.exists) {
        final data = requestDoc.data() as Map<String, dynamic>;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['respondedAt'] is Timestamp) {
          data['respondedAt'] =
              (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
        }
        FriendRequestModel request = FriendRequestModel.fromMap(data);

        await _firestore.collection('friendRequests').doc(requestId).delete();

        await deleteNotificationsByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception('Failed to cancel friend request: ${e.toString()}');
    }
  }

  Future<void> respondToFriendRequest(
    String requestId,
    FriendRequestStatus status,
  ) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': status.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      DocumentSnapshot requestDoc =
          await _firestore.collection('friendRequests').doc(requestId).get();

      if (requestDoc.exists) {
        final data = requestDoc.data() as Map<String, dynamic>;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['respondedAt'] is Timestamp) {
          data['respondedAt'] =
              (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
        }
        FriendRequestModel request = FriendRequestModel.fromMap(data);

        await _removeNotificationForCancelledRequest(
          request.receiverId,
          request.senderId,
        );

        if (status == FriendRequestStatus.accepted) {
          print('🤝 Creating friendship between ${request.senderId} and ${request.receiverId}');
          await createFriendship(request.senderId, request.receiverId);
          print('✅ Friendship created successfully');

          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Accepted',
              body: 'Your friend request has been accepted',
              type: NotificationType.friendRequestAccepted,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );
        } else if (status == FriendRequestStatus.declined) {
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Declined',
              body: 'Your friend request has been declined',
              type: NotificationType.friendRequestDeclined,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to respond to friend request: ${e.toString()}');
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            if (data['respondedAt'] is Timestamp) {
              data['respondedAt'] =
                  (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
            }
            return FriendRequestModel.fromMap(data);
          }).toList(),
        );
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            if (data['respondedAt'] is Timestamp) {
              data['respondedAt'] =
                  (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
            }
            return FriendRequestModel.fromMap(data);
          }).toList(),
        );
  }

  Future<FriendRequestModel?> getFriendRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data() as Map<String, dynamic>;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['respondedAt'] is Timestamp) {
          data['respondedAt'] =
              (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return FriendRequestModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friend request: ${e.toString()}');
    }
  }

  // --- Friendship Collection Operations ---

  Future<void> createFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      print('📝 Creating friendship document:');
      print('   - ID: $friendshipId');
      print('   - user1Id: ${userIds[0]}');
      print('   - user2Id: ${userIds[1]}');

      FriendshipModel friendship = FriendshipModel(
        id: friendshipId,
        user1Id: userIds[0],
        user2Id: userIds[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .set(friendship.toMap());
      
      print('✅ Friendship document created in Firestore');
    } catch (e) {
      print('❌ Failed to create friendship: ${e.toString()}');
      throw Exception('Failed to create friendship: ${e.toString()}');
    }
  }

  Future<void> removeFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';
      String chatId = '${userIds[0]}_${userIds[1]}'; // Same pattern as friendship ID

      print('🗑️ Removing friendship and chat between ${userIds[0]} and ${userIds[1]}');
      print('   - Friendship ID: $friendshipId');
      print('   - Chat ID: $chatId');

      // Delete the friendship document
      await _firestore.collection('friendships').doc(friendshipId).delete();
      print('✅ Friendship document deleted');

      // Delete the chat for both users (mark as deleted, don't actually delete)
      await deleteChatForUser(chatId, user1Id);
      await deleteChatForUser(chatId, user2Id);
      print('✅ Chat deleted for both users');

      // Send notification to the other user
      await createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user2Id,
          title: 'Friend Removed',
          body: 'You are no longer friends',
          type: NotificationType.friendRemoved,
          data: {'userId': user1Id},
          createdAt: DateTime.now(),
        ),
      );
      print('✅ Notification sent to removed friend');
    } catch (e) {
      print('❌ Failed to remove friendship: ${e.toString()}');
      throw Exception('Failed to remove friendship: ${e.toString()}');
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      // Update friendship document
      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });

      // Also add to blocker's blockedUsers list for quick access
      await _firestore.collection('users').doc(blockerId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedId])
      });
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> unblockUser(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      // Update friendship document
      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });

      // Also remove from user's blockedUsers list
      await _firestore.collection('users').doc(user1Id).update({
        'blockedUsers': FieldValue.arrayRemove([user2Id])
      });
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    // Create two separate streams for both conditions to ensure real-time updates
    // when the user is either user1Id OR user2Id in the friendship document
    final stream1 = _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .snapshots();

    final stream2 = _firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .snapshots();

    // Use Rx.combineLatest2 to properly combine both streams
    // This ensures real-time bidirectional updates for both users
    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<FriendshipModel>>(
      stream1,
      stream2,
      (snapshot1, snapshot2) {
        List<FriendshipModel> friendships = [];

        print('🔥 getFriendsStream update for user: $userId');
        print('   - user1Id matches: ${snapshot1.docs.length}');
        print('   - user2Id matches: ${snapshot2.docs.length}');

        // Process friendships where current user is user1Id
        for (var doc in snapshot1.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] =
                (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          friendships.add(FriendshipModel.fromMap(data));
        }

        // Process friendships where current user is user2Id
        for (var doc in snapshot2.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] =
                (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          friendships.add(FriendshipModel.fromMap(data));
        }

        print('   - Total friendships: ${friendships.length}');

        // Return all friendships including blocked ones
        // UI will handle showing block/unblock options
        return friendships;
      },
    );
  }

  Future<FriendshipModel?> getFriendship(
    String user1Id,
    String user2Id,
  ) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc =
          await _firestore.collection('friendships').doc(friendshipId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return FriendshipModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friendship: ${e.toString()}');
    }
  }

  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc =
          await _firestore.collection('friendships').doc(friendshipId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        FriendshipModel friendship = FriendshipModel.fromMap(data);
        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check if user is blocked: ${e.toString()}');
    }
  }

  Future<bool> isUnfriended(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc =
          await _firestore.collection('friendships').doc(friendshipId).get();

      return !doc.exists;
    } catch (e) {
      throw Exception('Failed to check if user is unfriended: ${e.toString()}');
    }
  }

  // --- Chat Collection Operations ---

  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      List<String> participants = [userId1, userId2];
      participants.sort();

      String chatId = '${participants[0]}_${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

      // Check if chat already exists
      DocumentSnapshot existingChatDoc = await chatRef.get();

      if (!existingChatDoc.exists) {
        // Create new chat with better initial lastMessage handling
        ChatModel baseChat = ChatModel(
          id: chatId,
          participants: participants,
          lastMessage: 'Start a conversation!',
          lastMessageTime: DateTime.now().add(const Duration(
              seconds:
                  1)), // Set a time slightly in future so it shows as recent
          lastMessageSenderId: userId1, // Any participant
          unreadCount: {userId1: 0, userId2: 0},
          deletedBy: {userId1: false, userId2: false},
          deletedAt: {userId1: null, userId2: null},
          lastSeenBy: {userId1: DateTime.now(), userId2: DateTime.now()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await chatRef.set(baseChat.toMap(), SetOptions(merge: true));
      } else {
        // Chat exists, ensure it has the required fields properly set
        final data = existingChatDoc.data() as Map<String, dynamic>;

        // Convert Timestamps to int (millisecondsSinceEpoch) before passing to fromMap
        if (data['lastMessageTime'] is Timestamp) {
          data['lastMessageTime'] =
              (data['lastMessageTime'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] =
              (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['lastSeenBy'] is Map) {
          (data['lastSeenBy'] as Map).forEach((key, value) {
            if (value is Timestamp) {
              data['lastSeenBy'][key] = value.millisecondsSinceEpoch;
            }
          });
        }
        if (data['deletedAt'] is Map) {
          (data['deletedAt'] as Map).forEach((key, value) {
            if (value is Timestamp) {
              data['deletedAt'][key] = value.millisecondsSinceEpoch;
            }
          });
        }

        ChatModel existingChat = ChatModel.fromMap(data);

        // If lastMessage is null/empty and there should be messages, try to fix it
        if ((existingChat.lastMessage == null ||
            existingChat.lastMessage!.isEmpty)) {
          // Check if there are actually messages in the chat
          QuerySnapshot messageCheck = await _firestore
              .collection('messages')
              .where('chatId', isEqualTo: chatId)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (messageCheck.docs.isNotEmpty) {
            // There are messages, set the last message properly
            final lastMsgData =
                messageCheck.docs.first.data() as Map<String, dynamic>;
            MessageModel lastMsg = MessageModel.fromMap(lastMsgData);
            await _firestore.collection('chats').doc(chatId).update({
              'lastMessage': lastMsg.content,
              'lastMessageTime': lastMsg.timestamp.millisecondsSinceEpoch,
              'lastMessageSenderId': lastMsg.senderId,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
          } else {
            // No messages, ensure we have a placeholder
            await _firestore.collection('chats').doc(chatId).update({
              'lastMessage': 'Start a conversation!',
              'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
              'lastMessageSenderId': userId1, // Use one of the participants
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }

        // Handle restore flags
        if (existingChat.isDeletedBy(userId1)) {
          await restoreChatForUser(chatId, userId1);
        }
        if (existingChat.isDeletedBy(userId2)) {
          await restoreChatForUser(chatId, userId2);
        }
      }
      return chatId;
    } catch (e) {
      throw Exception('Failed to create or get chat: ${e.toString()}');
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(PerformanceConfig.maxChatsLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Convert Timestamps to int (millisecondsSinceEpoch) before passing to fromMap
            if (data['lastMessageTime'] is Timestamp) {
              data['lastMessageTime'] =
                  (data['lastMessageTime'] as Timestamp).millisecondsSinceEpoch;
            }
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            if (data['updatedAt'] is Timestamp) {
              data['updatedAt'] =
                  (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
            }
            if (data['lastSeenBy'] is Map) {
              (data['lastSeenBy'] as Map).forEach((key, value) {
                if (value is Timestamp) {
                  data['lastSeenBy'][key] = value.millisecondsSinceEpoch;
                }
              });
            }
            if (data['deletedAt'] is Map) {
              (data['deletedAt'] as Map).forEach((key, value) {
                if (value is Timestamp) {
                  data['deletedAt'][key] = value.millisecondsSinceEpoch;
                }
              });
            }
            return ChatModel.fromMap(data);
          })
          .where((chat) => !chat.isDeletedBy(userId))
          .toList();
    });
  }

  Future<void> updateChatLastMessage(
      String chatId, MessageModel message) async {
    try {
      // Use consistent timestamp handling - if message has a valid timestamp, use it; otherwise use server timestamp
      final Map<String, dynamic> updateData = {
        'lastMessage': message.content,
        'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (message.timestamp != null) {
        updateData['lastMessageTime'] =
            message.timestamp!.millisecondsSinceEpoch;
      } else {
        updateData['lastMessageTime'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('chats').doc(chatId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update chat last message: ${e.toString()}');
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update last seen: ${e.toString()}');
    }
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': false,
      });
    } catch (e) {
      throw Exception('Failed to restore chat: ${e.toString()}');
    }
  }

  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': count,
      });
    } catch (e) {
      throw Exception('Failed to update unread count: ${e.toString()}');
    }
  }

  // --- Messages Collection Operations ---

  Future<void> sendMessage(MessageModel message) async {
    try {
      String chatId =
          await createOrGetChat(message.senderId, message.receiverId);

      final WriteBatch batch = _firestore.batch();

      // Always include both timestamps for instant display and server ordering
      final Map<String, dynamic> msgMap =
          message.copyWith(chatId: chatId).toMap();
      msgMap['clientTimestamp'] = Timestamp.fromDate(message.timestamp);
      msgMap['timestamp'] = FieldValue.serverTimestamp();

      final DocumentReference msgRef =
          _firestore.collection('messages').doc(message.id);
      batch.set(msgRef, msgMap, SetOptions(merge: true));

      final DocumentReference chatRef =
          _firestore.collection('chats').doc(chatId);

      final now = DateTime.now().millisecondsSinceEpoch;

      final updateData = {
        'lastMessage': message.content,
        'lastMessageTime': now,
        'lastMessageSenderId': message.senderId,
        'updatedAt': now,
        'lastSeenBy.${message.senderId}': now,
      };

      final participants = [message.senderId, message.receiverId];
      for (var userId in participants) {
        if (userId != message.senderId) {
          updateData['unreadCount.$userId'] = FieldValue.increment(1);
        }
      }

      batch.update(chatRef, updateData);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String userId1, String userId2) {
    List<String> participants = [userId1, userId2];
    participants.sort();
    String chatId = '${participants[0]}_${participants[1]}';

    // Fetch recent messages with limit for better performance
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .limit(PerformanceConfig.maxMessagesLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Make a mutable copy and ensure essential fields exist
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        if (!data.containsKey('id') ||
            data['id'] == null ||
            (data['id'] as String).isEmpty) {
          data['id'] = doc.id;
        }
        if (!data.containsKey('chatId') ||
            data['chatId'] == null ||
            (data['chatId'] as String).isEmpty) {
          data['chatId'] = chatId;
        }
        return MessageModel.fromMap(data);
      }).toList();
    });
  }

  Stream<List<MessageModel>> getMessagesStreamByChatId(String chatId) {
    // Provides a direct stream for a conversation thread identified by chatId with limit.
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .limit(PerformanceConfig.maxMessagesLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        if (!data.containsKey('id') ||
            data['id'] == null ||
            (data['id'] as String).isEmpty) {
          data['id'] = doc.id;
        }
        if (!data.containsKey('chatId') ||
            data['chatId'] == null ||
            (data['chatId'] as String).isEmpty) {
          data['chatId'] = chatId;
        }
        return MessageModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();

      // Get the deleted message info to potentially update chat lastMessage
      try {
        DocumentSnapshot messageDoc =
            await _firestore.collection('messages').doc(messageId).get();
        if (messageDoc.exists) {
          final data = messageDoc.data() as Map<String, dynamic>;
          MessageModel deletedMessage = MessageModel.fromMap(data);
          String chatId = deletedMessage.chatId;

          if (chatId.isNotEmpty) {
            // Find the most recent remaining message in the chat
            QuerySnapshot remainingMessages = await _firestore
                .collection('messages')
                .where('chatId', isEqualTo: chatId)
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

            if (remainingMessages.docs.isNotEmpty) {
              // Update chat with the new last message
              final newestData =
                  remainingMessages.docs.first.data() as Map<String, dynamic>;
              MessageModel newestMessage = MessageModel.fromMap(newestData);
              await updateChatLastMessage(chatId, newestMessage);
            } else {
              // No messages left, clear the lastMessage fields
              await _firestore.collection('chats').doc(chatId).update({
                'lastMessage': null,
                'lastMessageTime': null,
                'lastMessageSenderId': null,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        }
      } catch (e) {
        // If we can't get the message info or update the chat, just log the error
        // The message is already deleted, so this is not a critical failure
        print('Warning: Could not update chat lastMessage after deletion: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      // First get the message to find the chatId
      DocumentSnapshot messageDoc =
          await _firestore.collection('messages').doc(messageId).get();
      if (!messageDoc.exists) return;

      final data = messageDoc.data() as Map<String, dynamic>;
      MessageModel message = MessageModel.fromMap(data);

      // Update message content
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Check if this is the latest message before updating chat lastMessage
      String chatId = message.chatId ?? '';
      if (chatId.isNotEmpty) {
        QuerySnapshot latestMessages = await _firestore
            .collection('messages')
            .where('chatId', isEqualTo: chatId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (latestMessages.docs.isNotEmpty) {
          final latestData =
              latestMessages.docs.first.data() as Map<String, dynamic>;
          MessageModel latestMessage = MessageModel.fromMap(latestData);

          // Only update chat lastMessage if this is the latest message
          if (latestMessage.id == messageId) {
            await updateChatLastMessage(
                chatId, message.copyWith(content: newContent));
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  // --- Notifications Collection Operations ---

  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(PerformanceConfig.maxNotificationsLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            return NotificationModel.fromMap(data);
          }).toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception(
          'Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  Future<void> deleteNotificationsByTypeAndUser(
    String userId,
    NotificationType type,
    String relatedUserId,
  ) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in notifications.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['data'] != null &&
            (data['data']['senderId'] == relatedUserId ||
                data['data']['userId'] == relatedUserId)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      print("Error deleting notifications: $e");
    }
  }

  Future<void> _removeNotificationForCancelledRequest(
    String receiverId,
    String senderId,
  ) async {
    try {
      await deleteNotificationsByTypeAndUser(
        receiverId,
        NotificationType.friendRequest,
        senderId,
      );
    } catch (e) {
      print('Error removing notification for cancelled request: $e');
    }
  }

  Future<void> restoreUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to restore unread count: ${e.toString()}');
    }
  }

  // --- Privacy Settings Operations ---

  Future<void> updateUserPrivacySettings(
    String userId,
    Map<String, dynamic> privacySettings,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(privacySettings);
    } catch (e) {
      throw Exception('Failed to update privacy settings: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getUserPrivacySettings(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'showLastSeen': data['showLastSeen'] ?? true,
          'readReceipts': data['readReceipts'] ?? true,
          'profilePhotoVisibility': data['profilePhotoVisibility'] ?? 'everyone',
          'bioVisibility': data['bioVisibility'] ?? 'everyone',
        };
      }
      return {
        'showLastSeen': true,
        'readReceipts': true,
        'profilePhotoVisibility': 'everyone',
        'bioVisibility': 'everyone',
      };
    } catch (e) {
      throw Exception('Failed to get privacy settings: ${e.toString()}');
    }
  }

  // --- Enhanced Blocking Operations ---

  /// Add user to blocked list in user document (for quick checks)
  Future<void> addToBlockedList(String currentUserId, String userIdToBlock) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([userIdToBlock])
      });
    } catch (e) {
      throw Exception('Failed to add to blocked list: ${e.toString()}');
    }
  }

  /// Remove user from blocked list in user document
  Future<void> removeFromBlockedList(String currentUserId, String userIdToUnblock) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([userIdToUnblock])
      });
    } catch (e) {
      throw Exception('Failed to remove from blocked list: ${e.toString()}');
    }
  }

  /// Check if user is in blocked list (quick check from user document)
  Future<bool> isInBlockedList(String currentUserId, String otherUserId) async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final blockedUsers = data['blockedUsers'] as List<dynamic>?;
        return blockedUsers?.contains(otherUserId) ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check blocked list: ${e.toString()}');
    }
  }

  /// Check if either user has blocked the other (bidirectional check)
  Future<bool> isBlockedBidirectional(String user1Id, String user2Id) async {
    try {
      // Check if user1 blocked user2
      final user1Blocked = await isUserBlocked(user1Id, user2Id);
      if (user1Blocked) return true;

      // Check if user2 blocked user1
      final user2Blocked = await isUserBlocked(user2Id, user1Id);
      return user2Blocked;
    } catch (e) {
      throw Exception('Failed to check bidirectional block: ${e.toString()}');
    }
  }

  /// Get list of blocked user IDs for a user
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final blockedUsers = data['blockedUsers'] as List<dynamic>?;
        return blockedUsers?.cast<String>() ?? [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get blocked users: ${e.toString()}');
    }
  }

  /// Stream of blocked user IDs (real-time updates)
  Stream<List<String>> getBlockedUsersStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final blockedUsers = data['blockedUsers'] as List<dynamic>?;
        return blockedUsers?.cast<String>() ?? [];
      }
      return [];
    });
  }
}














