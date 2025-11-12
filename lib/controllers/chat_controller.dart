


import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/models/message_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';
import 'package:talkzy_beta1/services/translation_service.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TranslationService _translationService = TranslationService();
  final TextEditingController messageController = TextEditingController();
  final Uuid _uuid = Uuid();

  ScrollController? _scrollController;
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxList<String> _locallyDeletedMessageIds = <String>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);
  final RxString _chatId = ''.obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatActive = false.obs;
  final RxString _currentUserId = ''.obs;
  final RxString _selectedLanguage = ''.obs;
  final RxBool _isTranslating = false.obs;
  final RxBool _isBlocked = false.obs; // Track if messaging is blocked
  final RxString _blockMessage = ''.obs; // Message to show when blocked
  Worker? _messagesWorker;
  Worker? _authStateWorker;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<List<String>>? _blockedUsersSub;

  List<MessageModel> get messages => _messages.value;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  String get error => _error.value;
  UserModel? get otherUser => _otherUser.value;
  String get chatId => _chatId.value;
  bool get isTyping => _isTyping.value;
  String get selectedLanguage => _selectedLanguage.value;
  bool get isTranslating => _isTranslating.value;
  bool get isBlocked => _isBlocked.value;
  String get blockMessage => _blockMessage.value;

  ChatController({String? chatId, UserModel? otherUser}) {
    if (chatId != null) _chatId.value = chatId;
    if (otherUser != null) _otherUser.value = otherUser;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    _loadLanguagePreference();
    _loadLocallyDeletedMessages();
    _setupBlockStatusListener();
    messageController.addListener(_onMessageChanged);
  }

  @override
  void onReady() {
    super.onReady();
    _isChatActive.value = true;
    _setupAuthStateMonitoring();
  }

  @override
  void onClose() {
    _isChatActive.value = false;
    _markMessageAsRead();
    messageController.removeListener(_onMessageChanged);
    _messagesWorker?.dispose();
    _authStateWorker?.dispose();
    _messagesSub?.cancel();
    _blockedUsersSub?.cancel();
    _scrollController?.dispose();
    super.onClose();
  }

  void _initializeChat() async {
    final arguments = Get.arguments;
    if (arguments != null) {
      _otherUser.value = arguments['otherUser'];

      final currentUserId = _authController.user?.uid;
      final otherUserId = _otherUser.value?.id;

      if (arguments['chatId'] != null && arguments['chatId'].isNotEmpty) {
        _chatId.value = arguments['chatId'];
      } else if (currentUserId != null && otherUserId != null) {
        List<String> participants = [currentUserId, otherUserId];
        participants.sort();
        _chatId.value = '${participants[0]}_${participants[1]}';
      }

      if (currentUserId != null && otherUserId != null) {
        try {
          _isLoading.value = true;
          String ensuredChatId = await _firestoreService.createOrGetChat(
              currentUserId, otherUserId);
          _chatId.value = ensuredChatId;

          print('Chat initialized with chatId: $_chatId');

          _loadMessages();
          _markMessageAsRead();
        } catch (e) {
          print('Error ensuring chat exists: $e');
          _loadMessages();
          _markMessageAsRead();
        } finally {
          _isLoading.value = false;
        }
      }
    }
  }

  Future<void> _loadLanguagePreference() async {
    final savedLanguage = await TranslationService.getSelectedLanguage();
    if (savedLanguage != null) {
      _selectedLanguage.value = savedLanguage;
    }
  }

  Future<void> _loadLocallyDeletedMessages() async {
    // Load locally deleted message IDs from local storage
    // You can use SharedPreferences or GetStorage for this
    // For now, we'll keep them in memory
  }

  Future<void> _saveLocallyDeletedMessage(String messageId) async {
    _locallyDeletedMessageIds.add(messageId);
    // Save to local storage (SharedPreferences/GetStorage)
    // await GetStorage().write('deleted_messages_$chatId', _locallyDeletedMessageIds);
  }

  Future<void> setTranslationLanguage(String? languageCode) async {
    if (languageCode == null || languageCode.isEmpty) {
      _selectedLanguage.value = '';
      await TranslationService.clearSelectedLanguage();
      // Clear all translations
      for (var message in _messages) {
        message.translatedContent = null;
      }
      _messages.refresh();
      TranslationService.clearCache();
    } else {
      _selectedLanguage.value = languageCode;
      await TranslationService.saveSelectedLanguage(languageCode);
      // Translate all received messages
      await _translateAllMessages();
    }
  }

  Future<void> _translateAllMessages() async {
    final currentUserId = _authController.user?.uid;
    final languageCode = _selectedLanguage.value;
    if (currentUserId == null || languageCode.isEmpty) return;

    _isTranslating.value = true;

    try {
      final messagesToUpdate = _messages.toList();
      
      for (var message in messagesToUpdate) {
        if (message.senderId != currentUserId && message.translatedContent == null) {
          try {
            final translated = await _translationService.translateText(
              message.content,
              languageCode,
            );
            
            if (translated.toLowerCase() != message.content.toLowerCase()) {
              message.translatedContent = translated;
            }
          } catch (e) {
            print('Error translating message ${message.id}: $e');
          }
        }
      }
      
      _messages.assignAll(messagesToUpdate);
    } finally {
      _isTranslating.value = false;
    }
  }

  Future<void> _translateNewMessage(MessageModel message) async {
    final currentUserId = _authController.user?.uid;
    final languageCode = _selectedLanguage.value;
    if (currentUserId == null || 
        languageCode.isEmpty || 
        message.senderId == currentUserId ||
        message.translatedContent != null) {
      return;
    }

    try {
      final translated = await _translationService.translateText(
        message.content,
        languageCode,
      );
      
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1 && translated.toLowerCase() != message.content.toLowerCase()) {
        _messages[index].translatedContent = translated;
        _messages.refresh();
      }
    } catch (e) {
      print('Error translating new message: $e');
    }
  }

  void _loadMessages() {
    if (_chatId.value.isEmpty) {
      print('Cannot load messages: chatId is empty');
      return;
    }

    _messagesSub?.cancel();
    _messagesWorker?.dispose();
    _messages.clear();

    print('Loading messages for chatId: ${_chatId.value}');

    _messagesSub = _firestoreService
        .getMessagesStreamByChatId(_chatId.value)
        .listen((incoming) async {
      final sortedMessages = incoming.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      print("Loaded ${sortedMessages.length} messages from Firestore for chat: ${_chatId.value}");

      // Filter out locally deleted messages
      final filteredMessages = sortedMessages
          .where((msg) => !_locallyDeletedMessageIds.contains(msg.id))
          .toList();

      // Preserve existing translation cache across stream updates
      final messagesWithTranslationCopy = filteredMessages.map((msg) {
        final existingMessage = _messages.firstWhereOrNull((m) => m.id == msg.id);
        return msg.copyWith(translatedContent: existingMessage?.translatedContent);
      }).toList();

      _messages.assignAll(messagesWithTranslationCopy);
      
      // Trigger translation only for new/untranslated messages if a language is selected
      if (_selectedLanguage.value.isNotEmpty) {
        await _translateAllMessages();
      }
    }, onError: (err) {
      print('Messages stream error: $err');
      _error.value = err.toString();
    });

    _messagesWorker = ever(_messages, (List<MessageModel> messageList) {
      if (_isChatActive.value) {
        _markUnreadMessagesAsRead(messageList);
      }
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Setup real-time listener for block status
  void _setupBlockStatusListener() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    // Listen to current user's blocked list
    _blockedUsersSub = _firestoreService.getBlockedUsersStream(currentUserId).listen((blockedUserIds) {
      final otherUserId = _otherUser.value?.id;
      if (otherUserId != null) {
        if (blockedUserIds.contains(otherUserId)) {
          _isBlocked.value = true;
          _blockMessage.value = "You can't send messages to this contact because you've blocked them.";
        } else {
          // Check if other user blocked current user
          _checkIfBlockedByOther(currentUserId, otherUserId);
        }
      }
    });
  }

  /// Check if current user is blocked by the other user
  Future<void> _checkIfBlockedByOther(String currentUserId, String otherUserId) async {
    try {
      final isBlockedByOther = await _firestoreService.isInBlockedList(otherUserId, currentUserId);
      if (isBlockedByOther) {
        _isBlocked.value = true;
        _blockMessage.value = "You can't send messages to this contact.";
      } else {
        _isBlocked.value = false;
        _blockMessage.value = '';
      }
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  Future<void> _markUnreadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    try {
      final unreadMessages = messageList
          .where((message) =>
              message.receiverId == currentUserId &&
              !message.isRead &&
              message.senderId != currentUserId)
          .toList();

      for (var message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
      }

      if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
        await _firestoreService.restoreUnreadCount(
            _chatId.value, currentUserId);
      }
      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
            _chatId.value, currentUserId);
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isEmpty) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete chat'),
          content: Text(
              'Are you sure you want to delete this chat? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Delete'),
            ),
          ],
        ),
      );
      if (result == true) {
        _isLoading.value = true;
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);
        Get.delete<ChatController>(tag: _chatId.value);
        Get.back();
        Get.snackbar('Success', 'Chat deleted', snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      _error.value = e.toString();
      print('Error deleting chat: $e');
      Get.snackbar('Error', 'Failed to delete chat', snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> blockUser() async {
    try {
      final currentUserId = _authController.user?.uid;
      final otherUserId = _otherUser.value?.id;
      final otherUserName = _otherUser.value?.displayName ?? 'this user';

      if (currentUserId == null || otherUserId == null) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Block User'),
          content: Text(
              'Are you sure you want to block $otherUserName? You will no longer be able to chat with them.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Block'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _firestoreService.blockUser(currentUserId, otherUserId);
        Get.snackbar(
          'Success',
          '$otherUserName has been blocked',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error blocking user: $e');
      Get.snackbar(
        'Error',
        'Failed to block user',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> unblockUser() async {
    try {
      final currentUserId = _authController.user?.uid;
      final otherUserId = _otherUser.value?.id;
      final otherUserName = _otherUser.value?.displayName ?? 'this user';

      if (currentUserId == null || otherUserId == null) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Unblock User'),
          content: Text(
              'Are you sure you want to unblock $otherUserName? You will be able to chat with them again.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: Text('Unblock'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _firestoreService.unblockUser(currentUserId, otherUserId);
        Get.snackbar(
          'Success',
          '$otherUserName has been unblocked',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error unblocking user: $e');
      Get.snackbar(
        'Error',
        'Failed to unblock user',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void _onMessageChanged() {
    _isTyping.value = messageController.text.isNotEmpty;
  }

  Future<void> sendMessage() async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();

    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      Get.snackbar('Error', 'Cannot send empty message', snackPosition: SnackPosition.TOP);
      return;
    }

    // Check if messaging is blocked
    if (_isBlocked.value) {
      Get.snackbar(
        'Blocked',
        _blockMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 3),
      );
      return;
    }

    if (await _firestoreService.isUnfriended(currentUserId, otherUserId)) {
      Get.snackbar(
        'Error',
        'You cannot send messages to this user as you are not friends',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      _isSending.value = true;
      messageController.clear();

      if (_chatId.value.isEmpty) {
        List<String> participants = [currentUserId, otherUserId];
        participants.sort();
        _chatId.value = '${participants[0]}_${participants[1]}';
      }

      String chatId =
          await _firestoreService.createOrGetChat(currentUserId, otherUserId);

      if (_chatId.value != chatId) {
        _chatId.value = chatId;
        _loadMessages();
      }

      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        chatId: chatId,
      );

      print('Sending message: ${message.content} to chatId: $chatId');

      await _firestoreService.sendMessage(message);

      print('Message sent successfully');
    } catch (e) {
      final String errorText = e.toString();
      Get.snackbar('Error', 'Failed to send message: $errorText', snackPosition: SnackPosition.TOP);
      print('Error sending message: $errorText');
    } finally {
      _isSending.value = false;
    }
  }

  Future<void> _markMessageAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      try {
        await _firestoreService.restoreUnreadCount(
            _chatId.value, currentUserId);
      } catch (e) {
        print('Error marking message as read: $e');
      }
    }
  }

  void onChatResumed() {
    _isChatActive.value = true;
    _markUnreadMessagesAsRead(_messages);
  }

  void onChatPaused() {
    _isChatActive.value = false;
  }

  Future<void> deleteMessage(MessageModel message) async {
    try {
      await _firestoreService.deleteMessage(message.id);
      Get.snackbar("Success", "Message deleted", snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete message', snackPosition: SnackPosition.TOP);
      print('Error deleting message: $e');
    }
  }

  // Delete message locally only (for received messages)
  Future<void> deleteMessageLocally(MessageModel message) async {
    try {
      await _saveLocallyDeletedMessage(message.id);
      _messages.removeWhere((m) => m.id == message.id);
      print('Message deleted locally: ${message.id}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete message', snackPosition: SnackPosition.TOP);
      print('Error deleting message locally: $e');
    }
  }

  Future<void> editMessage(MessageModel message, String newContent) async {
    try {
      await _firestoreService.editMessage(message.id, newContent);
      Get.snackbar("Success", "Message edited", snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'Failed to edit message', snackPosition: SnackPosition.TOP);
      print('Error editing message: $e');
    }
  }

  bool isMyMessage(MessageModel message) {
    return message.senderId == _authController.user?.uid;
  }

  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    String format12Hour(DateTime dt) {
      int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      String minute = dt.minute.toString().padLeft(2, '0');
      String ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $ampm';
    }

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return format12Hour(timestamp);
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weekday = days[timestamp.weekday - 1];
      return '$weekday ${format12Hour(timestamp)}';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${format12Hour(timestamp)}';
    }
  }

  void _setupAuthStateMonitoring() {
    _authStateWorker = ever(
      _authController.rxUser,
      (User? user) {
        final newUserId = user?.uid ?? '';

        if (_currentUserId.value != newUserId) {
          if (_currentUserId.value.isNotEmpty && newUserId.isNotEmpty) {
            _loadMessages();
            _markMessageAsRead();
          } else if (_currentUserId.value.isEmpty && newUserId.isNotEmpty) {
            _loadMessages();
            _markMessageAsRead();
          } else if (_currentUserId.value.isNotEmpty && newUserId.isEmpty) {
            _messages.clear();
            _messagesSub?.cancel();
            _currentUserId.value = '';
          }

          _currentUserId.value = newUserId;
        }
      },
    );
  }

  void clearError() {
    _error.value = '';
  }
}