import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/profile_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/views/widgets/user_avatar.dart';

class PersonalInformationView extends GetView<ProfileController> {
  const PersonalInformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final bioController = TextEditingController();
    
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
          'Personal Information',
          style: TextStyle(
            color: ThemeHelper.textPrimaryColor(context),
            fontWeight: FontWeight.w600,
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

        // Initialize controllers with current values
        if (nameController.text.isEmpty) {
          nameController.text = user.displayName;
        }
        if (bioController.text.isEmpty) {
          bioController.text = user.bio;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture with Edit Button
              Stack(
                children: [
                  UserAvatar(
                    user: user,
                    radius: 60,
                    showOnlineStatus: false,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        _showAvatarOptions(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ThemeHelper.primaryColor(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: ThemeHelper.cardColor(context), width: 3),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: ThemeHelper.textPrimaryColor(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 32),
              
              // Name Field
              _buildTextField(
                controller: nameController,
                label: 'Display Name',
                icon: Icons.person_outline,
                hint: 'Enter your name',
              ),
              
              SizedBox(height: 20),
              
              // Bio Field
              _buildTextField(
                controller: bioController,
                label: 'Bio',
                icon: Icons.info_outline,
                hint: 'Tell us about yourself',
                maxLines: 3,
              ),
              
              SizedBox(height: 20),
              
              // Email Field (Read-only)
              _buildTextField(
                controller: TextEditingController(text: user.email),
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: false,
              ),
              
              SizedBox(height: 20),
              
              // Gender Field (Read-only, shows current selection)
              _buildTextField(
                controller: TextEditingController(
                  text: user.gender.isEmpty 
                    ? 'Not specified' 
                    : user.gender[0].toUpperCase() + user.gender.substring(1)
                ),
                label: 'Gender',
                icon: Icons.wc_outlined,
                enabled: false,
              ),
              
              SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _saveChanges(
                      nameController.text.trim(),
                      bioController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ThemeHelper.textPrimaryColor(Get.context!),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: TextStyle(
            color: enabled ? ThemeHelper.textPrimaryColor(Get.context!) : ThemeHelper.textSecondaryColor(Get.context!),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            filled: true,
            fillColor: enabled ? ThemeHelper.cardColor(Get.context!) : ThemeHelper.cardColor(Get.context!).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ThemeHelper.borderColor(Get.context!)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ThemeHelper.borderColor(Get.context!)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ThemeHelper.borderColor(Get.context!).withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return;

    final availableAvatars = user.gender == 'male' 
        ? controller.maleAvatars 
        : controller.femaleAvatars;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            // Title
            Text(
              'Choose Avatar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ThemeHelper.textPrimaryColor(context),
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 24),
            
            // Avatar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: availableAvatars.length,
              itemBuilder: (context, index) {
                final avatarCode = availableAvatars[index];
                final isSelected = controller.selectedAvatarCode == avatarCode;
                
                return GestureDetector(
                  onTap: () {
                    controller.selectAvatar(avatarCode);
                    controller.updateUserProfile();
                    Get.back();
                    Get.snackbar(
                      'Success',
                      'Avatar updated successfully',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppTheme.successColor.withOpacity(0.1),
                      colorText: AppTheme.successColor,
                      duration: Duration(seconds: 2),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : AppTheme.borderColor.withOpacity(0.3),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ] : [],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/$avatarCode.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _saveChanges(String name, String bio) {
    if (name.isEmpty) {
      Get.snackbar(
        'Error',
        'Name cannot be empty',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
      );
      return;
    }

    if (bio.isEmpty) {
      Get.snackbar(
        'Error',
        'Bio cannot be empty',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
      );
      return;
    }

    controller.updateUserProfile(name: name, bio: bio);
    Get.back();
    Get.snackbar(
      'Success',
      'Profile updated successfully',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.successColor.withOpacity(0.1),
      colorText: AppTheme.successColor,
    );
  }
}
