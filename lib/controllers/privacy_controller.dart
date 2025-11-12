import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/models/friendship_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';

class PrivacyController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Lazy getter for AuthController to avoid initialization issues
  AuthController get _authController => Get.find<AuthController>();

  final RxList<FriendshipModel> _blockedFriendships = <FriendshipModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Privacy Settings
  final RxBool _showLastSeen = true.obs;
  final RxBool _readReceipts = true.obs;
  final RxString _profilePhotoVisibility = 'everyone'.obs; // everyone, friends, nobody
  final RxString _bioVisibility = 'everyone'.obs; // everyone, friends, nobody

  List<FriendshipModel> get blockedFriendships => _blockedFriendships;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  List<UserModel> get blockedUsers => getBlockedUsers();
  
  // Privacy Settings Getters
  bool get showLastSeen => _showLastSeen.value;
  bool get readReceipts => _readReceipts.value;
  String get profilePhotoVisibility => _profilePhotoVisibility.value;
  String get bioVisibility => _bioVisibility.value;

  @override
  void onInit() {
    super.onInit();
    try {
      _loadBlockedUsers();
      _loadUsers();
      _loadPrivacySettings();
    } catch (e) {
      print('Error initializing PrivacyController: $e');
      Get.snackbar(
        'Error',
        'Failed to load privacy settings',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void _loadPrivacySettings() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      try {
        // Use real-time stream for instant updates across devices
        _firestoreService.getUserStream(currentUserId).listen((user) {
          if (user != null) {
            _showLastSeen.value = user.showLastSeen;
            _readReceipts.value = user.readReceipts;
            _profilePhotoVisibility.value = user.profilePhotoVisibility;
            _bioVisibility.value = user.bioVisibility;
          }
        });
      } catch (e) {
        print('Error loading privacy settings: $e');
      }
    }
  }

  void _loadBlockedUsers() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _blockedFriendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId).map((friendships) {
          return friendships.where((f) => f.isBlocked && f.blockedBy == currentUserId).toList();
        }),
      );
    }
  }

  void _loadUsers() {
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

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  List<UserModel> getBlockedUsers() {
    return _blockedFriendships
        .map((friendship) {
          final currentUserId = _authController.user?.uid ?? '';
          final blockedUserId = friendship.getOtherUserId(currentUserId);
          return _users[blockedUserId];
        })
        .whereType<UserModel>()
        .toList();
  }

  Future<void> unblockUser(String userId) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) {
        throw Exception('Current user is not logged in.');
      }

      await _firestoreService.unblockUser(currentUserId, userId);

      final userName = getUser(userId)?.displayName ?? 'User';
      Get.snackbar('Success', '$userName unblocked successfully');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to unblock user: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) {
        throw Exception('Current user is not logged in.');
      }

      await _firestoreService.blockUser(currentUserId, userId);

      final userName = getUser(userId)?.displayName ?? 'User';
      Get.snackbar('Success', '$userName blocked successfully');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to block user: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  // Privacy Settings Update Methods
  Future<void> updateLastSeenVisibility(bool value) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      _showLastSeen.value = value;
      
      await _firestoreService.updateUserPrivacySettings(
        currentUserId,
        {'showLastSeen': value},
      );
      
      Get.snackbar(
        'Updated',
        value ? 'Last seen is now visible' : 'Last seen is now hidden',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _error.value = e.toString();
      _showLastSeen.value = !value; // Rollback
      Get.snackbar(
        'Error', 
        'Failed to update setting: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> updateReadReceipts(bool value) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      _readReceipts.value = value;
      
      await _firestoreService.updateUserPrivacySettings(
        currentUserId,
        {'readReceipts': value},
      );
      
      Get.snackbar(
        'Updated',
        value ? 'Read receipts enabled' : 'Read receipts disabled',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _error.value = e.toString();
      _readReceipts.value = !value; // Rollback
      Get.snackbar(
        'Error', 
        'Failed to update setting: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> updateProfilePhotoVisibility(String value) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      _profilePhotoVisibility.value = value;
      
      await _firestoreService.updateUserPrivacySettings(
        currentUserId,
        {'profilePhotoVisibility': value},
      );
      
      Get.snackbar(
        'Updated',
        'Profile photo visibility set to ${value.capitalize}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _error.value = e.toString();
      _profilePhotoVisibility.value = _profilePhotoVisibility.value; // Keep old value
      Get.snackbar(
        'Error', 
        'Failed to update setting: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> updateBioVisibility(String value) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      _bioVisibility.value = value;
      
      await _firestoreService.updateUserPrivacySettings(
        currentUserId,
        {'bioVisibility': value},
      );
      
      Get.snackbar(
        'Updated',
        'Bio visibility set to ${value.capitalize}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _error.value = e.toString();
      _bioVisibility.value = _bioVisibility.value; // Keep old value
      Get.snackbar(
        'Error', 
        'Failed to update setting: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
}
