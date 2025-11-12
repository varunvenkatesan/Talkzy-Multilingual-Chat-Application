import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// 100% FREE Notification Service - No Cloud Functions Required!
/// Sends notifications directly from the app using FCM REST API
class FreeNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Cloud Messaging - Using direct FCM endpoint
  // TODO: Replace with your actual FCM Server Key from Firebase Console
  // Get it from: Firebase Console > Project Settings > Cloud Messaging > Server Key
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  /// Send a message notification
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String messageContent,
    required String chatId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;

      final receiverData = receiverDoc.data();
      final fcmToken = receiverData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Receiver has no FCM token');
        return;
      }

      // Get sender's profile picture
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();
      final senderPhotoUrl = senderData?['photoURL'] ?? '';

      // Create notification payload
      final payload = {
        'to': fcmToken,
        'priority': 'high',
        'notification': {
          'title': senderName,
          'body': messageContent.length > 100 
              ? '${messageContent.substring(0, 100)}...' 
              : messageContent,
          'sound': 'default',
          'badge': '1',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'data': {
          'type': 'message',
          'senderId': senderId,
          'senderName': senderName,
          'messageContent': messageContent,
          'chatId': chatId,
          'senderPhotoUrl': senderPhotoUrl,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'messages_channel',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': senderName,
                'body': messageContent,
              },
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      // Send notification via FCM REST API
      await _sendFCMNotification(payload);
      print('✅ Message notification sent to $receiverId');
    } catch (e) {
      print('❌ Error sending message notification: $e');
    }
  }

  /// Send a friend request notification
  Future<void> sendFriendRequestNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;

      final receiverData = receiverDoc.data();
      final fcmToken = receiverData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Receiver has no FCM token');
        return;
      }

      // Get sender's profile picture
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();
      final senderPhotoUrl = senderData?['photoURL'] ?? '';

      // Create notification payload
      final payload = {
        'to': fcmToken,
        'priority': 'high',
        'notification': {
          'title': 'New Friend Request',
          'body': '$senderName sent you a friend request',
          'sound': 'default',
          'badge': '1',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'data': {
          'type': 'friendRequest',
          'senderId': senderId,
          'senderName': senderName,
          'senderPhotoUrl': senderPhotoUrl,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'friend_requests_channel',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': 'New Friend Request',
                'body': '$senderName sent you a friend request',
              },
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      // Send notification via FCM REST API
      await _sendFCMNotification(payload);
      print('✅ Friend request notification sent to $receiverId');
    } catch (e) {
      print('❌ Error sending friend request notification: $e');
    }
  }

  /// Send a friend request accepted notification
  Future<void> sendFriendAcceptedNotification({
    required String senderId,
    required String accepterId,
    required String accepterName,
  }) async {
    try {
      // Get sender's (original requester) FCM token
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      if (!senderDoc.exists) return;

      final senderData = senderDoc.data();
      final fcmToken = senderData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Sender has no FCM token');
        return;
      }

      // Get accepter's profile picture
      final accepterDoc = await _firestore.collection('users').doc(accepterId).get();
      final accepterData = accepterDoc.data();
      final accepterPhotoUrl = accepterData?['photoURL'] ?? '';

      // Create notification payload
      final payload = {
        'to': fcmToken,
        'priority': 'high',
        'notification': {
          'title': 'Friend Request Accepted',
          'body': '$accepterName accepted your friend request',
          'sound': 'default',
          'badge': '1',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'data': {
          'type': 'friendAccepted',
          'accepterId': accepterId,
          'accepterName': accepterName,
          'userId': accepterId,
          'accepterPhotoUrl': accepterPhotoUrl,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'friend_requests_channel',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': 'Friend Request Accepted',
                'body': '$accepterName accepted your friend request',
              },
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      // Send notification via FCM REST API
      await _sendFCMNotification(payload);
      print('✅ Friend accepted notification sent to $senderId');
    } catch (e) {
      print('❌ Error sending friend accepted notification: $e');
    }
  }

  /// Send FCM notification using REST API
  Future<void> _sendFCMNotification(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ FCM notification sent successfully');
      } else {
        print('❌ FCM notification failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
    }
  }
}
