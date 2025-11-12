import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/privacy_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class BlockedContactsView extends GetView<PrivacyController> {
  const BlockedContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeHelper.backgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeHelper.textPrimaryColor(context)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Blocked Contacts',
          style: TextStyle(
            color: ThemeHelper.textPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (controller.blockedUsers.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.blockedUsers.length,
          itemBuilder: (context, index) {
            final user = controller.blockedUsers[index];
            return _buildBlockedUserCard(context, user);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ThemeHelper.primaryColor(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.block,
              size: 60,
              color: ThemeHelper.primaryColor(context).withOpacity(0.6),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Blocked Contacts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.textPrimaryColor(context),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You haven\'t blocked anyone yet. Blocked contacts won\'t be able to message you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ThemeHelper.textSecondaryColor(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(BuildContext context, dynamic user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeHelper.borderColor(context).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: ThemeHelper.primaryColor(context).withOpacity(0.1),
              backgroundImage: user.avatarCode != null
                  ? AssetImage('assets/images/${user.avatarCode}.png')
                  : null,
              child: user.avatarCode == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.primaryColor(context),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.textPrimaryColor(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeHelper.textSecondaryColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Unblock Button
            TextButton(
              onPressed: () => _showUnblockDialog(user),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.errorColor, width: 1),
                ),
              ),
              child: Text(
                'Unblock',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnblockDialog(dynamic user) {
    Get.dialog(
      AlertDialog(
        title: Text('Unblock ${user.displayName}?'),
        content: Text(
          'This person will be able to message you and see your activity again.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.unblockUser(user.id);
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
