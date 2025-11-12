

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/chat_controller.dart';
import 'package:talkzy_beta1/services/translation_service.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/views/widgets/message_bubble.dart';
import 'package:talkzy_beta1/controllers/chat_theme_controller.dart';
import 'package:talkzy_beta1/models/message_model.dart';
import 'package:talkzy_beta1/views/widgets/user_avatar.dart';
import 'package:talkzy_beta1/views/user_profile_view.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  late final String chatId;
  late final ChatController controller;
  
  // Emoji picker state
  bool isEmojiVisible = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to focus changes
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && isEmojiVisible) {
        setState(() {
          isEmojiVisible = false;
        });
      }
    });

    final arguments = Get.arguments;

    if (arguments?['chatId'] != null && arguments['chatId'].isNotEmpty) {
      chatId = arguments['chatId'];
    } else {
      final AuthController authController = Get.find<AuthController>();
      final currentUserId = authController.user?.uid;
      final otherUserId = arguments?['otherUser']?.id;

      if (currentUserId != null && otherUserId != null) {
        List<String> participants = [currentUserId, otherUserId];
        participants.sort();
        chatId = '${participants[0]}_${participants[1]}';
      } else {
        chatId = '';
      }
    }

    print('ChatView initialized with chatId: $chatId');

    if (!Get.isRegistered<ChatController>(tag: chatId)) {
      Get.put<ChatController>(
        ChatController(
          chatId: chatId,
          otherUser: arguments?['otherUser'],
        ),
        tag: chatId,
      );
    }
    controller = Get.find<ChatController>(tag: chatId);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Obx(() {
          final isDark = ThemeHelper.isDark(context);
          final chatTheme = Get.find<ChatThemeController>();
          final appBarBg = chatTheme.appBarBackgroundFor(isDark: isDark);
          return Container(
            decoration: BoxDecoration(
              gradient: appBarBg.gradient,
              color: appBarBg.color,
              border: Border(
                bottom: BorderSide(
                  color: appBarBg.bottomBorderColor,
                  width: 1,
                ),
              ),
            ),
          );
        }),
        leading: IconButton(
          onPressed: () {
            Get.delete<ChatController>(tag: chatId);
            Get.back();
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Obx(() {
          final otherUser = controller.otherUser;
          if (otherUser == null) return Text('Chat');
          return InkWell(
            onTap: () {
              // Navigate to user profile details
              Get.to(() => UserProfileView(user: otherUser));
            },
            child: Row(
              children: [
                UserAvatar(
                  user: otherUser,
                  radius: 20,
                  showOnlineStatus: false,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser.displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (PrivacyHelper.shouldShowOnlineStatus(otherUser))
                        Text(
                          'Online',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.successColor,
                              ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (otherUser.showLastSeen)
                        Text(
                          PrivacyHelper.getDisplayLastSeen(otherUser, otherUser.lastSeen),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecoundaryColor,
                              ),
                          overflow: TextOverflow.ellipsis,
                        )
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'language':
                  _showLanguageSelector();
                  break;
                case 'delete':
                  controller.deleteChat();
                  break;
                case 'block':
                  controller.blockUser();
                  break;
                case 'unblock':
                  controller.unblockUser();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'language',
                child: Obx(() {
                  final hasLanguage = controller.selectedLanguage.isNotEmpty;
                  return ListTile(
                    leading: Icon(
                      Icons.translate,
                      color: hasLanguage ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    ),
                    title: Text("Language"),
                    subtitle: hasLanguage
                        ? Text(
                            TranslationService.getLanguageName(controller.selectedLanguage),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            'Select translation language',
                            style: TextStyle(
                              color: AppTheme.textSecoundaryColor,
                              fontSize: 11,
                            ),
                          ),
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ),
              // Block or Unblock option based on current status
              PopupMenuItem(
                value: controller.isBlocked ? 'unblock' : 'block',
                child: Obx(() => ListTile(
                  leading: Icon(
                    controller.isBlocked ? Icons.check_circle_outline : Icons.block,
                    color: controller.isBlocked ? Colors.green : AppTheme.errorColor,
                  ),
                  title: Text(controller.isBlocked ? "Unblock User" : "Block User"),
                  contentPadding: EdgeInsets.zero,
                )),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  title: Text("Delete Chat"),
                  contentPadding: EdgeInsets.zero,
                ),
              )
            ],
          )
        ],
      ),
      body: Obx(() {
        final isDark = ThemeHelper.isDark(context);
        final chatTheme = Get.find<ChatThemeController>();
        final pageBg = chatTheme.pageBackgroundFor(isDark: isDark);
        return Container(
          decoration: BoxDecoration(
            gradient: pageBg.gradient,
            color: pageBg.color,
          ),
          child: Column(
        children: [
          // Language selection banner
          Obx(() {
            if (controller.selectedLanguage.isNotEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: ThemeHelper.isDark(context)
                      ? AppTheme.primaryColor.withOpacity(0.12)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: ThemeHelper.isDark(context)
                          ? AppTheme.primaryColor.withOpacity(0.25)
                          : AppTheme.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Translating to ${TranslationService.getLanguageName(controller.selectedLanguage)}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    InkWell(
                      onTap: () async {
                        await controller.setTranslationLanguage(null);
                        Get.snackbar(
                          'Translation Disabled',
                          'Messages will show in original language',
                          snackPosition: SnackPosition.TOP,
                          duration: Duration(seconds: 2),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeHelper.cardColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        child: Text(
                          'Turn Off',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
          
          // Translation loading indicator
          Obx(() {
            if (controller.isTranslating) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppTheme.primaryColor.withOpacity(0.05),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Translating messages...',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
          
          Expanded(
            child: Obx(() {
              print("ChatView rendering: ${controller.messages.length} messages");
              
              if (controller.isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMyMessage = controller.isMyMessage(message);
                  final showTime = index == 0 ||
                      controller.messages[index - 1].timestamp
                              .difference(message.timestamp)
                              .inMinutes
                              .abs() >
                          5;
                  return MessageBubble(
                    message: message,
                    isMyMessage: isMyMessage,
                    showTime: showTime,
                    timeText: controller.formatMessageTime(message.timestamp),
                    showTranslation: !isMyMessage && controller.selectedLanguage.isNotEmpty,
                    onLongPress: () => _showMessageOptions(message, isMyMessage),
                  );
                },
              );
            }),
          ),
          _buildMessageInput(),
          // Emoji Picker
          if (isEmojiVisible)
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: ThemeHelper.cardColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
                onBackspacePressed: () {
                  _onBackspacePressed();
                },
                config: Config(
                  height: 280,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 8,
                    emojiSizeMax: 32,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    backgroundColor: ThemeHelper.cardColor(context),
                    buttonMode: ButtonMode.MATERIAL,
                    loadingIndicator: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    noRecents: Center(
                      child: Text(
                        'No recent emojis',
                        style: TextStyle(
                          fontSize: 16,
                          color: ThemeHelper.textSecondaryColor(context),
                        ),
                      ),
                    ),
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: ThemeHelper.cardColor(context),
                    indicatorColor: AppTheme.primaryColor,
                    iconColorSelected: AppTheme.primaryColor,
                    iconColor: ThemeHelper.textSecondaryColor(context).withOpacity(0.6),
                    categoryIcons: const CategoryIcons(),
                    tabIndicatorAnimDuration: Duration(milliseconds: 300),
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    showBackspaceButton: true,
                    showSearchViewButton: true,
                  ),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
        ],
      ),
        );
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        controller.onChatResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.onChatPaused();
        break;
    }
  }

  // Emoji picker methods
  void _onEmojiSelected(Emoji emoji) {
    final textController = controller.messageController;
    final text = textController.text;
    final selection = textController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji.emoji,
    );
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.emoji.length,
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
    
    if (isEmojiVisible) {
      // Hide keyboard when showing emoji picker
      _focusNode.unfocus();
    } else {
      // Show keyboard when hiding emoji picker
      _focusNode.requestFocus();
    }
  }

  void _onBackspacePressed() {
    final textController = controller.messageController;
    final text = textController.text;
    final selection = textController.selection;
    
    if (selection.start > 0) {
      final newText = text.substring(0, selection.start - 1) + 
                      text.substring(selection.start);
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start - 1,
        ),
      );
    }
  }

  void _showLanguageSelector() {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ThemeHelper.borderColor(context),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate, color: ThemeHelper.primaryColor(context)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Translation Language',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Received messages will be translated',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ThemeHelper.textSecondaryColor(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: [
                  Obx(() => ListTile(
                        leading: Icon(
                          Icons.cancel,
                          color: controller.selectedLanguage.isEmpty
                              ? AppTheme.primaryColor
                              : AppTheme.textSecoundaryColor,
                        ),
                        title: Text('No Translation'),
                        subtitle: Text('Show messages in original language'),
                        trailing: controller.selectedLanguage.isEmpty
                            ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                            : null,
                        onTap: () async {
                          await controller.setTranslationLanguage(null);
                          Get.back();
                          Get.snackbar(
                            'Translation Disabled',
                            'Messages will be shown in original language',
                            snackPosition: SnackPosition.TOP,
                            duration: Duration(seconds: 2),
                            backgroundColor: AppTheme.cardColor,
                          );
                        },
                      )),
                  Divider(),
                  ...TranslationService.indianLanguages.map((lang) {
                    final code = lang['code']!;
                    final name = lang['name']!;
                    return Obx(() => ListTile(
                          leading: Icon(
                            Icons.language,
                            color: controller.selectedLanguage == code
                                ? AppTheme.primaryColor
                                : AppTheme.textSecoundaryColor,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: controller.selectedLanguage == code
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: controller.selectedLanguage == code
                              ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                              : null,
                          onTap: () async {
                            Get.back();
                            await controller.setTranslationLanguage(code);
                            Get.snackbar(
                              'Translation Enabled',
                              'Messages will be translated to $name',
                              snackPosition: SnackPosition.TOP,
                              duration: Duration(seconds: 2),
                            colorText: const Color.fromARGB(255, 33, 33, 33),
                              backgroundColor: const Color.fromARGB(63, 255, 255, 255),
                            );
                          },
                        ));
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatTheme = Get.find<ChatThemeController>();
    final accent = chatTheme.accentColorFor(isDark: isDark);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(
            color: accent.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.cardColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    // Emoji button
                    IconButton(
                      onPressed: _toggleEmojiPicker,
                      icon: Icon(
                        isEmojiVisible ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        color: isEmojiVisible ? accent : AppTheme.textSecoundaryColor,
                      ),
                    ),
                    // Text field
                    Expanded(
                      child: Obx(() => TextField(
                        controller: controller.messageController,
                        focusNode: _focusNode,
                        enabled: !controller.isBlocked,
                        decoration: InputDecoration(
                          hintText: controller.isBlocked 
                              ? controller.blockMessage
                              : 'Type a message',
                          hintStyle: controller.isBlocked
                              ? TextStyle(color: Colors.red.shade400, fontSize: 13)
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => controller.isBlocked ? null : controller.sendMessage(),
                      )),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Obx(() {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final chatTheme = Get.find<ChatThemeController>();
              final accent = chatTheme.accentColorFor(isDark: isDark);
              final btnColor = controller.isBlocked
                  ? AppTheme.borderColor
                  : (controller.isTyping ? accent : AppTheme.borderColor);
              final icoColor = controller.isBlocked
                  ? Colors.grey
                  : (controller.isTyping ? Colors.white : AppTheme.textSecoundaryColor);
              return Container(
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: controller.isBlocked || controller.isSending
                      ? null
                      : controller.sendMessage,
                  icon: controller.isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: icoColor,
                        ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ThemeHelper.textPrimaryColor(context),
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Send a message to get the chat started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeHelper.textSecondaryColor(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message, bool isMyMessage) {
    Get.bottomSheet(Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy option - available for all messages
          ListTile(
            leading: Icon(
              Icons.copy,
              color: ThemeHelper.primaryColor(context),
            ),
            title: Text(
              'Copy Text',
              style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
            ),
            onTap: () {
              Get.back();
              _copyMessageText(message);
            },
          ),
          // Edit and Delete for sent messages
          if (isMyMessage) ...[
            ListTile(
              leading: Icon(
                Icons.edit,
                color: ThemeHelper.primaryColor(context),
              ),
              title: Text(
                'Edit Message',
                style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
              ),
              onTap: () {
                Get.back();
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: AppTheme.errorColor,
              ),
              title: Text(
                'Delete Message',
                style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
              ),
              onTap: () {
                Get.back();
                _showDeleteDialog(message);
              },
            ),
          ],
          // Delete for received messages (local only)
          if (!isMyMessage)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
              title: Text(
                'Delete Message',
                style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
              ),
              subtitle: Text(
                'Only deleted from your device',
                style: TextStyle(
                  fontSize: 11,
                  color: ThemeHelper.textSecondaryColor(context),
                ),
              ),
              onTap: () {
                Get.back();
                _showDeleteReceivedMessageDialog(message);
              },
            ),
        ],
      ),
    ));
  }

  void _copyMessageText(MessageModel message) {
    Clipboard.setData(ClipboardData(text: message.content));
    Get.snackbar(
      'Copied',
      'Message copied to clipboard',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: ThemeHelper.cardColor(context),
    );
  }

  void _showEditDialog(MessageModel message) {
    final editController = TextEditingController(text: message.content);
    Get.dialog(
      AlertDialog(
        title: Text("Edit Message"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: 'Enter new message',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                controller.editMessage(message, editController.text.trim());
                Get.back();
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(MessageModel message) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Message"),
        content: Text(
            "Are you sure you want to delete this message? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteMessage(message);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showDeleteReceivedMessageDialog(MessageModel message) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Message"),
        content: Text(
            "This message will only be deleted from your device. The sender will still be able to see it."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteMessageLocally(message);
              Get.back();
              Get.snackbar(
                'Message Deleted',
                'Message removed from your chat',
                snackPosition: SnackPosition.TOP,
                duration: Duration(seconds: 2),
                backgroundColor: ThemeHelper.cardColor(context),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }
}