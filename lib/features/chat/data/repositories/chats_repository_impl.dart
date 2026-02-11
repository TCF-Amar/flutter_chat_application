import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/chat/data/datasources/chats_firebase_data_source.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:chat_kare/features/chat/data/models/chats_model.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:chat_kare/features/chat/domain/repositories/chats_repository.dart';

class ChatsRepositoryImpl implements ChatsRepository {
  ChatsRemoteDataSourceImpl chatFirebaseDataSource;

  ChatsRepositoryImpl({required this.chatFirebaseDataSource});

  @override
  Future<Result<void>> sendMessage(ChatsEntity message) async {
    try {
      await chatFirebaseDataSource.sendMessage(ChatsModel.fromEntity(message));
      return Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<ChatsEntity>> getMessagesStream(String chatId, {int limit = 20}) {
    return chatFirebaseDataSource.getMessages(chatId, limit).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Stream<List<String>> getTypingUsersStream(String chatId) {
    return chatFirebaseDataSource.getChatStream(chatId).map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      final data = snapshot.data()!;
      if (data.containsKey('typingUsers')) {
        return List<String>.from(data['typingUsers']);
      }
      return [];
    });
  }

  @override
  Future<void> sendTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await chatFirebaseDataSource.sendTypingStatus(
      chatId: chatId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  @override
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    await chatFirebaseDataSource.markMessageAsRead(
      chatId: chatId,
      messageId: messageId,
      userId: userId,
    );
  }

  @override
  Future<void> markAllMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    await chatFirebaseDataSource.markAllMessagesAsRead(
      chatId: chatId,
      userId: userId,
    );
  }

  @override
  Stream<int> getUnreadCountStream(String chatId, String userId) {
    return chatFirebaseDataSource.getUnreadCountStream(chatId, userId);
  }

  @override
  Future<Result<bool>> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    try {
      await chatFirebaseDataSource.editMessage(
        chatId: chatId,
        messageId: messageId,
        text: text,
      );
      return Right(true);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<ChatMetaData>> getChatsStream(String userId) {
    return chatFirebaseDataSource.getChatsStream(userId);
  }
}
