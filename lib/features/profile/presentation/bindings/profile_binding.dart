import 'package:chat_kare/features/profile/presentation/controllers/profile_controller.dart';
import 'package:get/get.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProfileController());
  }

  static Future<void> init() async {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
