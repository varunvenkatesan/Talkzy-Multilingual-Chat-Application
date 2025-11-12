import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/friends_controller.dart';
import 'package:talkzy_beta1/models/chat_model.dart';
import 'package:talkzy_beta1/models/notification_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';



class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  Worker? _authStateWorker;
  String _currentUserId = '';

  final RxList<ChatModel> _allChats = <ChatModel>[].obs;
  final RxList<ChatModel> _filteredChats = <ChatModel>[].obs;
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;
  final RxString _activeFilter = 'All'.obs;
  

  List<ChatModel> get chats => _getFilteredChats();
  List<ChatModel> get filteredChats => _filteredChats;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  bool get isSearching => _isSearching.value;
  String get activeFilter => _activeFilter.value;
  List<NotificationModel> get notifications => _notifications;

  // Get friends from FriendsController
  List<UserModel> get _myFriends {
    try {
      final friendsController = Get.find<FriendsController>();
      final friends = friendsController.friends;
      return friends;
    } catch (e) {
      return [];
    }
  }

  // Separate getter for active friends only
  // Only shows friends who are online AND have showLastSeen enabled
  List<UserModel> get activeFriends {
    return _myFriends
        .where((friend) => PrivacyHelper.isVisiblyOnline(friend))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  // Offline friends
  List<UserModel> get offlineFriends {
    return _myFriends
        .where((friend) => !PrivacyHelper.isVisiblyOnline(friend))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  // Active friends (online friends from your friends list)
  // Only includes users who are online AND have showLastSeen enabled (visible)
  List<UserModel> get activeUsers {
    return _myFriends
        .where((friend) => PrivacyHelper.isVisiblyOnline(friend))
        .toList();
  }

  // Remaining friends (offline friends from your friends list)
  // Includes offline users and users who have hidden their online status
  List<UserModel> get remainingFriends {
    return _myFriends
        .where((friend) => !PrivacyHelper.isVisiblyOnline(friend))
        .toList();
  }

  // Recent chats sorted by time
  List<ChatModel> get recentChatsSection {
    final list = List<ChatModel>.from(_allChats);
    list.sort((a, b) => (b.lastMessageTime ?? DateTime(0))
        .compareTo(a.lastMessageTime ?? DateTime(0)));
    return list;
  }

  // Find an existing chat with a given user id
  ChatModel? findChatWithUser(String userId) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null || userId.isEmpty) return null;

    for (final chat in _allChats) {
      if (chat.participants.contains(currentUserId) &&
          chat.participants.contains(userId)) {
        return chat;
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _setupAuthStateMonitoring();
  }

  @override
  void onClose() {
    _authStateWorker?.dispose();
    super.onClose();
  }

  void _loadChats() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _allChats.bindStream(_firestoreService.getUserChatsStream(currentUserId));
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

  void _loadNotifications() {
    
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  UserModel? getOtherUser(ChatModel chat) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      return _users[otherUserId];
    }
    return null;
  }

  String formatLastMessageTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return 'Online';
    } else {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}';
      }
    }
  }

  List<ChatModel> _getFilteredChats() {
    List<ChatModel> baseList = _isSearching.value ? _filteredChats : _allChats;

    switch (_activeFilter.value) {
      case 'Unread':
        return _applyUnreadFilter(baseList);
      case 'Recent':
        return _applyRecentFilter(baseList);
      case 'Active':
        return _applyActiveFilter(baseList);
      case 'All':
      default:
        return baseList;
    }
  }

  List<ChatModel> _applyUnreadFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return [];

    return chats
        .where((chat) => chat.getUnreadCount(currentUserId) > 0)
        .toList();
  }

  List<ChatModel> _applyRecentFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final threeDayAgo = now.subtract(const Duration(days: 3));
    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(threeDayAgo);
    }).toList();
  }

  List<ChatModel> _applyActiveFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(oneWeekAgo);
    }).toList();
  }

  void setFilter(String filterType) {
    _activeFilter.value = filterType;
    update();
  }

  void clearAllFilters() {
    _activeFilter.value = 'All';
    _clearSearch();
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;

    if (query.isEmpty) {
      _clearSearch();
    } else {
      _isSearching.value = true;
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    final lowercaseQuery = query.toLowerCase().trim();

    _filteredChats.value = _allChats.where((chat) {
      final otherUser = getOtherUser(chat);
      if (otherUser == null) return false;

      final displayNameMatch =
          otherUser.displayName.toLowerCase().contains(lowercaseQuery);
      final emailMatch = otherUser.email.toLowerCase().contains(lowercaseQuery);
      final lastMessageMatch =
          chat.lastMessage?.toLowerCase().contains(lowercaseQuery) ?? false;

      return displayNameMatch || emailMatch || lastMessageMatch;
    }).toList();

    _sortSearchResults(lowercaseQuery);
  }

  void _sortSearchResults(String query) {
    _filteredChats.sort((a, b) {
      final userA = getOtherUser(a);
      final userB = getOtherUser(b);

      if (userA == null || userB == null) return 0;

      final exactMatchA = userA.displayName.toLowerCase().startsWith(query);
      final exactMatchB = userB.displayName.toLowerCase().startsWith(query);

      if (exactMatchA && !exactMatchB) return -1;
      if (!exactMatchA && exactMatchB) return 1;

      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });
  }

  void _clearSearch() {
    _isSearching.value = false;
    _filteredChats.clear();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _clearSearch();
  }

  int getUnreadCount() {
    return _applyUnreadFilter(_allChats).length;
  }

  int getRecentCount() {
    return _applyRecentFilter(_allChats).length;
  }

  int getActiveCount() {
    return _applyActiveFilter(_allChats).length;
  }

  void openChat(ChatModel chat) {
    final otherUser = getOtherUser(chat);
    if (otherUser != null) {
      Get.toNamed(
        AppRoutes.chat,
        arguments: {
          'chatId': chat.id,
          'otherUser': otherUser,
        },
      );
    }
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> refreshChats() async {
    _isLoading.value = true;

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (_isSearching.value && _searchQuery.value.isNotEmpty) {
        _performSearch(_searchQuery.value);
      }
    } catch (e) {
      _error.value = 'Failed to refresh chats';
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  int getTotalUnreadCount() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return 0;

    int total = 0;
    for (var chat in _allChats) {
      total += chat.getUnreadCount(currentUserId);
    }
    return total;
  }

  int getUnreadNotificationsCount() {
    return _notifications.where((notif) => !notif.isRead).length;
  }

  Future<void> deleteChat(ChatModel chat) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      final otherUser = getOtherUser(chat);
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Chat'),
          content: Text(
              'Are you sure you want to delete the chat with ${otherUser?.displayName ?? 'this user'}? This action cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete'),
            )
          ],
        ),
      );

      if (result == true) {
        await _firestoreService.deleteChatForUser(chat.id, currentUserId);
        Get.snackbar('Success', 'Chat deleted', snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      print('Error deleting chat: ${e.toString()}');
      Get.snackbar('Error', 'Failed to delete chat', snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  void _setupAuthStateMonitoring() {
    _authStateWorker = ever(
      _authController.rxUser,
      _onAuthStateChanged,
    );
    _onAuthStateChanged(_authController.rxUser.value);
  }

  void _onAuthStateChanged(User? user) {
    final newUserId = user?.uid ?? '';

    if (_currentUserId == newUserId) return;

    _currentUserId = newUserId;

    if (newUserId.isNotEmpty) {
      _loadChats();
      _loadUsers();
      _loadNotifications();
    } else {
      _allChats.clear();
      _filteredChats.clear();
      _notifications.clear();
      _users.clear();
    }
  }

  void clearError() {
    _error.value = '';
  }


 
}

