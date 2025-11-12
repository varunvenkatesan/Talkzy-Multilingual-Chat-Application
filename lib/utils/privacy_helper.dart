import 'package:talkzy_beta1/models/user_model.dart';

/// Helper class for privacy-related logic
class PrivacyHelper {
  /// Check if profile photo should be visible based on privacy settings
  /// 
  /// [user] - The user whose photo visibility is being checked
  /// [viewerId] - The ID of the user viewing the profile
  /// [isFriend] - Whether the viewer is a friend of the user
  static bool canViewProfilePhoto(UserModel user, String viewerId, bool isFriend) {
    // User can always see their own photo
    if (user.id == viewerId) return true;
    
    switch (user.profilePhotoVisibility) {
      case 'everyone':
        return true;
      case 'friends':
        return isFriend;
      case 'nobody':
        return false;
      default:
        return true; // Default to everyone
    }
  }

  /// Check if bio should be visible based on privacy settings
  /// 
  /// [user] - The user whose bio visibility is being checked
  /// [viewerId] - The ID of the user viewing the profile
  /// [isFriend] - Whether the viewer is a friend of the user
  static bool canViewBio(UserModel user, String viewerId, bool isFriend) {
    // User can always see their own bio
    if (user.id == viewerId) return true;
    
    switch (user.bioVisibility) {
      case 'everyone':
        return true;
      case 'friends':
        return isFriend;
      case 'nobody':
        return false;
      default:
        return true; // Default to everyone
    }
  }

  /// Get display bio based on privacy settings
  /// 
  /// Returns the bio if visible, empty string otherwise
  static String getDisplayBio(UserModel user, String viewerId, bool isFriend) {
    if (canViewBio(user, viewerId, isFriend)) {
      return user.bio;
    }
    return '';
  }

  /// Check if last seen should be visible based on privacy settings
  /// 
  /// [user] - The user whose last seen visibility is being checked
  static bool canViewLastSeen(UserModel user) {
    return user.showLastSeen;
  }

  /// Get display last seen text based on privacy settings
  /// 
  /// Returns formatted last seen if visible, "Last seen recently" or "Offline" otherwise
  static String getDisplayLastSeen(UserModel user, DateTime lastSeen) {
    // If user has hidden their last seen, show generic message
    if (!user.showLastSeen) {
      return 'Last seen recently';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Last seen recently';
    }
  }

  /// Get online/offline status text based on privacy settings
  /// 
  /// Returns "Online" if user is online and privacy allows, otherwise returns last seen or generic message
  static String getOnlineStatusText(UserModel user) {
    // If user has hidden their status, show generic offline message
    if (!user.showLastSeen) {
      return 'Offline';
    }
    
    // If user is online and allows status to be shown
    if (user.isOnline) {
      return 'Online';
    }
    
    // User is offline, show last seen
    return getDisplayLastSeen(user, user.lastSeen);
  }

  /// Check if online status should be displayed
  /// 
  /// Returns true only if user is online AND has enabled last seen visibility
  static bool shouldShowOnlineStatus(UserModel user) {
    return user.isOnline && user.showLastSeen;
  }

  /// Check if user should be visible in active/online lists
  /// 
  /// Returns true only if user has enabled last seen visibility
  /// This controls whether the user appears in "Active Friends" horizontal scroll
  static bool shouldShowInActiveList(UserModel user) {
    return user.showLastSeen;
  }

  /// Check if user should appear as online to others
  /// 
  /// Returns true only if user is online AND has enabled last seen visibility
  static bool isVisiblyOnline(UserModel user) {
    return user.isOnline && user.showLastSeen;
  }

  /// Check if read receipts should be shown
  /// 
  /// Both sender and receiver must have read receipts enabled
  static bool shouldShowReadReceipts(UserModel sender, UserModel receiver) {
    return sender.readReceipts && receiver.readReceipts;
  }

  /// Get placeholder text for hidden profile photo (first letter of name)
  static String getProfilePhotoPlaceholder(String displayName) {
    if (displayName.isEmpty) return 'U';
    return displayName[0].toUpperCase();
  }

  /// Check if profile photo should be displayed based on privacy settings
  /// Returns true if the photo can be shown, false if text avatar should be shown
  static bool shouldShowProfilePhoto(UserModel user, String? viewerId, bool isFriend) {
    // User can always see their own photo
    if (viewerId == null || user.id == viewerId) return true;
    
    return canViewProfilePhoto(user, viewerId, isFriend);
  }
}
