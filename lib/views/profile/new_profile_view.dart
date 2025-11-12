import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/profile_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class NewProfileView extends GetView<ProfileController> {
  const NewProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeHelper.backgroundColor(context),
        elevation: 0,
        automaticallyImplyLeading: false,
       
        title: Text(
          'Profile',
          style: TextStyle(
            color: ThemeHelper.textPrimaryColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        final user = controller.currentUser;
        if (user == null) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeHelper.cardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ThemeHelper.borderColor(context).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image on the left with shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: controller.getAvatarPath(user.avatarCode, user.gender) != null
                            ? AssetImage(controller.getAvatarPath(user.avatarCode, user.gender)!)
                            : null,
                        child: controller.getAvatarPath(user.avatarCode, user.gender) == null
                            ? Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Name, Bio, Status, Email on the right (left-aligned)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          
                          // Name
                          Text(
                            user.displayName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: ThemeHelper.textPrimaryColor(context),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 6),
                          
                          // Bio (WhatsApp-style About)
                          Text(
                            user.bio,
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeHelper.textSecondaryColor(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          
                          // Online Status
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: user.isOnline ? AppTheme.successColor : AppTheme.textSecoundaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                user.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user.isOnline ? AppTheme.successColor : ThemeHelper.textSecondaryColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          
                          // Email
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeHelper.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 4),
              
              // Settings Options
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildOptionCard(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Change name, avatar',
                      onTap: () => Get.toNamed(AppRoutes.personalInformation),
                    ),
                    SizedBox(height: 12),
                    
                    _buildOptionCard(
                      icon: Icons.privacy_tip,
                      title: 'Privacy',
                      subtitle: 'Blocked contacts, visibility settings',
                      onTap: () => Get.toNamed(AppRoutes.privacySettings),
                    ),
                    SizedBox(height: 12),
                    
                    _buildOptionCard(
                      icon: Icons.lock_outline,
                      title: 'Account',
                      subtitle: 'Change password, delete account',
                      onTap: () => Get.toNamed(AppRoutes.accountSettings),
                    ),
                    SizedBox(height: 12),
                    
                    _buildOptionCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chats',
                      subtitle: 'Theme, chat theme',
                      onTap: () => Get.toNamed(AppRoutes.chatSettings),
                    ),
                    SizedBox(height: 12),
                    
                    _buildOptionCard(
                      icon: Icons.help_outline,
                      title: 'Help',
                      subtitle: 'Help center, FAQ, contact us',
                      onTap: () => Get.toNamed(AppRoutes.helpCenter),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // App Version
              Text(
                'Talkzy v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.textSecondaryColor(context),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: ThemeHelper.cardColor(Get.context!),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeHelper.borderColor(Get.context!).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.textPrimaryColor(Get.context!),
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.textSecondaryColor(Get.context!),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: ThemeHelper.textSecondaryColor(Get.context!).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
