import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseServices firebaseServices = Get.find<FirebaseServices>();
  final AuthUsecase authUsecase = Get.find<AuthUsecase>();
  final AuthStateNotifier authStateNotifier = Get.find<AuthStateNotifier>();

  final Rx<bool?> _authState = Rx<bool?>(null);
  bool? get authState => _authState.value;

  final Rx<UserEntity?> _currentUser = Rx<UserEntity?>(null);
  UserEntity? get currentUser => _currentUser.value;

  final RxBool _isLoading = RxBool(false);
  bool get isLoading => _isLoading.value;

  @override
  void onInit() async {
    super.onInit();
    _init();
  }

  void _init() async {
    _authState.value = authStateNotifier.isAuthenticated;

    if (authStateNotifier.isAuthenticated) {
      await getCurrentUser();
    }
    // Listen to AuthStateNotifier changes
    authStateNotifier.addListener(() async {
      final isAuthenticated = authStateNotifier.isAuthenticated;
      _authState.value = isAuthenticated;

      if (isAuthenticated) {
        await getCurrentUser();
      } else {
        _currentUser.value = null;
      }
    });
  }

  // Sign in
  final _signInEmailController = TextEditingController();
  TextEditingController get signInEmailController => _signInEmailController;
  final _signInPasswordController = TextEditingController();
  TextEditingController get signInPasswordController =>
      _signInPasswordController;

  Future<void> signIn() async {
    _isLoading.value = true;
    final result = await authUsecase.signIn(
      email: signInEmailController.text,
      password: signInPasswordController.text,
    );
    result.fold(
      (failure) {
        AppSnackbar.authError(
          message: "Invalid credential",
          title: 'Sign-in failed',
        );
        _isLoading.value = false;
      },
      (_) {
        AppSnackbar.success(
          message: 'Sign-in successful for: ${signInEmailController.text}',
          title: 'Success',
        );
        _isLoading.value = false;
      },
    );
  }

  // Sign up
  final _signUpEmailController = TextEditingController();
  TextEditingController get signUpEmailController => _signUpEmailController;
  final _signUpPasswordController = TextEditingController();
  TextEditingController get signUpPasswordController =>
      _signUpPasswordController;
  final _signUpConfirmPasswordController = TextEditingController();
  TextEditingController get signUpConfirmPasswordController =>
      _signUpConfirmPasswordController;

  final RxBool _isPhoneExist = RxBool(false);
  bool get isPhoneExist => _isPhoneExist.value;

  Future<void> signUp() async {
    _isLoading.value = true;

    final result = await authUsecase.signUp(
      email: signUpEmailController.text,
      password: signUpPasswordController.text,
    );
    result.fold(
      (failure) {
        _isLoading.value = false;
      },
      (user) {
        _currentUser.value = user;
        _isLoading.value = false;
      },
    );
  }

  Future<void> getCurrentUser() async {
    _isLoading.value = true;
    final uid = firebaseServices.auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final result = await authUsecase.getUser(uid);
    result.fold((failure) {}, (user) {
      _currentUser.value = user;
    });
    _isLoading.value = false;
  }

  Future<void> signOut() async {
    final result = await authUsecase.signOut();
    result.fold((failure) {}, (_) {
      _currentUser.value = null;
    });
  }

  // get user by id

  void clear() {
    _signInEmailController.clear();
    _signInPasswordController.clear();
    _signUpEmailController.clear();
    _signUpPasswordController.clear();
    _signUpConfirmPasswordController.clear();
  }

  @override
  void onClose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.onClose();
  }
}
