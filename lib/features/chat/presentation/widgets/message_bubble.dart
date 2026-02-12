import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/message_content_widget.dart';
import 'package:chat_kare/features/chat/presentation/widgets/reply_preview_widget.dart';
import 'package:chat_kare/features/chat/presentation/widgets/swipe_to_reply.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

//* Main message bubble widget with selection, highlighting, and swipe-to-reply.
//*
//* Handles:
//* - Message grouping (consecutive messages from same sender)
//* - Selection mode for multi-select operations
//* - Message highlighting when scrolled to
//* - Swipe-to-reply gesture
//* - Visibility detection for read receipts
//* - Reply preview display
class MessageBubble extends StatelessWidget {
  final ChatsEntity message;
  final ChatController controller;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.controller,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    //* Dynamic border radius based on message grouping
    //* Creates a "stacked" appearance for consecutive messages
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: Radius.circular(!isMe && !isFirstInGroup ? 0 : 15),
      topRight: Radius.circular(isMe && !isFirstInGroup ? 0 : 15),
      bottomLeft: Radius.circular(!isMe && !isLastInGroup ? 0 : 15),
      bottomRight: Radius.circular(isMe && !isLastInGroup ? 0 : 15),
    );

    return Obx(() {
      //* Selection mode state
      final isSelected = controller.selectedMessages.contains(message.id);
      final isSelectionMode = controller.selectedMessages.isNotEmpty;
      //* Highlight when replying to or referencing this message
      final isHighlighted = controller.highlightedMessageId.value == message.id;

      return SwipeToReply(
        onReply: () {
          //* Swipe gesture to reply - disabled in selection mode
          if (!isSelectionMode) {
            controller.replyToMessage(message);
          }
        },
        child: Container(
          margin: EdgeInsets.only(
            bottom: isLastInGroup ? 8 : 2, //* Larger gap between groups
            top: isFirstInGroup ? 4 : 0,
          ),
          width: double.infinity,
          //* Background color for selected/highlighted states
          decoration: BoxDecoration(
            color: isHighlighted
                ? context.colorScheme.primary.withValues(alpha: 0.3)
                : (isSelected
                      ? context.colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent),
          ),
          //* Align message bubble based on sender
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          //* Track message visibility for read receipts
          child: VisibilityDetector(
            key: Key(message.id),
            onVisibilityChanged: (info) {
              //* Mark as read when 50% visible and not from current user
              if (info.visibleFraction > 0.5 && !isMe && !message.isRead) {
                controller.markMessageAsRead(message.id);
              }
            },
            child: GestureDetector(
              //* Long press to enter selection mode
              onLongPress: () {
                controller.toggleMessageSelection(message.id);
              },
              //* Tap in selection mode toggles selection, otherwise ignored
              onTap: () {
                if (isSelectionMode) {
                  controller.toggleMessageSelection(message.id);
                }
              },
              //* Main message bubble container
              child: Container(
                constraints: BoxConstraints(maxWidth: context.width * 0.75),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isMe
                      ? context.colorScheme.primary
                      : context.colorScheme.surface,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //* Reply preview section - shows quoted message
                    if (message.replyToMessageId != null)
                      ReplyPreviewWidget(
                        message: message,
                        isMe: isMe,
                        onTap: () {
                          //* Tap on reply preview to scroll to original message
                          controller.scrollToMessage(message.replyToMessageId!);
                        },
                      ),

                    //* Message content with timestamp overlay/alignment
                    MessageContentWidget(
                      message: message,
                      isMe: isMe,
                      onCancelUpload: () => controller.cancelUpload(message.id),
                      onRetryUpload: () => controller.retryUpload(message.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
