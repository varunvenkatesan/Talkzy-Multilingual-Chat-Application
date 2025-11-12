import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class AccountSettingsView extends StatelessWidget {
  const AccountSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
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
          'Account Settings',
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
            // Security Section
            Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.textPrimaryColor(context),
              ),
            ),
            SizedBox(height: 16),
            
            _buildOptionCard(
              context: context,
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              iconColor: AppTheme.primaryColor,
              onTap: () => Get.toNamed(AppRoutes.changePassword),
            ),
            
            SizedBox(height: 32),
            
            // Account Management Section
            Text(
              'Account Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.textPrimaryColor(context),
              ),
            ),
            SizedBox(height: 16),
            
            _buildOptionCard(
              context: context,
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out from your account',
              iconColor: AppTheme.warningColor,
              onTap: () => _showLogoutDialog(authController),
            ),
            
            SizedBox(height: 12),
            
            _buildOptionCard(
              context: context,
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              iconColor: AppTheme.errorColor,
              onTap: () => _showDeleteAccountDialog(authController),
            ),
            
            SizedBox(height: 32),
            
            // Warning Text
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Deleting your account is permanent and cannot be undone. All your data will be lost.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
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

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AuthController authController) {
    // Auto-populate email from user profile (try userModel first, then Firebase Auth user)
    final userEmail = authController.userModel?.email ?? 
                      authController.user?.email ?? 
                      '';
    
    print('🔍 Delete Account Dialog - User Email: $userEmail');
    print('🔍 UserModel Email: ${authController.userModel?.email}');
    print('🔍 Firebase Auth Email: ${authController.user?.email}');
    
    final emailController = TextEditingController(text: userEmail);
    final passwordController = TextEditingController();
    final RxBool obscurePassword = true.obs;
    final RxBool isDeleting = false.obs;
    
    Get.dialog(
      AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
              ),
              SizedBox(height: 20),
              Text(
                'Enter your password to confirm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 12),
              // Email field (read-only, auto-populated)
              TextField(
                controller: emailController,
                enabled: false, // Make it read-only
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: AppTheme.textSecoundaryColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppTheme.textSecoundaryColor.withOpacity(0.1),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 12),
              Obx(() => TextField(
                controller: passwordController,
                obscureText: obscurePassword.value,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword.value 
                        ? Icons.visibility_off 
                        : Icons.visibility,
                      color: AppTheme.textSecoundaryColor,
                    ),
                    onPressed: () => obscurePassword.value = !obscurePassword.value,
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecoundaryColor)),
          ),
          Obx(() => TextButton(
            onPressed: isDeleting.value ? null : () async {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              
              // Validate password (email is auto-populated)
              if (password.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please enter your password',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  colorText: AppTheme.errorColor,
                  margin: EdgeInsets.all(16),
                );
                return;
              }
              
              isDeleting.value = true;
              
              try {
                await authController.deleteAccountWithPassword(email, password);
                Get.back(); // Close dialog on success
              } catch (e) {
                // Error is already handled in controller
                isDeleting.value = false;
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: isDeleting.value 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorColor),
                  ),
                )
              : Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }
}
