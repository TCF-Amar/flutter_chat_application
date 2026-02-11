import 'dart:async';
import 'dart:io';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/core/utils/cloudinary_utils.dart';
import 'package:chat_kare/core/utils/media_picker.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/domain/repositories/chats_repository.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/*
 * ChatController manages all chat functionality including:
 * - Real-time message streaming
 * - Typing indicators
 * - Message sending (text/media)
 * - Edit/Delete/Reply features
 * - Selection mode for bulk operations
 * - Media handling (images/documents)
 */
class ChatController extends GetxController {
  //? Logger
  final Logger log = Logger();
  //* ===========================================================================
  //* DEPENDENCIES & SERVICES
  //* ===========================================================================
  final ContactsEntity contact;
  final ChatsRepository chatsRepository;
  final NotificationServices notificationService;
  final AuthUsecase authUsecase;
  final AuthStateNotifier authStateNotifier;
  final FirebaseServices fs = Get.find();

  ChatController({required this.contact, required this.authStateNotifier})
    : chatsRepository = Get.find(),
      notificationService = Get.find(),
      authUsecase = Get.find();

  //* ===========================================================================
  //* REACTIVE STATE
  //* ===========================================================================
  //*/ Current chat user info
  final Rx<UserEntity?> user = Rx<UserEntity?>(null);

  //*/ List of all chat messages
  final RxList<ChatsEntity> messages = <ChatsEntity>[].obs;

  //*/ Loading state for messages
  final RxBool isLoading = false.obs;

  //*/ Indicates if other user is typing
  final RxBool isOtherUserTyping = false.obs;

  //*/ Error messages for UI display
  final RxString errorMessage = ''.obs;

  //*/ Pagination
  final RxInt messageLimit = 20.obs;
  final RxBool isLoadingMore = false.obs;

  //*/ Chat notification mute status
  final RxBool isMuted = false.obs;

  //* ===========================================================================
  //* UI CONTROLLERS
  //* ===========================================================================
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final AutoScrollController scrollController = AutoScrollController();
  final RxString highlightedMessageId = ''.obs;

  //* ===========================================================================
  //* STREAM SUBSCRIPTIONS & TIMERS
  //* ===========================================================================
  Timer? _typingTimer;
  StreamSubscription<List<ChatsEntity>>? _messagesSubscription;
  StreamSubscription<List<String>>? _typingSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  //* ===========================================================================
  //* UTILITY GETTERS
  //* ===========================================================================
  //*/ Generates unique chat ID between two users
  String get chatId => _generateChatId();

