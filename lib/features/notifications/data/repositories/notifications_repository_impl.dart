import 'package:chat_kare/core/errors/error_mapper.dart';
import 'package:chat_kare/core/errors/exceptions.dart';
import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/notifications/data/datasources/notifications_firebase_data_source.dart';
import 'package:chat_kare/features/notifications/data/models/notifications_model.dart';
import 'package:chat_kare/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:dartz/dartz.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsFirebaseDataSource notificationsFirebaseDataSource;
  NotificationsRepositoryImpl({required this.notificationsFirebaseDataSource});
  @override
  Stream<Result<List<NotificationsModel>>> getNotifications() {
    try {
      final result = notificationsFirebaseDataSource.getNotifications();
      return result.map((r) => Right(r));
    } on FirebaseException catch (e) {
      return Stream.error(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Stream.error(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markNotificationAsRead({
    required String notificationId,
  }) async {
    try {
      await notificationsFirebaseDataSource.markNotificationAsRead(
        notificationId: notificationId,
      );
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAllNotificationsAsRead() async {
    try {
      await notificationsFirebaseDataSource.markAllNotificationsAsRead();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<Result<int>> getUnreadCountStream() {
    try {
      final result = notificationsFirebaseDataSource.getUnreadCountStream();
      return result.map((r) => Right(r));
    } on FirebaseException catch (e) {
      return Stream.error(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Stream.error(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteNotification({
    required String notificationId,
  }) async {
    try {
      await notificationsFirebaseDataSource.deleteNotification(
        notificationId: notificationId,
      );
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteAllNotifications() async {
    try {
      await notificationsFirebaseDataSource.deleteAllNotifications();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
