/*
 * ChatInputWidget - Message Input Component for Chat Screen
 * 
 * This widget provides a comprehensive message input interface with:
 * - Text message input with emoji support
 * - Media attachments (camera, gallery, documents, location)
 * - Voice recording capability
 * - Message editing mode with preview
 * - Reply-to-message mode with preview
 * - Real-time typing indicators
 * 
 * The widget dynamically switches between three states:
 * 1. Normal Mode: Standard message input
 * 2. Editing Mode: Shows editing preview with original message
 * 3. Reply Mode: Shows reply preview with quoted message
 */

import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';

/// Message input widget for chat screen
/// Handles text input, media attachments, and message actions
class ChatInputWidget extends StatefulWidget {
  /// Controller managing chat state and message operations
  final ChatController controller;

  const ChatInputWidget({super.key, required this.controller});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  /// Builds the input widget with reactive state management
  /// Displays different UI based on editing or reply mode
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Check current input mode
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
            // Show editing preview if in edit mode
            if (isEditing)
              _buildEditingPreview()
            // Show reply preview if replying to a message
            else if (isReplying)
              _buildReplyPreview(replyMessage),
            // Always show input row
            _buildInputRow(isEditing),
          ],
        ),
      );
    });
  }

  /// Builds the editing preview banner
  /// Shows the original message text being edited with a close button
  Widget _buildEditingPreview() {
    return Column(
      children: [
        Container(
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
                // Cancel editing button
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: widget.controller.cancelEditing,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Spacer(),
                // Original message preview
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
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
        ),
      ],
    );
  }

  /// Builds the reply preview banner
  /// Shows the message being replied to with sender name and text
  ///
  /// Parameters:
  /// - [replyMessage]: The message entity being replied to
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
                    // Sender name ("You" or contact name)
                    Text(
                      replyMessage.receiverName == widget.controller.contact.uid
                          ? 'You'
                          : replyMessage.receiverName,
                      style: TextStyle(
                        // Blue for contact, green for current user
                        color:
                            replyMessage.senderId ==
                                widget.controller.contact.uid
                            ? Colors.blue
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    // Message text preview
                    Text(
                      replyMessage.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Cancel reply button
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

  /// Builds the main input row with text field and action buttons
  ///
  /// Features:
  /// - Attachment menu (camera, gallery, video, documents, location)
  /// - Text input field with emoji picker
  /// - Dynamic send/voice button based on text presence
  /// - Typing indicator trigger
  ///
  /// Parameters:
  /// - [isEditing]: Whether currently in editing mode (changes send icon to check)
  Widget _buildInputRow(bool isEditing) {
    return Row(
      children: [
        // Attachment menu button
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
              value: 'cameraVideo',
              child: Row(
                children: [
                  Icon(Icons.camera_alt, size: 20),
                  SizedBox(width: 8),
                  Text('Camera Video'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'galleryVideo',
              child: Row(
                children: [
                  Icon(Icons.photo_library, size: 20),
                  SizedBox(width: 8),
                  Text('Gallery Video'),
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

        // Text input field container
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
                    textCapitalization: TextCapitalization.sentences,
                    hint: "Type message...",
                    borderRadius: 14,
                    minLines: 1,
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    // Trigger typing indicator on text change
                    onChanged: (text) {
                      widget.controller.onTextChanged(text);
                    },
                    // Emoji picker button
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: _showEmojiPicker,
                    ),
                    // Dynamic suffix button (send or voice)
                    suffixIcon: Obx(() {
                      // Show send button if there's text or in editing mode
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
                      }
                      // Show voice recording button if no text
                      else {
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

  /// Shows emoji picker dialog
  /// TODO: Implement emoji picker functionality
  void _showEmojiPicker() {
    // Implement emoji picker
  }

  /// Handles attachment selection from popup menu
  ///
  /// Supported attachment types:
  /// - camera: Take photo with camera
  /// - gallery: Pick image from gallery
  /// - cameraVideo: Record video with camera
  /// - galleryVideo: Pick video from gallery
  /// - document: Pick document file
  /// - location: Share current location
  ///
  /// For media files, navigates to preview screen before sending
  void _handleAttachment(String type) async {
    Map<String, dynamic>? result;

    // Handle different attachment types
    switch (type) {
      case 'camera':
        result = await widget.controller.takePhoto();
        break;
      case 'gallery':
        result = await widget.controller.pickImageFromGallery();
        break;
      case 'cameraVideo':
        result = await widget.controller.pickVideoFromCamera();
        break;
      case 'galleryVideo':
        result = await widget.controller.pickVideoFromGallery();
        break;
      case 'document':
        result = await widget.controller.pickDocument();
        break;
      case 'location':
        // Location sharing doesn't need preview
        widget.controller.shareLocation();
        break;
    }

    // Navigate to media preview screen if media was selected
    if (result != null && mounted) {
      context.pushNamed(
        AppRoutes.mediaPreview.name,
        extra: {
          'file': result['file'],
          'type': result['type'],
          // Callback to send media with caption
          'onSend': (String caption) {
            widget.controller.sendMediaMessage(
              result!['file'],
              caption,
              result['type'],
            );
          },
        },
      );
    }
  }

  /// Starts voice recording for voice messages
  /// TODO: Implement voice recording functionality
  void _startVoiceRecording() {
    // Implement voice recording
  }
}
