import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/services/auth_service.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _emailSent = false.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get emailSent => _emailSent.value;

  TextEditingController get emailController => _emailController;

  @override
  void onClose() {
    _emailController.dispose();
    super.onClose();
  }

  Future<void> sentPasswordResetEmail() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      _emailSent.value = true;
      Get.snackbar(
        'Success',
        'Password reset email sent to ${_emailController.text}',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void goBackToLogin() {
    Get.back();
  }

  void resendEmail() {
    _emailSent.value = false;
    sentPasswordResetEmail();
  }

  String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}
