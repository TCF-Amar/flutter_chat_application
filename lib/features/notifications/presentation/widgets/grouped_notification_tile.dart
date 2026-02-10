import 'package:chat_kare/features/notifications/data/models/notifications_model.dart';
import 'package:chat_kare/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:chat_kare/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';

class GroupedNotificationTile extends StatefulWidget {
  final List<NotificationsModel> notifications;
  final NotificationsController controller;

  const GroupedNotificationTile({
    super.key,
    required this.notifications,
    required this.controller,
  });

  @override
  State<GroupedNotificationTile> createState() =>
      _GroupedNotificationTileState();
}

class _GroupedNotificationTileState extends State<GroupedNotificationTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // If only one notification, show regular tile
    if (widget.notifications.length == 1) {
      return NotificationTile(
        notification: widget.notifications.first,
        controller: widget.controller,
      );
    }

    final firstNotification = widget.notifications.first;
    final count = widget.notifications.length;

    return Column(
      children: [
        // Header showing sender and count
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: firstNotification.senderPhotoUrl.isNotEmpty
                  ? NetworkImage(firstNotification.senderPhotoUrl)
                  : null,
              child: firstNotification.senderPhotoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              firstNotification.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$count notifications',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _isExpanded ? 0.5 : 0,
              child: IconButton(
                icon: const Icon(Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),

        // Expanded list of notifications with smooth animation
        AnimatedSize(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Column(
                  children: widget.notifications.map((notification) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: NotificationTile(
                        notification: notification,
                        controller: widget.controller,
                      ),
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