  //* ===========================================================================
  //* LIFECYCLE METHODS
  //* ===========================================================================
  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _setupScrollListener();
  }

  /*
   * Initializes all real-time streams for the chat:
   * - Messages stream
   * - Typing indicators stream
   * - Unread count stream
   */
  Future<void> initializeChat() async {
    await _bindMessagesStream();
    await _bindTypingStream();
    await _bindUnreadCountStream();
  }

  //* ===========================================================================
  //* USER INFO LOADING
  //* ===========================================================================
  /*
   * Loads recipient user information from auth service
   */
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

  //* ===========================================================================
  //* MESSAGES STREAM MANAGEMENT
  //* ===========================================================================
  /*
   * Binds to real-time messages stream from Firestore
   */
  /*
   * Binds to real-time messages stream from Firestore
   */
  Future<void> _bindMessagesStream() async {
    if (messages.isEmpty) isLoading.value = true;
    _messagesSubscription?.cancel();
    _messagesSubscription = chatsRepository
        .getMessagesStream(chatId, limit: messageLimit.value)
        .listen(_onMessagesUpdated, onError: _onMessagesError);
  }

  /*
   * Handles incoming messages from stream
   * - Sorts by timestamp
   * - Updates UI
   * - Auto-scrolls to bottom
   */
  void _onMessagesUpdated(List<ChatsEntity> newMessages) {
    newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    bool isInitialLoad = isLoading.value;
    bool wasLoadingMore = isLoadingMore.value;

    messages.assignAll(newMessages);
    isLoading.value = false;
    isLoadingMore.value = false;
    errorMessage.value = '';

    //* Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isInitialLoad) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      } else if (!wasLoadingMore) {
        scrollToBottom();
      }
    });
  }

  void _onMessagesError(dynamic error) {
    errorMessage.value = 'Failed to load messages: $error';
    isLoading.value = false;
  }

  //* ===========================================================================
  //* TYPING INDICATOR
  //* ===========================================================================
  /*
   * Binds to real-time typing users stream
   */
  Future<void> _bindTypingStream() async {
    _typingSubscription?.cancel();
    _typingSubscription = chatsRepository.getTypingUsersStream(chatId).listen((
      typingUsers,
    ) {
      isOtherUserTyping.value = typingUsers.contains(contact.id);
    });
  }

  /*
   * Handles text input changes for typing indicator
   */
  final RxBool hasText = false.obs;
  void onTextChanged(String value) {
    hasText.value = value.trim().isNotEmpty;

    //* Manage typing timer
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

  /*
   * Sends typing status to other user via repository
   */
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

  //* ===========================================================================
  //* READ RECEIPTS
  //* ===========================================================================
  Future<void> _bindUnreadCountStream() async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId != null) {
      _unreadCountSubscription?.cancel();
      _unreadCountSubscription = chatsRepository
          .getUnreadCountStream(chatId, currentUserId)
          .listen((count) {
            //* Update UI if needed
          });
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

  //* ===========================================================================
  //* TEXT MESSAGING
  //* ===========================================================================
  /*
   * Sends text message with optimistic UI update
   */
  final Rx<String?> editingMessageId = Rx<String?>(null);
  final Rx<ChatsEntity?> replyMessage = Rx<ChatsEntity?>(null);

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
      replyToMediaUrl: replyTo?.mediaUrl,
    );

    cancelReply();
    messages.add(message);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    final result = await chatsRepository.sendMessage(message);
    result.fold((failure) {
      messages.remove(message);
      errorMessage.value = 'Failed to send message';
    }, (_) => messageFocusNode.requestFocus());
  }

  //* ===========================================================================
  //* MESSAGE EDITING
  //* ===========================================================================
  /*
   * Starts editing existing message
   */
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

  /*
   * Edits message with optimistic UI update
   */
  Future<void> editMessage() async {
    final messageId = editingMessageId.value;
    if (messageId == null) return;

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final oldMessage = messages[index];
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
    }, (_) {});
  }

  //* ===========================================================================
  //* MESSAGE REPLY
  //* ===========================================================================
  void replyToMessage(ChatsEntity message) {
    replyMessage.value = message;
    messageFocusNode.requestFocus();
  }

  void cancelReply() {
    replyMessage.value = null;
  }

  //* ===========================================================================
  //* MESSAGE SELECTION MODE
  //* ===========================================================================
  final RxList<String> selectedMessages = <String>[].obs;

  /*
   * Toggle message selection for bulk operations
   */
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
    clearSelection();
  }

  /*
   * Copy selected messages to clipboard
   */
  void copySelectedMessages() {
    final selectedText = messages
        .where((m) => selectedMessages.contains(m.id))
        .map((m) => m.text)
        .join('\n');
    Clipboard.setData(ClipboardData(text: selectedText));
    clearSelection();
  }

  //* ===========================================================================
  //* MEDIA MESSAGING
  //* ===========================================================================
  /*
   * Media picker methods
   */
  Future<Map<String, dynamic>?> takePhoto() async {
    final file = await MediaPicker.instance.pickImageFromCamera();
    if (file != null) {
      return {'file': file, 'type': MessageType.image};
    }
    return null;
  }

  Future<Map<String, dynamic>?> pickImageFromGallery() async {
    final file = await MediaPicker.instance.pickImageFromGallery();
    if (file != null) {
      log.d(file.path);
      return {'file': file, 'type': MessageType.image};
    }
    return null;
  }

  Future<Map<String, dynamic>?> pickDocument() async {
    final file = await MediaPicker.instance.pickDocument();
    if (file != null) {
      return {'file': file, 'type': MessageType.document};
    }
    return null;
  }

  Future<Map<String, dynamic>?> pickVideoFromGallery() async {
    final file = await MediaPicker.instance.pickVideoFromGallery();
    if (file != null) {
      log.d(file.path);
      return {'file': file, 'type': MessageType.video};
    }
    return null;
  }

  Future<Map<String, dynamic>?> pickVideoFromCamera() async {
    final file = await MediaPicker.instance.pickVideoFromCamera();
    if (file != null) {
      log.d(file.path);
      return {'file': file, 'type': MessageType.video};
    }
    return null;
  }

  /*
   * Sends media message (image/document) with Cloudinary upload
   */
  Future<void> sendMediaMessage(
    File file,
    String caption,
    MessageType type,
  ) async {
    await _sendMediaMessage(file, caption, type);
  }

  Future<void> _sendMediaMessage(
    File file,
    String caption,
    MessageType type,
  ) async {
    final currentUserId = authUsecase.currentUid;
    final currentUser = fs.currentUser;

    if (currentUserId == null || currentUser == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    try {
      log.d("Uploading media...");
      final mediaUrl = await CloudinaryUtils.uploadFile(
        file: file,
        isVideo: type == MessageType.video,
      );
      if (mediaUrl == null) return;
      log.d(mediaUrl);
      log.d("Media uploaded successfully");

      log.d("Sending message...");
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final replyTo = replyMessage.value;

      final message = ChatsEntity(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        receiverId: contact.id,
        senderName: authStateNotifier.user?.displayName ?? 'Unknown',
        senderPhotoUrl:
            authStateNotifier.user?.photoUrl ?? currentUser.photoURL,
        receiverName: contact.name,
        text: caption,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        readBy: const [],
        status: MessageStatus.sending,
        replyToMessageId: replyTo?.id,
        replyToSenderName: replyTo?.senderName,
        replyToText: replyTo?.text,
        replyToType: replyTo?.type,
        replyToMediaUrl: replyTo?.mediaUrl,
        mediaUrl: mediaUrl,
        mediaSize: await file.length(),
      );

      cancelReply();
      messages.add(message);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

      final result = await chatsRepository.sendMessage(message);
      result.fold(
        (failure) {
          messages.remove(message);
          errorMessage.value = 'Failed to send message';
        },
        (_) {
          log.d("Message sent successfully");
        },
      );
    } catch (e) {
      log.e(e);
    }
  }

  //* ===========================================================================
  //* UTILITY METHODS
  //* ===========================================================================
  Future<void> refreshMessages() async {
    await _bindMessagesStream();
  }

  Future<void> retryLoading() async {
    await _bindMessagesStream();
  }

  void searchMessages(String query) {}

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> scrollToMessage(String messageId) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      await scrollController.scrollToIndex(
        index,
        preferPosition: AutoScrollPosition.middle,
        duration: const Duration(milliseconds: 500),
      );

      highlightedMessageId.value = messageId;
      Future.delayed(const Duration(seconds: 3), () {
        highlightedMessageId.value = '';
      });
    } else {
      // Message not found in current list, could ideally load more messages or show info
      // Get.snackbar(
      //   "Message not found",
      //   "The message might be too old or deleted",
      // );
    }
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.hasClients) {
        // Check if scrolled to top (older messages)
        if (scrollController.position.pixels <= 100 && !isLoadingMore.value) {
          _loadMoreMessages();
        }
      }
    });
  }

  void _loadMoreMessages() {
    // Check if we have more messages to load by comparing current count with limit
    // Note: This is an estimation. If we have fewer messages than limit, we reached end.
    if (messages.length < messageLimit.value) return;

    isLoadingMore.value = true;
    messageLimit.value += 20;
    _bindMessagesStream();
  }

  /*
   * Generates deterministic chat ID from sorted user IDs
   */
  String _generateChatId() {
    final currentUserId = Get.find<AuthUsecase>().currentUid;
    if (currentUserId == null) return '';

    final sortedIds = [currentUserId, contact.id]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  //* ===========================================================================
  //* CHAT MANAGEMENT
  //* ===========================================================================
  void toggleMuteNotifications() {
    isMuted.value = !isMuted.value;
  }

  void blockUser() async {}

  void clearChat() async {}

  /*
   * Shares current location as a Google Maps link
   */
  Future<void> shareLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final locationUrl =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

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
        senderPhotoUrl:
            authStateNotifier.user?.photoUrl ?? currentUser.photoURL,
        receiverName: contact.name,
        text: locationUrl,
        type: MessageType.location,
        timestamp: DateTime.now(),
        isRead: false,
        readBy: const [],
        status: MessageStatus.sending,
        replyToMessageId: replyTo?.id,
        replyToSenderName: replyTo?.senderName,
        replyToText: replyTo?.text,
        replyToType: replyTo?.type,
        replyToMediaUrl: replyTo?.mediaUrl,
      );

      // Clear reply state
      cancelReply();

      // Optimistic update
      messages.add(message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

      final result = await chatsRepository.sendMessage(message);
      result.fold(
        (failure) {
          messages.remove(message);
          errorMessage.value = 'Failed to send location';
        },
        (_) {
          // Success
        },
      );
    } catch (e) {
      errorMessage.value = 'Error getting location: $e';
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage.value = 'Location services are disabled.';
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        errorMessage.value = 'Location permissions are denied';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage.value =
          'Location permissions are permanently denied, we cannot request permissions.';
      return false;
    }

    return true;
  }

  //* ===========================================================================
  //* LIFECYCLE CLEANUP
  //* ===========================================================================

  void onChatPaused() {
    _typingTimer?.cancel();
    _sendTypingStatus(false);
  }

  @override
  void onClose() {
    onChatPaused();

    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _unreadCountSubscription?.cancel();

    messageController.dispose();
    messageFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
