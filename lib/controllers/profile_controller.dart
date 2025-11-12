import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';

class ProfileController extends GetxController {

final FirestoreService _firestoreService= FirestoreService();
final AuthController _authController =Get.find<AuthController>();
final TextEditingController displayNameController = TextEditingController();
final TextEditingController emailController = TextEditingController();

final RxBool _isLoading = false.obs;
final RxBool _isEditing = false.obs;
final RxString _error =''.obs;
final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
final RxString _selectedGender = ''.obs;
final RxString _selectedAvatarCode = ''.obs;

// Avatar options
final List<String> maleAvatars = ['male_1', 'male_2', 'male_3'];
final List<String> femaleAvatars = ['female_1', 'female_2', 'female_3'];

bool get isLoading => _isLoading.value;
bool get isEditing  => _isEditing.value;
String get error => _error.value;
UserModel?  get currentUser => _currentUser.value;
String get selectedGender => _selectedGender.value;
String get selectedAvatarCode => _selectedAvatarCode.value;

 @override
 void onInit(){
  super.onInit();
  _loadUserData();
 }

 @override
 void onClose(){
  // displayNameController.dispose();
  // emailController.dispose();
  super.onClose();
 }

  void _loadUserData(){
   final currentUserId= _authController.user?.uid;

   if(currentUserId != null){
    _currentUser.bindStream(_firestoreService.getUserStream(currentUserId));

    ever(_currentUser, (UserModel? user){
        if(user != null){
          displayNameController.text=user.displayName;
          emailController.text=user.email;
          _selectedGender.value=user.gender;
          _selectedAvatarCode.value=user.avatarCode ?? '';
        }

    });
   }
  }

  void selectAvatar(String avatarCode) {
    _selectedAvatarCode.value = avatarCode;
  }

  String? getAvatarPath(String? avatarCode, String? gender) {
    if (avatarCode != null && avatarCode.isNotEmpty) {
      return 'assets/images/$avatarCode.png';
    } else if (gender == 'male') {
      return 'assets/images/male_1.png';
    } else if (gender == 'female') {
      return 'assets/images/female_1.png';
    }
    return null;
  }

  void toggleEditing(){
    _isEditing.value=!_isEditing.value;
    
    if(!_isEditing.value){
      final user = _currentUser.value;
      if(user != null){
        displayNameController.text=user.displayName;
        emailController.text=user.email;
        _selectedGender.value=user.gender;
      }
    }
  }

  void updateGender(String gender){
    _selectedGender.value=gender;
  }

  Future<void> updateProfile()async{
   try{
     _isLoading.value =true;
     _error.value='';
     final user=_currentUser.value;
     if(user == null) return;

     final updatedUser = user.copyWith(
      displayName: displayNameController.text,
      gender: _selectedGender.value,
      avatarCode: _selectedAvatarCode.value.isNotEmpty ? _selectedAvatarCode.value : null,
     );
   
    await _firestoreService.updateUser(updatedUser);
    _isEditing.value=false;
        Get.snackbar("Success", "Profile  Updated Successfully", snackPosition: SnackPosition.TOP);

  

   }catch(e){
    _error.value=e.toString();
    Get.snackbar("Error", "Failed To Update Profile", snackPosition: SnackPosition.TOP);

   }finally{
    _isLoading.value=false;
   }


  }
 
  Future<void>signOut()async{
    try{
      await _authController.signOut();

    }catch (e){
      Get.snackbar("Error","Failed To Sign Out", snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> deleteAccount()async{
    try{
      final result =await Get.dialog<bool>(
        AlertDialog(
          title: Text("Delete Account"),
          content:  Text('Are you sure you want to delete your account? This action can not be undone'),
        actions: [
          TextButton(onPressed:()=>Get.back(result: false),
           child: Text("Cancel"),),

           TextButton(onPressed:()=>Get.back(result: true),
           style:TextButton.styleFrom(backgroundColor: Colors.redAccent) ,
            child: Text("Delete", style: TextStyle(color: Colors.white),),),

        ],
        ),

      );

      if(result==true){
        _isLoading.value=true;
        await _authController.deleteAccount();
        // Safety: Ensure navigation to login page
        Get.offAllNamed(AppRoutes.login);
      }
    }catch(e){
            Get.snackbar("Error","Failed To Delete Account", snackPosition: SnackPosition.TOP);

    }finally{
      _isLoading.value=false;
    }
  }

  String getjoinedData(){
    final user=_currentUser.value;
    if(user == null) return '';
    final date=user.createdAt;
    final months=[
      'Jan','Fab','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
     
     return 'Joined ${months[date.month-1]} ${date.year}';


  }
   
   void clearError(){
    _error.value='';
   }

  // New method for updating user profile with name and bio
  Future<void> updateUserProfile({String? name, String? bio}) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      final user = _currentUser.value;
      if (user == null) return;

      final updatedUser = user.copyWith(
        displayName: name ?? user.displayName,
        bio: bio ?? user.bio,
        avatarCode: _selectedAvatarCode.value.isNotEmpty ? _selectedAvatarCode.value : user.avatarCode,
      );

      await _firestoreService.updateUser(updatedUser);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar("Error", "Failed to update profile", snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  // Show avatar selection dialog
  void showAvatarSelectionDialog() {
    final user = _currentUser.value;
    if (user == null) return;

    final availableAvatars = user.gender == 'male' ? maleAvatars : femaleAvatars;

    Get.dialog(
      AlertDialog(
        title: Text('Select Avatar'),
        content: Container(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availableAvatars.length,
            itemBuilder: (context, index) {
              final avatarCode = availableAvatars[index];
              final isSelected = _selectedAvatarCode.value == avatarCode;
              
              return GestureDetector(
                onTap: () {
                  selectAvatar(avatarCode);
                  Get.back();
                  updateUserProfile();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/$avatarCode.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Remove avatar
  Future<void> removeAvatar() async {
    try {
      _isLoading.value = true;
      final user = _currentUser.value;
      if (user == null) return;

      _selectedAvatarCode.value = '';
      final updatedUser = user.copyWith(
        avatarCode: null,
        photoURL: '',
      );

      await _firestoreService.updateUser(updatedUser);
      Get.snackbar("Success", "Avatar removed successfully", snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar("Error", "Failed to remove avatar", snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

}