

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';
import 'package:talkzy_beta1/views/user_profile_view.dart';

class FriendListItem extends StatelessWidget {
  final UserModel friend;
  final String lastSeenText;
  final VoidCallback onTap;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;
  final VoidCallback onRemove;
  final bool isBlocked;
  
  const FriendListItem({
    super.key, 
    required this.friend, 
    required this.lastSeenText, 
    required this.onTap, 
    this.onBlock, 
    this.onUnblock,
    required this.onRemove,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double avatarRadius = 30;
    
    final authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    const isFriend = true;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            // Avatar
            _buildPrivacyAwareAvatar(currentUserId, isFriend, avatarRadius),
              
            const SizedBox(width: 16),
            
            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFEAEAEA) : const Color(0xFF111111),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (friend.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      friend.bio,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    lastSeenText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFFA0A0A0) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
              
            // Menu Button
            PopupMenuButton<String>(
              onSelected:(value){
                switch(value){
                  case 'profile':
                    Get.to(() => UserProfileView(user: friend));
                    break;
                  case 'message':
                    onTap();
                    break;
                  case 'remove':
                    onRemove();
                    break;
                  case 'block':
                    onBlock?.call();
                    break;
                  case 'unblock':
                    onUnblock?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: const Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 12),
                      Text('View Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'message',
                  enabled: !isBlocked,
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: isBlocked ? Colors.grey : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: isBlocked ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, size: 20, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      const Text('Remove Friend'),
                    ],
                  ),
                ),
                if (!isBlocked && onBlock != null)
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        const Text('Block User'),
                      ],
                    ),
                  ),
                if (isBlocked && onUnblock != null)
                  PopupMenuItem(
                    value: 'unblock',
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Unblock User'),
                      ],
                    ),
                  ),
              ],
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyAwareAvatar(String currentUserId, bool isFriend, double avatarRadius) {
    final canViewPhoto = PrivacyHelper.canViewProfilePhoto(friend, currentUserId, isFriend);
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: isDark ? const Color(0xFF2A5A8A) : const Color(0xFF4A90E2),
      backgroundImage: canViewPhoto ? _getBackgroundImage() : null,
      child: canViewPhoto && _getBackgroundImage() != null
          ? null
          : _buildDefaultAvatar(),
    );
  }

  ImageProvider? _getBackgroundImage() {
    // Priority 1: Show uploaded photo if available
    if (friend.photoURL.isNotEmpty) {
      return NetworkImage(friend.photoURL);
    }
    
    // Priority 2: Show selected avatar if avatarCode exists
    if (friend.avatarCode != null && friend.avatarCode!.isNotEmpty) {
      return AssetImage('assets/images/${friend.avatarCode}.png');
    }
    
    // Priority 3: Show gender-based avatar
    if (friend.gender == 'male') {
      return const AssetImage('assets/images/male_avatar.png');
    } else if (friend.gender == 'female') {
      return const AssetImage('assets/images/female_avatar.png');
    }
    
    // No image available, will show initials
    return null;
  }

  // Extracted logic for default avatar
  Widget _buildDefaultAvatar(){
    return Text(
      friend.displayName.isNotEmpty
      ? friend.displayName[0].toUpperCase()
      : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}