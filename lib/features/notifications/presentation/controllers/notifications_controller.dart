import 'package:chat_kare/features/notifications/data/models/notifications_model.dart';
import 'package:chat_kare/features/shared/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:chat_kare/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';

class NotificationsController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final notificationsRepository = Get.find<NotificationsRepository>();
  final authController = Get.find<AuthController>();

  final _notifications = <NotificationsModel>[].obs;
  List<NotificationsModel> get notifications => _notifications.toList();

  final _unreadCount = 0.obs;
  int get unreadCount => _unreadCount.value;

  // Group consecutive notifications from the same sender
  List<List<NotificationsModel>> get groupedNotifications {
    if (_notifications.isEmpty) return [];

    final List<List<NotificationsModel>> groups = [];
    List<NotificationsModel> currentGroup = [_notifications[0]];

    for (int i = 1; i < _notifications.length; i++) {
      final current = _notifications[i];
      final previous = _notifications[i - 1];

      // Group if same sender
      if (current.senderId == previous.senderId) {
        currentGroup.add(current);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [current];
      }
    }

    // Add the last group
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return groups;
  }

  @override
  void onInit() {
    super.onInit();

    // Listen to user changes to fetch notifications on login and clear on logout
    ever(authController.rxCurrentUser, (user) {
      if (user != null) {
        getNotifications();
      } else {
        _notifications.clear();
      }
    });

    // Initial fetch if user is already logged in
    if (authController.currentUser != null) {
      getNotifications();
    }
  }

  Future<void> getNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = notificationsRepository.getNotifications();
    result.listen(
      (event) {
        event.fold(
          (failure) {
            errorMessage.value = failure.message;
            AppSnackbar.error(message: failure.message);
            isLoading.value = false;
          },
          (notifications) async {
            // Filter out items that are currently pending deletion
            if (_pendingDeletions.isNotEmpty) {
              notifications.removeWhere(
                (n) => _pendingDeletions.contains(n.id),
              );
            }
            _notifications.value = notifications;
            isLoading.value = false;
          },
        );
      },
      onError: (error) {
        errorMessage.value = error.toString();
        AppSnackbar.error(message: 'Failed to load notifications');
        isLoading.value = false;
      },
    );
  }

  // Selection state
  final RxList<NotificationsModel> selectedNotifications =
      <NotificationsModel>[].obs;

  bool get hasSelection => selectedNotifications.isNotEmpty;
  int get selectedCount => selectedNotifications.length;

  void toggleNotificationSelection(NotificationsModel notification) {
    if (selectedNotifications.contains(notification)) {
      selectedNotifications.remove(notification);
    } else {
      selectedNotifications.add(notification);
    }
  }

  void clearSelection() {
    selectedNotifications.clear();
  }

  bool isSelected(NotificationsModel notification) {
    return selectedNotifications.contains(notification);
  }

  Future<void> deleteNotification(NotificationsModel notification) async {
    try {
      // Remove from local list immediately for smooth animation
      _notifications.remove(notification);

      // Track this specific notification as pending deletion
      final pendingId = notification.id;
      
      _pendingDeletions.add(pendingId);

      AppSnackbar.withAction(
        title: 'Notification deleted',
        message: 'Notification deleted',
        actionLabel: 'Undo',
        onActionPressed: () {
          undoDelete(notification);
        },
        duration: 3,
      );

      await Future.delayed(const Duration(seconds: 3));

      // Check if this specific notification is still pending deletion (not undone)
      if (_pendingDeletions.contains(pendingId)) {
        await notificationsRepository.deleteNotification(
          notificationId: pendingId,
        );
        _pendingDeletions.remove(pendingId);
      }
    } catch (e) {
      // Re-add if deletion fails
      if (!_notifications.contains(notification)) {
        _notifications.add(notification);
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      _pendingDeletions.remove(notification.id);
      AppSnackbar.error(message: 'Failed to delete notification');
    }
  }

  // Set of IDs that are currently in the "Undo" window
  final Set<String> _pendingDeletions = <String>{};

  // clear all notifications
  Future<void> clearAllNotifications() async {
    final result = await notificationsRepository.deleteAllNotifications();
    result.fold(
      (failure) => AppSnackbar.error(message: failure.message),
      (_) => AppSnackbar.success(message: 'All notifications cleared'),
    );
  }

  // clear selected notifications
  Future<void> clearSelectedNotifications() async {
    final count = selectedNotifications.length;
    final deletedNotifications = List<NotificationsModel>.from(
      selectedNotifications,
    );

    // Remove from local list immediately
    _notifications.removeWhere(
      (notification) => selectedNotifications.contains(notification),
    );
    selectedNotifications.clear();

    AppSnackbar.withAction(
      title: 'Notifications deleted',
      message: '$count notifications deleted',
      actionLabel: 'Undo',
      onActionPressed: () {
        // Restore deleted notifications
        _notifications.addAll(deletedNotifications);
      },
      duration: 3,
    );

    // Wait 3 seconds before permanently deleting
    await Future.delayed(const Duration(seconds: 3));

    // Delete from Firestore
    for (var notification in deletedNotifications) {
      final result = await notificationsRepository.deleteNotification(
        notificationId: notification.id,
      );
      result.fold(
        (failure) => AppSnackbar.error(message: failure.message),
        (_) => null,
      );
    }
  }

  // mark selected notifications as read
  Future<void> markSelectedAsRead() async {
    final count = selectedNotifications.length;

    // Mark as read in Firestore
    for (var notification in selectedNotifications) {
      final result = await notificationsRepository.markNotificationAsRead(
        notificationId: notification.id,
      );
      result.fold(
        (failure) => AppSnackbar.error(message: failure.message),
        (_) => null,
      );
    }

    selectedNotifications.clear();
    AppSnackbar.success(message: '$count notifications marked as read');
  }

  // undo delete
  // undo delete
  void undoDelete(NotificationsModel notification) {
    if (_pendingDeletions.contains(notification.id)) {
      _pendingDeletions.remove(notification.id);
      _notifications.add(notification);
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      AppSnackbar.success(message: 'Notification restored');
    }
  }

  Future<void> markAsRead(NotificationsModel notification) async {
    final result = await notificationsRepository.markNotificationAsRead(
      notificationId: notification.id,
    );
    result.fold(
      (failure) => AppSnackbar.error(message: failure.message),
      (_) => AppSnackbar.success(message: 'Marked as read'),
    );
  }

  Future<void> markAllAsRead() async {
    final result = await notificationsRepository.markAllNotificationsAsRead();
    result.fold(
      (failure) => AppSnackbar.error(message: failure.message),
      (_) => AppSnackbar.success(message: 'Marked all as read'),
    );
  }
}
