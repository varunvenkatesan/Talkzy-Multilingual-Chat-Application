import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/privacy_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';

/// Debug/Test view to verify privacy features are working
class PrivacyTestView extends StatelessWidget {
  const PrivacyTestView({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to get controllers
    final authController = Get.find<AuthController>();
    final privacyController = Get.put(PrivacyController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text('Privacy Test/Debug'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auth Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔐 Authentication Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('User ID', authController.user?.uid ?? 'NULL'),
                    _buildInfoRow('Email', authController.user?.email ?? 'NULL'),
                    _buildInfoRow('Logged In', authController.user != null ? '✅ Yes' : '❌ No'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Privacy Settings Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔒 Privacy Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Last Seen', privacyController.showLastSeen ? '✅ Visible' : '❌ Hidden'),
                    _buildInfoRow('Read Receipts', privacyController.readReceipts ? '✅ Enabled' : '❌ Disabled'),
                    _buildInfoRow('Profile Photo', privacyController.profilePhotoVisibility.toUpperCase()),
                    _buildInfoRow('Bio', privacyController.bioVisibility.toUpperCase()),
                  ],
                )),
              ),
            ),

            SizedBox(height: 16),

            // Blocked Users Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚫 Blocked Contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Count', '${privacyController.blockedUsers.length}'),
                    _buildInfoRow('Loading', privacyController.isLoading ? '⏳ Yes' : '✅ No'),
                  ],
                )),
              ),
            ),

            SizedBox(height: 16),

            // Test Actions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Test Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        privacyController.updateLastSeenVisibility(!privacyController.showLastSeen);
                      },
                      icon: Icon(Icons.visibility),
                      label: Text('Toggle Last Seen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        privacyController.updateReadReceipts(!privacyController.readReceipts);
                      },
                      icon: Icon(Icons.done_all),
                      label: Text('Toggle Read Receipts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/privacy-settings');
                      },
                      icon: Icon(Icons.privacy_tip),
                      label: Text('Open Privacy Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How to Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Check if User ID is not NULL\n'
                      '2. Tap "Toggle Last Seen" button\n'
                      '3. Watch the "Last Seen" value change\n'
                      '4. Check Firebase Console to verify save\n'
                      '5. Restart app and check if settings persist',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label + ':',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
