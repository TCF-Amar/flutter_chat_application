import 'dart:async';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/domain/usecases/chats_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final AuthUsecase authUsecase = Get.find();
  final ChatsUsecase chatsUsecase = Get.find();
  final RxString uid = "".obs;
  final Rxn<UserEntity?> _user = Rxn<UserEntity?>();
  UserEntity? get user => _user.value;
  final Rxn<UserEntity?> _currentUser = Rxn<UserEntity?>();
  UserEntity? get currentUser => _currentUser.value;
  Rx<List<ChatsEntity>> messages = Rx<List<ChatsEntity>>([]);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchCurrentUser();
    ever(uid, (id) async {
      await getUserById(id);
      _bindMessagesStream();
      _bindTypingStream();
    });
    messageController.addListener(_onTextChanged);
  }

  Timer? _typingTimer;
  final RxBool isOtherUserTyping = false.obs;

  void _onTextChanged() {
    if (_typingTimer?.isActive ?? false) _typingTimer?.cancel();
    _sendTypingStatus(true);
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _sendTypingStatus(false);
    });
  }

  void _sendTypingStatus(bool isTyping) {
    final senderId = authUsecase.currentUid;
    final receiverId = uid.value;
    if (senderId != null && receiverId.isNotEmpty) {
      final chatId = getChatId(senderId, receiverId);
      chatsUsecase.sendTypingStatus(
        chatId: chatId,
        userId: senderId,
        isTyping: isTyping,
      );
    }
  }

  void _bindTypingStream() {
    final senderId = authUsecase.currentUid;
    final receiverId = uid.value;
    if (senderId != null && receiverId.isNotEmpty) {
      final chatId = getChatId(senderId, receiverId);
      chatsUsecase.getTypingUsersStream(chatId).listen((typingUsers) {
        isOtherUserTyping.value = typingUsers.contains(receiverId);
      });
    }
  }

  void _bindMessagesStream() {
    final senderId = authUsecase.currentUid;
    final receiverId = uid.value;
    if (senderId != null && receiverId.isNotEmpty) {
      messages.value = [];
      isLoading.value = true;
      final chatId = getChatId(senderId, receiverId);
      messages.bindStream(
        chatsUsecase.getMessages(chatId).map((data) {
          isLoading.value = false;
          return data;
        }),
      );
    }
  }

  Future<void> _fetchCurrentUser() async {
    final currentUid = authUsecase.currentUid;
    if (currentUid != null) {
      final result = await authUsecase.getUser(currentUid);
      result.fold(
        (failure) => null, // Handle error silently or log
        (user) => _currentUser.value = user,
      );
    }
  }

  Future<void> getUserById(String uid) async {
    final result = await authUsecase.getUser(uid);
    result.fold(
      (failure) async {
        _user.value = null;
      },
      (user) {
        _user.value = user;
      },
    );
  }

  final TextEditingController messageController = TextEditingController();

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final senderId = authUsecase.currentUid;
    if (senderId == null) {
      return;
    }

    final receiverId = uid.value;
    final chatId = getChatId(senderId, receiverId);
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final message = ChatsEntity(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      senderName: currentUser?.displayName ?? "Unknown",
      senderPhotoUrl: currentUser?.photoUrl,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: const [],
      mediaUrl: "",
      mediaSize: 0,
    );

    final result = await chatsUsecase.sendMessage(message);
    result.fold((failure) {}, (_) {
      messageController.clear();
    });
  }

  String getChatId(String id1, String id2) {
    if (id1.compareTo(id2) > 0) {
      return "${id1}_$id2";
    } else {
      return "${id2}_$id1";
    }
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}
