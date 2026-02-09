import 'dart:async';

import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:chat_kare/features/chat/domain/usecases/chats_usecase.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController {
  final ChatsUsecase chatsUsecase;
  final AuthUsecase authUseCase;
  final AuthStateNotifier authStateNotifier;

  ChatListController({
    required this.chatsUsecase,
    required this.authUseCase,
    required this.authStateNotifier,
  });

  final RxList<ChatMetaData> chats = <ChatMetaData>[].obs;
  final RxBool isLoading = false.obs;
  StreamSubscription? _chatsSubscription;
  final Rxn<UserEntity> currentUser = Rxn<UserEntity>();

  @override
  void onInit() {
    super.onInit();
    authStateNotifier.addListener(_handleAuthStateChange);
    if (authStateNotifier.isAuthenticated) {
      _fetchCurrentUserAndChats();
    }
  }

  void _handleAuthStateChange() {
    if (authStateNotifier.isAuthenticated) {
      _fetchCurrentUserAndChats();
    } else {
      chats.clear();
      currentUser.value = null;
      _chatsSubscription?.cancel();
    }
  }

  @override
  void onClose() {
    authStateNotifier.removeListener(_handleAuthStateChange);
    _chatsSubscription?.cancel();
    super.onClose();
  }

  Future<void> _fetchCurrentUserAndChats() async {
    isLoading.value = true;
    try {
      final uid = authUseCase.currentUid;
      if (uid != null) {
        _listenToChats(uid);

        final userResult = await authUseCase.getUser(uid);
        userResult.fold((l) => null, (r) => currentUser.value = r);
      } else {
        isLoading.value = false;
        chats.clear();
        currentUser.value = null;
      }
    } catch (e) {
      isLoading.value = false;
    }
  }

  void _listenToChats(String userId) {
    _chatsSubscription?.cancel();
    _chatsSubscription = chatsUsecase
        .getChatsStream(userId)
        .listen(
          (chatList) {
            chats.assignAll(chatList);
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            // Handle stream error
          },
        );
  }

  // Helper to convert ChatMetaData to ContactsEntity for navigation
  ContactsEntity getContactFromChat(ChatMetaData chat) {
    return ContactsEntity(
      id: chat.receiverId,
      name: chat.receiverName,
      phoneNumber: null,
      photoUrl: chat.receiverPhotoUrl,
    );
  }
}
