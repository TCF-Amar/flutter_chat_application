import 'dart:async';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/core/services/notification_services.dart';
import 'package:chat_kare/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class AuthStateNotifier extends ChangeNotifier {
  final FirebaseServices _firebaseServices;
  final Logger _logger = Logger();
  late final StreamSubscription<User?> _authStateSubscription;

  UserEntity? user;
  bool _isAuthenticated = false;
  bool _isProfileCompleted = false;
  bool get isProfileCompleted => _isProfileCompleted;

  AuthStateNotifier(this._firebaseServices) {
    _init();
  }

  /// Whether the user is currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  void _init() {
    // Check initial auth state
    final currentUser = _firebaseServices.auth.currentUser;
    _isAuthenticated = currentUser != null;

    if (currentUser != null) {
      _logger.i('User already signed in: ${currentUser.email}');
      // _initializeFcmToken();
      fetchUserProfile(currentUser.uid);
    }

    // Listen to auth state changes
    _authStateSubscription = _firebaseServices.auth.authStateChanges().listen((
      user,
    ) async {
      _isAuthenticated = user != null;

      _logger.i(
        'Auth state changed in AuthStateNotifier: ${user != null ? "Authenticated (${user.email})" : "Not authenticated"}',
      );

      // Initialize FCM token when user signs in
      if (user != null) {
        // if (!wasAuthenticated) {
        //   await _initializeFcmToken();
        // }
        await fetchUserProfile(user.uid);
      } else {
        _isProfileCompleted = false;
      }

      // Notify all listeners (GoRouter and AuthController)
      notifyListeners();
    });
  }

  Future<void> fetchUserProfile(String uid) async {
    try {
      // Assuming AuthRepositoryImpl is available via Get.find
      // If not, we might need to handle the case where it's not yet registered
      if (Get.isRegistered<AuthRepositoryImpl>()) {
        final authRepository = Get.find<AuthRepositoryImpl>();
        final result = await authRepository.getUser(uid);
        result.fold(
          (failure) {
            _logger.e('Failed to fetch user profile: ${failure.message}');
            _isProfileCompleted = false;
            user = null; // Clear userEntity on failure
          },
          (userEntity) {
            user = userEntity; // Update userEntity
            _isProfileCompleted = userEntity.isProfileCompleted;
            if (_isProfileCompleted) {
              _initializeFcmToken();
            }
            _logger.i('User profile fetched. Completed: $_isProfileCompleted');
          },
        );
        notifyListeners(); // Validate if this is needed, probably yes to trigger router
      } else {
        _logger.w("AuthRepositoryImpl not registered yet in AuthStateNotifier");
        // Fallback or retry logic could go here, but for now we assume false to be safe
        _isProfileCompleted = false;
      }
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
      _isProfileCompleted = false;
    }
  }

  /// Initialize FCM token for the current signed-in user
  Future<void> _initializeFcmToken() async {
    try {
      _logger.d('Initializing FCM token for current user');
      final notificationServices = Get.find<NotificationServices>();
      await notificationServices.initializeFcmToken();
      _logger.i('FCM token initialized for current user');
    } catch (e) {
      _logger.e('Failed to initialize FCM token: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
