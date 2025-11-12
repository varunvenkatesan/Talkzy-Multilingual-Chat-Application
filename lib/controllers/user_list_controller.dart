



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/models/friend_request_model.dart';
import 'package:talkzy_beta1/models/friendship_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/services/firestore_service.dart';
import 'package:uuid/uuid.dart';


enum UserRelationshipStatus{
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
}

class UserListController extends GetxController{
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = Uuid();

   final RxList<UserModel> _users = <UserModel>[].obs;
   final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
   final RxBool _isLoading = false.obs;
   final RxString _searchQuery=''.obs;
   final RxString _error =''.obs;

   final RxMap<String, UserRelationshipStatus> _userRelationships = <String, UserRelationshipStatus>{}.obs;
   final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
   final RxList<FriendRequestModel> _receivedRequests = <FriendRequestModel>[].obs;

   final RxList<FriendshipModel> _friendships =<FriendshipModel>[].obs;
  
  List<UserModel> get user => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  String get error => _error.value;
  Map<String, UserRelationshipStatus> get userRelationships =>  _userRelationships;


  @override
  void onInit(){

    super.onInit();
    _loadUsers();
    _loadRelationships();
    
    debounce(
      _sentRequests,
      (_)=> _filterUsers(), // Corrected from _filteredUsers() to _filterUsers() as it's a void method
      time: const Duration(milliseconds: 300),
      );
     // Added debounce for search query
    debounce(
        _searchQuery,
        (_) => _filterUsers(),
        time: const Duration(milliseconds: 300),
    );

  }

  void _loadUsers()async{
    _users.bindStream(_firestoreService.getAllUserStream());

    ever(_users,(List<UserModel> userList){
      final currentUserId = _authController.user?.uid;
      final otherUsers = userList.where((user)=> user.id != currentUserId).toList();
      if(_searchQuery.isEmpty){
        _filteredUsers.value=otherUsers;
      }else{
        _filterUsers();
      }
  });
  }
    
