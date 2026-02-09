import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';

abstract class ChatsRepository {
  Future<Result<void>> sendMessage(ChatsEntity message);

  Stream<List<ChatsEntity>> getMessagesStream(String chatId);

  Stream<List<String>> getTypingUsersStream(String chatId);

  Future<void> sendTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  });

  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String userId,
  });

  Future<void> markAllMessagesAsRead({
    required String chatId,
    required String userId,
  });

  Stream<int> getUnreadCountStream(String chatId, String userId);
}
