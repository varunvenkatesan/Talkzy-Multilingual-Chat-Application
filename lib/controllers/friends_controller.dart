import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/friend_requests_controller.dart';
import 'package:talkzy_beta1/models/friendship_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';

class FriendsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  // Find FriendRequestsController to get the unread count (must be bound first)
  late final FriendRequestsController _friendRequestsController =
      Get.find<FriendRequestsController>();

  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;
  final RxList<UserModel> _friends = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxList<UserModel> _filteredFriends = <UserModel>[].obs;

  StreamSubscription? _friendshipsSubscriptions;

  // Getters
  List<FriendshipModel> get friendships => _friendships.toList();
  List<UserModel> get friends => _friends;
  List<UserModel> get filteredFriends => _filteredFriends;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;

  // Calculates pending requests count for the badge
  RxInt get newRequestsCount => _friendRequestsController.receivedRequests
      .where((r) => r.status.name == 'pending')
      .length
      .obs;

  StreamSubscription? _friendsStatusSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadFriends();
    _setupFriendsStatusListener();

    // Debounce search query changes
    debounce(
      _searchQuery,
      (_) => _filterFriends(),
      time: const Duration(milliseconds: 300),
    );
  }

  void _setupFriendsStatusListener() {
    // Listen for real-time updates to friend statuses
    _friendsStatusSubscription =
        _firestoreService.getAllUserStream().listen((users) {
      final currentFriendIds = _friends.map((f) => f.id).toSet();

      // Update existing friends with new status
      for (var user in users) {
        if (currentFriendIds.contains(user.id)) {
          final index = _friends.indexWhere((f) => f.id == user.id);
          if (index != -1) {
            _friends[index] = user;
          }
        }
      }

      // Force UI update
      _friends.refresh();
    });

    // Filter whenever the source list or query changes
    ever(_friends, (_) => _filterFriends());
    ever(_searchQuery, (_) => _filterFriends());
  }

  @override
  void onClose() {
    _friendshipsSubscriptions?.cancel();
    super.onClose();
  }

  void _loadFriends() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _friendshipsSubscriptions?.cancel();

      // Listen to friendship list changes
      _friendshipsSubscriptions = _firestoreService
          .getFriendsStream(currentUserId)
          .listen((friendshipList) {
        _friendships.value = friendshipList;
        _loadFriendDetails(currentUserId, friendshipList);
      });
    }
  }

  Future<void> _loadFriendDetails(
      String currentUserId, List<FriendshipModel> friendshipList) async {
    try {
      if (_friends.isEmpty) {
        _isLoading.value = true;
      }

      List<UserModel> friendUsers = [];

      // Use Future.wait to fetch user details efficiently (using single-shot read for simplicity)
      final futures = friendshipList.map((friendship) async {
        String friendId = friendship.getOtherUserId(currentUserId);
        return await _firestoreService.getUser(friendId);
      }).toList();

      final results = await Future.wait(futures);

      for (var friend in results) {
        if (friend != null) {
          friendUsers.add(friend);
        }
      }

      _friends.value = friendUsers;
      _filterFriends();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  void _filterFriends() {
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      // Show all friends if no search query
      _filteredFriends.value = _friends;
    } else {
      // Filter by display name or email
      _filteredFriends.value = _friends.where((friend) {
        return friend.displayName.toLowerCase().contains(query) ||
            friend.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearch() {
    _searchQuery.value = '';
  }

  Future<void> refreshFriends() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _isLoading.value = true;
      _loadFriends();
    }
  }

  Future<void> removeFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Remove Friend'),
          content: Text(
              'Are you sure you want to remove ${friend.displayName} from your friends?'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Remove'),
            )
          ],
        ),
      );

      if (result == true) {
        final currentUserId = _authController.user?.uid;
        if (currentUserId != null) {
          await _firestoreService.removeFriendship(currentUserId, friend.id);
          Get.snackbar(
            'Success',
            '${friend.displayName} has been removed from your friends.',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove friend',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
      print(e.toString());
    }
  }

  Future<void> blockFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Block User'),
          content: Text(
              'Are you sure you want to block ${friend.displayName}? You will no longer be able to chat with them.'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (result == true) {
        final currentUserId = _authController.user?.uid;
        if (currentUserId != null) {
          await _firestoreService.blockUser(currentUserId, friend.id);
          Get.snackbar(
            'Success',
            '${friend.displayName} has been blocked',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        'Failed to block user',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
      print(e.toString());
    }
  }

  Future<void> unblockFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Unblock User'),
          content: Text(
              'Are you sure you want to unblock ${friend.displayName}? You will be able to chat with them again.'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Unblock'),
            ),
          ],
        ),
      );
      if (result == true) {
        final currentUserId = _authController.user?.uid;
        if (currentUserId != null) {
          await _firestoreService.unblockUser(currentUserId, friend.id);
          Get.snackbar(
            'Success',
            '${friend.displayName} has been unblocked',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        'Failed to unblock user',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
      print(e.toString());
    }
  }

  // Check if a friend is blocked
  bool isFriendBlocked(UserModel friend) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return false;
    
    final friendship = _friendships.firstWhereOrNull(
      (f) => (f.user1Id == currentUserId && f.user2Id == friend.id) ||
             (f.user2Id == currentUserId && f.user1Id == friend.id)
    );
    
    return friendship?.isBlocked == true && friendship?.blockedBy == currentUserId;
  }

  Future<void> startChat(UserModel friend) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        Get.toNamed(
          AppRoutes.chat,
          arguments: {
            'chatId': null,
            'otherUser': friend,
            'isNewChat': true,
          },
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start chat',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  String getLastSeenText(UserModel user) {
    // Use PrivacyHelper to respect user's privacy settings
    return PrivacyHelper.getOnlineStatusText(user);
  }

  void openFriendRequests() {
    Get.toNamed(AppRoutes.friendRequests);
  }

  void clearError() {
    _error.value = '';
  }
}
