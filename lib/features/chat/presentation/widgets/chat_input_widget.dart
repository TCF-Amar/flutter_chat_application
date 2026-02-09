import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';

class ChatInputWidget extends StatefulWidget {
  final ChatController controller;

  const ChatInputWidget({super.key, required this.controller});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = widget.controller.editingMessageId.value != null;
      final replyMessage = widget.controller.replyMessage.value;
      final isReplying = replyMessage != null;

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              _buildEditingPreview()
            else if (isReplying)
              _buildReplyPreview(replyMessage),
            _buildInputRow(isEditing),
          ],
        ),
      );
    });
  }

  Widget _buildEditingPreview() {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 8),
      height: 50,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: widget.controller.cancelEditing,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topLeft: Radius.circular(10),
                ),
              ),
              child: AppText(
                widget.controller.messageController.text,
                maxLines: 1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(ChatsEntity replyMessage) {
    return AnimatedContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.colorScheme.surface,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyMessage.receiverName ==
                              widget.controller.user.value?.uid
                          ? 'You'
                          : replyMessage.receiverName,
                      style: TextStyle(
                        color:
                            replyMessage.senderId ==
                                widget.controller.user.value?.uid
                            ? Colors.blue
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      replyMessage.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: widget.controller.cancelReply,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(bool isEditing) {
    return Row(
      children: [
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
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: widget.controller.messageController,
                    hint: "Type message...",
                    borderRadius: 14,
                    minLines: 1,
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChanged: (text) {
                      widget.controller.onTextChanged(text);
                    },
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: _showEmojiPicker,
                    ),
                    suffixIcon: Obx(() {
                      if (widget.controller.hasText.value || isEditing) {
                        return IconButton(
                          icon: Icon(
                            isEditing ? Icons.check : Icons.send,
                            color: Colors.blue,
                          ),
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
