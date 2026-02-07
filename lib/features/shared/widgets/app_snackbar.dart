import 'package:chat_kare/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Predefined snackbar types and custom snackbar builder using ScaffoldMessenger
class AppSnackbar {
  // Private constructor to prevent instantiation
  AppSnackbar._();

  static void _show({
    required String message,
    String? title,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool showProgressIndicator = false,
  }) {
    // Use the global key for reliability
    final messengerState = rootScaffoldMessengerKey.currentState;
    if (messengerState == null) return;

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 12)],
          if (showProgressIndicator) ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                if (title != null && title.isNotEmpty)
                  const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? const Color(0xFF323232),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      dismissDirection: DismissDirection.horizontal,
      action: action,
    );

    messengerState
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show success snackbar
  static void success({
    required String message,
    String title = 'Success',
    int duration = 3,
    SnackPosition position = SnackPosition
        .BOTTOM, // Material SnackBar calls are always bottom by default
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFF4CAF50),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: Duration(seconds: duration),
    );
  }

  /// Show error snackbar
  static void error({
    required String message,
    String title = 'Error',
    int duration = 4,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFFF44336),
      icon: const Icon(Icons.error, color: Colors.white),
      duration: Duration(seconds: duration),
    );
  }

  /// Show warning snackbar
  static void warning({
    required String message,
    String title = 'Warning',
    int duration = 3,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFFFF9800),
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: Duration(seconds: duration),
    );
  }

  /// Show info snackbar
  static void info({
    required String message,
    String title = 'Info',
    int duration = 3,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFF2196F3),
      icon: const Icon(Icons.info, color: Colors.white),
      duration: Duration(seconds: duration),
    );
  }

  /// Show loading snackbar
  static void loading({
    required String message,
    String title = 'Loading',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFF607D8B),
      duration: const Duration(days: 1), // Indefinite, requires manual dismiss
      showProgressIndicator: true,
    );
  }

  static void dismiss() {
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  static void custom({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    int duration = 3,
    SnackPosition position = SnackPosition.BOTTOM,
    EdgeInsets? margin,
    double? borderRadius,
    bool isDismissible = true,
    VoidCallback? onTap,
    TextButton?
    mainButton, // This might need adaptation if TextButton is passed, but SnackBarAction is preferred
  }) {
    // Adapter for mainButton to SnackBarAction if possible, or just ignore for now as custom is complex
    SnackBarAction? action;
    if (mainButton != null &&
        mainButton.onPressed != null &&
        mainButton.child is Text) {
      action = SnackBarAction(
        label: (mainButton.child as Text).data ?? 'ACTION',
        onPressed: mainButton.onPressed!,
        textColor: Colors.white,
      );
    }

    _show(
      message: message,
      title: title,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: Duration(seconds: duration),
      action: action,
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
    _show(
      message: message,
      title: title,
      backgroundColor: backgroundColor,
      duration: Duration(seconds: duration),
      action: SnackBarAction(
        label: actionLabel,
        onPressed: onActionPressed,
        textColor: Colors.white,
      ),
    );
  }

  /// Show network error snackbar
  static void networkError({
    String message = 'No internet connection. Please check your network.',
    VoidCallback? onRetry,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: 'Network Error',
      backgroundColor: const Color(0xFFD32F2F),
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      duration: onRetry != null
          ? const Duration(seconds: 10)
          : const Duration(seconds: 5),
      action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              onPressed: onRetry,
              textColor: Colors.white,
            )
          : null,
    );
  }

  /// Show validation error snackbar
  static void validationError({
    required String message,
    String title = 'Validation Error',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFFE91E63),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show authentication error snackbar
  static void authError({
    required String message,
    String title = 'Authentication Failed',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFFD32F2F),
      icon: const Icon(Icons.lock_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  /// Show server error snackbar
  static void serverError({
    String message = 'Something went wrong. Please try again later.',
    String title = 'Server Error',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      message: message,
      title: title,
      backgroundColor: const Color(0xFF9C27B0),
      icon: const Icon(Icons.cloud_off, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}
