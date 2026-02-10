import 'package:chat_kare/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationSelectionBar extends StatelessWidget {
  final NotificationsController controller;

  const NotificationSelectionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasSelection) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.blue.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${controller.selectedCount} selected'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    controller.clearSelectedNotifications();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.done_all_rounded),
                  onPressed: () {
                    controller.markSelectedAsRead();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.clearSelection,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
