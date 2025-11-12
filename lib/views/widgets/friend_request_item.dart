import 'package:flutter/material.dart';
import 'package:talkzy_beta1/models/friend_request_model.dart';
import 'package:talkzy_beta1/models/user_model.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/views/widgets/user_avatar.dart';

class FriendRequestItem extends StatelessWidget{
  final FriendRequestModel request;
  final UserModel user; // Details of the other user
  final String timeText;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final String? statusText;
  final Color? statusColor;

  const FriendRequestItem({
    super.key,
    required this.request,
    required this.user,
    required this.timeText, 
    required this.isReceived, 
    this.onAccept,
    this.onDecline,
    this.statusText,
    this.statusColor
  });

  @override
  Widget build(BuildContext context){
    // Show status tag for Sent requests OR Handled Received requests
    final bool showStatusTag = !isReceived || request.status != FriendRequestStatus.pending;

    return Card(
      child: Padding(padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // --- Avatar ---
                UserAvatar(
                  user: user,
                  radius: 24,
                  showOnlineStatus: false,
                ),
                const SizedBox(width: 12),
                
                // --- Details ---
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: 
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          )
                        ),
                        Text(
                          timeText,
                          style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecoundaryColor),
                        )
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecoundaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                )),
              ]
            ),
            
            // --- Action Buttons (Only for Received & Pending) ---
            if(isReceived && request.status == FriendRequestStatus.pending)...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.errorColor),
                        foregroundColor: AppTheme.errorColor,
                      ),
                      label:const Text('Decline'),
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                    label: const Text('Accept'),
                  )),
                ],
              ),
            ],
            
            // --- Status Container ---
            if (showStatusTag)...[
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical:6,horizontal: 12 ),
                decoration: BoxDecoration(
                  color: (statusColor ?? AppTheme.borderColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor ?? AppTheme.borderColor ),
                ),
                
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText ?? 'Status', 
                      style: TextStyle(
                        color: statusColor ?? AppTheme.textSecoundaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  ],
                ),
              ),
            ]
          ]
        ),
      )
    );
  }

  IconData _getStatusIcon(){
    switch(request.status){
      case FriendRequestStatus.accepted: return Icons.check_circle;
      case FriendRequestStatus.declined: return Icons.cancel;
      case FriendRequestStatus.pending:
      default: return Icons.hourglass_top;
    }
  }
}