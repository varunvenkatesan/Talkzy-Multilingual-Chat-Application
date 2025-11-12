
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/user_list_controller.dart';
import 'package:talkzy_beta1/views/widgets/user_list_item.dart';

class FindPeopleView extends GetView<UserListController> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111111) : const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildCapsuleSearch(context, isDark),
            Expanded(
              child: Obx(() {
                if (controller.filteredUsers.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }
                return _buildUserList(context, isDark);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        children: [
          Text(
            'Find Friends',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF222222),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Discover and connect with new friends.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleSearch(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextField(
          onChanged: controller.upateSearchQuery,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFFEAEAEA) : const Color(0xFF222222),
          ),
          decoration: InputDecoration(
            hintText: 'Search by name, email, or bio…',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[500],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Icon(
                Icons.search,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
                size: 22,
              ),
            ),
            suffixIcon: Obx(() {
              return controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () {
                        controller.clearSearch();
                      },
                    )
                  : const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: controller.filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = controller.filteredUsers[index];
        return UserListItem(
          user: user,
          onTap: () {},
          controller: controller,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No users available right now.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}