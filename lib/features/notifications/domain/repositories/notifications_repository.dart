import 'package:chat_kare/core/utils/typedefs.dart';
import 'package:chat_kare/features/notifications/data/models/notifications_model.dart';

abstract class NotificationsRepository {
  Stream<Result<List<NotificationsModel>>> getNotifications();
  Future<Result<void>> markNotificationAsRead({required String notificationId});
  Future<Result<void>> markAllNotificationsAsRead();
  Stream<Result<int>> getUnreadCountStream();
  Future<Result<void>> deleteNotification({required String notificationId});
  Future<Result<void>> deleteAllNotifications();
}
