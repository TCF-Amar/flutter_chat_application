import 'package:chat_kare/features/home/presentation/controllers/home_controller.dart';
import 'package:get/get.dart';

class HomeBinding {
  static Future<void> init() async {
    // controller
    Get.lazyPut(() => HomeController());
  }
}
