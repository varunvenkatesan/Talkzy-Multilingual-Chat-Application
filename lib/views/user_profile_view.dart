import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/friends_controller.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/views/widgets/user_avatar.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';

class UserProfileView extends StatelessWidget {
  final UserModel user;

  const UserProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    
    // Check if the user is a friend
    bool isFriend = false;
    try {
      final friendsController = Get.find<FriendsController>();
      isFriend = friendsController.friends.any((friend) => friend.id == user.id);
    } catch (e) {
      // FriendsController might not be initialized
      isFriend = false;
    }
    
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeHelper.backgroundColor(context),
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
        ),
        iconTheme: IconThemeData(color: ThemeHelper.textPrimaryColor(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with Image
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Profile Image with Online Status
                  Stack(
                    children: [
                      UserAvatar(
                        user: user,
                        radius: 60,
                        showOnlineStatus: false,
                        viewerId: currentUserId,
                        isFriend: isFriend,
                      ),
                      if (PrivacyHelper.shouldShowOnlineStatus(user))
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: ThemeHelper.cardColor(context), width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.textPrimaryColor(context),
                        ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Online/Offline Status - Only show if privacy allows
                  if (user.showLastSeen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PrivacyHelper.shouldShowOnlineStatus(user)
                            ? AppTheme.successColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: PrivacyHelper.shouldShowOnlineStatus(user)
                              ? AppTheme.successColor
                              : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: PrivacyHelper.shouldShowOnlineStatus(user)
                                ? AppTheme.successColor
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            PrivacyHelper.shouldShowOnlineStatus(user)
                                ? 'Online'
                                : PrivacyHelper.getDisplayLastSeen(user, user.lastSeen),
                            style: TextStyle(
                              color: PrivacyHelper.shouldShowOnlineStatus(user)
                                  ? AppTheme.successColor
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Profile Details Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Bio Card
                  _buildInfoCard(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    content: user.bio.isNotEmpty ? user.bio : 'No bio available',
                    iconColor: AppTheme.primaryColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Email Card
                  _buildInfoCard(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Email',
                    content: user.email,
                    iconColor: Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Member Since Card
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Member Since',
                    content: _formatDate(user.createdAt),
                    iconColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeHelper.borderColor(context).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeHelper.textSecondaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.textPrimaryColor(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
