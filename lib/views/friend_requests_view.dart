

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/friend_requests_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/views/widgets/friend_request_item.dart';

class FriendRequestsView extends GetView<FriendRequestsController>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(), 
        ),
      ),
      body: Column(
        children: [
          // --- Tab Bar Implementation ---
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Obx(() =>
              Row(
                children: [
                  // Received Tab (Index 0)
                  _buildTabButton(context, 0, 'Received (${controller.receivedRequests.length})', Icons.inbox),
                  // Sent Tab (Index 1)
                  _buildTabButton(context, 1, 'Sent (${controller.sentRequests.length})', Icons.send),
                ],
              )
            ),
          ),
          
          // --- Content Area ---
          Expanded(child: Obx((){
            if (controller.isLoading && controller.receivedRequests.isEmpty && controller.sentRequests.isEmpty) {
                return const Center(child: CircularProgressIndicator());
            }

            return IndexedStack(
              index: controller.selectedTabIndex,
              children: [
                _buildReceivedRequestsTab(),
                _buildSentRequestsTab(),
              ],
            );
          })),
        ],
      )
    );
  }

  // Helper method for Tab Buttons
  Widget _buildTabButton(BuildContext context, int index, String label, IconData icon) {
    final isSelected = controller.selectedTabIndex == index;
    final color = isSelected ? Colors.white : AppTheme.textSecoundaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // --- Received Requests Tab Content ---
  Widget _buildReceivedRequestsTab(){
    return Obx((){
      if(controller.receivedRequests.isEmpty){
        return _buildEmptyState(
          icon:Icons.inbox_outlined,
          title:'No Friend Requests',
          message: 'When someone sends you a friend request, it will appear here.'
        );
      }
      
      return ListView.separated(
        padding:const EdgeInsets.all(16),
        itemCount: controller.receivedRequests.length,
        separatorBuilder: (context,index)=>const SizedBox(height: 8),
        itemBuilder: (context,index){
          final request = controller.receivedRequests[index];
          final sender = controller.getUser(request.senderId);
            
          if(sender==null){
            return const SizedBox.shrink();
          }
            
          return FriendRequestItem(
            request:request,
            user:sender,
            timeText:controller.getRequestTimeText(request.createdAt),
            isReceived:true,
                onAccept: () async => await controller.acceptRequest(request),

               onDecline: () async => await controller.declineFriendRequest(request),);
        },
      );
    });
  }

  
  // --- Sent Requests Tab Content (FIXED) ---
  Widget _buildSentRequestsTab(){
    return Obx((){
      // FIX 1: Check controller.sentRequests.isEmpty
      if(controller.sentRequests.isEmpty){ 
        return _buildEmptyState(
          icon:Icons.send_outlined,
          title:'No Sent Requests',
          message: 'Friend Requests you send will appear here.'
        );
      }
      
      return ListView.separated(
        padding:const EdgeInsets.all(16),
        itemCount: controller.sentRequests.length,
        separatorBuilder: (context,index)=>const SizedBox(height: 8),
        itemBuilder: (context,index){
          final request = controller.sentRequests[index];
          
          // FIX 2: Use request.receiverId to get the user who is receiving the request.
          final receiver = controller.getUser(request.receiverId); 
            
          if(receiver==null){
            return const SizedBox.shrink();
          }
            
          return FriendRequestItem(
            request:request,
            user:receiver,
            timeText:controller.getRequestTimeText(request.createdAt),
            isReceived:false,
            statusText:controller.getStatusText(request.status),
            statusColor:controller.getStatusColor(request.status),
          );
        },
      );
    });
  }
  
  // --- Empty State Builder ---
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }){
    return Center(
      child:Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius:BorderRadius.circular(50), 
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(title,
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecoundaryColor,
            ),
            textAlign: TextAlign.center,
          )
        ],),
      ), 
    );
  }
}