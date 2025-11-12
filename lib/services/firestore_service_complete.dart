import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:talkzy_beta1/models/chat_model.dart';
import 'package:talkzy_beta1/models/friend_request_model.dart';
import 'package:talkzy_beta1/models/friendship_model.dart';
import 'package:talkzy_beta1/models/message_model.dart';
import 'package:talkzy_beta1/models/notification_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['lastSeen'] is Timestamp) {
          data['lastSeen'] = (data['lastSeen'] as Timestamp).millisecondsSinceEpoch;
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
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
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
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      if (data['lastSeen'] is Timestamp) {
        data['lastSeen'] = (data['lastSeen'] as Timestamp).millisecondsSinceEpoch;
      }
      return UserModel.fromMap(data);
    });
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Stream<List<UserModel>> getAllUserStream() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          if (data['lastSeen'] is Timestamp) {
            data['lastSeen'] = (data['lastSeen'] as Timestamp).millisecondsSinceEpoch;
          }
          return UserModel.fromMap(data);
        }).toList());
  }

  // ==================== CHAT OPERATIONS ====================

  Future<String> createOrGetChat(String user1Id, String user2Id) async {
    try {
      final chatId = _generateChatId(user1Id, user2Id);
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        final chat = ChatModel(
          id: chatId,
          participants: [user1Id, user2Id],
          unreadCount: {user1Id: 0, user2Id: 0},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore.collection('chats').doc(chatId).set(chat.toMap());
      }
      return chatId;
    } catch (e) {
      throw Exception('Failed to create or get chat: ${e.toString()}');
    }
  }

  String _generateChatId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data['lastMessageTime'] is Timestamp) {
                data['lastMessageTime'] = (data['lastMessageTime'] as Timestamp).millisecondsSinceEpoch;
              }
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
              }
              if (data['updatedAt'] is Timestamp) {
                data['updatedAt'] = (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
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
            .where((chat) => chat.deletedBy[userId] != true)
            .toList());
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': true,
        'deletedAt.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  Future<bool> isUnfriended(String user1Id, String user2Id) async {
    try {
      final friendshipId = _generateChatId(user1Id, user2Id);
      final doc = await _firestore.collection('friendships').doc(friendshipId).get();
      return !doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last seen: ${e.toString()}');
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

  // ==================== MESSAGE OPERATIONS ====================

  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore.collection('messages').doc(message.id).set(message.toMap());

      final otherUserId = message.receiverId;
      await _firestore.collection('chats').doc(message.chatId).update({
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<MessageModel>> getMessagesStreamByChatId(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              if (!data.containsKey('id') || data['id'] == null || (data['id'] as String).isEmpty) {
                data['id'] = doc.id;
              }
              if (!data.containsKey('chatId') || data['chatId'] == null || (data['chatId'] as String).isEmpty) {
                data['chatId'] = chatId;
              }
              return MessageModel.fromMap(data);
            })
            .toList());
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  // ==================== FRIEND REQUEST OPERATIONS ====================

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      await _firestore.collection('friendRequests').doc(request.id).set(request.toMap());

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: request.receiverId,
        title: 'New Friend Request',
        body: 'You have a new friend request',
        type: NotificationType.friendRequest,
        data: {'requestId': request.id, 'senderId': request.senderId},
        createdAt: DateTime.now(),
      );
      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to send friend request: ${e.toString()}');
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
              }
              if (data['respondedAt'] is Timestamp) {
                data['respondedAt'] = (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
              }
              return FriendRequestModel.fromMap(data);
            })
            .toList());
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
              }
              if (data['respondedAt'] is Timestamp) {
                data['respondedAt'] = (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
              }
              return FriendRequestModel.fromMap(data);
            })
            .toList());
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to cancel friend request: ${e.toString()}');
    }
  }

  Future<void> respondToFriendRequest(String requestId, FriendRequestStatus status) async {
    try {
      final requestDoc = await _firestore.collection('friendRequests').doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Friend request not found');

      final data = requestDoc.data()!;
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
      }
      if (data['respondedAt'] is Timestamp) {
        data['respondedAt'] = (data['respondedAt'] as Timestamp).millisecondsSinceEpoch;
      }
      final request = FriendRequestModel.fromMap(data);

      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': status.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (status == FriendRequestStatus.accepted) {
        final friendshipId = _generateChatId(request.senderId, request.receiverId);
        final friendship = FriendshipModel(
          id: friendshipId,
          user1Id: request.senderId,
          user2Id: request.receiverId,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('friendships').doc(friendshipId).set(friendship.toMap());

        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: request.senderId,
          title: 'Friend Request Accepted',
          body: 'Your friend request was accepted',
          type: NotificationType.friendRequestAccepted,
          data: {'userId': request.receiverId},
          createdAt: DateTime.now(),
        );
        await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
      }
    } catch (e) {
      throw Exception('Failed to respond to friend request: ${e.toString()}');
    }
  }

  // ==================== FRIENDSHIP OPERATIONS ====================

  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .switchMap((snapshot1) {
      return _firestore
          .collection('friendships')
          .where('user2Id', isEqualTo: userId)
          .snapshots()
          .map((snapshot2) {
        final allDocs = [...snapshot1.docs, ...snapshot2.docs];
        return allDocs
            .map((doc) {
              final data = doc.data();
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
              }
              return FriendshipModel.fromMap(data);
            })
            .where((friendship) => !friendship.isBlocked)
            .toList();
      });
    });
  }

  Future<void> removeFriendship(String user1Id, String user2Id) async {
    try {
      final friendshipId = _generateChatId(user1Id, user2Id);
      await _firestore.collection('friendships').doc(friendshipId).delete();

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user2Id,
        title: 'Friend Removed',
        body: 'A friend has removed you from their friends list',
        type: NotificationType.friendRemoved,
        data: {'userId': user1Id},
        createdAt: DateTime.now(),
      );
      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to remove friendship: ${e.toString()}');
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      final friendshipId = _generateChatId(blockerId, blockedId);
      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final friendshipId = _generateChatId(blockerId, blockedId);
      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  // ==================== NOTIFICATION OPERATIONS ====================

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
              }
              return NotificationModel.fromMap(data);
            })
            .toList());
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
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }
}
