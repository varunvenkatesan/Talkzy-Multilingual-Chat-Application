
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/user_list_controller.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final UserListController controller;
  
  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    
    return Obx(() {
      final relationshipStatus = controller.getUserRelationshipStatus(user.id);
      // In Find Friends, users are not friends yet
      final isFriend = relationshipStatus == UserRelationshipStatus.friends;

      // This condition ensures friends are not shown in "Find People"
      if (relationshipStatus == UserRelationshipStatus.friends) {
        return const SizedBox.shrink(); 
      }
      
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ThemeHelper.borderColor(context),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showUserProfileBottomSheet(context),
          child: Row(
            children: [
              _buildAvatar(currentUserId, isFriend, isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.textPrimaryColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: ThemeHelper.textSecondaryColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user.bio,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: ThemeHelper.textSecondaryColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildCapsuleButton(relationshipStatus, isDark),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvatar(String currentUserId, bool isFriend, bool isDark) {
    final canViewPhoto = PrivacyHelper.canViewProfilePhoto(user, currentUserId, isFriend);
    
    return CircleAvatar(
      radius: 32,
      backgroundColor: AppTheme.primaryColor,
      backgroundImage: canViewPhoto ? _getBackgroundImage() : null,
      child: canViewPhoto && _getBackgroundImage() != null
          ? null
          : Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  ImageProvider? _getBackgroundImage() {
    // Priority 1: Show uploaded photo if available
    if (user.photoURL.isNotEmpty) {
      return NetworkImage(user.photoURL);
    }
    
    // Priority 2: Show selected avatar if avatarCode exists
    if (user.avatarCode != null && user.avatarCode!.isNotEmpty) {
      return AssetImage('assets/images/${user.avatarCode}.png');
    }
    
    // Priority 3: Show gender-based avatar
    if (user.gender == 'male') {
      return const AssetImage('assets/images/male_avatar.png');
    } else if (user.gender == 'female') {
      return const AssetImage('assets/images/female_avatar.png');
    }
    
    // No image available, will show initials
    return null;
  }

  Widget _buildCapsuleButton(UserRelationshipStatus relationshipStatus, bool isDark) {
    switch (relationshipStatus) {
      case UserRelationshipStatus.none:
        return InkWell(
          onTap: () => controller.handleRelationshipAction(user),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Add Friend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE0E0E0) : const Color.fromARGB(255, 8, 117, 249),
                ),
              ),
            ),
          ),
        );

      case UserRelationshipStatus.friendRequestSent:
        return GestureDetector(
          onTap: () {
            print('🔘 Requested button tapped');
            _showCancleRequestDialog();
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Requested',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[600] : const Color.fromARGB(255, 2, 195, 8),
                ),
              ),
            ),
          ),
        );

      case UserRelationshipStatus.friendRequestReceived:
        return InkWell(
          onTap: () => controller.handleRelationshipAction(user),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Accept',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );

      case UserRelationshipStatus.blocked:
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A2A2A) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              'Blocked',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
        );

      case UserRelationshipStatus.friends:
        return const SizedBox.shrink();
    }
  }
  
  void _showCancleRequestDialog() {
    print('📱 Showing cancel request dialog for ${user.displayName}');
    Get.dialog(
      Builder(
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Cancel Friend Request",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              "Are you sure you want to cancel the friend request to ${user.displayName}?",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('❌ User chose to keep request');
                  Navigator.of(dialogContext).pop();
                  print('🔙 Dialog closed');
                },
                child: Text(
                  "Keep Request",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  print('✅ User confirmed cancel request');
                  Navigator.of(dialogContext).pop();
                  print('🔙 Dialog closed, calling cancelFriendRequest');
                  controller.cancelFriendRequest(user);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'Cancel Request',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          );
        }
      ),
      barrierDismissible: true,
    );
  }

  void _showUserProfileBottomSheet(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final relationshipStatus = controller.getUserRelationshipStatus(user.id);
    final isFriend = relationshipStatus == UserRelationshipStatus.friends;
    final canViewPhoto = PrivacyHelper.canViewProfilePhoto(user, currentUserId, isFriend);
    
    
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeHelper.textSecondaryColor(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Profile Image with ring and status
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeHelper.cardColor(context),
                  border: Border.all(color: ThemeHelper.borderColor(context).withOpacity(0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: AppTheme.primaryColor,
                      backgroundImage: canViewPhoto ? _getBackgroundImage() : null,
                      child: canViewPhoto && _getBackgroundImage() != null
                          ? null
                          : Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    if (PrivacyHelper.shouldShowOnlineStatus(user))
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: ThemeHelper.cardColor(context), width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Name
              Text(
                user.displayName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.textPrimaryColor(context),
                  letterSpacing: 0.3,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Email with icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: ThemeHelper.textSecondaryColor(context).withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: ThemeHelper.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
              
              if (user.bio.isNotEmpty) ...[
                const SizedBox(height: 20),
                // Divider
                Container(
                  width: 60,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        ThemeHelper.borderColor(context).withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Bio with icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: ThemeHelper.textSecondaryColor(context).withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ThemeHelper.textSecondaryColor(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ThemeHelper.backgroundColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeHelper.borderColor(context).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          user.bio,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: ThemeHelper.textPrimaryColor(context),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 28),
              
              // Action Button (Add Friend / Request Sent / Accept)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Obx(() {
                  final relationshipStatus = controller.getUserRelationshipStatus(user.id);
                  return _buildProfileActionButton(relationshipStatus);
                }),
              ),
              
              const SizedBox(height: 24),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }


  Widget _buildProfileActionButton(UserRelationshipStatus relationshipStatus) {
    switch (relationshipStatus) {
      case UserRelationshipStatus.none:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              controller.handleRelationshipAction(user);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text(
              'Add Friend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );

      case UserRelationshipStatus.friendRequestSent:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Get.back();
              _showCancleRequestDialog();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: ThemeHelper.borderColor(Get.context!),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(
              Icons.schedule_rounded,
              size: 18,
              color: ThemeHelper.textSecondaryColor(Get.context!),
            ),
            label: Text(
              'Cancel Request',
              style: TextStyle(
                color: ThemeHelper.textSecondaryColor(Get.context!),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );

      case UserRelationshipStatus.friendRequestReceived:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              controller.handleRelationshipAction(user);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text(
              'Accept Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );

      case UserRelationshipStatus.blocked:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).brightness == Brightness.dark
                  ? const Color(0xFF3A2A2A)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Blocked',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );

      case UserRelationshipStatus.friends:
        return const SizedBox.shrink();
    }
  }
}