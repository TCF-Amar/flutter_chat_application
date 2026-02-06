import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Predefined snackbar types and custom snackbar builder
class AppSnackbar {
  // Private constructor to prevent instantiation
  AppSnackbar._();

  /// Show success snackbar
  static void success({
    required String message,
    String title = 'Success',
    int duration = 3,
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  /// Show error snackbar
  static void error({
    required String message,
    String title = 'Error',
    int duration = 4,
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFF44336),
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  /// Show warning snackbar
  static void warning({
    required String message,
    String title = 'Warning',
    int duration = 3,
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFFF9800),
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  /// Show info snackbar
  static void info({
    required String message,
    String title = 'Info',
    int duration = 3,
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFF2196F3),
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  /// Show loading snackbar
  static void loading({
    required String message,
    String title = 'Loading',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFF607D8B),
      colorText: Colors.white,
      icon: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      duration: const Duration(days: 1), // Indefinite
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: false,
      showProgressIndicator: false,
    );
  }

  static void dismiss() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    } catch (e) {
      // Ignore errors if snackbar controller is not initialized
    }
  }

  static void custom({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    int duration = 3,
    SnackPosition position = SnackPosition.TOP,
    EdgeInsets? margin,
    double? borderRadius,
    bool isDismissible = true,
    VoidCallback? onTap,
    TextButton? mainButton,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor ?? const Color(0xFF323232),
      colorText: textColor ?? Colors.white,
      icon: icon,
      duration: Duration(seconds: duration),
      margin: margin ?? const EdgeInsets.all(16),
      borderRadius: borderRadius ?? 12,
      isDismissible: isDismissible,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      onTap: onTap != null ? (_) => onTap() : null,
      mainButton: mainButton,
    );
  }

  /// Show snackbar with action button
  static void withAction({
    required String message,
    required String actionLabel,
    required VoidCallback onActionPressed,
    String title = 'Notice',
    Color? backgroundColor,
    int duration = 5,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor ?? const Color(0xFF323232),
      colorText: Colors.white,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          onActionPressed();
        },
        child: Text(
          actionLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Show network error snackbar
  static void networkError({
    String message = 'No internet connection. Please check your network.',
    VoidCallback? onRetry,
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      'Network Error',
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: Colors.white,
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      mainButton: onRetry != null
          ? TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                onRetry();
              },
              child: const Text(
                'RETRY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  /// Show validation error snackbar
  static void validationError({
    required String message,
    String title = 'Validation Error',
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFE91E63),
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
    );
  }

  /// Show authentication error snackbar
  static void authError({
    required String message,
    String title = 'Authentication Failed',
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: Colors.white,
      icon: const Icon(Icons.lock_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
    );
  }

  /// Show server error snackbar
  static void serverError({
    String message = 'Something went wrong. Please try again later.',
    String title = 'Server Error',
    SnackPosition position = SnackPosition.TOP,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFF9C27B0),
      colorText: Colors.white,
      icon: const Icon(Icons.cloud_off, color: Colors.white),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
    );
  }
}
