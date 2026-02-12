import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:flutter/material.dart';

//* Widget that displays the reply mode preview banner.
//*
//* Shows:
//* - Sender name (color-coded: blue for contact, green for current user)
//* - Truncated message text preview
//* - Close button to cancel reply
//* - Animated appearance
class ReplyPreviewBanner extends StatelessWidget {
  final ChatsEntity replyMessage;
  final String currentUserId;
  final VoidCallback onCancel;

  const ReplyPreviewBanner({
    super.key,
    required this.replyMessage,
    required this.currentUserId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the reply message is from the current user
    final isFromCurrentUser = replyMessage.senderId == currentUserId;

    return AnimatedContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.colorScheme.surface,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name ("You" or contact name)
                    Text(
                      isFromCurrentUser ? 'You' : replyMessage.senderName,
                      style: TextStyle(
                        // Blue for contact, green for current user
                        color: isFromCurrentUser ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    // Message text preview
                    Text(
                      replyMessage.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Cancel reply button
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
