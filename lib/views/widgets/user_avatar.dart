import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/utils/privacy_helper.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showOnlineStatus;
  final String? viewerId; // ID of the user viewing the avatar
  final bool isFriend; // Whether the viewer is a friend of this user

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 28,
    this.showOnlineStatus = false,
    this.viewerId,
    this.isFriend = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if profile photo should be visible based on privacy settings
    final canViewPhoto = viewerId == null || 
        PrivacyHelper.canViewProfilePhoto(user, viewerId!, isFriend);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.primaryColor,
          child: canViewPhoto && user.photoURL.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user.photoURL,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    memCacheWidth: (radius * 4).toInt(),
                    memCacheHeight: (radius * 4).toInt(),
                    placeholder: (context, url) => Container(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      child: Center(
                        child: SizedBox(
                          width: radius * 0.5,
                          height: radius * 0.5,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return _buildDefaultAvatar(canViewPhoto);
                    },
                  ),
                )
              : _buildDefaultAvatar(canViewPhoto),
        ),
        if (showOnlineStatus && PrivacyHelper.shouldShowOnlineStatus(user))
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.60,
              height: radius * 0.60,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                border: Border.all(color: Colors.white, width: 2.5),
                shape: BoxShape.circle,
              ),
            ),
          )
      ],
    );
  }

  Widget _buildDefaultAvatar(bool canViewPhoto) {
    // If photo is not visible due to privacy, show text avatar
    if (!canViewPhoto) {
      return _buildTextAvatar();
    }

    // Priority 1: Show selected avatar if avatarCode exists
    if (user.avatarCode != null && user.avatarCode!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          'assets/images/${user.avatarCode}.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gender-based or initial letter if avatar not found
            return _buildFallbackAvatar();
          },
        ),
      );
    }

    // Priority 2: Show gender-based default avatar
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    // Show gender-based avatar if gender is selected
    if (user.gender == 'male') {
      return ClipOval(
        child: Image.asset(
          'assets/images/male_avatar.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    } else if (user.gender == 'female') {
      return ClipOval(
        child: Image.asset(
          'assets/images/female_avatar.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }

    // Default to initial letter avatar if no gender selected
    return _buildTextAvatar();
  }

  // Text avatar showing first letter of name
  Widget _buildTextAvatar() {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * 0.8,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
