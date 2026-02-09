import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final ChatController controller;
  final ContactsEntity contact;

  const ChatAppBarWidget({
    super.key,
    required this.controller,
    required this.contact,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ChatAppBarWidget> createState() => _ChatAppBarWidgetState();
}

class _ChatAppBarWidgetState extends State<ChatAppBarWidget> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
    
      backgroundColor: context.theme.colorScheme.surface,
      surfaceTintColor: context.theme.colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.pop();
        },
      ),
      title: _buildTitle(),
      actions: [
        IconButton(icon: const Icon(Icons.video_call), onPressed: () {}),
        IconButton(icon: const Icon(Icons.call), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showContactInfo,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final userName =
              widget.controller.user.value?.displayName ??
              widget.contact.name ??
              widget.contact.phoneNumber ??
              'Unknown';
          return Text(
            userName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          );
        }),
        const SizedBox(height: 2),
        Obx(() {
          if (widget.controller.isOtherUserTyping.value) {
            return const Text(
              'Typing...',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            );
          }

          return Obx(() {
            if (widget.controller.user.value?.status == 'online') {
              return const Text(
                'Online',
                style: TextStyle(fontSize: 12, color: Colors.green),
              );
            } else if (widget.controller.user.value?.lastSeen != null) {
              return Text(
                'Last seen ${_formatLastSeen(widget.controller.user.value!.lastSeen!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              );
            }
            return const SizedBox.shrink();
          });
        }),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(lastSeen);
    }
  }

  void _showContactInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final user = widget.controller.user.value;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.displayName ?? widget.contact.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (user?.email != null)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(user!.email),
                  ),
                if (user?.phoneNumber != null)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(user!.phoneNumber!),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    // Navigate to contact details page
                  },
                  child: const Text('View Full Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  context.pop();
                  _showBlockConfirmation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report User'),
                onTap: () {
                  context.pop();
                  _showReportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search in Chat'),
                onTap: () {
                  context.pop();
                  _showSearchDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Mute Notifications'),
                onTap: () {
                  context.pop();
                  _toggleMuteNotifications();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Clear Chat'),
                onTap: () {
                  context.pop();
                  _showClearChatConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              widget.controller.blockUser();
              context.pop(); // Go back to chat list
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    // Implement report dialog
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search in Chat'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Search messages...'),
            onChanged: (query) {
              widget.controller.searchMessages(query);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _toggleMuteNotifications() {
    widget.controller.toggleMuteNotifications();
    Get.snackbar(
      'Notifications',
      widget.controller.isMuted.value ? 'Muted' : 'Unmuted',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              widget.controller.clearChat();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
