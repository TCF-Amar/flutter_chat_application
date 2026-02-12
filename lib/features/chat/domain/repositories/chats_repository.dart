import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';

abstract class ChatsRepository {
  Future<Result<void>> sendMessage(ChatsEntity message);

  Stream<List<ChatsEntity>> getMessagesStream(String chatId, {int limit = 20});

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
  Future<Result<bool>> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  });

  Stream<List<ChatMetaData>> getChatsStream(String userId);

  Future<Result<void>> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String userId,
  });

  Future<Result<void>> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  });

}
