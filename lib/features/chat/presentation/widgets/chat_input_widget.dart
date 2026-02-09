import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatInputWidget extends StatefulWidget {
  final ChatController controller;

  const ChatInputWidget({super.key, required this.controller});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        // border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Emoji button
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: _showEmojiPicker,
          ),

          // Attachment button
          PopupMenuButton<String>(
            icon: const Icon(Icons.attach_file),
            onSelected: (value) => _handleAttachment(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Camera'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: Row(
                  children: [
                    Icon(Icons.photo_library, size: 20),
                    SizedBox(width: 8),
                    Text('Gallery'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'document',
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 20),
                    SizedBox(width: 8),
                    Text('Document'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 8),
                    Text('Location'),
                  ],
                ),
              ),
            ],
          ),

          // Message input field
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextFormField(
                      controller: widget.controller.messageController,
                      hint: "Type message...",
                      borderRadius: 24,
                      minLines: 1,
                      maxLines: 5,
                      onChanged: (text) {
                        widget.controller.onTextChanged(text);
                      },
                      suffixIcon: Obx(() {
                        if (widget.controller.hasText.value) {
                          return IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: () {
                              widget.controller.sendMessage();
                            },
                          );
                        } else {
                          return IconButton(
                            icon: const Icon(Icons.mic, color: Colors.grey),
                            onPressed: _startVoiceRecording,
                          );
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    // Implement emoji picker
  }

  void _handleAttachment(String type) {
    switch (type) {
      case 'camera':
        widget.controller.takePhoto();
        break;
      case 'gallery':
        widget.controller.pickImageFromGallery();
        break;
      case 'document':
        widget.controller.pickDocument();
        break;
      case 'location':
        widget.controller.shareLocation();
        break;
    }
  }

  void _startVoiceRecording() {
    // Implement voice recording
  }
}
