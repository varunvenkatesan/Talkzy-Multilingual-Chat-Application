

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/models/friend_request_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';

class FriendRequestsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>(); 
  
  // Observable lists and map
  final RxList<FriendRequestModel> _receivedRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  
  // State variables
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _selectedTabIndex = 0.obs;

  // Getters
  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get selectedTabIndex => _selectedTabIndex.value;

  @override
  void onInit() {
    super.onInit();
    _loadFriendRequests();
    _loadUser();
  }

  void _loadFriendRequests() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );
      
      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStream(currentUserId),
      );
    }
  }

  void _loadUser() {
    _users.bindStream(
      _firestoreService.getAllUserStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var user in userList) {
          userMap[user.id] = user;
        }
        return userMap;
      }),
    );
  }

  void changeTab(int index) {
    _selectedTabIndex.value = index;
  }

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    try {
      _isLoading.value = true;
      
      final userName = getUser(request.senderId)?.displayName ?? 'User';
      
      // Step 1: Optimistically remove from received requests list (instant UI feedback)
      _receivedRequests.removeWhere((r) => r.id == request.id);
      
      // Step 2: Update Firestore - this creates the friendship and triggers real-time streams
      // The streams will automatically update both users' friend lists
      await _firestoreService.respondToFriendRequest(
        request.id,
        FriendRequestStatus.accepted,
      );
      
      // Step 3: Show success message
      // No need to manually refresh - the real-time streams handle it automatically
      Get.snackbar(
        'Success', 
        'You and $userName are now friends!',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      
    } catch (e) {
      print('Error accepting friend request: ${e.toString()}');
      _error.value = 'Failed to accept friend request';
      
      // Rollback: Re-add the request to the list if it failed
      if (!_receivedRequests.any((r) => r.id == request.id)) {
        _receivedRequests.add(request);
      }
      
      Get.snackbar(
        'Error', 
        'Failed to accept friend request. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declineFriendRequest(FriendRequestModel request) async {
    try {
      _isLoading.value = true;
      
      final userName = getUser(request.senderId)?.displayName ?? 'User';
      
      // Optimistically remove from received requests list
      _receivedRequests.removeWhere((r) => r.id == request.id);
      
      await _firestoreService.respondToFriendRequest(
        request.id,
        FriendRequestStatus.declined,
      );
      
      Get.snackbar(
        'Declined', 
        'Friend request from $userName declined',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      print('Error declining friend request: ${e.toString()}');
      _error.value = 'Failed to decline friend request';
      
      // Rollback: Re-add the request if it failed
      if (!_receivedRequests.any((r) => r.id == request.id)) {
        _receivedRequests.add(request);
      }
      
      Get.snackbar(
        'Error', 
        'Failed to decline friend request. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      
      if (currentUserId == null) {
        throw Exception('Current user is not logged in.');
      }
      
      await _firestoreService.unblockUser(currentUserId, userId);
      
      final userName = getUser(userId)?.displayName ?? 'User';
      Get.snackbar('Success', '$userName unblocked successfully', snackPosition: SnackPosition.TOP);
    } catch (e) {
      print('Error unblocking user: ${e.toString()}');
      _error.value = 'Failed to unblock User';
    } finally {
      _isLoading.value = false;
    }
  }

  String getRequestTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} d ago';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  String getStatusText(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return 'Pending';
      case FriendRequestStatus.accepted:
        return 'Accepted';
      case FriendRequestStatus.declined:
        return "Declined";
    }
  }

  Color getStatusColor(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return Colors.orange;
      case FriendRequestStatus.accepted:
        return Colors.green;
      case FriendRequestStatus.declined:
        return Colors.redAccent;
    }
  }
}