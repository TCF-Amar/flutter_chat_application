import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chat_kare/features/chat/presentation/widgets/swipe_to_reply.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

          // Dynamic border radius based on message grouping
          // Creates a "stacked" appearance for consecutive messages
          final BorderRadius borderRadius = BorderRadius.only(
            topLeft: Radius.circular(!isMe && !isFirstInGroup ? 0 : 10),
            topRight: Radius.circular(isMe && !isFirstInGroup ? 0 : 10),
            bottomLeft: Radius.circular(!isMe && !isLastInGroup ? 0 : 10),
            bottomRight: Radius.circular(isMe && !isLastInGroup ? 0 : 10),
          );

          return AutoScrollTag(
            key: ValueKey(index),
            controller: controller.scrollController,
            index: index,
            // Highlight color when programmatically scrolled to
            highlightColor: context.colorScheme.primary.withValues(alpha: 0.3),
            child: Obx(() {
              // Selection mode state
              final isSelected = controller.selectedMessages.contains(
                message.id,
              );
              final isSelectionMode = controller.selectedMessages.isNotEmpty;
              // Highlight when replying to or referencing this message
              final isHighlighted =
                  controller.highlightedMessageId.value == message.id;

              return SwipeToReply(
                onReply: () {
                  // Swipe gesture to reply - disabled in selection mode
                  if (!isSelectionMode) {
                    controller.replyToMessage(message);
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: isLastInGroup ? 8 : 2, // Larger gap between groups
                    top: isFirstInGroup ? 4 : 0,
                  ),
                  width: double.infinity,
                  // Background color for selected/highlighted states
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? context.colorScheme.primary.withValues(alpha: 0.3)
                        : (isSelected
                              ? context.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                )
                              : Colors.transparent),
                  ),
                  // Align message bubble based on sender
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  // Track message visibility for read receipts
                  child: VisibilityDetector(
                    key: Key(message.id),
                    onVisibilityChanged: (info) {
                      // Mark as read when 50% visible and not from current user
                      if (info.visibleFraction > 0.5 &&
                          !isMe &&
                          !message.isRead) {
                        controller.markMessageAsRead(message.id);
                      }
                    },
                    child: GestureDetector(
                      // Long press to enter selection mode
                      onLongPress: () {
                        controller.toggleMessageSelection(message.id);
                      },
                      // Tap in selection mode toggles selection, otherwise ignored
                      onTap: () {
                        if (isSelectionMode) {
                          controller.toggleMessageSelection(message.id);
                        }
                      },
                      // Main message bubble container
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: context.width * 0.75,
                        ),
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
                            // Reply preview section - shows quoted message
                            if (message.replyToMessageId != null)
                              GestureDetector(
                                onTap: () {
                                  // Tap on reply preview to scroll to original message
                                  controller.scrollToMessage(
                                    message.replyToMessageId!,
                                  );
                                },
                                child: _buildReplyPreview(
                                  context,
                                  message,
                                  isMe,
                                ),
                              ),

                            // Message content with timestamp overlay/alignment
                            _buildMessageContentWithTimestamp(
                              context,
                              message,
                              isMe,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      );
    });
  }

  //* Builds a preview of the message being replied to.
  //*
  //* Displays:
  //* - Sender name of the original message
  //* - Media thumbnail if available (image/video)
  //* - Truncated text content
  //* - Left border accent for visual distinction
  Widget _buildReplyPreview(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    return GestureDetector(
      onTap: () {
        controller.scrollToMessage(message.replyToMessageId!);
      },
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

  //* Builds the main message content with appropriate timestamp positioning.
  //*
  //* Different layout strategies based on message type:
  //* - Deleted messages: Special styling with block icon
  //* - Media messages: Timestamp overlay on bottom-right
  //* - Text/Other messages: Timestamp inline at end of text
  Widget _buildMessageContentWithTimestamp(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    // Helper to build consistent timestamp widget across all message types
    Widget buildTimestamp({Color? color}) {
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

    // Handle deleted messages (visible to everyone)
    if (message.isDeletedForEveryone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.block),
            const SizedBox(width: 4),
            AppText(
              "This message was deleted",
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: buildTimestamp(),
            ),
          ],
        ),
      );
    }

    // For Media types (Image, Video), use Stack overlay for timestamp
    if (message.type == MessageType.image ||
        message.type == MessageType.video) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: _buildMediaContent(context, message, isMe),
          ),
          buildTimestamp(),
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
          _buildTextOrOtherContent(context, message, isMe),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: buildTimestamp(),
          ),
        ],
      ),
    );
  }

  //* Routes message to appropriate media content builder.
  //*
  //* Supported media types:
  //* - Image: Display with optional caption
  //* - Video: Display with play button overlay
  Widget _buildMediaContent(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(context, message);
      case MessageType.video:
        return _buildVideoMessage(context, message);
      default:
        return const SizedBox.shrink();
    }
  }

  //* Routes non-media messages to appropriate content builder.
  //*
  //* Supported types:
  //* - Text: Simple text display
  //* - Location: Interactive map link
  //* - Document: File with download/view action
  Widget _buildTextOrOtherContent(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    switch (message.type) {
      case MessageType.location:
        return _buildLocationMessage(context, message, isMe);
      case MessageType.document:
        return _buildDocumentMessage(context, message, isMe);
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

  //* Builds image message with comprehensive upload state management.
  //*
  //* States handled:
  //* 1. Uploading: Shows local file preview + progress overlay with cancel
  //* 2. Failed: Shows local file preview + error overlay with retry
  //* 3. Success: Shows cached network image + tap to fullscreen
  //* 4. Optional text caption below image
  Widget _buildImageMessage(BuildContext context, ChatsEntity message) {
    final isUploading = message.status == MessageStatus.uploading;
    final isFailed = message.status == MessageStatus.failed;
    final hasLocalFile = message.localFilePath != null;

    return GestureDetector(
      onTap: () {
        // Navigate to full-screen media viewer only for successfully uploaded images
        if (!isUploading && !isFailed && message.mediaUrl != null) {
          context.pushNamed(
            AppRoutes.networkMediaView.name,
            extra: {'url': message.mediaUrl, 'type': MessageType.image},
          );
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview (local or network)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(
                  message,
                  isUploading,
                  isFailed,
                  hasLocalFile,
                ),
              ),
              // Optional caption text
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppText(
                    message.text,
                    fontSize: 16,
                    overflow: TextOverflow.visible,
                    color: Colors.white, // Caption always white for contrast
                  ),
                ),
              ],
            ],
          ),
          // State overlay for upload in progress
          if (isUploading) _buildUploadingOverlay(context, message),
          // State overlay for failed upload
          if (isFailed) _buildFailedOverlay(context, message),
        ],
      ),
    );
  }

  //* Builds appropriate image preview based on upload state.
  //*
  //* Priority order:
  //* 1. Local file (during upload/failed states)
  //* 2. Network image (successful upload)
  //* 3. Placeholder (fallback)
  Widget _buildImagePreview(
    ChatsEntity message,
    bool isUploading,
    bool isFailed,
    bool hasLocalFile,
  ) {
    // Show local file preview during upload or after failure
    if ((isUploading || isFailed) && hasLocalFile) {
      return Image.file(
        File(message.localFilePath!),
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 250,
            height: 250,
            color: Colors.grey.withValues(alpha: 0.3),
            child: const Icon(Icons.broken_image, size: 50),
          );
        },
      );
    }

    // Show cached network image for successfully uploaded images
    if (message.mediaUrl != null) {
      return CachedNetworkImage(
        imageUrl: message.mediaUrl!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 250,
          height: 250,
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }

    // Fallback placeholder
    return Container(
      width: 250,
      height: 250,
      color: Colors.grey.withValues(alpha: 0.3),
      child: const Icon(Icons.image, size: 50),
    );
  }

  //* Builds video message with thumbnail and upload management.
  //*
  //* Features:
  //* - Distinct visual for local vs network videos
  //* - Upload progress with cancel
  //* - Failed state with retry
  //* - Play button overlay for successful uploads
  Widget _buildVideoMessage(BuildContext context, ChatsEntity message) {
    final isUploading = message.status == MessageStatus.uploading;
    final isFailed = message.status == MessageStatus.failed;
    final hasLocalFile = message.localFilePath != null;

    return GestureDetector(
      onTap: () {
        // Navigate to video player for successfully uploaded videos
        if (!isUploading && !isFailed && message.mediaUrl != null) {
          context.pushNamed(
            AppRoutes.networkMediaView.name,
            extra: {'url': message.mediaUrl, 'type': MessageType.video},
          );
        }
      },
      child: Stack(
        children: [
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Local video placeholder
                if ((isUploading || isFailed) && hasLocalFile)
                  const Icon(Icons.videocam, size: 50, color: Colors.white70)
                // Play button for ready-to-play videos
                else if (message.mediaUrl != null)
                  const Icon(
                    Icons.play_circle_fill,
                    size: 50,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
          // Upload progress overlay
          if (isUploading) _buildUploadingOverlay(context, message),
          // Failed upload overlay
          if (isFailed) _buildFailedOverlay(context, message),
        ],
      ),
    );
  }

  //* Builds overlay for messages currently uploading.
  //*
  //* Displays:
  //* - Progress percentage
  //* - Circular progress indicator
  //* - Cancel button to abort upload
  Widget _buildUploadingOverlay(BuildContext context, ChatsEntity message) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: message.uploadProgress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 8),
            AppText(
              '${(message.uploadProgress * 100).toInt()}%',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            // Cancel upload button
            TextButton.icon(
              onPressed: () {
                controller.cancelUpload(message.id);
              },
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              label: const AppText('Cancel', fontSize: 12, color: Colors.white),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //* Builds overlay for messages that failed to upload.
  //*
  //* Displays:
  //* - Error icon
  //* - Error message (custom or default)
  //* - Retry button to attempt upload again
  Widget _buildFailedOverlay(BuildContext context, ChatsEntity message) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppText(
                message.uploadError ?? 'Upload failed',
                fontSize: 12,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            // Retry upload button
            TextButton.icon(
              onPressed: () {
                controller.retryUpload(message.id);
              },
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const AppText('Retry', fontSize: 12, color: Colors.white),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //* Builds location message with interactive map link.
  //*
  //* Message.text should contain a valid URL (Google Maps, Apple Maps, etc.)
  //* Opens in external map application on tap.
  Widget _buildLocationMessage(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(message.text);
        // Attempt to launch in external map app
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback - try direct launch
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: isMe ? Colors.white : Colors.red),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'View Location',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //* Builds document/file message.
  //*
  //* Features:
  //* - File icon
  //* - Filename (from message.text)
  //* - Opens document in external viewer on tap
  Widget _buildDocumentMessage(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(message.mediaUrl ?? '');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.text.isNotEmpty ? message.text : 'Document',
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
