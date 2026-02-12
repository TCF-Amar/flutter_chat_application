import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

//* Widget responsible for rendering the list of chat messages.
//*
//* Handles:
//* - Displaying message bubbles with proper grouping (consecutive messages from same sender)
//* - Read receipts and message status indicators
//* - Message selection for multi-select operations
//* - Reply previews and swipe-to-reply gesture
//* - Media messages (images, videos) with upload progress
//* - Location and document messages
//* - Automatic scrolling to highlighted messages
//* - Visibility detection for read receipts
//*
//* Note: Most UI logic has been extracted to separate widget files:
//* - message_bubble.dart: Main bubble container
//* - message_content_widget.dart: Content routing and timestamp
//* - reply_preview_widget.dart: Reply preview display
//* - image_message_widget.dart: Image with upload states
//* - video_message_widget.dart: Video with upload states
//* - upload_overlay_widgets.dart: Progress and error overlays
//* - special_message_widgets.dart: Location and document types
class ListChats extends StatelessWidget {
  final ChatController controller;
  final Function(ChatsEntity)? onMessageVisible;

  const ListChats({super.key, required this.controller, this.onMessageVisible});

  @override
  Widget build(BuildContext context) {
    // Listen to reactive state changes from GetX controller
    return Obx(() {
      final messages = controller.messages;

      // Loading state
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Empty state
      if (messages.isEmpty) {
        return const Center(child: Text("No messages yet"));
      }

      // Main messages list
      return ListView.builder(
        controller: controller.scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];

          // Notify parent widget when message becomes visible (for analytics/tracking)
          onMessageVisible?.call(message);

          // Determine if the message was sent by the current user
          final isMe = message.senderId == controller.fs.currentUser?.uid;

          // Group consecutive messages from the same sender for bubble styling
          // First message in a group has rounded top corners
          final bool isFirstInGroup =
              index == 0 || messages[index - 1].senderId != message.senderId;
          // Last message in a group has rounded bottom corners
          final bool isLastInGroup =
              index == messages.length - 1 ||
              messages[index + 1].senderId != message.senderId;

          return AutoScrollTag(
            key: ValueKey(index),
            controller: controller.scrollController,
            index: index,
            // Highlight color when programmatically scrolled to
            highlightColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
            child: MessageBubble(
              message: message,
              controller: controller,
              isMe: isMe,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
            ),
          );
        },
      );
    });
  }
}
