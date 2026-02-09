import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';

import 'package:chat_kare/features/chat/presentation/widgets/swipe_to_reply.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

          return Obx(() {
            final isSelected = controller.selectedMessages.contains(message.id);
            final isSelectionMode = controller.selectedMessages.isNotEmpty;

            return SwipeToReply(
              onReply: () {
                if (!isSelectionMode) {
                  controller.replyToMessage(message);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? context.colorScheme.primary
                            : context.colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: isMe
                              ? const Radius.circular(10)
                              : const Radius.circular(0),
                          topRight: isMe
                              ? const Radius.circular(0)
                              : const Radius.circular(10),
                          bottomLeft: const Radius.circular(10),
                          bottomRight: const Radius.circular(10),
                        ),
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
                            Container(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isMe
                                          ? Colors.white
                                          : context.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    message.replyToText ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 6, // Space between text and time
                            runSpacing: 2, // Space if it wraps
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: AppText(
                                  message.text,
                                  fontSize: 16,
                                  overflow: TextOverflow.visible,
                                  color: isMe ? Colors.white : null,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (message.isEdited)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: AppText(
                                        '(edited)',
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : null,
                                      ),
                                    ),
                                  AppText(
                                    DateFormat(
                                      'hh:mm a',
                                    ).format(message.timestamp),
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : null,
                                  ),
                                  if (isMe &&
                                      message.status !=
                                          MessageStatus.sending) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.isRead
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: message.isRead
                                          ? Colors.blue.shade200
                                          : Colors.white70,
                                    ),
                                  ],
                                  if (isMe &&
                                      message.status ==
                                          MessageStatus.sending) ...[
                                    const SizedBox(width: 3),
                                    const SizedBox(
                                      height: 10,
                                      width: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
        },
      );
    });
  }
}
