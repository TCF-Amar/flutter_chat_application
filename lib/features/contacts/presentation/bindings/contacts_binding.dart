import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:get/get.dart';

class ContactsBinding {
  static Future<void> init() async {
    Get.put(  ContactsController());
  }
}
