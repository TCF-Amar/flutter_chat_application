import 'dart:async';

import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:chat_kare/features/chat/domain/usecases/chats_usecase.dart';
import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController {
  //* ==============================================================================
  //* DEPENDENCIES
  //* ==============================================================================
  final ChatsUsecase chatsUsecase;
  final AuthUsecase authUseCase;
  final AuthStateNotifier authStateNotifier;

  ChatListController({
    required this.chatsUsecase,
    required this.authUseCase,
    required this.authStateNotifier,
  });

  //* ==============================================================================
  //* STATE VARIABLES
  //* ==============================================================================
  final RxList<ChatMetaData> chats = <ChatMetaData>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<UserEntity> currentUser = Rxn<UserEntity>();

  //* ==============================================================================
  //* PRIVATE VARIABLES
  //* ==============================================================================
  StreamSubscription? _chatsSubscription;

  //* ==============================================================================
  //* LIFECYCLE METHODS
  //* ==============================================================================
  @override
  void onInit() {
    super.onInit();
    authStateNotifier.addListener(_handleAuthStateChange);
    if (authStateNotifier.isAuthenticated) {
      _fetchCurrentUserAndChats();
    }
  }

  @override
  void onClose() {
    authStateNotifier.removeListener(_handleAuthStateChange);
    _chatsSubscription?.cancel();
    super.onClose();
  }

  //* ==============================================================================
  //* AUTH STATE HANDLING
  //* ==============================================================================
  void _handleAuthStateChange() {
    if (authStateNotifier.isAuthenticated) {
      _fetchCurrentUserAndChats();
    } else {
      chats.clear();
      currentUser.value = null;
      _chatsSubscription?.cancel();
    }
  }

  //* ==============================================================================
  //* DATA FETCHING
  //* ==============================================================================
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
            //* Handle stream error
          },
        );
  }

  //* ==============================================================================
  //* USER DETAILS FETCHING
  //* ==============================================================================

  /// Fetch full user details from Firestore
  Future<UserEntity?> getUserDetails(String userId) async {
    try {
      final userResult = await authUseCase.getUser(userId);
      return userResult.fold((failure) {
        // Log error but don't throw
        return null;
      }, (user) => user);
    } catch (e) {
      return null;
    }
  }

  /// Check if a user is in the current user's contact list
  Future<bool> isUserInContacts(String userId) async {
    try {
      // Try to get ContactsController if it's registered
      if (Get.isRegistered<ContactsController>()) {
        final contactsController = Get.find<ContactsController>();
        final contact = contactsController.getContactByUid(userId);
        return contact != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  //* Helper to convert ChatMetaData to UserEntity for navigation (deprecated)
  @Deprecated('Use getUserDetails() instead to fetch full user data')
  UserEntity getContactFromChat(ChatMetaData chat) {
    return UserEntity(
      uid: chat.receiverId,
      email: '',
      displayName: chat.receiverName,
      photoUrl: chat.receiverPhotoUrl,
      isProfileCompleted: true,
    );
  }
}
