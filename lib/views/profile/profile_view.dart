
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/profile_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/services/fcm_notification_service.dart';

class ProfileView  extends GetView<ProfileController>{
  const ProfileView({super.key});
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
       appBar: AppBar(
        title: Text("Profile"),
        // leading: IconButton(onPressed:()=>Get.back(), 
        //  icon:Icon(Icons.arrow_back)),
         actions: [
          Obx(()=>TextButton(onPressed: controller.isEditing 
          ? controller.toggleEditing 
          : controller.toggleEditing,
           child: Text(controller.isEditing ? 'Cancel': "Edit",
           style: TextStyle(
            color: controller.isEditing
            ?AppTheme.errorColor
            :AppTheme.primaryColor,
           ),
           )))
         ],
       ),

       body: Obx((){
        final user=controller.currentUser;
        if(user == null){
          return Center(child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
           child: Column(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      Obx(() => CircleAvatar(
                        radius:60,
                        backgroundColor: AppTheme.primaryColor,
                        child:user.photoURL.isNotEmpty ? ClipOval(child: Image.network(user.photoURL,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context,error,StackTrace){
                          return _buildDefaultAvatar(user, controller.selectedAvatarCode);
                  
                        },
                        )
                        
                        
                      )
                      :_buildDefaultAvatar(user, controller.selectedAvatarCode),
                      )),
                      if(controller.isEditing)
                        Positioned(
                         bottom:0,
                         right: 0,
                         child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white,width: 2),
                          ),
                          // child: IconButton(onPressed: ()
                          // {
                          //  Get.snackbar('Info','Photo Update Coming Soon!');
                          // },
                          // icon: Icon(Icons.camera_alt,
                          // size: 20,
                          // color: Colors.white,
                          
                          // ),
                       
                          ),
                          
                         ),
                        
                        
                        
                      
                      
                  
                    ],
                  ),
                
             
                SizedBox(height: 16,)   ,
                Text(user.displayName,
                style: Theme.of(Get.context!).textTheme.headlineSmall ?.copyWith(fontWeight: FontWeight.bold),
                
                ),
                SizedBox(height: 4,)   ,
                Text(user.email,
                style: Theme.of(Get.context!).textTheme.bodyMedium ?.copyWith(color:  AppTheme.textSecoundaryColor),
                
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4,horizontal: 12),
                  decoration: BoxDecoration(
                    color: user.isOnline ? AppTheme.secondaryColor.withOpacity(0.1)
                    :AppTheme.textSecoundaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color:user.isOnline ? AppTheme.successColor:
                          AppTheme.textSecoundaryColor,
                          borderRadius: BorderRadius.circular(4), 
                        ),
        
                      ),
                      SizedBox(width: 6,),
                      Text(user.isOnline ? 'Online': 'Offline',
                      style: Theme.of(Get.context!).textTheme.bodySmall ?.copyWith(
                        color: user.isOnline
                        ? AppTheme.successColor
                        :AppTheme.textSecoundaryColor,
                        fontWeight: FontWeight.w600,

                      ),

                      ),

                    ],
                  ),
                ),
                  SizedBox(height: 8,),
                  Text(controller.getjoinedData(),
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecoundaryColor,
                  ),
                  ),
                  

           ],
           ),
           
           SizedBox(height: 32,),
           Obx(()=>
           Card(
             child: Padding(padding: EdgeInsets.all(20),
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personal Information",
                  style: Theme.of(Get.context!).textTheme.headlineSmall ?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,  
                  ),
                ),
                SizedBox(height: 20,),
                TextFormField(
                    controller: controller.displayNameController,
                    enabled: controller.isEditing,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),   
                ),

                 SizedBox(height: 16,),
                 TextFormField(
                    controller: controller.emailController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText:"Email can't be changed",  
                    ),   
                ),

                 SizedBox(height: 20,),
                 Text(
                  "Gender",
                  style: Theme.of(Get.context!).textTheme.bodyLarge ?.copyWith(
                    fontWeight: FontWeight.w600,  
                  ),
                ),
                 SizedBox(height: 5,),
                 Obx(() => Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/male_1.png',
                              width: 28,
                              height: 28,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Male',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        value: 'male',
                        groupValue: controller.selectedGender,
                        onChanged: controller.isEditing ? (value) {
                          if (value != null) {
                            controller.updateGender(value);
                          }
                        } : null,
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/female_1.png',
                              width: 28,
                              height: 28,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Female',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        value: 'female',
                        groupValue: controller.selectedGender,
                        onChanged: controller.isEditing ? (value) {
                          if (value != null) {
                            controller.updateGender(value);
                          }
                        } : null,
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                )),

                // Avatar Selection
                Obx(() {
                  if (controller.selectedGender.isEmpty || !controller.isEditing) {
                    return SizedBox.shrink();
                  }

                  final avatars = controller.selectedGender == 'male' 
                      ? controller.maleAvatars 
                      : controller.femaleAvatars;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        "Choose Avatar",
                        style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(3, (index) {
                            final avatarCode = avatars[index]; // Use unique code for each avatar
                            final isSelected = controller.selectedAvatarCode == avatarCode;
                            
                            return GestureDetector(
                              onTap: () {
                                controller.selectAvatar(avatarCode);
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppTheme.primaryColor 
                                        : Colors.grey.shade300,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ] : null,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/${avatarCode}.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                }),
                  
                 if(controller.isEditing)...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: controller.isLoading ? null :controller.updateProfile,
                     child: 
                        controller.isLoading ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      :Text("Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        )
                      ),
                    ),
                  ),
                   SizedBox(height: 16,),
                  // // Add test notification button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: OutlinedButton(
                  //     onPressed: () {
                  //       // Call the test notification service
                  //       _showTestNotification();
                  //     },
                  //     child: Text("Test Notification"),
                  //     style: OutlinedButton.styleFrom(
                  //       side: BorderSide(color: AppTheme.primaryColor),
                  //       foregroundColor: AppTheme.primaryColor,
                  //       padding: EdgeInsets.symmetric(vertical: 16),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       )
                  //     ),
                  //   ),
                  // ),
                ]
              ],
             ),
             ),
           ),
           ),
           
           SizedBox(height: 32,),

           Card(
             child: Column(
               children: [
                 Column(
                children: [
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text('Privacy'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: ()=>Get.toNamed(AppRoutes.privacySettings),
                ),
                Divider(height: 1,color: Colors.grey,),
                ListTile(
                  leading: Icon(
                    Icons.security,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: ()=>Get.toNamed(AppRoutes.changePassword),
                ),
                Divider(height: 1,color: Colors.grey,),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: AppTheme.errorColor,
                  ),
                  title: Text('Delete Account'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: controller.deleteAccount,
                ),

                 Divider(height: 1,color: Colors.grey,),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: AppTheme.errorColor,
                  ),
                  title: Text('Sign Out'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: controller.signOut,
                ),




                ],
                ),
               ],
             ),
           ),

           SizedBox(height: 20),
           Text("Talkzy ChatApp v1.0.0",
           style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecoundaryColor,
           ),
           ),

           



           ],
        ),
           
        );
      }),
    );
  }
  
  // Add this method to the ProfileView class
  void _showTestNotification() async {
    try {
      final notificationService = Get.find<FCMNotificationService>();
      final token = await notificationService.getToken();
      if (token != null) {
        Get.snackbar(
          'FCM Token',
          'Token: ${token.substring(0, 20)}...',
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 5),
        );
        print('Full FCM Token: $token');
      } else {
        Get.snackbar(
          'Error',
          'Could not get FCM token',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error getting FCM token: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }
  
  Widget _buildDefaultAvatar(user, String avatarCode) {
    // Priority 1: Show selected avatar if avatarCode exists
    if (avatarCode.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          'assets/images/$avatarCode.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gender-based avatar
            return _buildGenderAvatar(user);
          },
        ),
      );
    }

    // Priority 2: Show gender-based avatar
    return _buildGenderAvatar(user);
  }

  Widget _buildGenderAvatar(user) {
    // Show gender-based avatar if gender is selected
    if (user.gender == 'male') {
      return ClipOval(
        child: Image.asset(
          'assets/images/male_1.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (user.gender == 'female') {
      return ClipOval(
        child: Image.asset(
          'assets/images/female_1.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // Default to initial letter avatar if no gender selected
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}