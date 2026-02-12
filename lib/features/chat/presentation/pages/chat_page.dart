import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/chat_app_bar_widget.dart';
import 'package:chat_kare/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:chat_kare/features/chat/presentation/widgets/chat_messages_widget.dart';
import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatPage extends StatefulWidget {
  final UserEntity contact;
  const ChatPage({super.key, required this.contact});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late ChatController _controller;
  final String _controllerTag = 'chat_${DateTime.now().millisecondsSinceEpoch}';

  //* Get contact from ContactsController for latest data (custom names, etc.)
  UserEntity get _contact {
    try {
      final contactsController = Get.find<ContactsController>();
      return contactsController.getContactByUid(widget.contact.uid) ??
          widget.contact;
    } catch (e) {
      // Fallback to widget.contact if ContactsController not available
      return widget.contact;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Create a unique controller for this chat page
    _controller = Get.put(
      ChatController(
        contact: _contact,
        authStateNotifier: Get.find<AuthStateNotifier>(),
      ),
      tag: _controllerTag,
    );

    // Initialize chat after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initializeChat();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - mark messages as read
        // _controller.markAllMessagesAsRead();
        break;
      case AppLifecycleState.paused:
        // App went to background
        _controller.onChatPaused();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Clean up controller when page is disposed
    if (Get.isRegistered<ChatController>(tag: _controllerTag)) {
      Get.delete<ChatController>(tag: _controllerTag);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ChatAppBarWidget(controller: _controller, contact: _contact),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: ChatMessagesWidget(
                  controller: _controller,
                  contact: _contact,
                ),
              ),
              ChatInputWidget(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}
