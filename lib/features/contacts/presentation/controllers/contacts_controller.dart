import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  final textInputType = TextInputType.emailAddress.obs;

  void toggleInputType() {
    if (textInputType.value == TextInputType.emailAddress) {
      textInputType.value = TextInputType.phone;
    } else {
      textInputType.value = TextInputType.emailAddress;
    }

    // Force keyboard update
    if (contactInfoFocusNode.hasFocus) {
      contactInfoFocusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        contactInfoFocusNode.requestFocus();
      });
    }
  }

  final nameController = TextEditingController();
  final contactInfoController = TextEditingController();
  final contactInfoFocusNode = FocusNode();

  @override
  void onClose() {
    nameController.dispose();
    contactInfoController.dispose();
    contactInfoFocusNode.dispose();
    super.onClose();
  }
}
