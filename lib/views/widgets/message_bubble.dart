

// import 'package:flutter/material.dart';
// import 'package:talkzy_beta1/models/message_model.dart';
// import 'package:talkzy_beta1/theme/app_theme.dart';
// import 'package:talkzy_beta1/theme/theme_helper.dart';

// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMyMessage;
//   final bool showTime;
//   final String timeText;
//   final bool showTranslation;
//   final VoidCallback? onLongPress;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMyMessage,
//     required this.showTime,
//     required this.timeText,
//     this.showTranslation = false,
//     this.onLongPress,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         if (showTime) ...[
//           const SizedBox(height: 16),
//           Center(
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//               decoration: BoxDecoration(
//                 color: ThemeHelper.textSecondaryColor(context).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 timeText,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: ThemeHelper.textSecondaryColor(context),
//                     ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//         ] else
//           const SizedBox(height: 4),
//         Row(
//           mainAxisAlignment:
//               isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             if (!isMyMessage) const SizedBox(width: 8),
//             Flexible(
//               child: GestureDetector(
//                 onLongPress: onLongPress,
//                 child: Container(
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.75,
//                   ),
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: isMyMessage
//                         ? AppTheme.primaryColor
//                         : ThemeHelper.cardColor(context),
//                     borderRadius: BorderRadius.only(
//                       topLeft: const Radius.circular(20),
//                       topRight: const Radius.circular(20),
//                       bottomLeft: isMyMessage
//                           ? const Radius.circular(20)
//                           : const Radius.circular(4),
//                       bottomRight: isMyMessage
//                           ? const Radius.circular(4)
//                           : const Radius.circular(20),
//                     ),
//                     border: isMyMessage
//                         ? null
//                         : Border.all(color: ThemeHelper.borderColor(context), width: 1),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       )
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Original message
//                       Text(
//                         message.content,
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: isMyMessage
//                                   ? Colors.white
//                                   : ThemeHelper.textPrimaryColor(context),
//                             ),
//                       ),
                      
//                       // Translation section
//                       if (showTranslation && message.translatedContent != null) ...[
//                         const SizedBox(height: 8),
//                         Container(
//                           padding: const EdgeInsets.only(top: 8),
//                           decoration: BoxDecoration(
//                             border: Border(
//                               top: BorderSide(
//                                 color: isMyMessage
//                                     ? Colors.white.withOpacity(0.3)
//                                     : ThemeHelper.borderColor(context),
//                                 width: 1,
//                               ),
//                             ),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.translate,
//                                     size: 12,
//                                     color: isMyMessage
//                                         ? Colors.white.withOpacity(0.7)
//                                         : AppTheme.primaryColor,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     'Translation',
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.copyWith(
//                                           color: isMyMessage
//                                               ? Colors.white.withOpacity(0.7)
//                                               : AppTheme.primaryColor,
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 message.translatedContent!,
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodyMedium
//                                     ?.copyWith(
//                                       color: isMyMessage
//                                           ? Colors.white.withOpacity(0.9)
//                                           : ThemeHelper.textPrimaryColor(context),
//                                       fontStyle: FontStyle.italic,
//                                     ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
                      
//                       // Edited indicator
//                       if (message.isEdited) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           'Edited',
//                           style:
//                               Theme.of(context).textTheme.bodySmall?.copyWith(
//                                     color: isMyMessage
//                                         ? Colors.white.withOpacity(0.7)
//                                         : AppTheme.textSecoundaryColor,
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                         )
//                       ]
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             if (isMyMessage) _buildMessageStatus(context),
//           ],
//         )
//       ],
//     );
//   }

//   Widget _buildMessageStatus(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 8.0, bottom: 0),
//       child: Icon(
//         message.isRead ? Icons.done_all : Icons.done,
//         size: 16,
//         color: message.isRead
//             ? AppTheme.primaryColor
//             : ThemeHelper.textSecondaryColor(context),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/chat_theme_controller.dart';
import 'package:talkzy_beta1/models/message_model.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:talkzy_beta1/theme/theme_helper.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final bool showTime;
  final String timeText;
  final bool showTranslation;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.showTime,
    required this.timeText,
    this.showTranslation = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final chatThemeController = Get.find<ChatThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final bubbleTheme = chatThemeController.themeFor(isDark: isDark);
      return Column(
      children: [
        if (showTime) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: ThemeHelper.textSecondaryColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeHelper.textSecondaryColor(context),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 4),
        Row(
          mainAxisAlignment:
              isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMyMessage) const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isMyMessage ? bubbleTheme.outgoingGradient : null,
                    color: isMyMessage
                        ? bubbleTheme.outgoingColor
                        : bubbleTheme.incomingColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMyMessage
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isMyMessage
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    border: isMyMessage
                        ? null
                        : Border.all(color: bubbleTheme.incomingBorderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original message
                      Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isMyMessage
                                  ? bubbleTheme.outgoingTextColor
                                  : bubbleTheme.incomingTextColor,
                            ),
                      ),
                      
                      // Translation section
                      if (showTranslation && message.translatedContent != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isMyMessage
                                    ? Colors.white.withOpacity(0.3)
                                    : bubbleTheme.translationDividerColorOnIncoming,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 12,
                                    color: isMyMessage
                                        ? Colors.white.withOpacity(0.7)
                                        : AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Translation',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isMyMessage
                                              ? Colors.white.withOpacity(0.7)
                                              : AppTheme.primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.translatedContent!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isMyMessage
                                          ? Colors.white.withOpacity(0.9)
                                          : bubbleTheme.incomingTextColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Edited indicator
                      if (message.isEdited) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Edited',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isMyMessage
                                        ? Colors.white.withOpacity(0.7)
                                        : AppTheme.textSecoundaryColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
            if (isMyMessage) _buildMessageStatus(context),
          ],
        )
      ],
    );
    });
  }

  Widget _buildMessageStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 0),
      child: Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 16,
        color: message.isRead
            ? AppTheme.primaryColor
            : ThemeHelper.textSecondaryColor(context),
      ),
    );
  }
}