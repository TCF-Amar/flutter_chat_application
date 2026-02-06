import 'package:chat_kare/core/errors/failure.dart';
import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class AuthController extends GetxController {
  final FirebaseServices firebaseServices = Get.find<FirebaseServices>();
  final AuthUsecase authUsecase = Get.find<AuthUsecase>();
  final AuthStateNotifier authStateNotifier = Get.find<AuthStateNotifier>();
  final Logger _logger = Logger();

  final Rx<bool?> _authState = Rx<bool?>(null);
  bool? get authState => _authState.value;

  final Rx<UserEntity?> _currentUser = Rx<UserEntity?>(null);
  UserEntity? get currentUser => _currentUser.value;

  final RxBool _isLoading = RxBool(false);
  bool get isLoading => _isLoading.value;

  @override
  void onInit() async {
    super.onInit();
    // signOut();
    _logger.i('AuthController initialized');

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
    _logger.i('Sign-in attempt for email: ${signInEmailController.text}');
    final result = await authUsecase.signIn(
      email: signInEmailController.text,
      password: signInPasswordController.text,
    );
    result.fold(
      (failure) {
        _isLoading.value = false;
        _logger.e('Sign-in failed: ${failure.message}');
      },
      (_) {
        _isLoading.value = false;
        _logger.i('Sign-in successful for: ${signInEmailController.text}');
      },
    );
  }

  // Sign up
  // final _signUpFormKey = GlobalKey<FormState>();
  // GlobalKey<FormState> get signUpFormKey => _signUpFormKey;
  final _signUpEmailController = TextEditingController();
  TextEditingController get signUpEmailController => _signUpEmailController;
  final _signUpPasswordController = TextEditingController();
  TextEditingController get signUpPasswordController =>
      _signUpPasswordController;
  final _signUpConfirmPasswordController = TextEditingController();
  TextEditingController get signUpConfirmPasswordController =>
      _signUpConfirmPasswordController;
  // final _signUpDisplayNameController = TextEditingController();
  // TextEditingController get signUpDisplayNameController =>
  //     _signUpDisplayNameController;

  final RxBool _isPhoneExist = RxBool(false);
  bool get isPhoneExist => _isPhoneExist.value;

  Future<void> signUp() async {
    _isLoading.value = true;
    _logger.i('Sign-up attempt for email: ${signUpEmailController.text}');

    final result = await authUsecase.signUp(
      email: signUpEmailController.text,
      password: signUpPasswordController.text,
    );
    result.fold(
      (failure) {
        _isLoading.value = false;
        _logger.e('Sign-up failed: ${failure.message}');
      },
      (user) {
        _currentUser.value = user;
        _isLoading.value = false;
        _logger.i('Sign-up successful for: ${signUpEmailController.text}');
      },
    );
  }

  Future<void> getCurrentUser() async {
    _isLoading.value = true;
    final uid = firebaseServices.auth.currentUser?.uid;
    if (uid == null) {
      _logger.w('Cannot get current user: No user authenticated');
      return;
    }

    _logger.i('Fetching current user data for uid: $uid');
    final result = await authUsecase.getUser(uid);
    result.fold(
      (failure) async {
        _logger.e('Failed to fetch current user: ${failure.message}');
        if (failure is UserNotFoundFailure) {
          _logger.w('User document missing. Signing out to clean up state.');
          await signOut();
        }
      },
      (user) {
        _logger.i('Current user fetched successfully');
        _currentUser.value = user;
      },
    );
    _isLoading.value = false;
  }

  Future<void> signOut() async {
    _logger.i('Sign-out attempt');
    final result = await authUsecase.signOut();
    result.fold((failure) => _logger.e('Sign-out failed: ${failure.message}'), (
      _,
    ) {
      _logger.i('Sign-out successful');
      _currentUser.value = null;
    });
  }

  
  void clear() {
    _signInEmailController.clear();
    _signInPasswordController.clear();
    _signUpEmailController.clear();
    _signUpPasswordController.clear();
    _signUpConfirmPasswordController.clear();
    // _signUpDisplayNameController.clear();
  }

  @override
  void onClose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    // _signUpDisplayNameController.dispose();
    super.onClose();
  }
}
