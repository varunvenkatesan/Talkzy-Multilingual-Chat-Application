import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/views/widgets/user_avatar.dart';

class UserProfileDetailsView extends StatelessWidget {
  const UserProfileDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get user from arguments
    final UserModel user = Get.arguments as UserModel;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Profile Details',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            
            // Profile Image
            Center(
              child: UserAvatar(
                user: user,
                radius: 60,
                showOnlineStatus: true,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Name
            Text(
              user.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Online/Offline Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: user.isOnline 
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.textSecoundaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: user.isOnline 
                          ? AppTheme.successColor 
                          : AppTheme.textSecoundaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    user.isOnline 
                        ? 'Online' 
                        : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                    style: TextStyle(
                      color: user.isOnline 
                          ? AppTheme.successColor 
                          : AppTheme.textSecoundaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Details Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.borderColor.withOpacity(0.15),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio Section
                  if (user.bio.isNotEmpty) ...[
                    _buildSectionHeader('About', Icons.info_outline),
                    SizedBox(height: 12),
                    Text(
                      user.bio,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimaryColor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                  
                  // Email Section
                  _buildSectionHeader('Email', Icons.email_outlined),
                  SizedBox(height: 12),
                  _buildInfoRow(Icons.email, user.email),
                  
                  SizedBox(height: 24),
                  
                  
                  
                  // Member Since
                  _buildSectionHeader('Member Since', Icons.calendar_today_outlined),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.date_range,
                    _formatDate(user.createdAt),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecoundaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(lastSeen);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
