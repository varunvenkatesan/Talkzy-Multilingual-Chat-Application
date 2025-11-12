import 'dart:async';
import 'dart:typed_data'; // Add this import for Int64List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/services/notification_handler.dart';

class RealtimeNotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions for real-time listeners
  StreamSubscription? _messageSubscription;
  StreamSubscription? _friendRequestSubscription;
  StreamSubscription? _friendAcceptSubscription;
  StreamSubscription? _authStateSubscription;

  // Notification channels
  static const String _messageChannelId = 'messages';
  static const String _friendChannelId = 'friend_requests';
  
  // Remove const from these declarations since they contain non-const values
  static final AndroidNotificationDetails _messageChannel = AndroidNotificationDetails(
    _messageChannelId,
    'Messages',
    channelDescription: 'Notifications for new messages',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern
    sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
    styleInformation: BigTextStyleInformation(''),
    playSound: true, // Ensure sound plays
  );

  static final AndroidNotificationDetails _friendChannel = AndroidNotificationDetails(
    _friendChannelId,
    'Friend Requests',
    channelDescription: 'Notifications for friend requests and acceptances',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern
    sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
    styleInformation: BigTextStyleInformation(''),
    playSound: true, // Ensure sound plays
    // Add action buttons for friend requests
    actions: [
      AndroidNotificationAction('accept', 'Accept'),
      AndroidNotificationAction('ignore', 'Ignore'),
    ],
  );

  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Listen for auth state changes to restart listeners when user changes
      _authStateSubscription = _auth.authStateChanges().listen((User? user) {
        print('Auth state changed, user: ${user?.uid}');
        // Cancel existing subscriptions
        _cancelSubscriptions();
        
        // Restart listeners if user is authenticated
        if (user != null) {
          _startMessageListener();
          _startFriendRequestListener();
          _startFriendAcceptListener();
        }
      });

      // Start real-time listeners if user is already authenticated
      if (_auth.currentUser != null) {
        _startMessageListener();
        _startFriendRequestListener();
        _startFriendAcceptListener();
      }
    } catch (e) {
      print('Error initializing RealtimeNotificationService: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        // Handle notification actions
        onDidReceiveBackgroundNotificationResponse: _onNotificationBackgroundTap,
      );
      
      // Create notification channels
      await _createNotificationChannels();
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }
  
  Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Create message channel with sound and vibration
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _messageChannelId,
            'Messages',
            description: 'Notifications for new messages',
            importance: Importance.high,
            enableVibration: true,
            // Note: AndroidNotificationChannel doesn't support custom vibration patterns or sounds in the same way
          ),
        );
        
        // Create friend request channel with sound and vibration
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _friendChannelId,
            'Friend Requests',
            description: 'Notifications for friend requests and acceptances',
            importance: Importance.high,
            enableVibration: true,
            // Note: AndroidNotificationChannel doesn't support custom vibration patterns or sounds in the same way
          ),
        );
      }
    } catch (e) {
      print('Error creating notification channels: $e');
    }
  }

  void _startMessageListener() {
    try {
      final userId = _auth.currentUser?.uid;
      print('Starting message listener, current user ID: $userId');
      if (userId == null) {
        print('No current user, returning');
        return;
      }

      print('Setting up message listener for user: $userId');

      _messageSubscription = _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          // Remove the isRead filter to catch all new messages
          .snapshots()
          .listen((snapshot) async {
        print('Message snapshot received with ${snapshot.docChanges.length} changes');
        for (var change in snapshot.docChanges) {
          print('Processing change of type: ${change.type}');
          if (change.type == DocumentChangeType.added) {
            final message = change.doc.data();
            print('New message added: $message');
            if (message == null) {
              print('Message data is null, skipping');
              continue;
            }

            // Log the message details
            print('Message details - ID: ${change.doc.id}, receiverId: ${message['receiverId']}, senderId: ${message['senderId']}');
            
            // Only show notification for unread messages
            // Check if isRead field exists and is true
            if (message.containsKey('isRead') && message['isRead'] == true) {
              print('Message is already read, skipping notification');
              continue;
            }
            
            print('Message is unread, preparing notification');

            try {
              print('Getting sender information for senderId: ${message['senderId']}');
              // Get sender's information
              final senderDoc = await _firestore.collection('users').doc(message['senderId']).get();
              final senderData = senderDoc.data();
              print('Sender data: $senderData');
              final senderName = senderData?['displayName'] ?? senderData?['name'] ?? 'Someone';
              print('Sender name: $senderName');
              // Remove the profile image for now to avoid potential issues
              // final senderPhotoUrl = senderData?['photoURL'] ?? '';

              // Create notification with sound and vibration
              final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
                _messageChannelId,
                'Messages',
                channelDescription: 'Notifications for new messages',
                importance: Importance.high,
                priority: Priority.high,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern
                sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
                styleInformation: BigTextStyleInformation(message['content'] ?? ''),
                playSound: true, // Ensure sound plays
                // Remove profile image for now
                // largeIcon: senderPhotoUrl.isNotEmpty 
                //     ? FilePathAndroidBitmap(senderPhotoUrl) 
                //     : const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              );

              print('Showing notification with title: $senderName, body: ${message['content']}');
              // Show notification
              await _notifications.show(
                change.doc.id.hashCode,
                senderName,
                message['content'],
                NotificationDetails(
                  android: androidPlatformChannelSpecifics,
                  iOS: const DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  ),
                ),
                payload: 'message:${message['chatId']}:${message['senderId']}',
              );
              print('Notification shown successfully');
            } catch (e) {
              print('Error showing message notification: $e');
            }
          }
        }
      }, onError: (error) {
        print('Error in message listener: $error');
      });
    } catch (e) {
      print('Error starting message listener: $e');
    }
  }

  void _startFriendRequestListener() {
    try {
      final userId = _auth.currentUser?.uid;
      print('Starting friend request listener, current user ID: $userId');
      if (userId == null) {
        print('No current user, returning');
        return;
      }

      _friendRequestSubscription = _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) async {
        print('Friend request snapshot received with ${snapshot.docChanges.length} changes');
        for (var change in snapshot.docChanges) {
          print('Processing friend request change of type: ${change.type}');
          if (change.type == DocumentChangeType.added) {
            final request = change.doc.data();
            print('New friend request added: $request');
            if (request == null) {
              print('Friend request data is null, skipping');
              continue;
            }

            try {
              print('Getting requester information for senderId: ${request['senderId']}');
              // Get requester's information
              final requesterDoc = await _firestore.collection('users').doc(request['senderId']).get();
              final requesterData = requesterDoc.data();
              print('Requester data: $requesterData');
              final requesterName = requesterData?['displayName'] ?? requesterData?['name'] ?? 'Someone';
              print('Requester name: $requesterName');

              // Create notification with action buttons, sound and vibration
              final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
                _friendChannelId,
                'Friend Requests',
                channelDescription: 'Notifications for friend requests and acceptances',
                importance: Importance.high,
                priority: Priority.high,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern
                sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
                styleInformation: BigTextStyleInformation('$requesterName wants to connect with you'),
                playSound: true, // Ensure sound plays
                // Add action buttons
                actions: [
                  AndroidNotificationAction('accept_${request['senderId']}', 'Accept'),
                  AndroidNotificationAction('ignore_${request['senderId']}', 'Ignore'),
                ],
              );

              print('Showing friend request notification');
              // Show notification
              await _notifications.show(
                change.doc.id.hashCode,
                'New Friend Request',
                '$requesterName wants to connect with you',
                NotificationDetails(
                  android: androidPlatformChannelSpecifics,
                  iOS: const DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  ),
                ),
                payload: 'friendRequest:${request['senderId']}',
              );
              print('Friend request notification shown successfully');
            } catch (e) {
              print('Error showing friend request notification: $e');
            }
          }
        }
      }, onError: (error) {
        print('Error in friend request listener: $error');
      });
    } catch (e) {
      print('Error starting friend request listener: $e');
    }
  }

  void _startFriendAcceptListener() {
    try {
      final userId = _auth.currentUser?.uid;
      print('Starting friend accept listener, current user ID: $userId');
      if (userId == null) {
        print('No current user, returning');
        return;
      }

      _friendAcceptSubscription = _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots()
          .listen((snapshot) async {
        print('Friend accept snapshot received with ${snapshot.docChanges.length} changes');
        for (var change in snapshot.docChanges) {
          print('Processing friend accept change of type: ${change.type}');
          if (change.type == DocumentChangeType.modified) {
            final request = change.doc.data();
            print('Friend request modified: $request');
            if (request == null) {
              print('Friend request data is null, skipping');
              continue;
            }

            try {
              print('Getting accepter information for receiverId: ${request['receiverId']}');
              // Get accepter's information
              final accepterDoc = await _firestore.collection('users').doc(request['receiverId']).get();
              final accepterData = accepterDoc.data();
              print('Accepter data: $accepterData');
              final accepterName = accepterData?['displayName'] ?? accepterData?['name'] ?? 'Someone';
              print('Accepter name: $accepterName');

              // Create notification for accepted friend request with sound and vibration
              final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
                _friendChannelId,
                'Friend Requests',
                channelDescription: 'Notifications for friend requests and acceptances',
                importance: Importance.high,
                priority: Priority.high,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern
                sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
                styleInformation: BigTextStyleInformation('$accepterName accepted your friend request'),
                playSound: true, // Ensure sound plays
              );

              print('Showing friend accept notification');
              // Show notification
              await _notifications.show(
                change.doc.id.hashCode,
                'Friend Request Accepted',
                '$accepterName accepted your friend request',
                NotificationDetails(
                  android: androidPlatformChannelSpecifics,
                  iOS: const DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  ),
                ),
                payload: 'friendAccepted:${request['receiverId']}',
              );
              print('Friend accept notification shown successfully');
            } catch (e) {
              print('Error showing friend accept notification: $e');
            }
          }
        }
      }, onError: (error) {
        print('Error in friend accept listener: $error');
      });
    } catch (e) {
      print('Error starting friend accept listener: $e');
    }
  }

  void _cancelSubscriptions() {
    print('Cancelling all subscriptions');
    _messageSubscription?.cancel();
    _friendRequestSubscription?.cancel();
    _friendAcceptSubscription?.cancel();
    _messageSubscription = null;
    _friendRequestSubscription = null;
    _friendAcceptSubscription = null;
  }

  void _onNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      print('Notification tapped with payload: $payload');
      if (payload == null) {
        print('No payload in notification response');
        return;
      }

      // Handle action buttons
      if (response.actionId != null) {
        print('Notification action tapped: ${response.actionId}');
        _handleNotificationAction(response.actionId!, payload);
        return;
      }

      final parts = payload.split(':');
      if (parts.length < 2) {
        print('Invalid payload format');
        return;
      }

      final type = parts[0];
      final id = parts[1];
      print('Handling notification of type: $type with id: $id');

      switch (type) {
        case 'message':
          final chatId = parts.length > 2 ? parts[1] : '';
          final senderId = parts.length > 2 ? parts[2] : '';
          print('Navigating to chat with chatId: $chatId, senderId: $senderId');
          Get.toNamed('/chat', arguments: {'chatId': chatId, 'otherUserId': senderId});
          break;
        case 'friendRequest':
          print('Navigating to friend requests');
          Get.toNamed('/friend-requests');
          break;
        case 'friendAccepted':
          print('Navigating to profile with userId: $id');
          Get.toNamed('/profile', arguments: {'userId': id});
          break;
        default:
          print('Unknown notification type: $type');
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  void _handleNotificationAction(String actionId, String payload) {
    try {
      print('Handling notification action: $actionId with payload: $payload');
      if (actionId.startsWith('accept_')) {
        final senderId = actionId.substring(7); // Remove 'accept_' prefix
        print('Accepting friend request from senderId: $senderId');
        // Handle accept action
        NotificationHandler.acceptFriendRequest(senderId);
      } else if (actionId.startsWith('ignore_')) {
        final senderId = actionId.substring(7); // Remove 'ignore_' prefix
        print('Ignoring friend request from senderId: $senderId');
        // Handle ignore action
        NotificationHandler.ignoreFriendRequest(senderId);
      }
    } catch (e) {
      print('Error handling notification action: $e');
    }
  }

  void _onNotificationBackgroundTap(NotificationResponse response) {
    try {
      print('Background notification tapped');
      // Handle background notification taps
      _onNotificationTap(response);
    } catch (e) {
      print('Error handling background notification tap: $e');
    }
  }

  @override
  void onClose() {
    print('RealtimeNotificationService closing, cancelling subscriptions');
    _cancelSubscriptions();
    _authStateSubscription?.cancel();
    super.onClose();
  }
}