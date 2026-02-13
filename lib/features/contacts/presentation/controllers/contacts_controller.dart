import 'dart:async';

import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/contacts/domain/entities/contact_entity.dart';
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

  final _contacts = <UserEntity>[].obs;
  List<UserEntity> get contacts => _contacts.toList();

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
  final searchResults = <UserEntity>[].obs;
  final debounce = Duration(milliseconds: 500);
  Timer? _debounceTimer;

  void findContacts() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      final query = searchController.text.toLowerCase().trim();
      if (query.isEmpty) {
        searchResults.clear();
      } else {
        final results = _contacts.where((contact) {
          final nameMatch = contact.displayName
              .toString()
              .toLowerCase()
              .contains(query);
          final emailMatch = contact.email.toString().toLowerCase().contains(
            query,
          );
          final phoneMatch = contact.phoneNumber.toString().contains(query);
          return nameMatch || emailMatch || phoneMatch;
        }).toList();

        // Sort results: matches starting with query come first
        results.sort((a, b) {
          final aName = a.displayName.toString().toLowerCase();
          final bName = b.displayName.toString().toLowerCase();
          final aStarts = aName.startsWith(query);
          final bStarts = bName.startsWith(query);

          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          return aName.compareTo(bName);
        });

        searchResults.assignAll(results);
      }
    });
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;
    final result = await usecase.getContacts();
    result.fold((failure) {
      Logger().e(failure.message);
      AppSnackbar.error(message: failure.message);
    }, (data) => _contacts.assignAll(data));
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

    final newContact = ContactEntity(
      contactUid: '',
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

  Future<void> updateContact(ContactEntity contact) async {
    isUpdating.value = true;
    final result = await usecase.updateContact(contact);
    result.fold(
      (failure) {
        AppSnackbar.error(message: failure.message);
      },
      (success) {
        AppSnackbar.success(message: "Contact updated successfully");
        fetchContacts();
      },
    );
    isUpdating.value = false;
  }

  Future<void> deleteContact(String uid) async {
    isDeleting.value = true;
    final result = await usecase.deleteContact(uid);
    result.fold(
      (failure) {
        AppSnackbar.error(message: failure.message);
      },
      (success) {
        AppSnackbar.success(message: "Contact deleted successfully");
        fetchContacts();
      },
    );
    isDeleting.value = false;
  }

  Future<void> refreshContacts() async {
    isLoading.value = true;
    _contacts.clear();
    await fetchContacts();
    isLoading.value = false;
  }

  //* Get contact by uid - returns contact with custom name if available
  UserEntity? getContactByUid(String uid) {
    try {
      return _contacts.firstWhere((contact) => contact.uid == uid);
    } catch (e) {
      return null;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    contactInfoController.dispose();
    contactInfoFocusNode.dispose();
    super.onClose();
  }
}
