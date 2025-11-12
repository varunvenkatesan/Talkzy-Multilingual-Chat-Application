import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/friends_controller.dart';
import 'package:talkzy_beta1/views/widgets/friend_list_item.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class FriendsView extends GetView<FriendsController> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeHelper.backgroundColor(context),
        title: Text(
                'Friends',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: ThemeHelper.textPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: controller.openFriendRequests,
          ),
        ],
      ),
      body: SafeArea(
        
        
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildSearchBar(context, isDark),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshFriends,
                child: Obx(() {
                  if (controller.isLoading && controller.friends.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.filteredFriends.isEmpty) {
                    return _buildEmptyState(context, isDark);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: controller.filteredFriends.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final friend = controller.filteredFriends[index];
                      final isBlocked = controller.isFriendBlocked(friend);
                      return FriendListItem(
                        friend: friend,
                        lastSeenText: controller.getLastSeenText(friend),
                        onTap: () => controller.startChat(friend),
                        onRemove: () => controller.removeFriend(friend),
                        onBlock: isBlocked ? null : () => controller.blockFriend(friend),
                        onUnblock: isBlocked ? () => controller.unblockFriend(friend) : null,
                        isBlocked: isBlocked,
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      
      padding: const EdgeInsets.only(top: 0, bottom: 12, left: 16, right: 4),
      child: Stack(
        children: [
          Column(
            children: [
          
              Text(
                'Your connected contacts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ThemeHelper.textSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
         
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? ThemeHelper.cardColor(context) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextField(
          onChanged: controller.updateSearchQuery,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark ? ThemeHelper.textPrimaryColor(context) : const Color(0xFF222222),
          ),
          decoration: InputDecoration(
            hintText: 'Search friends…',
            hintStyle: TextStyle(
              color: isDark ? ThemeHelper.textSecondaryColor(context) : Colors.grey[500],
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                Icons.search,
                color: isDark ? ThemeHelper.textSecondaryColor(context) : Colors.grey[500],
                size: 22,
              ),
            ),
            suffixIcon: Obx(() {
              return controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? ThemeHelper.textSecondaryColor(context) : Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.isNotEmpty
                ? 'No friends found.'
                : 'No friends added yet.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? ThemeHelper.textSecondaryColor(context) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
