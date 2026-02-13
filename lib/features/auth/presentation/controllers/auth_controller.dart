/*
 * AuthController - Authentication State Management
 * 
 * GetX controller managing authentication state and user operations.
 * 
 * Key Responsibilities:
 * - Manages authentication state (signed in/out)
 * - Handles user sign in, sign up, and sign out
 * - Maintains current user data
 * - Manages user online/offline status
 * - Provides text controllers for auth forms
 * 
 * State Management:
 * - Uses GetX reactive programming (Rx)
 * - Listens to AuthStateNotifier for auth changes
 * - Updates UI automatically via Obx widgets
 */

import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/auth/domain/usecases/auth_usecase.dart';
import 'package:chat_kare/features/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//* Controller for authentication operations and state
class AuthController extends GetxController {
  //* Firebase services instance
  final FirebaseServices firebaseServices = Get.find<FirebaseServices>();

  //* Auth use case for business logic
  final AuthUsecase authUsecase = Get.find<AuthUsecase>();

  //* Auth state notifier for global auth state
  final AuthStateNotifier authStateNotifier = Get.find<AuthStateNotifier>();

  //* Reactive authentication state (null = unknown, true = authenticated, false = not authenticated)
  final Rx<bool?> _authState = Rx<bool?>(null);
  bool? get authState => _authState.value;

  //* Reactive current user entity
  final Rx<UserEntity?> _currentUser = Rx<UserEntity?>(null);
  UserEntity? get currentUser => _currentUser.value;
  Rx<UserEntity?> get rxCurrentUser => _currentUser;

  //* Reactive loading state for async operations
  final RxBool _isLoading = RxBool(false);
  bool get isLoading => _isLoading.value;

  //* Initializes controller and sets up auth state listener
  @override
  void onInit() async {
    super.onInit();
    _init();
  }

  //* Sets up initial auth state and listener
  //*
  //* Listens to AuthStateNotifier for auth changes and updates local state.
  void _init() async {
    // Set initial auth state
    _authState.value = authStateNotifier.isAuthenticated;

    // Fetch current user if authenticated
    if (authStateNotifier.isAuthenticated) {
      await getCurrentUser();
    }

    // Listen to auth state changes
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

  // ==================== Sign In ====================

  //* Text controller for sign-in email input
  final _signInEmailController = TextEditingController();
  TextEditingController get signInEmailController => _signInEmailController;

  //* Text controller for sign-in password input
  final _signInPasswordController = TextEditingController();
  TextEditingController get signInPasswordController =>
      _signInPasswordController;

  //* Signs in user with email and password
  //*
  //* Shows success/error snackbar and sets user status to online.
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
      (_) async {
        AppSnackbar.success(
          message: 'Sign-in successful for: ${signInEmailController.text}',
          title: 'Success',
        );
        // Set user status to online after successful sign in
        await authStateNotifier.setUserOnline();
        _isLoading.value = false;
      },
    );
  }

  // ==================== Sign Up ====================

  //* Text controller for sign-up email input
  final _signUpEmailController = TextEditingController();
  TextEditingController get signUpEmailController => _signUpEmailController;

  //* Text controller for sign-up password input
  final _signUpPasswordController = TextEditingController();
  TextEditingController get signUpPasswordController =>
      _signUpPasswordController;

  //* Text controller for sign-up confirm password input
  final _signUpConfirmPasswordController = TextEditingController();
  TextEditingController get signUpConfirmPasswordController =>
      _signUpConfirmPasswordController;

  //* Flag to check if phone number already exists (for validation)
  final RxBool _isPhoneExist = RxBool(false);
  bool get isPhoneExist => _isPhoneExist.value;

  //* Signs up new user with email and password
  //*
  //* Creates user account and user document in Firestore.
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

  //* Fetches current user data from Firestore
  //*
  //* Called on app start and after sign-in to get latest user data.
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

  //* Signs out current user
  //*
  //* Sets user status to offline before signing out.
  Future<void> signOut() async {
    _isLoading.value = true;

    // Set user status to offline before signing out
    await authStateNotifier.setUserOffline();

    final result = await authUsecase.signOut();
    result.fold((failure) {}, (_) {
      _currentUser.value = null;
    });

    _isLoading.value = false;
  }

  //* Clears all text controllers
  //*
  //* Called when switching between sign-in and sign-up forms.
  void clear() {
    _signInEmailController.clear();
    _signInPasswordController.clear();
    _signUpEmailController.clear();
    _signUpPasswordController.clear();
    _signUpConfirmPasswordController.clear();
  }

  //* Disposes all text controllers
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
