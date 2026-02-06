import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class ProfileController extends GetxController {
  final AuthUsecase _authUsecase = Get.find<AuthUsecase>();
  final AuthController _authController = Get.find<AuthController>();
  final AuthStateNotifier _authStateNotifier = Get.find<AuthStateNotifier>();
  final Logger _logger = Logger();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> completeProfile() async {
    if (!formKey.currentState!.validate()) return;

    _isLoading.value = true;
    final currentUser = _authController.currentUser;

    if (currentUser == null) {
      _logger.e('Cannot complete profile: No current user');
      _isLoading.value = false;
      return;
    }

    final updatedUser = currentUser.copyWith(
      displayName: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      isProfileCompleted:
          nameController.text.isNotEmpty && phoneController.text.isNotEmpty,
    );

    final result = await _authUsecase.updateUser(updatedUser);

    result.fold(
      (failure) {
        _logger.e('Failed to complete profile: ${failure.message}');
        Get.snackbar(
          'Error',
          failure.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (user) async {
        _logger.i('Profile completed successfully');
        // Update local user state
        await _authStateNotifier.fetchUserProfile(user.uid);
        try {
          await Get.find<NotificationServices>().initializeFcmToken();
        } catch (e) {
          _logger.e('Failed to initialize FCM token: $e');
        }
      },
    );
    _isLoading.value = false;
  }
}
