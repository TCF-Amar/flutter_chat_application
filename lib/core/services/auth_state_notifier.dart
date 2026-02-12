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
  bool get isAuthenticated => _isAuthenticated;

  bool _isProfileCompleted = false;
  bool get isProfileCompleted => _isProfileCompleted;

  bool _isLoadingUserProfile = false;
  bool get isLoadingUserProfile => _isLoadingUserProfile;

  AuthStateNotifier(this._firebaseServices) {
    _init();
  }

  void _init() {
    // Check initial auth state
    final currentUser = _firebaseServices.auth.currentUser;
    _isAuthenticated = currentUser != null;

    if (currentUser != null) {
      _logger.i('User already signed in: ${currentUser.email}');
      _isLoadingUserProfile = true;
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

      // User signed in
      if (user != null) {
        _isLoadingUserProfile = true;
        await fetchUserProfile(user.uid);
      } else {
        // User signed out
        _isProfileCompleted = false;
        _isLoadingUserProfile = false;
        this.user = null;
      }

      // Notify all listeners (GoRouter and AuthController)
      notifyListeners();
    });
  }

  Future<void> fetchUserProfile(String uid) async {
    _isLoadingUserProfile = true;
    // Notify listeners so UI/Router knows we are loading
    notifyListeners();

    try {
      if (Get.isRegistered<AuthRepositoryImpl>()) {
        final authRepository = Get.find<AuthRepositoryImpl>();
        final result = await authRepository.getUser(uid);
        result.fold(
          (failure) {
            _logger.e('Failed to fetch user profile: ${failure.message}');
            _isProfileCompleted = false;
            user = null;
          },
          (userEntity) {
            user = userEntity;
            _isProfileCompleted = userEntity.isProfileCompleted;
            if (_isProfileCompleted) {
              _initializeFcmToken();
            }
            _logger.i('User profile fetched. Completed: $_isProfileCompleted');
          },
        );
      } else {
        _logger.w("AuthRepositoryImpl not registered yet in AuthStateNotifier");
        _isProfileCompleted = false;
      }
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
      _isProfileCompleted = false;
    } finally {
      _isLoadingUserProfile = false;
      notifyListeners();
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

  /// Set user status to online
  Future<void> setUserOnline() async {
    if (!_isAuthenticated || user == null) return;

    try {
      final authRepository = Get.find<AuthRepositoryImpl>();
      await authRepository.updateUserStatus(uid: user!.uid, status: 'online');
      _logger.i('User status set to online');
    } catch (e) {
      _logger.e('Failed to set user online: $e');
    }
  }

  /// Set user status to offline
  Future<void> setUserOffline() async {
    if (!_isAuthenticated || user == null) return;

    try {
      final authRepository = Get.find<AuthRepositoryImpl>();
      await authRepository.updateUserStatus(uid: user!.uid, status: 'offline');
      _logger.i('User status set to offline');
    } catch (e) {
      _logger.e('Failed to set user offline: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
