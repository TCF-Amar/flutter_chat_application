import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:flutter/material.dart';

//* Widget that displays a preview of the message being replied to.
//*
//* Shows:
//* - Sender name of the original message
//* - Media thumbnail if available (image/video)
//* - Truncated text content or media type indicator
//* - Left border accent for visual distinction
//*
//* Tapping scrolls to the original message in the chat.
class ReplyPreviewWidget extends StatelessWidget {
  final ChatsEntity message;
  final bool isMe;
  final VoidCallback onTap;

  const ReplyPreviewWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.white : context.colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail for replied media message
            if (message.replyToMediaUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: message.replyToMediaUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.withValues(alpha: 0.1)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 16),
                  ),
                ),
              ),

            // Reply content details
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name
                  Text(
                    message.replyToSenderName ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isMe ? Colors.white : context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Message type indicator and truncated content
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Media type icons
                      if (message.replyToType == MessageType.image)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.photo,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if (message.replyToType == MessageType.video)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.videocam,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),

                      // Message text (or media placeholder text)
                      Flexible(
                        child: Text(
                          message.replyToText != null &&
                                  message.replyToText!.isNotEmpty
                              ? message.replyToText!
                              : (message.replyToType == MessageType.image
                                    ? 'Photo'
                                    : (message.replyToType == MessageType.video
                                          ? 'Video'
                                          : 'Message')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
