import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/notifications/data/models/notifications_model.dart';
import 'package:chat_kare/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:chat_kare/features/notifications/presentation/widgets/dismiss_backgrounds.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationTile extends StatelessWidget {
  final NotificationsModel notification;
  final NotificationsController controller;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ObjectKey(notification),
      background: const DismissBackground(),
      secondaryBackground: const DismissSecondaryBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await controller.deleteNotification(notification);
          return true;
        } else if (direction == DismissDirection.endToStart) {
          await controller.markAsRead(notification);
          return false;
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Obx(() {
          final isSelected = controller.selectedNotifications.contains(
            notification,
          );

          return ListTile(
            titleAlignment: .center,
            minTileHeight: 50,
            leading: _buildLeading(isSelected, context),
            title: Text(
              notification.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _buildSubtitle(),
            isThreeLine: true,
            selected: isSelected,
            onLongPress: () {
              controller.toggleNotificationSelection(notification);
            },
            onTap: () {
              if (controller.hasSelection) {
                controller.toggleNotificationSelection(notification);
              } else {
                if (notification.chatId.isNotEmpty) {
                  // TODO: Navigate to chat
                }
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildLeading(bool isSelected, BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: context.colorScheme.primary,
          backgroundImage: notification.senderPhotoUrl.isNotEmpty
              ? NetworkImage(notification.senderPhotoUrl)
              : null,
          child: notification.senderPhotoUrl.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        if (isSelected)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        AppText(notification.body, maxLines: 1, overflow: .ellipsis),
        const SizedBox(height: 4),
        Text(
          _formatTimestamp(notification.timestamp),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
