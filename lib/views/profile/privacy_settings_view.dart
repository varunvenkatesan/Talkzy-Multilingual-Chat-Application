import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/privacy_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/views/profile/blocked_contacts_view.dart';

class PrivacySettingsView extends GetView<PrivacyController> {
  const PrivacySettingsView({super.key});

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
          'Privacy',
          style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blocked Contacts Section
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.block,
                    color: AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Blocked Contacts',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Obx(() {
                  final count = controller.blockedUsers.length;
                  return Text(
                    count > 0 ? '$count blocked' : 'No blocked contacts',
                    style: TextStyle(color: ThemeHelper.textSecondaryColor(context)),
                  );
                }),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.to(() => const BlockedContactsView()),
              ),
            ),

            // Privacy Settings Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Last Seen & Online Status
                  Obx(() => SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.visibility,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Last Seen & Online Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      controller.showLastSeen
                          ? 'Everyone can see when you\'re online'
                          : 'Nobody can see when you\'re online',
                      style: TextStyle(color: ThemeHelper.textSecondaryColor(context), fontSize: 12),
                    ),
                    value: controller.showLastSeen,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) => controller.updateLastSeenVisibility(value),
                  )),
                ],
              ),
            ),

            // Profile Photo Visibility
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.photo_camera,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Profile Photo Visibility',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Obx(() => Text(
                      'Who can see your profile photo: ${controller.profilePhotoVisibility.capitalize}',
                      style: TextStyle(color: ThemeHelper.textSecondaryColor(context), fontSize: 12),
                    )),
                  ),
                  Obx(() => Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Everyone'),
                        subtitle: Text(
                          'All users can see your profile photo',
                          style: TextStyle(color: ThemeHelper.textSecondaryColor(context), fontSize: 11),
                        ),
                        value: 'everyone',
                        groupValue: controller.profilePhotoVisibility,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) => controller.updateProfilePhotoVisibility(value!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Friends Only'),
                        subtitle: Text(
                          'Only your friends can see your profile photo',
                          style: TextStyle(color: ThemeHelper.textSecondaryColor(context), fontSize: 11),
                        ),
                        value: 'friends',
                        groupValue: controller.profilePhotoVisibility,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) => controller.updateProfilePhotoVisibility(value!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Nobody'),
                        subtitle: Text(
                          'No one can see your profile photo',
                          style: TextStyle(color: ThemeHelper.textSecondaryColor(context), fontSize: 11),
                        ),
                        value: 'nobody',
                        groupValue: controller.profilePhotoVisibility,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) => controller.updateProfilePhotoVisibility(value!),
                      ),
                    ],
                  )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Privacy settings help you control who can see your information and how you interact with others.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ThemeHelper.textSecondaryColor(context),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
