import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/features/contacts/domain/usecases/contacts_usecase.dart';
import 'package:chat_kare/features/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

class ContactsController extends GetxController {
  final ContactsUsecase usecase = Get.find();
  final fs = Get.find<FirebaseServices>();
  final authController = Get.find<AuthController>();
  final textInputType = TextInputType.numberWithOptions().obs;

  void toggleInputType() {
    if (textInputType.value == TextInputType.emailAddress) {
      textInputType.value = TextInputType.numberWithOptions();
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

  final inputTypeEmail = TextInputType.emailAddress;
  final inputTypeNumber = TextInputType.numberWithOptions(
    signed: true,
    decimal: true,
  );

  final contacts = <ContactsEntity>[].obs;

  final isLoading = false.obs;
  final isUpdating = false.obs;
  final isDeleting = false.obs;
  final isAdding = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  final searchController = TextEditingController();
  final searchResults = <ContactsEntity>[].obs;
  final debounce = Duration(milliseconds: 500);

  void findContacts() {
    searchResults.value = contacts.where((contact) {
      return contact.name.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          contact.phoneNumber!.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          contact.email!.toLowerCase().contains(
            searchController.text.toLowerCase(),
          );
    }).toList();
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;
    final result = await usecase.getContacts();
    result.fold((failure) {
      Logger().e(failure.message);
      AppSnackbar.error(message: failure.message);
    }, (data) => contacts.assignAll(data));
    isLoading.value = false;
  }

  Future<bool> addContact(BuildContext context) async {
    if (contactInfoController.text.isEmpty) {
      AppSnackbar.warning(message: "Please enter email or phone number");
      return false;
    }

    isAdding.value = true;

    String? email;
    String? phoneNumber;

    if (textInputType.value == TextInputType.emailAddress) {
      if (!contactInfoController.text.isEmail) {
        AppSnackbar.warning(message: "Please enter a valid email");
        isAdding.value = false;
        return false;
      }
      email = contactInfoController.text.trim();
    } else {
      if (!contactInfoController.text.isPhoneNumber) {
        AppSnackbar.warning(message: "Please enter a valid phone number");
        isAdding.value = false;
        return false;
      }
      phoneNumber = contactInfoController.text.trim();
    }

    final newContact = ContactsEntity(
      id: '',
      name: nameController.text.trim().isNotEmpty
          ? nameController.text.trim()
          : 'Unknown',
      email: email,
      phoneNumber: phoneNumber,
    );

    final result = await usecase.addContact(
      newContact,
      authController.currentUser!,
    );

    bool isSuccess = false;
    result.fold(
      (failure) {
        AppSnackbar.error(message: failure.message);
      },
      (success) {
        AppSnackbar.success(message: "Contact added successfully");
        fetchContacts();
        nameController.clear();
        contactInfoController.clear();
        isSuccess = true;
        if (context.mounted) {
          context.pop();
        }
      },
    );

    isAdding.value = false;
    return isSuccess;
  }

  Future<bool> updateContact() async {
    return false;
  }

  Future<bool> deleteContact() async {
    return false;
  }

  Future<void> refreshContacts() async {
    isLoading.value = true;
    contacts.clear();
    await fetchContacts();
    isLoading.value = false;
  }

  @override
  void onClose() {
    nameController.dispose();
    contactInfoController.dispose();
    contactInfoFocusNode.dispose();
    super.onClose();
  }
}
