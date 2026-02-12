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
 * 
 * Note: Most UI logic has been extracted to separate widget files:
 * - editing_preview_widget.dart: Editing mode banner
 * - reply_preview_banner.dart: Reply mode banner
 * - attachment_menu_button.dart: Media attachment menu
 * - message_text_field.dart: Text input with actions
 */

import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/attachment_menu_button.dart';
import 'package:chat_kare/features/chat/presentation/widgets/editing_preview_widget.dart';
import 'package:chat_kare/features/chat/presentation/widgets/message_text_field.dart';
import 'package:chat_kare/features/chat/presentation/widgets/reply_preview_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              EditingPreviewWidget(
                messageText: widget.controller.messageController.text,
                onCancel: widget.controller.cancelEditing,
              )
            // Show reply preview if replying to a message
            else if (isReplying)
              ReplyPreviewBanner(
                replyMessage: replyMessage,
                currentUserId: widget.controller.fs.currentUser?.uid ?? '',
                onCancel: widget.controller.cancelReply,
              ),
            // Always show input row
            _buildInputRow(isEditing),
          ],
        ),
      );
    });
  }

  /// Builds the main input row with attachment menu and text field
  Widget _buildInputRow(bool isEditing) {
    return Row(
      children: [
        // Attachment menu button
        AttachmentMenuButton(
          onTakePhoto: widget.controller.takePhoto,
          onPickImageFromGallery: widget.controller.pickImageFromGallery,
          onPickVideoFromCamera: widget.controller.pickVideoFromCamera,
          onPickVideoFromGallery: widget.controller.pickVideoFromGallery,
          onPickDocument: widget.controller.pickDocument,
          onShareLocation: widget.controller.shareLocation,
        ),

        // Text input field
        MessageTextField(
          controller: widget.controller.messageController,
          onChanged: widget.controller.onTextChanged,
          onSend: widget.controller.sendMessage,
          onEmojiPicker: _showEmojiPicker,
          onVoiceRecording: _startVoiceRecording,
          hasText: widget.controller.hasText,
          isEditing: isEditing,
        ),
      ],
    );
  }

  /// Shows emoji picker dialog
  /// TODO: Implement emoji picker functionality
  void _showEmojiPicker() {
    // Implement emoji picker
  }

  /// Starts voice recording for voice messages
  /// TODO: Implement voice recording functionality
  void _startVoiceRecording() {
    // Implement voice recording
  }
}
