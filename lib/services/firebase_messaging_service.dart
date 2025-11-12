import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



// Background handler must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized in background isolate
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // no-op if already initialized by native code
    }

    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await notifications.initialize(initSettings);

    // Build notification details from message
    final data = message.data;
    final String type = data['type'] ?? '';
    final String title = message.notification?.title ?? data['title'] ?? 'Notification';
    final String body = message.notification?.body ?? data['body'] ?? '';
final token = await FirebaseMessaging.instance.getToken();
print('FCM token: $token'); 

    final androidDetails = AndroidNotificationDetails(
      _channelIdForType(type),
      _channelNameForType(type),
      channelDescription: _channelDescForType(type),
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await notifications.show(
      _randomId(),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      payload: _payloadFromData(data),
    );
  } catch (_) {}
}

class FirebaseMessagingService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _configureFCMHandlers();
    await _logFCMToken();
  }

  Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  Future<void> _initializeLocalNotifications() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _notifications.initialize(settings, onDidReceiveNotificationResponse: _onNotificationTap, onDidReceiveBackgroundNotificationResponse: _onNotificationTap);
  }

  Future<void> _configureFCMHandlers() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Show a local notification when a message is received in foreground
      await _showLocalFromRemote(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _openFromData(message.data);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _openFromData(initial.data);
    }
  }

  Future<void> _showLocalFromRemote(RemoteMessage message) async {
    final data = message.data;
    final String type = data['type'] ?? '';
    String title = message.notification?.title ?? data['title'] ?? '';
    String body = message.notification?.body ?? data['body'] ?? '';

    // Derive title/body when only data is sent
    if (title.isEmpty || body.isEmpty) {
      switch (type) {
        case 'message':
          title = data['senderName'] ?? 'New message';
          body = data['preview'] ?? '';
          break;
        case 'friendRequest':
          title = 'New Friend Request';
          body = '${data['senderName'] ?? 'Someone'} wants to connect with you';
          break;
        case 'friendAccepted':
          title = 'Friend Request Accepted';
          body = '${data['name'] ?? 'Someone'} accepted your friend request';
          break;
        default:
          title = 'Notification';
          body = data['message'] ?? '';
      }
    }

    final androidDetails = AndroidNotificationDetails(
      _channelIdForType(type),
      _channelNameForType(type),
      channelDescription: _channelDescForType(type),
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(body),
      actions: type == 'friendRequest'
          ? [
              AndroidNotificationAction('accept_${data['senderId']}', 'Accept'),
              AndroidNotificationAction('ignore_${data['senderId']}', 'Ignore'),
            ]
          : null,
    );

    await _notifications.show(
      _randomId(),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
      payload: _payloadFromData({
        ...data,
        'chatId': _chatIdFromData(data) ?? data['chatId'],
      }),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Handle action buttons for friend request
    if (response.actionId != null && response.actionId!.isNotEmpty) {
      final actionId = response.actionId!;
      if (actionId.startsWith('accept_')) {
        final senderId = actionId.substring(7);
        _acceptFriendRequest(senderId);
        return;
      }
      if (actionId.startsWith('ignore_')) {
        final senderId = actionId.substring(7);
        _ignoreFriendRequest(senderId);
        return;
      }
    }

    final parts = payload.split(':');
    if (parts.isEmpty) return;
    final type = parts[0];
    _navigateFromPayloadParts(parts, type);
  }

  void _openFromData(Map<String, dynamic> data) async {
    final type = data['type'];
    switch (type) {
      case 'message': {
        final computedChatId = _chatIdFromData(data) ?? data['chatId'];
        final otherUserId = data['senderId'] ?? await _otherUserFromChat(computedChatId);
        Get.toNamed('/chat', arguments: {'chatId': computedChatId, 'otherUserId': otherUserId});
        break;
      }
      case 'friendRequest':
        Get.toNamed('/friend-requests');
        break;
      case 'friendAccepted':
        Get.toNamed('/profile', arguments: {'userId': data['userId'] ?? data['receiverId']});
        break;
      default:
        break;
    }
  }

  void _navigateFromPayloadParts(List<String> parts, String type) {
    switch (type) {
      case 'message':
        final chatId = parts.length > 1 ? parts[1] : '';
        final senderId = parts.length > 2 ? parts[2] : '';
        Get.toNamed('/chat', arguments: {'chatId': chatId, 'otherUserId': senderId});
        break;
      case 'friendRequest':
        Get.toNamed('/friend-requests');
        break;
      case 'friendAccepted':
        final userId = parts.length > 1 ? parts[1] : '';
        Get.toNamed('/profile', arguments: {'userId': userId});
        break;
      default:
        break;
    }
  }

  Future<void> _acceptFriendRequest(String senderId) async {
    try {
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
      await _firestore.collection('friendRequests').doc(qs.docs.first.id).update({'status': 'accepted'});
    } catch (_) {}
  }

  Future<void> _ignoreFriendRequest(String senderId) async {
    try {
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
    } catch (_) {}
  }

  Future<void> _logFCMToken() async {
    try {
      final token = await _messaging.getToken();
      final uid = _auth.currentUser?.uid;
      if (uid != null && token != null) {
        await _firestore.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (_) {}
  }
}

int _randomId() => Random().nextInt(1 << 31);

String _payloadFromData(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  switch (type) {
    case 'message':
      final chatId = data['chatId'] ?? _chatIdFromData(data) ?? '';
      return 'message:$chatId:${data['senderId'] ?? ''}';
    case 'friendRequest':
      return 'friendRequest:${data['senderId'] ?? ''}';
    case 'friendAccepted':
      return 'friendAccepted:${data['userId'] ?? data['receiverId'] ?? ''}';
    default:
      return 'generic:';
  }
}

String? _chatIdFromData(Map<String, dynamic> data) {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String? current = auth.currentUser?.uid;
    final String? other = data['senderId'] as String?;
    if (current == null || other == null || other.isEmpty) return null;
    final participants = [current, other]..sort();
    return '${participants[0]}_${participants[1]}';
  } catch (_) {
    return null;
  }
}

Future<String?> _otherUserFromChat(String? chatId) async {
  try {
    if (chatId == null || chatId.isEmpty) return null;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String? current = auth.currentUser?.uid;
    if (current == null) return null;
    final FirebaseFirestore fs = FirebaseFirestore.instance;
    final doc = await fs.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> participants = (data['participants'] as List<dynamic>? ) ?? const [];
    for (final p in participants) {
      if (p is String && p != current) return p;
    }
    return null;
  } catch (_) {
    return null;
  }
}

String _channelIdForType(String type) {
  switch (type) {
    case 'message':
      return 'messages';
    case 'friendRequest':
    case 'friendAccepted':
      return 'friend_requests';
    default:
      return 'general';
  }
}

String _channelNameForType(String type) {
  switch (type) {
    case 'message':
      return 'Messages';
    case 'friendRequest':
    case 'friendAccepted':
      return 'Friend Requests';
    default:
      return 'General';
  }
}

String _channelDescForType(String type) {
  switch (type) {
    case 'message':
      return 'Notifications for new messages';
    case 'friendRequest':
    case 'friendAccepted':
      return 'Notifications for friend requests and updates';
    default:
      return 'General notifications';
  }
}


