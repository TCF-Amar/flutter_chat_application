import 'dart:async';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/domain/repositories/chats_repository.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ContactsEntity contact;
  final ChatsRepository chatsRepository;
  final NotificationServices notificationService;
  final AuthUsecase authUsecase;
  final AuthStateNotifier authStateNotifier; // Injected
  final FirebaseServices fs = Get.find();

  ChatController({required this.contact, required this.authStateNotifier})
    : chatsRepository = Get.find(),
      notificationService = Get.find(),
      authUsecase = Get.find();

  final Rx<UserEntity?> user = Rx<UserEntity?>(null);
  final RxList<ChatsEntity> messages = <ChatsEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isOtherUserTyping = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isMuted = false.obs;

  final TextEditingController messageController = TextEditingController();

  final FocusNode messageFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  Timer? _typingTimer;
  StreamSubscription<List<ChatsEntity>>? _messagesSubscription;
  StreamSubscription<List<String>>? _typingSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  String get chatId => _generateChatId();

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    // messageController.addListener(_onTextChanged); // Moved to onChanged in UI
  }

  Future<void> initializeChat() async {
    await _bindMessagesStream();
    await _bindTypingStream();
    await _bindUnreadCountStream();
    await _bindUnreadCountStream();
    // await _markAllMessagesAsRead(); // Let VisibilityDetector handle it
  }

  Future<void> _loadUserInfo() async {
    try {
      final result = await authUsecase.getUser(contact.id);
      result.fold(
        (failure) => errorMessage.value = 'Failed to load user info',
        (userData) => user.value = userData,
      );
    } catch (e) {
      errorMessage.value = 'Error loading user info: $e';
    }
  }

  Future<void> _bindMessagesStream() async {
    isLoading.value = true;

    _messagesSubscription?.cancel();
    _messagesSubscription = chatsRepository
        .getMessagesStream(chatId)
        .listen(_onMessagesUpdated, onError: _onMessagesError);
  }

  void _onMessagesUpdated(List<ChatsEntity> newMessages) {
    // Sort messages by timestamp (oldest first)
    newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    bool isInitialLoad = isLoading.value;
    messages.assignAll(newMessages);
    isLoading.value = false;
    errorMessage.value = '';

    // Mark new messages as read
    // Mark new messages as read
    // _autoMarkNewMessagesAsRead(); // Let VisibilityDetector handle it

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isInitialLoad) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      } else {
        scrollToBottom();
      }
    });
  }

  void _onMessagesError(dynamic error) {
    errorMessage.value = 'Failed to load messages: $error';
    isLoading.value = false;
  }

  Future<void> _bindTypingStream() async {
    _typingSubscription?.cancel();
    _typingSubscription = chatsRepository.getTypingUsersStream(chatId).listen((
      typingUsers,
    ) {
      isOtherUserTyping.value = typingUsers.contains(contact.id);
    });
  }

  Future<void> _bindUnreadCountStream() async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId != null) {
      _unreadCountSubscription?.cancel();
      _unreadCountSubscription = chatsRepository
          .getUnreadCountStream(chatId, currentUserId)
          .listen((count) {
            // Update UI if needed
          });
    }
  }

  final RxBool hasText = false.obs;

  void onTextChanged(String value) {
    hasText.value = value.trim().isNotEmpty;

    // Send typing indicator
    if (_typingTimer?.isActive ?? false) {
      _typingTimer?.cancel();
    }

    if (value.isNotEmpty) {
      _sendTypingStatus(true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _sendTypingStatus(false);
      });
    } else {
      _sendTypingStatus(false);
    }
  }

  void _sendTypingStatus(bool isTyping) {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId != null) {
      chatsRepository.sendTypingStatus(
        chatId: chatId,
        userId: currentUserId,
        isTyping: isTyping,
      );
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId == null) return;

    await chatsRepository.markMessageAsRead(
      chatId: chatId,
      messageId: messageId,
      userId: currentUserId,
    );
  }

  Future<void> markAllMessagesAsRead() async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId == null) return;

    await chatsRepository.markAllMessagesAsRead(
      chatId: chatId,
      userId: currentUserId,
    );
  }

  Future<void> sendMessage() async {
    if (editingMessageId.value != null) {
      await editMessage();
      return;
    }
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();

    final currentUserId = authUsecase.currentUid;
    final currentUser = fs.currentUser;

    if (currentUserId == null || currentUser == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final replyTo = replyMessage.value;

    final message = ChatsEntity(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: contact.id,
      senderName: authStateNotifier.user?.displayName ?? 'Unknown',
      senderPhotoUrl: authStateNotifier.user?.photoUrl ?? currentUser.photoURL,
      receiverName: contact.name,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: const [],
      status: MessageStatus.sending,
      replyToMessageId: replyTo?.id,
      replyToSenderName: replyTo?.senderName,
      replyToText: replyTo?.text,
      replyToType: replyTo?.type,
    );

    // Clear reply state
    cancelReply();

    // Optimistic update
    messages.add(message);
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    final result = await chatsRepository.sendMessage(message);
    result.fold(
      (failure) {
        messages.remove(message);
        errorMessage.value = 'Failed to send message';
        Get.snackbar('Error', 'Failed to send message');
      },
      (_) {
        messageFocusNode.requestFocus();
      },
    );
  }

  final Rx<String?> editingMessageId = Rx<String?>(null);

  void startEditing(ChatsEntity message) {
    editingMessageId.value = message.id;
    messageController.text = message.text;
    messageFocusNode.requestFocus();
  }

  void cancelEditing() {
    editingMessageId.value = null;
    messageController.clear();
    messageFocusNode.unfocus();
  }

  final Rx<ChatsEntity?> replyMessage = Rx<ChatsEntity?>(null);

  void replyToMessage(ChatsEntity message) {
    replyMessage.value = message;
    messageFocusNode.requestFocus();
  }

  void cancelReply() {
    replyMessage.value = null;
  }

  Future<void> editMessage() async {
    final messageId = editingMessageId.value;
    if (messageId == null) return;

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // Optimistic update
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final oldMessage = messages[index];

      // If text hasn't changed, just cancel editing
      if (oldMessage.text == text) {
        cancelEditing();
        return;
      }

      messages[index] = ChatsEntity(
        id: oldMessage.id,
        chatId: oldMessage.chatId,
        senderId: oldMessage.senderId,
        receiverId: oldMessage.receiverId,
        senderName: oldMessage.senderName,
        receiverName: oldMessage.receiverName,
        senderPhotoUrl: oldMessage.senderPhotoUrl,
        text: text,
        type: oldMessage.type,
        timestamp: oldMessage.timestamp,
        isRead: oldMessage.isRead,
        readBy: oldMessage.readBy,
        status: oldMessage.status,
        isEdited: true,
      );
    }

    cancelEditing();

    final result = await chatsRepository.editMessage(
      chatId: chatId,
      messageId: messageId,
      text: text,
    );

    result.fold((failure) {
      errorMessage.value = 'Failed to edit message';
      Get.snackbar('Error', 'Failed to edit message');
      // Revert optimistic update if needed, or just let stream refresh handle it
    }, (_) => null);
  }

  // selected chat
  // ------------------------------------------------------

  final RxList<String> selectedMessages = <String>[].obs;

  void toggleMessageSelection(String messageId) {
    if (selectedMessages.contains(messageId)) {
      selectedMessages.remove(messageId);
    } else {
      selectedMessages.add(messageId);
    }
  }

  void clearSelection() {
    selectedMessages.clear();
  }

  void deleteSelectedMessages() {
    Get.snackbar('Delete', 'Deleted ${selectedMessages.length} messages');
    clearSelection();
  }

  void copySelectedMessages() {
    final selectedText = messages
        .where((m) => selectedMessages.contains(m.id))
        .map((m) => m.text)
        .join('\n');
    Clipboard.setData(ClipboardData(text: selectedText));
    Get.snackbar('Copy', 'Copied to clipboard');
    clearSelection();
  }

  // ------------------------------------------------------

  Future<void> refreshMessages() async {
    await _bindMessagesStream();
  }

  Future<void> retryLoading() async {
    await _bindMessagesStream();
  }

  void searchMessages(String query) {
    // isme chat search ki functionality add karni hai
  }

  void takePhoto() async {
    // isme camera ki functionality add karni hai
  }

  void pickImageFromGallery() async {
    // isme gallery ki functionality add karni hai
  }

  void pickDocument() async {
    // isme document ki functionality add karni hai
  }

  void shareLocation() async {
    // isme location ki functionality add karni hai
  }

  void blockUser() async {
    // isme block user ki functionality add karni hai
  }

  void toggleMuteNotifications() {
    isMuted.value = !isMuted.value;
    // Save to preferences
  }

  void clearChat() async {
    // Implement clear chat functionality
  }

  void onChatPaused() {
    _typingTimer?.cancel();
    _sendTypingStatus(false);
  }

  @override
  void onClose() {
    onChatPaused();
    // markAllMessagesAsRead(); // Can fail if auth state is flaky on close? But OK.

    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _unreadCountSubscription?.cancel();

    messageController.dispose();

    messageFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  String _generateChatId() {
    final currentUserId = Get.find<AuthUsecase>().currentUid;
    if (currentUserId == null) return '';

    final sortedIds = [currentUserId, contact.id]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
