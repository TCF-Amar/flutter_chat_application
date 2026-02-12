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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// Controller responsible for managing all chat-related operations and state.
///
/// This controller handles:
/// - Real-time message streaming via Firestore
/// - Sending and receiving messages (text, image, video, document, location)
/// - Typing indicators with debouncing
/// - Read receipts and unread counts
/// - Message editing, deletion (for me / for everyone)
/// - Reply feature and swipe-to-reply gesture handling
/// - Multi-select mode for bulk operations
/// - Media upload to Cloudinary with progress tracking and cancellation
/// - Location sharing with permission handling
/// - Auto-scrolling to new messages or specific messages
/// - Pagination (load more messages on scroll to top)
///
/// The controller is designed to be used with GetX for dependency injection
/// and reactive state management. It observes streams from the [ChatsRepository]
/// and updates the reactive lists accordingly.
class ChatController extends GetxController {
  //? Logger
  final Logger log = Logger();

  //* ===========================================================================
  //* DEPENDENCIES & SERVICES
  //* ===========================================================================

  /// The other user entity this chat is with.
  final UserEntity contact;

  /// Repository for chat operations (Firestore).
  final ChatsRepository chatsRepository;

  /// Service for handling push notifications.
  final NotificationServices notificationService;

  /// Use case for authentication-related operations.
  final AuthUsecase authUsecase;

  /// Notifier for the current authenticated user's state.
  final AuthStateNotifier authStateNotifier;

  /// Firebase services instance (provides current user and auth).
  final FirebaseServices fs = Get.find();

  ChatController({required this.contact, required this.authStateNotifier})
    : chatsRepository = Get.find(),
      notificationService = Get.find(),
      authUsecase = Get.find();

  //* ===========================================================================
  //* REACTIVE STATE (Observable variables for UI)
  //* ===========================================================================

  /// List of all messages in this chat, sorted chronologically.
  final RxList<ChatsEntity> messages = <ChatsEntity>[].obs;

  /// Indicates whether the initial messages are loading.
  final RxBool isLoading = false.obs;

  /// Indicates whether the other user is currently typing.
  final RxBool isOtherUserTyping = false.obs;

  /// Holds any error message to be displayed to the user.
  final RxString errorMessage = ''.obs;

  //* Pagination ----------------------------------------------------------------

  /// Number of messages to fetch per query. Increases as user loads more.
  final RxInt messageLimit = 20.obs;

  /// Indicates whether more messages are being loaded (for pagination).
  final RxBool isLoadingMore = false.obs;

  //* Chat settings -------------------------------------------------------------

  /// Whether notifications for this chat are muted.
  final RxBool isMuted = false.obs;

  //* Upload state --------------------------------------------------------------

  /// Tracks upload progress per message ID (values 0.0 to 1.0).
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;

  /// Cancellation flags for ongoing uploads. Set to true to abort upload.
  final RxMap<String, bool> uploadCancellations = <String, bool>{}.obs;

  //* ===========================================================================
  //* UI CONTROLLERS (Text editing, focus, scrolling)
  //* ===========================================================================

  /// Controller for the message input field.
  final TextEditingController messageController = TextEditingController();

  /// Focus node for the message input field.
  final FocusNode messageFocusNode = FocusNode();

  /// Controller for the scrollable message list (with index-based scrolling).
  final AutoScrollController scrollController = AutoScrollController();

  /// ID of the currently highlighted message (e.g., after replying or jumping).
  final RxString highlightedMessageId = ''.obs;

  //* ===========================================================================
  //* STREAM SUBSCRIPTIONS & TIMERS
  //* ===========================================================================

  Timer? _typingTimer; // Debounce timer for sending typing status.
  StreamSubscription<List<ChatsEntity>>? _messagesSubscription;
  StreamSubscription<List<String>>? _typingSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  //* ===========================================================================
  //* UTILITY GETTERS
  //* ===========================================================================

  /// Generates a deterministic chat ID based on the two user IDs (sorted).
  String get chatId => _generateChatId();