   void _loadRelationships(){
    final currentUserId = _authController.user?.uid;

    if(currentUserId != null){

      // load sent friend requests
      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStream(currentUserId)
      );
          //load received friend requests
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId)
      );
      
      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      ever(_sentRequests, (_) {
        print('📤 Sent requests updated: ${_sentRequests.length}');
        _updateAllRelationshipsStatus();
      });
      ever(_receivedRequests, (_) {
        print('📥 Received requests updated: ${_receivedRequests.length}');
        _updateAllRelationshipsStatus();
      });
      ever(_friendships, (_) {
        print('👥 Friendships updated: ${_friendships.length}');
        _updateAllRelationshipsStatus();
      });

      ever(_users, (_) {
        print('👤 Users updated: ${_users.length}');
        _updateAllRelationshipsStatus();
      });

    }
   }
   
   void _updateAllRelationshipsStatus(){
    final currentUserId =_authController.user?.uid;

    if(currentUserId == null)return;
    
    print('🔄 Updating all relationship statuses. Friendships count: ${_friendships.length}');
    
    for(var user in _users){
          if(user.id != currentUserId){
            final status = _calculateUserRelationshipStatus(user.id);
            _userRelationships[user.id] = status;
          }
    }
    
    // Force UI update after relationship status changes
    _userRelationships.refresh();
    _filterUsers();
    
    print('✅ Relationship statuses updated. Total relationships: ${_userRelationships.length}');
   }

    UserRelationshipStatus _calculateUserRelationshipStatus(String userId){
      final currentUserId = _authController.user?.uid;

      if(currentUserId==null) return UserRelationshipStatus.none;

      // check if they are friends

      final friendship = _friendships.firstWhereOrNull(
        (f)=>
        (f.user1Id== currentUserId && f.user2Id== userId)||
        (f.user1Id == userId && f.user2Id == currentUserId),
      );
  
      if(friendship !=null){
        if(friendship.isBlocked){
          return UserRelationshipStatus.blocked;

        }else{
          return UserRelationshipStatus.friends;
        } 
      }
      // check if there is a pending friend sent to the user
      final sentRequest = _sentRequests.firstWhereOrNull(
        (r)=> r.receiverId == userId && r.status == FriendRequestStatus.pending,
      );
      
      if(sentRequest !=null ){
      return UserRelationshipStatus.friendRequestSent;

      }

      final receivedRequest = _receivedRequests.firstWhereOrNull(
      (r)=> r.senderId == userId && r.status == FriendRequestStatus.pending,
      );
      
      if(receivedRequest != null){
        return UserRelationshipStatus.friendRequestReceived;
      }
      return UserRelationshipStatus.none;

    }
    void _filterUsers(){
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    // Get list of user IDs who sent friend requests to current user
    final requestSenderIds = _receivedRequests
        .where((r) => r.status == FriendRequestStatus.pending)
        .map((r) => r.senderId)
        .toSet();

    List<UserModel> filteredList;
    
    if(query.isEmpty){
      filteredList = _users
      .where((user)=> user.id != currentUserId)
      .toList();
    }
    else{
      filteredList = _users
          .where(
            (user){
              return user.id != currentUserId && 
              (user.displayName.toLowerCase().contains(query)||
               user.email.toLowerCase().contains(query)
               );
          }).toList();
    }
    
    // Separate users into two groups: request senders and others
    final requestSenders = filteredList
        .where((user) => requestSenderIds.contains(user.id))
        .toList();
    
    final otherUsers = filteredList
        .where((user) => !requestSenderIds.contains(user.id))
        .toList();
    
    // Merge lists with request senders first
    _filteredUsers.value = [...requestSenders, ...otherUsers];
    }
    
    void upateSearchQuery(String query){
      _searchQuery.value =query;
    }
      void clearSearch(){
      _searchQuery.value='';
      }

      Future<void> sendFriendRequest(UserModel user)async{
      try{
      print('🚀 Starting sendFriendRequest for user: ${user.displayName}');
      _isLoading.value=true;
        final currentUserId = _authController.user?.uid;
        print('📝 Current user ID: $currentUserId');

        if(currentUserId != null){
          final request = FriendRequestModel(
            id: _uuid.v4(), 
            senderId: currentUserId, 
            receiverId: user.id, 
            createdAt: DateTime.now(),
            );
          print('📤 Created friend request: ${request.id}');

            _userRelationships[user.id]= UserRelationshipStatus.friendRequestSent;
            print('✅ Updated UI optimistically');

            await _firestoreService.sendFriendRequest(request);
            print('✅ Friend request sent to Firebase successfully');
            Get.snackbar(
              'Success', 
              'Friend Request sent to ${user.displayName}',
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green,
              snackPosition: SnackPosition.TOP,
            );
      } else {
        print('❌ Current user ID is null!');
        Get.snackbar('Error', 'User not authenticated', snackPosition: SnackPosition.TOP);
      }
        }
          
      catch(e){
        _userRelationships[user.id] =UserRelationshipStatus.none;
        _error.value = e.toString();
        print('❌ Error sending friend request: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        Get.snackbar(
          'Error', 
          'Failed to send friend request: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
      finally{
        _isLoading.value=false;
        print('🏁 sendFriendRequest completed');
      }
      }
  
    Future<void> cancelFriendRequest(UserModel user)async{
      try{
      print('🚀 Starting cancelFriendRequest for user: ${user.displayName}');
      _isLoading.value=true;
        final currentUserId = _authController.user?.uid;
        print('📝 Current user ID: $currentUserId');

        if(currentUserId != null){
          final request = _sentRequests.firstWhereOrNull(
            (r)=>
            r.receiverId == user.id &&
            r.status == FriendRequestStatus.pending,
          );
          print('📝 Found request: ${request?.id}');

          if(request != null){
            _userRelationships[user.id] = UserRelationshipStatus.none;
            print('✅ Updated UI optimistically');

            await _firestoreService.cancelFriendRequest(request.id);
            print('✅ Friend request cancelled successfully');
            Get.snackbar(
              'Success', 
              'Friend Request cancelled to ${user.displayName}',
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green,
              snackPosition: SnackPosition.TOP,
            );
          } else {
            print('❌ Request not found in _sentRequests');
            Get.snackbar('Error', 'Friend request not found', snackPosition: SnackPosition.TOP);
          }
        } else {
          print('❌ Current user ID is null!');
          Get.snackbar('Error', 'User not authenticated', snackPosition: SnackPosition.TOP);
        }
      }  catch(e){
        _userRelationships[user.id] =UserRelationshipStatus.friendRequestSent;
        _error.value = e.toString();
        print('❌ Error cancelling friend request: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        Get.snackbar(
          'Error', 
          'Failed to cancel friend request: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
      finally{
        _isLoading.value=false;
        print('🏁 cancelFriendRequest completed');
      }
      }

         Future<void> acceptFriendRequest(UserModel user)async{
      try{
      print('🚀 Starting acceptFriendRequest for user: ${user.displayName}');
      _isLoading.value=true;
      final currentUserId=_authController.user?.uid;
      print('📝 Current user ID: $currentUserId');
      print('📝 Received requests count: ${_receivedRequests.length}');
      print('📝 Current friendships count: ${_friendships.length}');
      
      if(currentUserId != null){
        final request = _receivedRequests.firstWhereOrNull(
          (r)=>
          r.senderId==user.id && r.status == FriendRequestStatus.pending,
        );
        print('📝 Found request: ${request?.id}');

        if(request != null){
          // Optimistically update UI
          _userRelationships[user.id] = UserRelationshipStatus.friends;
          print('✅ Updated UI optimistically to friends');
        
          await _firestoreService.respondToFriendRequest(
          request.id,
          FriendRequestStatus.accepted,
          );
          print('✅ Friend request accepted in Firebase');
          print('📝 Friendships after accept: ${_friendships.length}');
          
          // The real-time stream will automatically update both users' friend lists
          // No need to manually refresh - the listeners handle it
          
          Get.snackbar(
            'Success', 
            'You and ${user.displayName} are now friends!',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
          );
        } else {
          print('❌ Request not found in _receivedRequests');
          Get.snackbar('Error', 'Friend request not found', snackPosition: SnackPosition.TOP);
        }
      } else {
        print('❌ Current user ID is null!');
        Get.snackbar('Error', 'User not authenticated', snackPosition: SnackPosition.TOP);
      }
      }  catch(e){
        // Rollback on error
        _userRelationships[user.id] =UserRelationshipStatus.friendRequestReceived;
        _error.value = e.toString();
        print('❌ Error accepting friend request: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        Get.snackbar(
          'Error', 
          'Failed to accept friend request: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
      finally{
        _isLoading.value=false;
        print('🏁 acceptFriendRequest completed');
        
        // Force a manual refresh after a short delay to ensure streams have updated
        Future.delayed(const Duration(milliseconds: 1000), () {
          print('🔄 Manual refresh after friend request acceptance');
          _updateAllRelationshipsStatus();
        });
      }
      }

  // Manual refresh function for debugging
  void forceRefresh() {
    print('🔄 Force refreshing all relationship data');
    _updateAllRelationshipsStatus();
  }


          Future<void> declineFriendRequest(UserModel user)async{
      try{
      _isLoading.value=true;
      final currentUserId=_authController.user?.uid;
      
      if(currentUserId != null){
        final request = _receivedRequests.firstWhereOrNull(
          (r)=>
          r.senderId==user.id && r.status == FriendRequestStatus.pending,
        );

        if(request != null){
          _userRelationships[user.id] = UserRelationshipStatus.none;
        
          await _firestoreService.respondToFriendRequest(
          request.id,
          FriendRequestStatus.declined,
          );
          Get.snackbar('Success', 'Friend Request Declined', snackPosition: SnackPosition.TOP);

        }
      }
      
      }  catch(e){
        _userRelationships[user.id] =UserRelationshipStatus.friendRequestReceived;
        _error.value = e.toString();
        print('Error declining friend request: $e');
        Get.snackbar('Error', 'Failed to decline friend request', snackPosition: SnackPosition.TOP);
      }
      finally{
        _isLoading.value=false;
      } 
      }
  
  Future<void> startChat(UserModel user) async{
    try{
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if(currentUserId != null){
        final relationship = _userRelationships[user.id] ?? UserRelationshipStatus.none;
        if(relationship != UserRelationshipStatus.friends){
              Get.snackbar('Info',"You can only chat with friends. Please send  a friend request first.", snackPosition: SnackPosition.TOP);
              return;
        }

        final chatId= await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );

       // if(chatId !=null){
       //    Get.snackbar('Success', "Chat Started with ${user.displayName}");

          Get.toNamed(
            AppRoutes.chat, 
            arguments: {'chatId': chatId,'otherUser': user}
            );
       // }
      }
    }
    catch(e){
    _error.value =e.toString();
    print("Error starting chat:$e");
    Get.snackbar("Error",'Failed to start chat', snackPosition: SnackPosition.TOP);
    }
    finally{
      _isLoading.value=false;
    }
  }

    UserRelationshipStatus getUserRelationshipStatus(String userId){
      return _userRelationships[userId] ?? UserRelationshipStatus.none;
    }

   String getRelationshipButtonText(UserRelationshipStatus status){
    switch(status){
      case UserRelationshipStatus.none:
      return 'Add';
      case UserRelationshipStatus.friendRequestSent:
      return 'Request sent';
      case UserRelationshipStatus.friendRequestReceived:
      return 'Accept';
      case UserRelationshipStatus.friends:
      return 'Message';
      case UserRelationshipStatus.blocked:
      return 'Blocked';
      
        
    }
   }
   
   IconData getRelationshipButtonIcon(UserRelationshipStatus status){
    switch(status){
      case UserRelationshipStatus.none:
      return Icons.person_add;
       case UserRelationshipStatus.friendRequestSent:
      return Icons.access_time;
      case UserRelationshipStatus.friendRequestReceived:
      return Icons.check;

      case UserRelationshipStatus.friends:
      return Icons.chat_bubble_outline;

      case UserRelationshipStatus.blocked:
      return Icons.block;

    }
   }
   Color getRelationshipButtonColor(UserRelationshipStatus status){
     switch(status){
      case UserRelationshipStatus.none:
      return Colors.blue;
       case UserRelationshipStatus.friendRequestSent:
      return Colors.orange;
      case UserRelationshipStatus.friendRequestReceived:
      return Colors.green;

      case UserRelationshipStatus.friends:
      return Colors.blue;

      case UserRelationshipStatus.blocked:
      return Colors.redAccent;
     }
   
  

   }

   void handleRelationshipAction(UserModel user){
    final status = getUserRelationshipStatus(user.id);
    switch (status){
      case UserRelationshipStatus.none:
      sendFriendRequest(user);
      break;
      
      case UserRelationshipStatus.friendRequestSent:
        cancelFriendRequest(user);
      break;

      case UserRelationshipStatus.friendRequestReceived:
      acceptFriendRequest(user);
      break;

      case UserRelationshipStatus.friends:
      startChat(user);
      break;
      case UserRelationshipStatus.blocked:
      Get.snackbar('Info', "You have blocked this user", snackPosition: SnackPosition.TOP);
      break;

    }
   }
   
   String getLastSeenText(UserModel user){
    if(user.isOnline){
      return 'online';
    }
    else{
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);

      if(difference.inMinutes<1){
        return 'Just now';
      }
      else if(difference.inHours < 1){
        return 'Last seen ${difference.inMinutes} m ago';

      }
      else if(difference.inDays <1){
        return 'Last seen ${difference.inHours} h ago';
      }
        else if(difference.inDays <7){
        return 'Last seen ${difference.inHours} d ago';
      }
      else {
        return 'Last seen ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}';
      }
    }
   }
   void _clearError(){
    _error.value ='';
   }
 }

 