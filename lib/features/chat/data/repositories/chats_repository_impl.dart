import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/chat/data/datasources/chats_firebase_data_source.dart';
import 'package:chat_kare/features/chat/data/models/chats_model.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatsRepositoryImpl {
  ChatsRemoteDataSourceImpl chatFirebaseDataSource;

  ChatsRepositoryImpl({required this.chatFirebaseDataSource});

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

  Stream<List<ChatsEntity>> getMessages(String chatId) {
    return chatFirebaseDataSource.getMessages(chatId).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

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
}
