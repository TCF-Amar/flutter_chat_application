import 'package:chat_kare/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:chat_kare/features/notifications/presentation/widgets/grouped_notification_tile.dart';
import 'package:chat_kare/features/notifications/presentation/widgets/notification_selection_bar.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return AppScaffold(
      appBar: DefaultAppBar(title: "Notifications", centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.getNotifications();
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorState(controller);
          }

          if (controller.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              NotificationSelectionBar(controller: controller),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.groupedNotifications.length,
                  itemBuilder: (context, index) {
                    final group = controller.groupedNotifications[index];
                    return GroupedNotificationTile(
                      notifications: group,
                      controller: controller,
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildErrorState(NotificationsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          AppText(controller.errorMessage.value, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.getNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const AppText('No notifications yet'),
        ],
      ),
    );
  }
}
