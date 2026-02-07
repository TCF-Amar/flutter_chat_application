import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/chat/data/repositories/chats_repository_impl.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';

class ChatsUsecase {
  final ChatsRepositoryImpl chatsRepository;

  ChatsUsecase({required this.chatsRepository});

  Future<Result<void>> sendMessage(ChatsEntity message) async {
    return await chatsRepository.sendMessage(message);
  }

  Stream<List<ChatsEntity>> getMessages(String chatId) {
    return chatsRepository.getMessages(chatId);
  }

  Stream<List<String>> getTypingUsersStream(String chatId) {
    return chatsRepository.getTypingUsersStream(chatId);
  }

  Future<void> sendTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    return await chatsRepository.sendTypingStatus(
      chatId: chatId,
      userId: userId,
      isTyping: isTyping,
    );
  }
}
