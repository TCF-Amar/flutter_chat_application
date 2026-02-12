import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/widgets/image_message_widget.dart';
import 'package:chat_kare/features/chat/presentation/widgets/special_message_widgets.dart';
import 'package:chat_kare/features/chat/presentation/widgets/video_message_widget.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//* Widget that routes messages to appropriate content builders.
//*
//* Handles:
//* - Timestamp positioning (overlay for media, inline for text)
//* - Deleted message display
//* - Routing to media/text/location/document widgets
//* - Message status indicators (read receipts, sending state)
class MessageContentWidget extends StatelessWidget {
  final ChatsEntity message;
  final bool isMe;
  final VoidCallback onCancelUpload;
  final VoidCallback onRetryUpload;

  const MessageContentWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.onCancelUpload,
    required this.onRetryUpload,
  });

  @override
  Widget build(BuildContext context) {
    // Handle deleted messages (visible to everyone)
    if (message.isDeletedForEveryone) {
      return _buildDeletedMessage(context);
    }

    // For Media types (Image, Video), use Stack overlay for timestamp
    if (message.type == MessageType.image ||
        message.type == MessageType.video) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: _buildMediaContent(context),
          ),
          _buildTimestamp(context),
        ],
      );
    }

    // For Text and other types, use Wrap layout for inline timestamp
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 6,
        runSpacing: 2,
        children: [
          _buildTextOrOtherContent(context),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: _buildTimestamp(context),
          ),
        ],
      ),
    );
  }

  //* Builds deleted message display with icon and italic text.
  Widget _buildDeletedMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.block),
          const SizedBox(width: 4),
          AppText(
            "This message was deleted",
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: isMe ? Colors.white70 : Colors.grey[600],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildTimestamp(context),
          ),
        ],
      ),
    );
  }

  //* Routes message to appropriate media content builder.
  Widget _buildMediaContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return ImageMessageWidget(
          message: message,
          onCancelUpload: onCancelUpload,
          onRetryUpload: onRetryUpload,
        );
      case MessageType.video:
        return VideoMessageWidget(
          message: message,
          onCancelUpload: onCancelUpload,
          onRetryUpload: onRetryUpload,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  //* Routes non-media messages to appropriate content builder.
  Widget _buildTextOrOtherContent(BuildContext context) {
    switch (message.type) {
      case MessageType.location:
        return LocationMessageWidget(message: message, isMe: isMe);
      case MessageType.document:
        return DocumentMessageWidget(message: message, isMe: isMe);
      case MessageType.text:
      default:
        return AppText(
          message.text,
          fontSize: 16,
          overflow: TextOverflow.visible,
          color: isMe ? Colors.white : null,
        );
    }
  }

  //* Builds consistent timestamp widget with status indicators.
  //*
  //* Shows:
  //* - (edited) badge if message was edited
  //* - Formatted time (e.g., "02:30 PM")
  //* - Read receipts (double check) or sent status (single check)
  //* - Loading indicator for messages being sent
  Widget _buildTimestamp(BuildContext context, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Show '(edited)' badge if message was edited
        if (message.isEdited)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AppText(
              '(edited)',
              fontSize: 10,
              color: color ?? (isMe ? Colors.white70 : Colors.grey),
            ),
          ),

        // Formatted time (e.g., "02:30 PM")
        AppText(
          DateFormat('hh:mm a').format(message.timestamp),
          fontSize: 10,
          color: color ?? (isMe ? Colors.white70 : Colors.grey),
        ),

        // Message status indicators for sent messages
        if (isMe && message.status != MessageStatus.sending) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: message.isRead
                ? Colors.blue.shade200
                : (color ?? Colors.white70),
          ),
        ],

        // Loading indicator for messages being sent
        if (isMe && message.status == MessageStatus.sending) ...[
          const SizedBox(width: 3),
          SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: color ?? Colors.white70,
            ),
          ),
        ],
      ],
    );
  }
}
