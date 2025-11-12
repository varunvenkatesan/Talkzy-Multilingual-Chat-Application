import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/services/auth_service.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxString _error = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isinitialized = false.obs;
  User? get user => _user.value;
  UserModel? get userModel => _userModel.value; 
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _user.value!=null;
  bool get isinitialized => _isinitialized.value;
  Stream<User?> get userStream => _user.stream;
  Rx<User?> get rxUser => _user;

  get text => null;
  
  
  @override
  void onInit(){
    super.onInit();
    _user.bindStream(_authService.authStateChanges);
    // Remove the automatic navigation from here to avoid conflicts with splash screen
    // ever(_user, _handleAuthStateChange);
  }

  // This method was causing conflicts with splash screen navigation
  // void _handleAuthStateChange(User? user){
  //   if(user==null){
  //     if(Get.currentRoute!= AppRoutes.login){
  //       Get.offAllNamed(AppRoutes.login);
  //     }
  //   }
  //   else{
  //     if(Get.currentRoute!= AppRoutes.main){
  //       Get.offAllNamed(AppRoutes.main);
  //   }
  // }
  // if(! _isinitialized.value){
  //   _isinitialized.value=true;
  // }
  // }

  void checkInitialAuthState(){
    final currentUser = FirebaseAuth.instance.currentUser;
    if(currentUser !=null){
      _user.value=currentUser;
      // Don't navigate here, let the splash screen handle navigation
      // Get.offAllNamed(AppRoutes.main);
    }else{
      // Don't navigate here, let the splash screen handle navigation
      // Get.offAllNamed(AppRoutes.login);
    }
    _isinitialized.value=true;
  }

   Future<void> signInWithEmailAndPassword(String email,String password)  async {
    try{
      _isLoading.value=true;
      _error.value='';

      UserModel? userModel = await _authService.signInWithEmailAndPassword(
        email,
       password
         );
      if(userModel!=null){
        _userModel.value =userModel;
        Get.offAllNamed(AppRoutes.main);
      }
    }catch(e){
      _error.value=e.toString();
      String message = 'Failed to login';
      final m = e.toString();
      if (m.contains('wrong-password')) {
        message = 'Wrong password';
      } else if (m.contains('user-not-found')) {
        message = 'No account found for this email';
      } else if (m.contains('invalid-email')) {
        message = 'Invalid email address';
      } else if (m.contains('too-many-requests')) {
        message = 'Too many attempts. Try again later';
      } else if (m.contains('network-request-failed')) {
        message = 'Network error. Check your connection';
      }
      Get.snackbar('Error', message, colorText: AppTheme.errorColor, snackPosition: SnackPosition.TOP);
      print(e);
    }
    finally{
      _isLoading.value=false;
    }
   }


   
   Future<void> registerWithEmailAndPassword(String email, String password, String displayName, String gender, {String? avatarCode}) async {
    try{
      _isLoading.value=true;
      _error.value='';

      UserModel? userModel = await _authService.registerWithEmailAndPassword(email, password, displayName, gender, avatarCode: avatarCode);
      if(userModel!=null){
        _userModel.value =userModel;
        Get.offAllNamed(AppRoutes.main);
      }
    }catch(e){
      _error.value=e.toString();
      print('Registration Error: $e');
      
      // Show detailed error message
      String errorMessage = 'Failed to create account';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Check your connection';
      } else if (e.toString().contains('operation-not-allowed')) {
        errorMessage = 'Email/Password sign-in is disabled. Enable it in Firebase Console > Authentication > Sign-in method.';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    }
    finally{
      _isLoading.value=false;
    }
   }

   Future<void>signOut()async{
      try{
        print('🚪 AuthController: Starting sign out...');
        _isLoading.value=true;
        
        await _authService.signOut();
        print('✅ AuthController: Sign out service completed');
        
        _userModel.value=null;
        _user.value=null;
        print('✅ AuthController: User data cleared');
        
        // Navigate to login
        Get.offAllNamed(AppRoutes.login);
        print('✅ AuthController: Navigated to login');
        
        Get.snackbar(
          'Success',
          'Signed out successfully',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      }catch(e){
        _error.value =e.toString();
        print('❌ AuthController: Sign out error: ${e.toString()}');
        
        Get.snackbar(
          'Error',
          'Failed to sign out: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
      finally{
        _isLoading.value=false;
        print('🏁 AuthController: Sign out process completed');
      }
   }

     Future<void> deleteAccount()async{
      try{
        _isLoading.value=true;
        await _authService.deleteAccount();
        _userModel.value=null;
        Get.offAllNamed(AppRoutes.login);
      }catch(e){
        _error.value =e.toString();
        Get.snackbar('Error','Failed TO Delete Account', snackPosition: SnackPosition.TOP);
      }
      finally{
        _isLoading.value=false;
        
      }
   }

   Future<void> deleteAccountWithPassword(String email, String password) async {
      try {
        _isLoading.value = true;
        
        // Get current user email from either userModel or Firebase Auth
        final currentUserEmail = _userModel.value?.email ?? _user.value?.email;
        
        print('🔍 Delete Account - Provided Email: $email');
        print('🔍 Delete Account - Current User Email: $currentUserEmail');
        print('🔍 Delete Account - UserModel Email: ${_userModel.value?.email}');
        print('🔍 Delete Account - Firebase Auth Email: ${_user.value?.email}');
        
        // Verify email matches current user (check both sources)
        if (email != currentUserEmail) {
          throw Exception('Email does not match your account');
        }
        
        // Delete account with email and password for reauthentication
        await _authService.deleteAccount(email: email, password: password);
        _userModel.value = null;
        
        // Show success message
        Get.snackbar(
          'Success',
          'Account deleted successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        );
        
        // Navigate to login after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          Get.offAllNamed(AppRoutes.login);
        });
      } on FirebaseAuthException catch (e) {
        _error.value = e.code;
        String errorMessage;
        
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'user-not-found':
            errorMessage = 'User not found.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'requires-recent-login':
            errorMessage = 'Please re-authenticate and try again.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to delete account. Please try again.';
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
        );
        rethrow; // Rethrow to handle in UI
      } catch (e) {
        _error.value = e.toString();
        Get.snackbar(
          'Error',
          'Failed to delete account: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
        );
        rethrow; // Rethrow to handle in UI
      } finally {
        _isLoading.value = false;
      }
   }

   void cleaeError(){
    _error.value='';
   }

}