import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:get/get.dart';

class CoreDi {
  static final CoreDi instance = CoreDi._();
  CoreDi._();

  Future<void> init() async {
    // Initialize NotificationServices
    Get.put(NotificationServices.instance, permanent: true);
    await NotificationServices.instance.init();
    NotificationServices.instance.listenToFcm();

    // Initialize FirebaseServices
    Get.put(FirebaseServices(), permanent: true);

    // Initialize AuthStateNotifier (depends on FirebaseServices)
    Get.put(AuthStateNotifier(Get.find<FirebaseServices>()), permanent: true);
  }
}
