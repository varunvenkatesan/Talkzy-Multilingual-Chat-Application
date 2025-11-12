

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/home_controller.dart';
import 'package:talkzy_beta1/models/chat_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';
import 'package:talkzy_beta1/views/user_profile_view.dart';

// Removed redundant imports

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final UserModel otherUser;
  final String lastMessageTime;
  final VoidCallback onTap;
  
  const ChatListItem({
    super.key, 
    required this.chat, 
    required this.otherUser,
    required this.lastMessageTime, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context){
    final AuthController authController = Get.find<AuthController>();
    final HomeController homeController = Get.find<HomeController>();
    final currentUserId = authController.user?.uid ?? '';
    final unreadCount = chat.getUnreadCount(currentUserId);
    // In Chat List, users ARE friends (can only chat with friends)
    const isFriend = true;
    
    return Card(
      color: ThemeHelper.cardColor(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ThemeHelper.borderColor(context).withOpacity(0.4), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showChatOptions(context, homeController),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Stack(
              children: [
                _buildPrivacyAwareAvatar(currentUserId, isFriend),
                if (PrivacyHelper.shouldShowOnlineStatus(otherUser))
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        border: Border.all(color: ThemeHelper.cardColor(context), width: 2),
                        shape: BoxShape.circle, 
                      ),
                    ), 
                  )
              ],
            ),
            const SizedBox(width: 16),
            
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        otherUser.displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lastMessageTime.isNotEmpty)
                      Text(
                        lastMessageTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: unreadCount > 0 ? AppTheme.primaryColor : AppTheme.textSecoundaryColor,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                      )
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: 
                    Row(
                      children: [
                        if (chat.lastMessageSenderId == currentUserId) ...[
                          Icon(
                            _getSeenStatusIcon(chat),
                            size: 14,
                            color: _getSeenStatusColor(chat),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(child: Text(
                          _getDisplayText(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: unreadCount > 0 ? AppTheme.primaryColor : AppTheme.textSecoundaryColor,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                fontStyle: _shouldShowBio() ? FontStyle.italic : FontStyle.normal,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ))
                        
                      ],
                    )
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],

                ]),
                // FIX: Status Text is now outside the main row for better layout control
                if (chat.lastMessageSenderId == currentUserId)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _getSeenStatusText(chat),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getSeenStatusColor(chat),
                        fontSize: 11,
                      ),
                    ),
                  )
              ],
            )),
          ]
          ),
        ),
      ),
    );
  }

  // WhatsApp-style logic: Show bio if no messages, otherwise show last message
  bool _shouldShowBio() {
    return chat.lastMessage == null || 
           chat.lastMessage!.isEmpty || 
           chat.lastMessage == 'Start a conversation!';
  }

  String _getDisplayText() {
    if (_shouldShowBio()) {
      // No messages yet, show bio
      return otherUser.bio.isNotEmpty ? otherUser.bio : 'Tap to chat';
    } else {
      // Has messages, show last message
      return chat.lastMessage ?? 'No message yet';
    }
  }

  Widget _buildPrivacyAwareAvatar(String currentUserId, bool isFriend) {
    final canViewPhoto = PrivacyHelper.canViewProfilePhoto(otherUser, currentUserId, isFriend);
    
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.primaryColor,
      backgroundImage: canViewPhoto ? _getBackgroundImage() : null,
      child: canViewPhoto && _getBackgroundImage() != null
          ? null
          : _buildDefaultAvatar(),
    );
  }

  ImageProvider? _getBackgroundImage() {
    // Priority 1: Show uploaded photo if available
    if (otherUser.photoURL.isNotEmpty) {
      return NetworkImage(otherUser.photoURL);
    }
    
    // Priority 2: Show selected avatar if avatarCode exists
    if (otherUser.avatarCode != null && otherUser.avatarCode!.isNotEmpty) {
      return AssetImage('assets/images/${otherUser.avatarCode}.png');
    }
    
    // Priority 3: Show gender-based avatar
    if (otherUser.gender == 'male') {
      return const AssetImage('assets/images/male_avatar.png');
    } else if (otherUser.gender == 'female') {
      return const AssetImage('assets/images/female_avatar.png');
    }
    
    // No image available, will show initials
    return null;
  }

  Widget _buildDefaultAvatar() {
    return Text(
      otherUser.displayName.isNotEmpty ? otherUser.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  IconData _getSeenStatusIcon(ChatModel chat) {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final otherUserId = chat.getOtherParticipant(currentUserId);

    if (chat.isMessageSeen(currentUserId, otherUserId)) {
      return Icons.done_all;
    } else {
      return Icons.done;
    }
  }

  Color _getSeenStatusColor(ChatModel chat) {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final otherUserId = chat.getOtherParticipant(currentUserId);

    if (chat.isMessageSeen(currentUserId, otherUserId)) {
      return AppTheme.primaryColor;
    } else {
      return AppTheme.textSecoundaryColor;
    }
  }

  String _getSeenStatusText(ChatModel chat) {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final otherUserId = chat.getOtherParticipant(currentUserId);

    if (chat.isMessageSeen(currentUserId, otherUserId)) {
      return 'Seen'; // FIX: Changed 'Send' to 'Seen'
    } else {
      return 'Delivered';
    }
  }

  void _showChatOptions(BuildContext context, HomeController homeController) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeHelper.textSecondaryColor(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.person_outline, color: AppTheme.primaryColor),
              title: Text(
                'View Profile',
                style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
              ),
              subtitle: Text(
                'View ${otherUser.displayName}\'s profile',
                style: TextStyle(color: ThemeHelper.textSecondaryColor(context)),
              ),
              onTap: () {
                Get.back();
                Get.to(() => UserProfileView(user: otherUser));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: Text(
                'Delete Chat',
                style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
              ),
              subtitle: Text(
                'This will delete that chat for you only',
                style: TextStyle(color: ThemeHelper.textSecondaryColor(context)),
              ),
              onTap: () {
                Get.back();
                homeController.deleteChat(chat);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}