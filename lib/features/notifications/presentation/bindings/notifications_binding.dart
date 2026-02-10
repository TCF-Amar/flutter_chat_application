import 'package:chat_kare/features/notifications/data/datasources/notifications_firebase_data_source.dart';
import 'package:chat_kare/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:chat_kare/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:chat_kare/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:get/get.dart';

class NotificationsBinding {
  static void init() {
    // datasouirce
    Get.put(NotificationsFirebaseDataSource());
    // repository
    Get.put<NotificationsRepository>(
      NotificationsRepositoryImpl(notificationsFirebaseDataSource: Get.find()),
    );
    // controller
    Get.put(NotificationsController());
  }
}
