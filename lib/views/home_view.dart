import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/home_controller.dart';
import 'package:talkzy_beta1/controllers/main_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';
import 'package:talkzy_beta1/views/widgets/chat_list_item.dart';
import 'package:talkzy_beta1/views/widgets/user_avatar.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: _buildAppBar(context, authController),
      body: Column(
        children: [
          _buildSearchBar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshChats,
              color: AppTheme.primaryColor,
              child: Obx(() {
                if (controller.isSearching && controller.searchQuery.isNotEmpty) {
                  final hasResults = controller.filteredChats.isNotEmpty;
                  return hasResults
                      ? _buildSearchChatsList()
                      : _buildNoSearchResults();
                }

                final hasAnyData = controller.activeUsers.isNotEmpty ||
                    controller.chats.isNotEmpty ||
                    controller.remainingFriends.isNotEmpty;

                if (!hasAnyData) return _buildEmptyState();

                return _buildMainContent();
              }),
            ),
          )
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthController authController,
  ) {
    return AppBar(
      backgroundColor: ThemeHelper.backgroundColor(context),
      foregroundColor: ThemeHelper.textPrimaryColor(context),
      elevation: 0,
      centerTitle: false,
      title: Obx(() => controller.isSearching 
        ? const Text(
            'Search Results',
            style: TextStyle(fontWeight: FontWeight.w600),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/talkzy_SS_AN.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 3),
              Text(
                'Talkzy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.textPrimaryColor(context),
                ),
              ),
            ],
          ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        Obx(() => controller.isSearching
            ? IconButton(
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.clear_rounded))
            : _buildNotificationButton()),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Obx(() {
      final unreadNotifications = controller.getUnreadNotificationsCount();

      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: ThemeHelper.cardColor(Get.context!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: controller.openNotifications,
                icon: const Icon(Icons.notifications_outlined),
                iconSize: 22,
                splashRadius: 20,
              ),
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(

                    
                    color: const Color.fromARGB(255, 43, 74, 249),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ThemeHelper.cardColor(Get.context!), width: 1.5),
                  ),
                  constraints: const BoxConstraints(minHeight: 16, minWidth: 16),
                  child: Text(
                    unreadNotifications > 99 ? '99+' : unreadNotifications.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      color: ThemeHelper.backgroundColor(Get.context!),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(Get.context!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(
              color: ThemeHelper.textSecondaryColor(Get.context!).withOpacity(0.8),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: ThemeHelper.textSecondaryColor(Get.context!).withOpacity(0.8),
              size: 20,
            ),
            suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: controller.clearSearch,
                    icon: Icon(
                      Icons.clear_rounded,
                      color: ThemeHelper.textSecondaryColor(Get.context!).withOpacity(0.8),
                      size: 18,
                    ))
                : const SizedBox.shrink()),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.backgroundColor(Get.context!),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveFriendsSection(),
          _buildRecentChatsHeader(),
          Expanded(child: _buildRecentChatsList()),
        ],
      ),
    );
  }

  Widget _buildActiveFriendsSection() {
    return Obx(() {
      final hasActive = controller.activeUsers.isNotEmpty;
      final hasFriends = controller.remainingFriends.isNotEmpty;
      
      if (!hasActive && !hasFriends) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headers
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasActive)
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ThemeHelper.textPrimaryColor(Get.context!),
                    ),
                  ),
                if (hasFriends)
                  Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ThemeHelper.textPrimaryColor(Get.context!).withOpacity(0.85),
                    ),
                  ),
              ],
            ),
          ),
          
          // Horizontal scrollable section
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: ThemeHelper.cardColor(Get.context!),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeHelper.borderColor(Get.context!),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Active Users
                if (hasActive) ...[
                  ...controller.activeUsers.map((user) => 
                    _buildActiveUserCard(user, true)),
                  
                  // Divider between Active and Friends
                  if (hasFriends)
                    Container(
                      width: 1,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: ThemeHelper.borderColor(Get.context!).withOpacity(0.5),
                    ),
                ],
                
                // Friend Users (not online)
                if (hasFriends)
                  ...controller.remainingFriends.map((user) => 
                    _buildActiveUserCard(user, false)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _buildActiveUserCard(dynamic user, bool isOnline) {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    
    return GestureDetector(
      onTap: () {
        final chat = controller.findChatWithUser(user.id);
        if (chat != null) {
          controller.openChat(chat);
        } else {
          Get.toNamed(AppRoutes.chat, arguments: {
            'chatId': null,
            'otherUser': user,
            'isNewChat': true,
          });
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                UserAvatar(
                  user: user,
                  radius: 30,
                  showOnlineStatus: false,
                  viewerId: currentUserId,
                  isFriend: true, // Users in Active/Friends section are always friends
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height:18,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: ThemeHelper.cardColor(Get.context!), width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user.displayName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.textPrimaryColor(Get.context!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChatsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            String title = 'Recent Chats';
            switch (controller.activeFilter) {
              case 'Unread':
                title = 'Unread Messages';
                break;
              case 'Recent':
                title = 'Recent Messages';
                break;
              case 'Active':
                title = 'Active Conversations';
                break;
            }
            return Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeHelper.textPrimaryColor(Get.context!),
              ),
            );
          }),
          _buildFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Obx(() {
      final currentFilter = controller.activeFilter;
      
      // Get the count for the current filter
      int getFilterCount(String filter) {
        switch (filter) {
          case 'Unread':
            return controller.getUnreadCount();
          case 'Recent':
            return controller.getRecentCount();
          case 'Active':
            return controller.getActiveCount();
          default:
            return 0;
        }
      }
      
      String getDisplayText(String filter) {
        if (filter == 'All') {
          return 'All';
        }
        final count = getFilterCount(filter);
        return '$filter ($count)';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: DropdownButton<String>(
          value: currentFilter,
          underline: const SizedBox(),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: ThemeHelper.cardColor(Get.context!),
          borderRadius: BorderRadius.circular(12),
          items: [
            DropdownMenuItem(
              value: 'All',
              child: Text(getDisplayText('All')),
            ),
            DropdownMenuItem(
              value: 'Unread',
              child: Text(getDisplayText('Unread')),
            ),
            DropdownMenuItem(
              value: 'Recent',
              child: Text(getDisplayText('Recent')),
            ),
            DropdownMenuItem(
              value: 'Active',
              child: Text(getDisplayText('Active')),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.setFilter(newValue);
            }
          },
        ),
      );
    });
  }

  Widget _buildRecentChatsList() {
    return Obx(() {
      if (controller.chats.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: ThemeHelper.textSecondaryColor(Get.context!),
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.textPrimaryColor(Get.context!),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start chatting with your friends',
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeHelper.textSecondaryColor(Get.context!),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.chats.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: ThemeHelper.borderColor(Get.context!).withOpacity(0.22),
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final chat = controller.chats[index];
          final otherUser = controller.getOtherUser(chat);

          if (otherUser == null) return const SizedBox.shrink();
          
          return ChatListItem(
            chat: chat,
            otherUser: otherUser,
            lastMessageTime: controller.formatLastMessageTime(chat.lastMessageTime),
            onTap: () => controller.openChat(chat),
          );
        },
      );
    });
  }

  Widget _buildSearchChatsList() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor(Get.context!),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchResultsHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.filteredChats.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: ThemeHelper.borderColor(Get.context!).withOpacity(0.4), indent: 72),
              itemBuilder: (context, index) {
                final chat = controller.filteredChats[index];
                final otherUser = controller.getOtherUser(chat);

                if (otherUser == null) return const SizedBox.shrink();
                
                return ChatListItem(
                  chat: chat,
                  otherUser: otherUser,
                  lastMessageTime: controller.formatLastMessageTime(chat.lastMessageTime),
                  onTap: () => controller.openChat(chat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Obx(() => Text(
            'Found ${controller.filteredChats.length} result${controller.filteredChats.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 14,
              color: ThemeHelper.textSecondaryColor(Get.context!),
            ),
          )),
          const Spacer(),
          TextButton(
            onPressed: controller.clearSearch,
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.backgroundColor(Get.context!),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: ThemeHelper.textSecondaryColor(Get.context!),
              ),
              const SizedBox(height: 16),
              Text(
                'No conversations found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.textPrimaryColor(Get.context!),
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                'No results for "${controller.searchQuery}"',
                style: TextStyle(color: ThemeHelper.textSecondaryColor(Get.context!)),
                textAlign: TextAlign.center,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppRoutes.friends);
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.chat_rounded, size: 20),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor(Get.context!),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(70),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with friends and start meaningful conversations',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecoundaryColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final mainController = Get.find<MainController>();
                    mainController.changeTabIndex(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'Find Friends',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.person_search_outlined , color: Colors.white,),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}