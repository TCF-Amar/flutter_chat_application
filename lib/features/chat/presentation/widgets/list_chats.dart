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

class ListChats extends StatelessWidget {
  final ChatController controller;
  final Function(ChatsEntity)? onMessageVisible;

  const ListChats({super.key, required this.controller, this.onMessageVisible});

  @override
  Widget build(BuildContext context) {
    // final ChatController controller = Get.find<ChatController>(); // Removed explicitly finding
    return Obx(() {
      final messages = controller.messages;
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (messages.isEmpty) {
        return const Center(child: Text("No messages yet"));
      }

      return ListView.builder(
        controller: controller.scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          onMessageVisible?.call(message);

          final isMe = message.senderId == controller.fs.currentUser?.uid;

          // Check for consecutive messages
          final bool isFirstInGroup =
              index == 0 || messages[index - 1].senderId != message.senderId;
          final bool isLastInGroup =
              index == messages.length - 1 ||
              messages[index + 1].senderId != message.senderId;

          // Define border radius based on grouping
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
            highlightColor: context.colorScheme.primary.withValues(alpha: 0.3),
            child: Obx(() {
              final isSelected = controller.selectedMessages.contains(
                message.id,
              );
              final isSelectionMode = controller.selectedMessages.isNotEmpty;
              final isHighlighted =
                  controller.highlightedMessageId.value == message.id;

              return SwipeToReply(
                onReply: () {
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
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? context.colorScheme.primary.withValues(alpha: 0.3)
                        : (isSelected
                              ? context.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                )
                              : Colors.transparent),
                  ),
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: VisibilityDetector(
                    key: Key(message.id),
                    onVisibilityChanged: (info) {
                      if (info.visibleFraction > 0.5 &&
                          !isMe &&
                          !message.isRead) {
                        controller.markMessageAsRead(message.id);
                      }
                    },
                    child: GestureDetector(
                      onLongPress: () {
                        controller.toggleMessageSelection(message.id);
                      },
                      onTap: () {
                        if (isSelectionMode) {
                          controller.toggleMessageSelection(message.id);
                        }
                      },
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
                            if (message.replyToMessageId != null)
                              GestureDetector(
                                onTap: () {
                                  controller.scrollToMessage(
                                    message.replyToMessageId!,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.black.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: isMe
                                            ? Colors.white
                                            : context.colorScheme.primary,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (message.replyToMediaUrl != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  message.replyToMediaUrl!,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.1),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.error,
                                                        size: 16,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.replyToSenderName ??
                                                  'Unknown',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isMe
                                                    ? Colors.white
                                                    : context
                                                          .colorScheme
                                                          .primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (message.replyToType ==
                                                    MessageType.image)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 4,
                                                    ),
                                                    child: Icon(
                                                      Icons.photo,
                                                      size: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                if (message.replyToType ==
                                                    MessageType.video)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 4,
                                                    ),
                                                    child: Icon(
                                                      Icons.videocam,
                                                      size: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                Flexible(
                                                  child: Text(
                                                    message.replyToText !=
                                                                null &&
                                                            message
                                                                .replyToText!
                                                                .isNotEmpty
                                                        ? message.replyToText!
                                                        : (message.replyToType ==
                                                                  MessageType
                                                                      .image
                                                              ? 'Photo'
                                                              : (message.replyToType ==
                                                                        MessageType
                                                                            .video
                                                                    ? 'Video'
                                                                    : 'Message')),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
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
                              ),
                            // Content and Timestamp
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

  Widget _buildMessageContentWithTimestamp(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    // Helper to build timestamp widget
    Widget buildTimestamp({Color? color}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (message.isEdited)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: AppText(
                '(edited)',
                fontSize: 10,
                color: color ?? (isMe ? Colors.white70 : Colors.grey),
              ),
            ),
          AppText(
            DateFormat('hh:mm a').format(message.timestamp),
            fontSize: 10,
            color: color ?? (isMe ? Colors.white70 : Colors.grey),
          ),
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

    // Handle deleted messages
    if (message.isDeletedForEveryone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          runSpacing: 2,
          children: [
            AppText(
              "This message was deleted",
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: buildTimestamp(),
            ),
          ],
        ),
      );
    }

    // For Media types (Image, Video), we use Stack to overlay timestamp
    if (message.type == MessageType.image ||
        message.type == MessageType.video) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: _buildMediaContent(context, message, isMe),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: buildTimestamp(color: Colors.white),
            ),
          ),
        ],
      );
    }

    // For Text and other types, we use the Flow/Wrap layout
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

  Widget _buildImageMessage(BuildContext context, ChatsEntity message) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoutes.networkMediaView.name,
          extra: {'url': message.mediaUrl, 'type': MessageType.image},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl ?? '',
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: Colors.grey.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: 250, // Slightly wider
              fit: BoxFit.cover,
            ),
          ),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppText(
                message.text,
                fontSize: 16,
                overflow: TextOverflow.visible,
                color: Colors
                    .white, // Usually media caption is on media or dark bg
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context, ChatsEntity message) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoutes.networkMediaView.name,
          extra: {'url': message.mediaUrl, 'type': MessageType.video},
        );
      },
      child: Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          image: null, // You could add a thumbnail here if available
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Placeholder/Thumbnail logic could go here
            const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessage(
    BuildContext context,
    ChatsEntity message,
    bool isMe,
  ) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(message.text);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: Try to launch anyway without checking
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