  //* ===========================================================================
  //* LIFECYCLE METHODS
  //* ===========================================================================

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
  }

  /// Initializes all real-time streams for this chat.
  ///
  /// Must be called after the controller is created. Subscribes to:
  /// - Messages stream
  /// - Typing indicator stream
  /// - Unread count stream (optional)
  Future<void> initializeChat() async {
    await _bindMessagesStream();
    await _bindTypingStream();
    await _bindUnreadCountStream();
  }

  //* ===========================================================================
  //* MESSAGES STREAM MANAGEMENT
  //* ===========================================================================

  /// Binds to the real-time messages stream from Firestore.
  ///
  /// Fetches messages with the current [messageLimit] and listens for updates.
  /// Cancels any previous subscription to avoid memory leaks.
  Future<void> _bindMessagesStream() async {
    if (messages.isEmpty) isLoading.value = true;
    _messagesSubscription?.cancel();
    _messagesSubscription = chatsRepository
        .getMessagesStream(chatId, limit: messageLimit.value)
        .listen(_onMessagesUpdated, onError: _onMessagesError);
  }

  /// Callback for new message batches from the stream.
  ///
  /// - Filters out messages deleted by the current user.
  /// - Sorts messages by timestamp.
  /// - Updates the reactive [messages] list.
  /// - Manages loading states and triggers auto-scroll if appropriate.
  ///
  /// [newMessages] is the latest batch from the repository.
  void _onMessagesUpdated(List<ChatsEntity> newMessages) {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId != null) {
      // Remove messages that the current user has deleted for themselves.
      newMessages.removeWhere((m) => m.deletedBy.contains(currentUserId));
    }
    newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final bool isInitialLoad = isLoading.value;
    final bool wasLoadingMore = isLoadingMore.value;

    messages.assignAll(newMessages);
    isLoading.value = false;
    isLoadingMore.value = false;
    errorMessage.value = '';

    // Auto-scroll to bottom on initial load or when a new message is sent.
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

  /// Handles errors from the messages stream.
  void _onMessagesError(dynamic error) {
    errorMessage.value = 'Failed to load messages: $error';
    isLoading.value = false;
  }

  //* ===========================================================================
  //* TYPING INDICATOR
  //* ===========================================================================

  /// Binds to the real-time stream of users currently typing in this chat.
  Future<void> _bindTypingStream() async {
    _typingSubscription?.cancel();
    _typingSubscription = chatsRepository.getTypingUsersStream(chatId).listen((
      typingUsers,
    ) {
      // Update UI if the other user is typing.
      isOtherUserTyping.value = typingUsers.contains(contact.uid);
    });
  }

  /// Indicates whether the current user has typed any non-empty text.
  final RxBool hasText = false.obs;

  /// Called whenever the text input changes.
  ///
  /// Updates [hasText] and manages the typing indicator:
  /// - Sends `typing = true` immediately.
  /// - Cancels any pending timer.
  /// - Starts a 2‑second timer to send `typing = false` after the user stops.
  ///
  /// [value] is the current text in the input field.
  void onTextChanged(String value) {
    hasText.value = value.trim().isNotEmpty;

    // Cancel previous timer to avoid premature "stop typing".
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

  /// Sends a typing status update to the repository.
  ///
  /// [isTyping] true indicates the user started typing, false when stopped.
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

  /// Subscribes to the unread message count stream for this chat.
  ///
  /// Currently only updates the internal state; UI integration is optional.
  Future<void> _bindUnreadCountStream() async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId != null) {
      _unreadCountSubscription?.cancel();
      _unreadCountSubscription = chatsRepository
          .getUnreadCountStream(chatId, currentUserId)
          .listen((count) {
            // Can be used to update badge or mark as read.
          });
    }
  }

  /// Marks a single message as read by the current user.
  ///
  /// [messageId] ID of the message to mark.
  Future<void> markMessageAsRead(String messageId) async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId == null) return;

    await chatsRepository.markMessageAsRead(
      chatId: chatId,
      messageId: messageId,
      userId: currentUserId,
    );
  }

  /// Marks all messages in this chat as read for the current user.
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

  /// ID of the message currently being edited, or null if not editing.
  final Rx<String?> editingMessageId = Rx<String?>(null);

  /// Message that is being replied to, or null if no reply is pending.
  final Rx<ChatsEntity?> replyMessage = Rx<ChatsEntity?>(null);

  /// Sends a text message, or saves changes if currently editing.
  ///
  /// Performs optimistic UI update:
  /// - Clears the input field immediately.
  /// - Adds a placeholder message with [MessageStatus.sending].
  /// - Calls repository to actually send.
  /// - On success, status is updated by the real-time stream.
  /// - On failure, the optimistic message is removed.
  Future<void> sendMessage() async {
    // If we are in editing mode, redirect to edit.
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

    // Construct the optimistic message.
    final message = ChatsEntity(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: contact.uid,
      senderName: authStateNotifier.user?.displayName ?? 'Unknown',
      senderPhotoUrl: authStateNotifier.user?.photoUrl ?? currentUser.photoURL,
      receiverName: contact.displayName.toString(),
      receiverPhotoUrl: contact.photoUrl,
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

    // Clear reply state immediately.
    cancelReply();

    // Add optimistic message to UI.
    messages.add(message);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    final result = await chatsRepository.sendMessage(message);
    result.fold((failure) {
      // Remove the optimistic message on failure.
      messages.remove(message);
      errorMessage.value = 'Failed to send message';
    }, (_) => messageFocusNode.requestFocus());
  }

  //* ===========================================================================
  //* MESSAGE EDITING
  //* ===========================================================================

  /// Enters editing mode for the given message.
  ///
  /// Populates the text field with the current message text and gives focus.
  ///
  /// [message] The message to edit.
  void startEditing(ChatsEntity message) {
    editingMessageId.value = message.id;
    messageController.text = message.text;
    messageFocusNode.requestFocus();
  }

  /// Cancels editing mode and clears the input field.
  void cancelEditing() {
    editingMessageId.value = null;
    messageController.clear();
    messageFocusNode.unfocus();
  }

  /// Saves the edited message content.
  ///
  /// Performs optimistic UI update: replaces the original message with a copy
  /// that has [isEdited] = true. If the text hasn't changed, simply cancels.
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

      // Optimistic update: mark as edited.
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
      // Revert optimistic update? Reload stream?
    }, (_) {});
  }

  //* ===========================================================================
  //* MESSAGE REPLY
  //* ===========================================================================

  /// Sets the message to be replied to and focuses the input field.
  ///
  /// [message] The original message being replied to.
  void replyToMessage(ChatsEntity message) {
    replyMessage.value = message;
    messageFocusNode.requestFocus();
  }

  /// Clears the current reply state.
  void cancelReply() {
    replyMessage.value = null;
  }

  //* ===========================================================================
  //* MESSAGE SELECTION MODE (for multi-select actions)
  //* ===========================================================================

  /// List of message IDs currently selected by the user.
  final RxList<String> selectedMessages = <String>[].obs;

  /// Toggles selection of a message.
  ///
  /// If the message is already selected, it is removed; otherwise added.
  ///
  /// [messageId] The ID of the message.
  void toggleMessageSelection(String messageId) {
    if (selectedMessages.contains(messageId)) {
      selectedMessages.remove(messageId);
    } else {
      selectedMessages.add(messageId);
    }
  }

  /// Clears all selected messages.
  void clearSelection() {
    selectedMessages.clear();
  }

  /// Deletes all selected messages **for the current user only**.
  ///
  /// Calls [deleteMessageForMe] on each selected message, then clears selection.
  void deleteSelectedMessagesForMe() {
    final selectedIds = List<String>.from(selectedMessages);
    for (final id in selectedIds) {
      final message = messages.firstWhereOrNull((m) => m.id == id);
      if (message != null) {
        deleteMessageForMe(message);
      }
    }
    clearSelection();
  }

  /// Deletes all selected messages **for everyone**.
  ///
  /// Calls [deleteMessageForEveryone] on each selected message, then clears selection.
  void deleteSelectedMessagesForEveryone() {
    final selectedIds = List<String>.from(selectedMessages);
    for (final id in selectedIds) {
      final message = messages.firstWhereOrNull((m) => m.id == id);
      if (message != null) {
        deleteMessageForEveryone(message);
      }
    }
    clearSelection();
  }

  /// Deletes a single message for the current user only.
  ///
  /// Optimistically removes the message from the list.
  /// On failure, attempts to reload the stream to restore state.
  ///
  /// [message] The message entity to delete.
  Future<void> deleteMessageForMe(ChatsEntity message) async {
    final currentUserId = authUsecase.currentUid;
    if (currentUserId == null) return;

    // Optimistic removal.
    messages.removeWhere((m) => m.id == message.id);

    final result = await chatsRepository.deleteMessageForMe(
      chatId: chatId,
      messageId: message.id,
      userId: currentUserId,
    );

    result.fold((failure) {
      errorMessage.value = 'Failed to delete message for me';
      _bindMessagesStream(); // Reload to restore.
    }, (_) {});
  }

  /// Deletes a single message for everyone.
  ///
  /// Optimistically marks the message as deleted ([isDeletedForEveryone] = true).
  /// On failure, reloads the stream.
  ///
  /// [message] The message entity to delete.
  Future<void> deleteMessageForEveryone(ChatsEntity message) async {
    // Optimistic update: replace with a placeholder.
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = ChatsEntity(
        id: message.id,
        chatId: message.chatId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        senderName: message.senderName,
        receiverName: message.receiverName,
        senderPhotoUrl: message.senderPhotoUrl,
        text: '',
        type: message.type,
        timestamp: message.timestamp,
        isRead: message.isRead,
        readBy: message.readBy,
        status: message.status,
        isEdited: message.isEdited,
        isDeletedForEveryone: true,
      );
    }

    final result = await chatsRepository.deleteMessageForEveryone(
      chatId: chatId,
      messageId: message.id,
    );

    result.fold((failure) {
      errorMessage.value = 'Failed to delete message for everyone';
      _bindMessagesStream();
    }, (_) {});
  }

  /// Copies the text of all selected messages to the clipboard.
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

  // Media picker methods ------------------------------------------------------

  /// Opens the camera to take a photo.
  ///
  /// Returns a map containing the file, its type, and a callback to send it.
  /// The callback accepts an optional caption.
  Future<Map<String, dynamic>?> takePhoto() async {
    final file = await MediaPicker.instance.pickImageFromCamera();
    if (file != null) {
      File? imageFile = file;
      final context = Get.context;
      if (context != null && context.mounted) {
        final edited = await MediaPicker.instance.editImage(context, file);
        if (edited != null) {
          imageFile = edited;
        }
      }

      return {
        'file': imageFile,
        'type': MessageType.image,
        'onSend': (String caption) =>
            sendMediaMessage(imageFile!, caption, MessageType.image),
      };
    }
    return null;
  }

  /// Opens the gallery to pick an image.
  ///
  /// Returns a map with the file, type, and send callback.
  Future<Map<String, dynamic>?> pickImageFromGallery() async {
    final file = await MediaPicker.instance.pickImageFromGallery();
    if (file != null) {
      log.d(file.path);

      File? imageFile = file;
      final context = Get.context;
      if (context != null && context.mounted) {
        final edited = await MediaPicker.instance.editImage(context, file);
        if (edited != null) {
          imageFile = edited;
        }
      }

      return {
        'file': imageFile,
        'type': MessageType.image,
        'onSend': (String caption) =>
            sendMediaMessage(imageFile!, caption, MessageType.image),
      };
    }
    return null;
  }

  /// Opens the system file picker to select a document.
  ///
  /// Returns a map with the file, type ([MessageType.document]), and send callback.
  Future<Map<String, dynamic>?> pickDocument() async {
    final file = await MediaPicker.instance.pickDocument();
    if (file != null) {
      return {
        'file': file,
        'type': MessageType.document,
        'onSend': (String caption) =>
            sendMediaMessage(file, caption, MessageType.document),
      };
    }
    return null;
  }

  /// Opens the gallery to pick a video.
  ///
  /// Returns a map with the file, type ([MessageType.video]), and send callback.
  Future<Map<String, dynamic>?> pickVideoFromGallery() async {
    final file = await MediaPicker.instance.pickVideoFromGallery();
    if (file != null) {
      log.d(file.path);
      return {
        'file': file,
        'type': MessageType.video,
        'onSend': (String caption) =>
            sendMediaMessage(file, caption, MessageType.video),
      };
    }
    return null;
  }

  /// Opens the camera to record a video.
  ///
  /// Returns a map with the file, type ([MessageType.video]), and send callback.
  Future<Map<String, dynamic>?> pickVideoFromCamera() async {
    final file = await MediaPicker.instance.pickVideoFromCamera();
    if (file != null) {
      log.d(file.path);
      return {
        'file': file,
        'type': MessageType.video,
        'onSend': (String caption) =>
            sendMediaMessage(file, caption, MessageType.video),
      };
    }
    return null;
  }

  // Sending media messages ----------------------------------------------------

  /// Public entry point to send a media message.
  ///
  /// Delegates to the private async implementation.
  Future<void> sendMediaMessage(
    File file,
    String caption,
    MessageType type,
  ) async {
    await _sendMediaMessage(file, caption, type);
  }

  /// Internal asynchronous method that handles the entire media sending flow.
  ///
  /// Steps:
  /// 1. Optimistically add a placeholder message with [MessageStatus.uploading].
  /// 2. Upload file to Cloudinary with progress tracking.
  /// 3. On cancellation: remove the message and abort.
  /// 4. On upload success: update message with media URL and change status to [MessageStatus.sending].
  /// 5. On upload failure: mark message as [MessageStatus.failed] with error details.
  /// 6. Finally, send the message entity via repository.
  ///
  /// [file] The local file to upload.
  /// [caption] Optional text caption.
  /// [type] Type of media (image, video, document).
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

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final replyTo = replyMessage.value;

    // Optimistic message (uploading state, with local file path for preview).
    final message = ChatsEntity(
      id: messageId,
      chatId: chatId,
      senderId: currentUserId,
      receiverId: contact.uid,
      senderName: authStateNotifier.user?.displayName ?? 'Unknown',
      senderPhotoUrl: authStateNotifier.user?.photoUrl ?? currentUser.photoURL,
      receiverName: contact.displayName.toString(),
      receiverPhotoUrl: contact.photoUrl,
      text: caption,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: const [],
      status: MessageStatus.uploading,
      replyToMessageId: replyTo?.id,
      replyToSenderName: replyTo?.senderName,
      replyToText: replyTo?.text,
      replyToType: replyTo?.type,
      replyToMediaUrl: replyTo?.mediaUrl,
      localFilePath: file.path, // Used for preview and retry.
      uploadProgress: 0.0,
    );

    cancelReply();
    messages.add(message);
    uploadProgress[messageId] = 0.0;
    uploadCancellations[messageId] = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    try {
      log.d("Uploading media...");

      // Upload to Cloudinary with progress callback.
      final uploadResult = await CloudinaryUtils.uploadFile(
        file: file,
        isVideo: type == MessageType.video,
        onProgress: (progress) {
          // Check if user cancelled the upload.
          if (uploadCancellations[messageId] == true) {
            return;
          }
          uploadProgress[messageId] = progress;

          // Update the optimistic message with current progress.
          final index = messages.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            messages[index] = ChatsEntity(
              id: message.id,
              chatId: message.chatId,
              senderId: message.senderId,
              receiverId: message.receiverId,
              senderName: message.senderName,
              receiverName: message.receiverName,
              senderPhotoUrl: message.senderPhotoUrl,
              receiverPhotoUrl: message.receiverPhotoUrl,
              text: message.text,
              type: message.type,
              timestamp: message.timestamp,
              isRead: message.isRead,
              readBy: message.readBy,
              status: MessageStatus.uploading,
              replyToMessageId: message.replyToMessageId,
              replyToSenderName: message.replyToSenderName,
              replyToText: message.replyToText,
              replyToType: message.replyToType,
              replyToMediaUrl: message.replyToMediaUrl,
              localFilePath: message.localFilePath,
              uploadProgress: progress,
            );
          }
        },
      );

      // Handle cancellation.
      if (uploadCancellations[messageId] == true) {
        log.d("Upload cancelled by user");
        messages.removeWhere((m) => m.id == messageId);
        uploadProgress.remove(messageId);
        uploadCancellations.remove(messageId);
        return;
      }

      // Upload failed.
      if (uploadResult['success'] != true) {
        final errorMsg = uploadResult['error'] ?? 'Unknown error';
        log.e("Upload failed: $errorMsg");

        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = ChatsEntity(
            id: message.id,
            chatId: message.chatId,
            senderId: message.senderId,
            receiverId: message.receiverId,
            senderName: message.senderName,
            receiverName: message.receiverName,
            senderPhotoUrl: message.senderPhotoUrl,
            receiverPhotoUrl: message.receiverPhotoUrl,
            text: message.text,
            type: message.type,
            timestamp: message.timestamp,
            isRead: message.isRead,
            readBy: message.readBy,
            status: MessageStatus.failed,
            replyToMessageId: message.replyToMessageId,
            replyToSenderName: message.replyToSenderName,
            replyToText: message.replyToText,
            replyToType: message.replyToType,
            replyToMediaUrl: message.replyToMediaUrl,
            localFilePath: message.localFilePath,
            uploadError: errorMsg,
          );
        }
        uploadProgress.remove(messageId);
        return;
      }

      // Upload succeeded.
      final mediaUrl = uploadResult['url'];
      log.d(mediaUrl);
      log.d("Media uploaded successfully");

      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = ChatsEntity(
          id: message.id,
          chatId: message.chatId,
          senderId: message.senderId,
          receiverId: message.receiverId,
          senderName: message.senderName,
          receiverName: message.receiverName,
          senderPhotoUrl: message.senderPhotoUrl,
          receiverPhotoUrl: message.receiverPhotoUrl,
          text: message.text,
          type: message.type,
          timestamp: message.timestamp,
          isRead: message.isRead,
          readBy: message.readBy,
          status: MessageStatus.sending,
          replyToMessageId: message.replyToMessageId,
          replyToSenderName: message.replyToSenderName,
          replyToText: message.replyToText,
          replyToType: message.replyToType,
          replyToMediaUrl: message.replyToMediaUrl,
          mediaUrl: mediaUrl,
          mediaSize: await file.length(),
        );
      }

      uploadProgress.remove(messageId);

      log.d("Sending message...");
      final result = await chatsRepository.sendMessage(messages[index]);
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
      // Mark as failed on exception.
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = ChatsEntity(
          id: message.id,
          chatId: message.chatId,
          senderId: message.senderId,
          receiverId: message.receiverId,
          senderName: message.senderName,
          receiverName: message.receiverName,
          senderPhotoUrl: message.senderPhotoUrl,
          receiverPhotoUrl: message.receiverPhotoUrl,
          text: message.text,
          type: message.type,
          timestamp: message.timestamp,
          isRead: message.isRead,
          readBy: message.readBy,
          status: MessageStatus.failed,
          replyToMessageId: message.replyToMessageId,
          replyToSenderName: message.replyToSenderName,
          replyToText: message.replyToText,
          replyToType: message.replyToType,
          replyToMediaUrl: message.replyToMediaUrl,
          localFilePath: message.localFilePath,
          uploadError: e.toString(),
        );
      }
      uploadProgress.remove(messageId);
    }
  }

  /// Retries a failed upload.
  ///
  /// Locates the failed message by [messageId], verifies that the local file
  /// still exists, removes the failed message, and restarts the upload.
  Future<void> retryUpload(String messageId) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = messages[index];
    if (message.localFilePath == null) {
      errorMessage.value = 'Cannot retry: local file not found';
      return;
    }

    final file = File(message.localFilePath!);
    if (!await file.exists()) {
      errorMessage.value = 'Cannot retry: local file no longer exists';
      return;
    }

    // Remove the failed message and resend.
    messages.removeAt(index);
    await _sendMediaMessage(file, message.text, message.type);
  }

  /// Cancels an ongoing upload.
  ///
  /// Sets the cancellation flag for the given [messageId], removes the
  /// optimistic message from the list, and cleans up progress tracking.
  void cancelUpload(String messageId) {
    uploadCancellations[messageId] = true;

    messages.removeWhere((m) => m.id == messageId);
    uploadProgress.remove(messageId);

    // Clean up the flag after a short delay to avoid interfering with retries.
    Future.delayed(const Duration(seconds: 2), () {
      uploadCancellations.remove(messageId);
    });
  }

  //* ===========================================================================
  //* UTILITY METHODS
  //* ===========================================================================

  /// Manually refreshes the messages stream.
  Future<void> refreshMessages() async {
    await _bindMessagesStream();
  }

  /// Alias for retry on stream error; rebinds the messages stream.
  Future<void> retryLoading() async {
    await _bindMessagesStream();
  }

  /// Placeholder for message search functionality.
  void searchMessages(String query) {
    // TODO: Implement search.
  }

  /// Smoothly scrolls the message list to the bottom.
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Scrolls to a specific message by its ID and highlights it temporarily.
  ///
  /// If the message is already loaded, scrolls to its index.
  /// Otherwise, does nothing (could be extended to load more messages).
  ///
  /// [messageId] The ID of the target message.
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
      // Optionally implement loading older messages until the target is found.
    }
  }

  /// Sets up a scroll listener to detect when the user reaches the top.
  ///
  /// When the scroll position is near the top (≤ 100 pixels) and not already
  /// loading more, triggers [_loadMoreMessages].
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.hasClients) {
        if (scrollController.position.pixels <= 100 && !isLoadingMore.value) {
          _loadMoreMessages();
        }
      }
    });
  }

  /// Increases the message limit and rebinds the stream to load older messages.
  ///
  /// This is an approximation: if we have fewer messages than the current limit,
  /// we assume there are no more to load.
  void _loadMoreMessages() {
    if (messages.length < messageLimit.value) return;

    isLoadingMore.value = true;
    messageLimit.value += 20;
    _bindMessagesStream();
  }

  /// Generates a deterministic and unique chat ID for a pair of users.
  ///
  /// The ID is constructed by sorting the two user IDs lexicographically and
  /// prefixing with `chat_`. This ensures the same ID regardless of order.
  String _generateChatId() {
    final currentUserId = Get.find<AuthUsecase>().currentUid;
    if (currentUserId == null) return '';

    final sortedIds = [currentUserId, contact.uid]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  //* ===========================================================================
  //* CHAT MANAGEMENT
  //* ===========================================================================

  /// Toggles mute state for this chat.
  ///
  /// Actual mute logic (e.g., Firestore update) should be implemented.
  void toggleMuteNotifications() {
    isMuted.value = !isMuted.value;
  }

  /// Placeholder for blocking the other user.
  void blockUser() async {}

  /// Placeholder for clearing the entire chat history.
  void clearChat() async {}

  /// Shares the user's current location as a Google Maps link.
  ///
  /// Steps:
  /// 1. Check and request location permissions.
  /// 2. Get current position via [Geolocator].
  /// 3. Construct a Google Maps URL.
  /// 4. Send as a text message with type [MessageType.location].
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
        receiverId: contact.uid,
        senderName: authStateNotifier.user?.displayName ?? 'Unknown',
        senderPhotoUrl:
            authStateNotifier.user?.photoUrl ?? currentUser.photoURL,
        receiverName: contact.displayName.toString(),
        receiverPhotoUrl: contact.photoUrl,
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

      cancelReply();
      messages.add(message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

      final result = await chatsRepository.sendMessage(message);
      result.fold((failure) {
        messages.remove(message);
        errorMessage.value = 'Failed to send location';
      }, (_) {});
    } catch (e) {
      errorMessage.value = 'Error getting location: $e';
    }
  }

  /// Checks and requests location permissions.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  /// Displays error messages via [errorMessage] on failure.
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

  /// Called when the chat screen is paused (e.g., user navigates away).
  ///
  /// Stops the typing indicator and cancels the debounce timer.
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
