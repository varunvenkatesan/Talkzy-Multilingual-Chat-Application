

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/friends_controller.dart';
import 'package:talkzy_beta1/controllers/home_controller.dart';
import 'package:talkzy_beta1/controllers/profile_controller.dart';
import 'package:talkzy_beta1/controllers/user_list_controller.dart';

class MainController extends GetxController {
  
  final RxInt _currentIndex = 0.obs;
  final PageController pageController = PageController();

  int get currentIndex => _currentIndex.value;

  @override
  void onInit() {
    super.onInit();
    
    // CRITICAL FIX: Use Get.put() for views loaded immediately (Friends, FindPeople)
    // This ensures controllers are ready before their views access .value
    Get.lazyPut(()=>HomeController());
    Get.lazyPut(() =>FriendsController());
    Get.lazyPut(() => UserListController()); 
    
    // LazyPut is fine for other controllers
    Get.lazyPut(() => ProfileController());
  }

  @override 
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  // Corrected method name typo
  void changeTabIndex(int index) {
    _currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease, 
    );
  }

  void onPageChanged(int index) {
    _currentIndex.value = index;
  }
    
  // Placeholder/Example method (must be unboxed to return int)
  int getUnreadCount() {

    try{
    final homeController = Get.find<HomeController>();
    return homeController.getTotalUnreadCount();
    // You would typically use Get.find<HomeController>() here.
   // return 5; 
  }
  
  catch(e){
  return 0;
  }
  }
  // Placeholder/Example method (must be unboxed to return int)
  int getNotificationCount() {
    
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getUnreadNotificationsCount();
    }catch(e){
 return 0; 
    }

   
  }
}



