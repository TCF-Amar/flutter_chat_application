import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/list_chats.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatMessagesWidget extends StatelessWidget {
  final ChatController controller;
  final ContactsEntity contact;

  const ChatMessagesWidget({
    super.key,
    required this.controller,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.errorMessage.value,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.retryLoading,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (controller.messages.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No messages yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                'Say hello to start the conversation!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.refreshMessages();
        },

        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListChats(
            controller: controller,
            onMessageVisible: (message) {
              // Mark message as read when it becomes visible
              if (!message.isRead && message.senderId == contact.id) {
                controller.markMessageAsRead(message.id);
              }
            },
          ),
        ),
      );
    });
  }
}
