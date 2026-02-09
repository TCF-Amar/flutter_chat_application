import 'dart:async';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/domain/repositories/chats_repository.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ContactsEntity contact;
  final ChatsRepository chatsRepository;
  final NotificationServices notificationService;
  final AuthUsecase authUsecase;
  final FirebaseServices fs = Get.find();

  ChatController({required this.contact})
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

    final message = ChatsEntity(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: contact.id,
      senderName: currentUser.displayName ?? currentUser.email ?? 'Unknown',
      senderPhotoUrl: currentUser.photoURL,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: const [],
      status: MessageStatus.sending,
    );

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

  Future<void> refreshMessages() async {
    await _bindMessagesStream();
  }

  Future<void> retryLoading() async {
    await _bindMessagesStream();
  }

  void searchMessages(String query) {
    // Implement search functionality
  }

  void takePhoto() async {
    // Implement camera functionality
  }

  void pickImageFromGallery() async {
    // Implement gallery picker
  }

  void pickDocument() async {
    // Implement document picker
  }

  void shareLocation() async {
    // Implement location sharing
  }

  void blockUser() async {
    // Implement block user functionality
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

    // Sort IDs to ensure consistent chat ID
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
