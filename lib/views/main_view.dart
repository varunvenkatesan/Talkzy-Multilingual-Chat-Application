
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/main_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/views/find_people_view.dart';
import 'package:talkzy_beta1/views/home_view.dart';
import 'package:talkzy_beta1/views/profile/new_profile_view.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Minimize app instead of closing
        return false;
      },
      child: Scaffold(
        backgroundColor: ThemeHelper.backgroundColor(context),
        // Keep page state when switching tabs
        body: PageView(
          physics: const NeverScrollableScrollPhysics(), // Prevent swipe
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          children: [
            HomeView(),
            FindPeopleView(),
            NewProfileView(),
          ]
              .map((page) => KeyedSubtree(
                    key: ValueKey(page.runtimeType),
                    child: page,
                  ))
              .toList(),
        ),
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: controller.currentIndex,
            onTap: controller.changeTabIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: ThemeHelper.textSecondaryColor(context),
            backgroundColor: ThemeHelper.cardColor(context),
            elevation: 8,
            items: [
              // 1. CHATS TAB
              BottomNavigationBarItem(
                icon: _buildIconWithBadge(
                  Icons.chat_outlined,
                  controller.getUnreadCount(),
                ),
                activeIcon: _buildIconWithBadge(
                  Icons.chat,
                  controller.getUnreadCount(),
                ),
                label: 'Chats',
              ),

              // 2. FIND FRIENDS TAB
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_search_outlined),
                activeIcon: const Icon(Icons.person_search),
                label: 'Find Friends',
              ),

              // 3. PROFILE TAB
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_circle_outlined),
                activeIcon: const Icon(Icons.account_circle),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(IconData icon, int count) {
    return Stack(
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(minWidth: 12, maxHeight: 12),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}
