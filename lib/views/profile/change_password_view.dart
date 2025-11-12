import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:talkzy_beta1/controllers/change_password_controller.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeHelper.backgroundColor(context),
        title: Text(
          "Change  Password",
          style: TextStyle(color: ThemeHelper.textPrimaryColor(context)),
        ),
      ),

      body: SafeArea(child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 20,),
            Center(
             child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: ThemeHelper.backgroundColor(context),
               shape: BoxShape.circle
              ),
              child: Icon(
                Icons.security_rounded,
                size: 40,
                color: ThemeHelper.textPrimaryColor(context),
              ),
             ), 
            ),
            SizedBox(height: 24,),
            Text('Update Your Password',
            style:Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ) ,
             textAlign: TextAlign.center,
            ),
            SizedBox(height: 8,),
            Text('Enter the current password and choose a new secure password',
            style:Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeHelper.textSecondaryColor(context),
            ) ,
             textAlign: TextAlign.start,
             
            ),   

            SizedBox(height: 40,),

            Obx(()=>TextFormField(
                controller: controller.currentPasswordController,
                obscureText: controller.obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(onPressed: controller.toggleCurrentPasswordVisibility,
                   icon:  Icon(
                    controller.obscureCurrentPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined
                   ),
                   
                   ),
                   hintText: "Enter your current password",
                ),
                validator: controller.validateCurrentPassword,


            ),
            ),
           
            SizedBox(height: 20,),

            
            Obx(()=>TextFormField(
                controller: controller.newPasswordController,
                obscureText: controller.obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(onPressed: controller.toggleNewPasswordVisibility,
                   icon:  Icon(
                    controller.obscureNewPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined
                   ),
                   
                   ),
                   hintText: "Enter your current password",
                ),
                validator: controller.validateNewPassword,


            ),
            ),
             SizedBox(height: 20,),

            
            Obx(()=>TextFormField(
                controller: controller.confirmPasswordController,
                obscureText: controller.obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(onPressed: controller.toggleConfirmPasswordVisibility,
                   icon:  Icon(
                    controller.obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined
                   ),
                   
                   ),
                   hintText: "Confirm your new password",
                ),
                validator: controller.validateConfirmPassword,


            ),
            ),
            SizedBox(height: 40,),
            Obx(()=>SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading ? null : controller.changePassword,
                  icon: controller.isLoading ? SizedBox(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ) ,
                  ):Icon(Icons.security),
                 label: Text(controller.isLoading ? 'Upadting...':'Update Password'),
                 ),
            ))

          ],
        ),

        ),
      ))     



    );
  }
}