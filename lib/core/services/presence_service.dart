import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Service to manage user presence (online/offline status)
/// Listens to app lifecycle changes and updates user status accordingly
class PresenceService with WidgetsBindingObserver {
  final AuthStateNotifier _authStateNotifier;

  PresenceService({required AuthStateNotifier authStateNotifier})
    : _authStateNotifier = authStateNotifier;

  /// Initialize the presence service
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    // Set user online when service initializes
    if (_authStateNotifier.isAuthenticated) {
      _authStateNotifier.setUserOnline();
    }
  }

  /// Dispose the presence service
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Set user offline when service disposes
    if (_authStateNotifier.isAuthenticated) {
      _authStateNotifier.setUserOffline();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_authStateNotifier.isAuthenticated) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _authStateNotifier.setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background or became inactive
        _authStateNotifier.setUserOffline();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being closed
        _authStateNotifier.setUserOffline();
        break;
    }
  }

  /// Factory method to create and register PresenceService with GetX
  static PresenceService init() {
    final authStateNotifier = Get.find<AuthStateNotifier>();
    final service = PresenceService(authStateNotifier: authStateNotifier);
    service.initialize();
    Get.put(service);
    return service;
  }
}
