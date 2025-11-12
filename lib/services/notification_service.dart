import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print('🔔 Background message received: ${message.messageId}');
    
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await notifications.initialize(initSettings);

    final data = message.data;
    final String type = data['type'] ?? '';
    String title = message.notification?.title ?? data['title'] ?? 'Notification';
    String body = message.notification?.body ?? data['body'] ?? '';

    // Build notification content based on type
    if (title.isEmpty || body.isEmpty) {
      switch (type) {
        case 'message':
          title = data['senderName'] ?? 'New Message';
          body = data['messageContent'] ?? data['preview'] ?? '';
          break;
        case 'friendRequest':
          title = 'Friend Request';
          body = '${data['senderName'] ?? 'Someone'} sent you a friend request';
          break;
        case 'friendAccepted':
          title = 'Friend Request Accepted';
          body = '${data['accepterName'] ?? 'Someone'} accepted your friend request';
          break;
      }
    }

    // Show high-priority notification
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );

    await notifications.show(
      _generateNotificationId(),
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: _createPayload(data),
    );
    
    print('✅ Background notification shown: $title');
  } catch (e) {
    print('❌ Error in background handler: $e');
  }
}

/// Main Notification Service - Handles all real-time notifications
class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channels
  static const String _messageChannelId = 'messages_channel';
  static const String _friendChannelId = 'friend_requests_channel';
  static const String _generalChannelId = 'general_channel';

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      print('🔔 Initializing Notification Service...');
      
      // Request permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Create notification channels
      await _createNotificationChannels();
      
      // Configure FCM handlers
      await _configureFCMHandlers();
      
      // Save FCM token to Firestore
      await _saveFCMToken();
      
      // Listen for token refresh
      _listenForTokenRefresh();
      
      print('✅ Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Notification Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request Android 13+ POST_NOTIFICATIONS permission
      final status = await Permission.notification.request();
      print('📱 Android notification permission status: $status');
      
      if (status.isDenied) {
        print('⚠️ Notification permission denied');
        Get.snackbar(
          'Notification Permission Required',
          'Please enable notifications to receive messages and friend requests',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
      }
      
      if (status.isPermanentlyDenied) {
        print('⚠️ Notification permission permanently denied');
        Get.snackbar(
          'Notification Permission Required',
          'Please enable notifications in app settings',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        );
      }
      
      // Request FCM permissions (iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        announcement: true,
      );
      
      print('📱 FCM permission status: ${settings.authorizationStatus}');
      
      // Set foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleNotificationTap,
    );
    
    print('✅ Local notifications initialized');
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Messages channel - High priority
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _messageChannelId,
            'Messages',
            description: 'Notifications for new messages',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
            enableLights: true,
          ),
        );
        
        // Friend requests channel - High priority
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _friendChannelId,
            'Friend Requests',
            description: 'Notifications for friend requests and acceptances',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
            enableLights: true,
          ),
        );
        
        // General channel - Default priority
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _generalChannelId,
            'General',
            description: 'General notifications',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );
        
        print('✅ Notification channels created');
      }
    } catch (e) {
      print('❌ Error creating notification channels: $e');
    }
  }

  /// Configure FCM message handlers
  Future<void> _configureFCMHandlers() async {
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📨 Foreground message received: ${message.data}');
      await _showLocalNotification(message);
    });
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped (background): ${message.data}');
      _navigateFromMessage(message.data);
    });
    
    // Handle notification tap when app is terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 Notification tapped (terminated): ${initialMessage.data}');
      // Delay navigation to ensure app is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        _navigateFromMessage(initialMessage.data);
      });
    }
    
    print('✅ FCM handlers configured');
  }

  /// Show local notification from FCM message
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final String type = data['type'] ?? '';
      String title = message.notification?.title ?? data['title'] ?? '';
      String body = message.notification?.body ?? data['body'] ?? '';
      
      // Build title and body based on type if not provided
      if (title.isEmpty || body.isEmpty) {
        switch (type) {
          case 'message':
            title = data['senderName'] ?? 'New Message';
            body = data['messageContent'] ?? data['preview'] ?? '';
            break;
          case 'friendRequest':
            title = 'Friend Request';
            body = '${data['senderName'] ?? 'Someone'} sent you a friend request';
            break;
          case 'friendAccepted':
            title = 'Friend Request Accepted';
            body = '${data['accepterName'] ?? 'Someone'} accepted your friend request';
            break;
          default:
            title = 'Notification';
            body = data['message'] ?? '';
        }
      }
      
      // Get profile image for message notifications
      Uint8List? largeIconBytes;
      if (type == 'message' && data['senderId'] != null) {
        largeIconBytes = await _downloadProfileImage(data['senderId']);
      } else if (type == 'friendRequest' && data['senderId'] != null) {
        largeIconBytes = await _downloadProfileImage(data['senderId']);
      } else if (type == 'friendAccepted' && data['accepterId'] != null) {
        largeIconBytes = await _downloadProfileImage(data['accepterId']);
      }
      
      // Build notification details
      final androidDetails = AndroidNotificationDetails(
        _getChannelId(type),
        _getChannelName(type),
        channelDescription: _getChannelDescription(type),
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        styleInformation: BigTextStyleInformation(body),
        largeIcon: largeIconBytes != null 
            ? ByteArrayAndroidBitmap(largeIconBytes) 
            : const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        category: type == 'message' 
            ? AndroidNotificationCategory.message 
            : AndroidNotificationCategory.social,
        visibility: NotificationVisibility.public,
        actions: type == 'friendRequest' ? [
          AndroidNotificationAction('accept_${data['senderId']}', 'Accept'),
          AndroidNotificationAction('decline_${data['senderId']}', 'Decline'),
        ] : null,
      );
      
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      
      await _notifications.show(
        _generateNotificationId(),
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: _createPayload(data),
      );
      
      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Download profile image for notification
  Future<Uint8List?> _downloadProfileImage(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final photoUrl = userData?['photoURL'] as String?;
      
      if (photoUrl != null && photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
        final response = await http.get(Uri.parse(photoUrl)).timeout(
          const Duration(seconds: 5),
        );
        if (response.statusCode == 200) {
          return Uint8List.fromList(response.bodyBytes);
        }
      }
    } catch (e) {
      print('❌ Error downloading profile image: $e');
    }
    return null;
  }

  /// Handle notification tap
  @pragma('vm:entry-point')
  static void _handleNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      print('🔔 Notification tapped with payload: $payload');
      
      if (payload == null) return;
      
      // Handle action buttons
      if (response.actionId != null && response.actionId!.isNotEmpty) {
        _handleNotificationAction(response.actionId!, payload);
        return;
      }
      
      // Parse payload and navigate
      final parts = payload.split(':');
      if (parts.isEmpty) return;
      
      final type = parts[0];
      _navigateFromPayload(parts, type);
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Handle notification action buttons
  static void _handleNotificationAction(String actionId, String payload) {
    try {
      if (actionId.startsWith('accept_')) {
        final senderId = actionId.substring(7);
        _acceptFriendRequest(senderId);
      } else if (actionId.startsWith('decline_')) {
        final senderId = actionId.substring(8);
        _declineFriendRequest(senderId);
      }
    } catch (e) {
      print('❌ Error handling notification action: $e');
    }
  }

  /// Accept friend request from notification
  static Future<void> _acceptFriendRequest(String senderId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await firestore
            .collection('friendRequests')
            .doc(querySnapshot.docs.first.id)
            .update({'status': 'accepted'});
        
        Get.snackbar(
          'Friend Request Accepted',
          'You are now friends!',
          snackPosition: SnackPosition.TOP,
        );
        
        print('✅ Friend request accepted from notification');
      }
    } catch (e) {
      print('❌ Error accepting friend request: $e');
    }
  }

  /// Decline friend request from notification
  static Future<void> _declineFriendRequest(String senderId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await firestore
            .collection('friendRequests')
            .doc(querySnapshot.docs.first.id)
            .update({'status': 'declined'});
        
        Get.snackbar(
          'Friend Request Declined',
          'Friend request declined',
          snackPosition: SnackPosition.TOP,
        );
        
        print('✅ Friend request declined from notification');
      }
    } catch (e) {
      print('❌ Error declining friend request: $e');
    }
  }

  /// Navigate from notification payload
  static void _navigateFromPayload(List<String> parts, String type) {
    try {
      switch (type) {
        case 'message':
          final chatId = parts.length > 1 ? parts[1] : '';
          final senderId = parts.length > 2 ? parts[2] : '';
          if (chatId.isNotEmpty && senderId.isNotEmpty) {
            Get.toNamed('/chat', arguments: {
              'chatId': chatId,
              'otherUserId': senderId,
            });
          }
          break;
        case 'friendRequest':
          Get.toNamed('/friend-requests');
          break;
        case 'friendAccepted':
          final userId = parts.length > 1 ? parts[1] : '';
          if (userId.isNotEmpty) {
            Get.toNamed('/chat', arguments: {
              'otherUserId': userId,
            });
          }
          break;
      }
    } catch (e) {
      print('❌ Error navigating from payload: $e');
    }
  }

  /// Navigate from FCM message data
  void _navigateFromMessage(Map<String, dynamic> data) {
    try {
      final type = data['type'] ?? '';
      
      switch (type) {
        case 'message':
          final chatId = data['chatId'] ?? _computeChatId(data['senderId']);
          final senderId = data['senderId'] ?? '';
          if (chatId != null && senderId.isNotEmpty) {
            Get.toNamed('/chat', arguments: {
              'chatId': chatId,
              'otherUserId': senderId,
            });
          }
          break;
        case 'friendRequest':
          Get.toNamed('/friend-requests');
          break;
        case 'friendAccepted':
          final userId = data['accepterId'] ?? data['userId'] ?? '';
          if (userId.isNotEmpty) {
            Get.toNamed('/chat', arguments: {
              'otherUserId': userId,
            });
          }
          break;
      }
    } catch (e) {
      print('❌ Error navigating from message: $e');
    }
  }

  /// Compute chat ID from sender ID
  String? _computeChatId(String? senderId) {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || senderId == null) return null;
      
      final participants = [currentUserId, senderId]..sort();
      return '${participants[0]}_${participants[1]}';
    } catch (e) {
      return null;
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      final userId = _auth.currentUser?.uid;
      
      if (token != null && userId != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('💾 FCM token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Listen for token refresh
  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).set({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          print('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
        }
      } catch (e) {
        print('❌ Error updating refreshed token: $e');
      }
    });
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      print('🗑️ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}

// Helper functions

String _getChannelId(String type) {
  switch (type) {
    case 'message':
      return NotificationService._messageChannelId;
    case 'friendRequest':
    case 'friendAccepted':
      return NotificationService._friendChannelId;
    default:
      return NotificationService._generalChannelId;
  }
}

String _getChannelName(String type) {
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

String _getChannelDescription(String type) {
  switch (type) {
    case 'message':
      return 'Notifications for new messages';
    case 'friendRequest':
    case 'friendAccepted':
      return 'Notifications for friend requests and acceptances';
    default:
      return 'General notifications';
  }
}

int _generateNotificationId() {
  return Random().nextInt(2147483647);
}

String _createPayload(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  
  switch (type) {
    case 'message':
      final chatId = data['chatId'] ?? '';
      final senderId = data['senderId'] ?? '';
      return 'message:$chatId:$senderId';
    case 'friendRequest':
      final senderId = data['senderId'] ?? '';
      return 'friendRequest:$senderId';
    case 'friendAccepted':
      final userId = data['accepterId'] ?? data['userId'] ?? '';
      return 'friendAccepted:$userId';
    default:
      return 'general:';
  }
}
