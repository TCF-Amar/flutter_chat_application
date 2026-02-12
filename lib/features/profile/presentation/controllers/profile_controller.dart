import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
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
  final TextEditingController statusController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxBool _isEditMode = false.obs;
  bool get isEditMode => _isEditMode.value;

  final Rx<UserEntity?> _currentUser = Rx<UserEntity?>(null);
  UserEntity? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    statusController.dispose();
    super.onClose();
  }

  /// Load current user profile data
  Future<void> loadUserProfile() async {
    _isLoading.value = true;
    final user = _authStateNotifier.user;

    if (user != null) {
      _currentUser.value = user;
      nameController.text = user.displayName ?? '';
      phoneController.text = user.phoneNumber ?? '';
      statusController.text = user.status ?? '';
    }

    _isLoading.value = false;
  }

  /// Toggle edit mode
  void toggleEditMode() {
    _isEditMode.value = !_isEditMode.value;
    if (!_isEditMode.value) {
      // Reset to original values if canceling edit
      loadUserProfile();
    }
  }

  /// Update user profile
  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    _isLoading.value = true;
    final user = _currentUser.value;

    if (user == null) {
      _logger.e('Cannot update profile: No current user');
      _isLoading.value = false;
      return;
    }

    final updatedUser = user.copyWith(
      displayName: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      status: statusController.text.trim(),
    );

    final result = await _authUsecase.updateUser(updatedUser);

    result.fold(
      (failure) {
        _logger.e('Failed to update profile: ${failure.message}');
        Get.snackbar(
          'Error',
          failure.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (user) async {
        _logger.i('Profile updated successfully');
        await _authStateNotifier.fetchUserProfile(user.uid);
        _currentUser.value = user;
        _isEditMode.value = false;
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
    _isLoading.value = false;
  }

  /// Update profile photo
  Future<void> updateProfilePhoto() async {
    // TODO: Implement photo picker and upload
    Get.snackbar(
      'Info',
      'Photo upload feature coming soon',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
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
