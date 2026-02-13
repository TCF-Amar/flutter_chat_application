/*
 * ChatsRepositoryImpl - Chat Repository Implementation
 * 
 * Implements the repository pattern for chat operations.
 * Acts as a bridge between the domain layer and data source layer.
 * 
 * Responsibilities:
 * - Delegates data operations to ChatsRemoteDataSource
 * - Converts between models (data layer) and entities (domain layer)
 * - Handles error mapping from Firebase exceptions to domain failures
 * - Provides streams for real-time chat updates
 */

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

//* Implementation of ChatsRepository using Firebase as data source
class ChatsRepositoryImpl implements ChatsRepository {
  //* Remote data source for Firebase operations
  ChatsRemoteDataSourceImpl chatFirebaseDataSource;

  ChatsRepositoryImpl({required this.chatFirebaseDataSource});

  //* Sends a message to Firestore
  //*
  //* Converts entity to model, sends via data source, and handles errors.
  //* Returns Right(null) on success, Left(Failure) on error.
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
  //

  //* Gets real-time stream of messages for a chat
  //*
  //* Converts models from data source to entities for domain layer.
  //*
  //* Parameters:
  //* - [chatId]: Unique identifier for the chat
  //* - [limit]: Maximum number of messages to fetch (default: 20)
  @override
  Stream<List<ChatsEntity>> getMessagesStream(String chatId, {int limit = 20}) {
    return chatFirebaseDataSource.getMessages(chatId, limit).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

  //* Gets real-time stream of users currently typing in a chat
  //*
  //* Returns list of user IDs who are currently typing.
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

  //* Updates typing status for a user in a chat
  //*
  //* Parameters:
  //* - [chatId]: Chat identifier
  //* - [userId]: User who is typing
  //* - [isTyping]: true if user started typing, false if stopped
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

  //* Marks a specific message as read by a user
  //*
  //* Updates message read status and decrements unread count.
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

  //* Marks all unread messages in a chat as read
  //*
  //* Batch operation to mark all messages as read at once.
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

  //* Gets real-time stream of unread message count for a user
  @override
  Stream<int> getUnreadCountStream(String chatId, String userId) {
    return chatFirebaseDataSource.getUnreadCountStream(chatId, userId);
  }

  //* Edits an existing message's text content
  //*
  //* Returns Right(true) on success, Left(Failure) on error.
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

  //* Gets real-time stream of all chats for a user
  //*
  //* Returns chat metadata including last message, unread count, etc.
  @override
  Stream<List<ChatMetaData>> getChatsStream(String userId) {
    return chatFirebaseDataSource.getChatsStream(userId);
  }

  //* Deletes a message for the current user only
  //*
  //* Message remains visible to other participants.
  //* Returns Right(null) on success, Left(Failure) on error.
  @override
  Future<Result<void>> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await chatFirebaseDataSource.deleteMessageForMe(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
      );
      return Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  //* Deletes a message for all participants
  //*
  //* Message content is removed and marked as deleted for everyone.
  //* Only the sender can delete for everyone.
  //* Returns Right(null) on success, Left(Failure) on error.
  @override
  Future<Result<void>> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await chatFirebaseDataSource.deleteMessageForEveryone(
        chatId: chatId,
        messageId: messageId,
      );
      return Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
