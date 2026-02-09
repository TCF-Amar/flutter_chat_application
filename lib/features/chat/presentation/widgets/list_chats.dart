import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
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
          // ... rest of builder

          return VisibilityDetector(
            key: Key(message.id),
            onVisibilityChanged: (info) {
              if (info.visibleFraction > 0.5 && !isMe && !message.isRead) {
                controller.markMessageAsRead(message.id);
              }
            },
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: context.width * 0.7),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isMe
                      ? context.colorScheme.primary
                      : context.colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
                    bottomRight: isMe
                        ? Radius.circular(0)
                        : Radius.circular(12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AppText(
                        message.text,
                        fontSize: 16,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          DateFormat('hh:mm a').format(message.timestamp),
                          fontSize: 10,
                        ),
                        if (isMe) ...[
                          SizedBox(width: 4),
                          if (message.status == MessageStatus.sending)
                            const SizedBox(
                              height: 12,
                              width: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (message.status != MessageStatus.sending)
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 16,
                              color: message.isRead
                                  ? context.textColors.link
                                  : context.textColors.white,
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
