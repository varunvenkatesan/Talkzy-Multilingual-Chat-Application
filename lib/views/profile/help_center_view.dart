import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

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
          'Help Center',
          style: TextStyle(
            color: ThemeHelper.textPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Section
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.textPrimaryColor(context),
              ),
            ),
            SizedBox(height: 16),
            
            _buildOptionCard(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'talkzychatappofficial@gmail.com',
              iconColor: AppTheme.primaryColor,
              onTap: () {
                Get.snackbar(
                  'Email Support',
                  'Send your queries to talkzychatappofficial@gmail.com',
                  snackPosition: SnackPosition.TOP,
                  duration: Duration(seconds: 4),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  colorText: AppTheme.primaryColor,
                );
              },
            ),
            
            SizedBox(height: 32),
            
            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.textPrimaryColor(context),
              ),
            ),
            SizedBox(height: 16),
            
            _buildFAQItem(
              context: context,
              question: 'What is Talkzy?',
              answer: 'Talkzy is a modern messaging app that allows you to connect with friends and family. Chat in real-time, share moments, and stay connected with features like message translation, customizable chat themes, and privacy controls.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How does the translation feature work?',
              answer: 'Talkzy offers real-time message translation! In any chat, tap the menu (three dots) and select "Language" to choose your preferred translation language. All incoming messages will be automatically translated to your selected language. You can translate to Hindi, Tamil, Telugu, Bengali, Marathi, Gujarati, Kannada, Malayalam, Punjabi, and Urdu.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do I customize my chat theme?',
              answer: 'Go to Profile > Chat Settings to personalize your chat experience. Choose from beautiful themes like Ocean, Forest, Sunset, and Midnight. Each theme changes your chat bubble colors, backgrounds, and overall chat appearance.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do I add friends?',
              answer: 'Navigate to the "Find Friends" tab from the bottom navigation. Search for users by name or email, then tap the "Add Friend" button to send a friend request. Once they accept, you can start chatting!',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do I change my profile picture?',
              answer: 'Go to Profile > Personal Information, tap the camera icon on your profile picture, and choose from our collection of avatars or upload your own photo. You can also select gender-based default avatars.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'Can I edit or delete messages?',
              answer: 'Yes! Long press on any message you sent to see options. You can edit the message content or delete it. For received messages, you can delete them locally (only removes from your device). Edited messages show an "Edited" indicator.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do privacy settings work?',
              answer: 'Talkzy respects your privacy. Go to Profile > Privacy to control who can see your profile photo, last seen status, and online status. You can choose between Everyone, Friends Only, or Nobody for each setting.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'What does blocking a user do?',
              answer: 'When you block someone, they cannot send you messages or see your online status. You can block/unblock users from the chat menu. Blocked users won\'t be notified that they\'ve been blocked.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do I enable dark mode?',
              answer: 'Go to Profile > Chat Settings and toggle the "Dark Mode" switch. The app will switch to a beautiful dark theme that\'s easier on your eyes, especially at night.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do I change my password?',
              answer: 'Navigate to Profile > Account > Change Password. Enter your current password, then your new password twice to confirm. Make sure to use a strong password with letters, numbers, and special characters.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'What happens if I delete my account?',
              answer: 'Deleting your account is permanent and cannot be undone. All your data including messages, friends, profile information, and chat history will be permanently deleted from our servers. Consider this carefully before proceeding.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'How do notifications work?',
              answer: 'Talkzy sends you notifications for new messages, friend requests, and important updates. You can manage notification permissions in your device settings. Make sure notifications are enabled to stay updated.',
            ),
            
            SizedBox(height: 12),
            
            _buildFAQItem(
              context: context,
              question: 'Is my data secure?',
              answer: 'Yes! We take your privacy seriously. Your messages are stored securely, and we never share your personal information with third parties. Read our Privacy Policy below for complete details on how we protect your data.',
            ),
            
            SizedBox(height: 32),
            
            // Privacy Policy Section
            _buildOptionCard(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Learn how we protect your data',
              iconColor: AppTheme.primaryColor,
              onTap: () => _showPrivacyPolicy(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThemeHelper.borderColor(context).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
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
                      color: ThemeHelper.textPrimaryColor(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeHelper.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ThemeHelper.textSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeHelper.borderColor(context).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.help_outline,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.textPrimaryColor(context),
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: ThemeHelper.textSecondaryColor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: January 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecoundaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16),
              _buildPrivacySection(
                'Information We Collect',
                'We collect information you provide when creating an account (name, email, profile picture) and content you share (messages, photos). We also collect usage data to improve our services.',
              ),
              SizedBox(height: 12),
              _buildPrivacySection(
                'How We Use Your Information',
                'Your information is used to provide and improve our messaging services, enable communication between users, personalize your experience, and ensure platform security.',
              ),
              SizedBox(height: 12),
              _buildPrivacySection(
                'Data Security',
                'We implement industry-standard security measures to protect your data. Your messages are stored securely on Firebase servers with encryption. We never share your personal information with third parties without your consent.',
              ),
              SizedBox(height: 12),
              _buildPrivacySection(
                'Your Privacy Controls',
                'You have full control over your privacy settings. You can choose who sees your profile photo, online status, and last seen information. You can also block users and delete your account at any time.',
              ),
              SizedBox(height: 12),
              _buildPrivacySection(
                'Data Retention',
                'Your messages and profile data are retained as long as your account is active. When you delete your account, all your data is permanently removed from our servers.',
              ),
              SizedBox(height: 12),
              _buildPrivacySection(
                'Contact Us',
                'If you have questions about our privacy practices, please contact us at talkzychatappofficial@gmail.com',
              ),
              SizedBox(height: 16),
              Text(
                '© 2025 Talkzy. All rights reserved.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecoundaryColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecoundaryColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
