import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/list_chats.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:chat_kare/features/chat/presentation/bindings/chats_binding.dart';

class ChatPage extends StatefulWidget {
  final ContactsEntity contact;
  const ChatPage({super.key, required this.contact});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    ChatsBinding.init();
    final ChatController controller = Get.find<ChatController>();
    controller.uid.value = widget.contact.id;
  }

  @override
  void dispose() {
    ChatsBinding.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();
    final user = controller.user;
    return AppScaffold(
      appBar: DefaultAppBar(
        centerTitle: false,
        title: "",
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              widget.contact.name != null
                  ? widget.contact.name!
                  : user?.displayName ??
                        widget.contact.phoneNumber ??
                        user?.phoneNumber ??
                        "",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            Obx(
              () => controller.isOtherUserTyping.value
                  ? const AppText(
                      "Typing...",
                      fontSize: 12,
                      color: Colors.green,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const ListChats(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppTextFormField(
              prefixIcon: Icon(Icons.emoji_emotions_outlined),
              controller: controller.messageController,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined),
                  // Icon(Icons.attach_file),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      controller.sendMessage();
                    },
                  ),
                  SizedBox(width: 8),
                ],
              ),

              hint: 'Type a message',
            ),
          ),
        ],
      ),
    );
  }
}
