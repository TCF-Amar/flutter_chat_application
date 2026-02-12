import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//* Text input field widget for message composition.
//*
//* Features:
//* - Multi-line text input with auto-grow
//* - Emoji picker button (prefix)
//* - Dynamic suffix button (send/voice/check icon)
//* - Typing indicator trigger
//* - Capitalization and keyboard type handling
class MessageTextField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onSend;
  final VoidCallback onEmojiPicker;
  final VoidCallback onVoiceRecording;
  final RxBool hasText;
  final bool isEditing;

  const MessageTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.onEmojiPicker,
    required this.onVoiceRecording,
    required this.hasText,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                hint: "Type message...",
                borderRadius: 14,
                minLines: 1,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                // Trigger typing indicator on text change
                onChanged: onChanged,
                // Emoji picker button
                prefixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: onEmojiPicker,
                ),
                // Dynamic suffix button (send or voice)
                suffixIcon: Obx(() {
                  // Show send button if there's text or in editing mode
                  if (hasText.value || isEditing) {
                    return IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.send,
                        color: Colors.blue,
                      ),
                      onPressed: onSend,
                    );
                  }
                  // Show voice recording button if no text
                  else {
                    return IconButton(
                      icon: const Icon(Icons.mic, color: Colors.grey),
                      onPressed: onVoiceRecording,
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
