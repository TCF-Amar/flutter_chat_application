/*
 * ChatAppBarWidget - Custom AppBar for Chat Screen
 * 
 * This widget provides a dynamic app bar that switches between two modes:
 * 1. Normal Mode: Shows contact info, call buttons, and more options
 * 2. Selection Mode: Shows message selection count and action buttons (reply, edit, delete, copy, forward)
 * 
 * Features:
 * - Contact avatar and online/typing status display
 * - Video/audio call integration
 * - Message selection and bulk operations
 * - Contact info modal with add-to-contacts functionality
 * - Chat options (search, mute, wallpaper, block, report, clear)
 */

import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/domain/entities/user_entity.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_list_controller.dart';
import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:chat_kare/features/calls/presentation/pages/call_banner_page.dart';
import 'package:chat_kare/features/calls/presentation/widgets/calls_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Custom AppBar widget for chat screen
/// Implements PreferredSizeWidget to work as an AppBar
class ChatAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  /// Controller managing chat state and operations
  final ChatController controller;

  /// Contact user entity for displaying user info
  final UserEntity contact;

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
  /// Builds the app bar with reactive state management
  /// Switches between normal mode and selection mode based on selected messages
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Determine if we're in message selection mode
      final isSelectionMode = widget.controller.selectedMessages.isNotEmpty;
      final selectedCount = widget.controller.selectedMessages.length;

      return AppBar(
        backgroundColor: isSelectionMode
            ? context.colorScheme.primary.withValues(alpha: 0.1)
            : context.colorScheme.surface,
        surfaceTintColor: isSelectionMode
            ? context.colorScheme.primary.withValues(alpha: 0.1)
            : context.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        leading: isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close, color: context.colorScheme.icon),
                onPressed: () {
                  widget.controller.clearSelection();
                },
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: context.colorScheme.icon),
                onPressed: () {
                  context.pop();
                },
              ),
        titleSpacing: 0,
        title: isSelectionMode
            ? Text(
                '$selectedCount',
                style: TextStyle(
                  color: context.colorScheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : InkWell(
                onTap: _showContactInfo,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTitle()),
                    ],
                  ),
                ),
              ),
        actions: isSelectionMode
            ? [
                if (selectedCount == 1) ...[
                  IconButton(
                    icon: Icon(Icons.reply, color: context.colorScheme.icon),
                    onPressed: () {
                      final messageId =
                          widget.controller.selectedMessages.first;
                      final message = widget.controller.messages.firstWhere(
                        (m) => m.id == messageId,
                      );
                      widget.controller.replyToMessage(message);
                      widget.controller.clearSelection();
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final messageId =
                          widget.controller.selectedMessages.first;
                      final message = widget.controller.messages.firstWhere(
                        (m) => m.id == messageId,
                      );
                      final isMe =
                          message.senderId ==
                          widget.controller.authUsecase.currentUid;
                      if (isMe) {
                        return IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: context.colorScheme.icon,
                          ),
                          onPressed: () {
                            widget.controller.startEditing(message);
                            widget.controller.clearSelection();
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: context.colorScheme.icon,
                  ),
                  onPressed: () {
                    _showDeleteConfirmation();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: context.colorScheme.icon),
                  onPressed: () {
                    widget.controller.copySelectedMessages();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.forward, color: context.colorScheme.icon),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forward not implemented yet'),
                      ),
                    );
                  },
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.video_call, color: context.colorScheme.icon),
                  onPressed: () {
                    showCallBanner(
                      context,
                      name: widget.contact.displayName.toString(),
                      photoUrl: widget.contact.photoUrl,
                      callType: CallType.video,
                      initialStatus: CallStatus.outgoing,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call, color: context.colorScheme.icon),
                  onPressed: () {
                    showCallBanner(
                      context,
                      name: "${widget.contact.displayName}",
                      photoUrl: widget.contact.photoUrl,
                      callType: CallType.audio,
                      initialStatus: CallStatus.outgoing,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: context.colorScheme.icon),
                  onPressed: _showMoreOptions,
                ),
              ],
      );
    });
  }

  /// Builds the contact's avatar
  /// Shows profile photo if available, otherwise shows first letter of name
  Widget _buildAvatar() {
    final photoUrl = widget.contact.photoUrl;

    return CircleAvatar(
      radius: 20,
      backgroundColor: context.colorScheme.primary.withValues(alpha: 0.1),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              (widget.contact.displayName.toString())
                  .substring(0, 1)
                  .toUpperCase(),
              style: TextStyle(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  /// Builds the title section showing contact name and status
  /// Displays typing indicator, online status, or last seen time
  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact name
        Text(
          widget.controller.contact.displayName.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.colorScheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        // Status indicator (typing, online, or last seen)
        Obx(() {
          // Priority 1: Show typing indicator
          if (widget.controller.isOtherUserTyping.value) {
            return Text(
              'Typing...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: context.colorScheme.primary,
              ),
            );
          }

          // Priority 2: Show online status
          if (widget.controller.contact.status == 'online') {
            return Text(
              'Online',
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            );
          }
          // Priority 3: Show last seen time
          else if (widget.controller.contact.lastSeen != null) {
            return Text(
              'Last seen ${_formatLastSeen(widget.controller.contact.lastSeen!)}',
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.textSecondary,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// Formats the last seen timestamp into a human-readable string
  /// Returns relative time (e.g., "5 minutes ago") or formatted date for older timestamps
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
      return DateFormat('MMM d, hh:mm a').format(lastSeen);
    }
  }

  /// Shows contact information modal with full user details
  ///
  /// Features:
  /// - Fetches complete user data from Firestore via ChatListController
  /// - Shows loading indicator during fetch
  /// - Displays user avatar, name, email, and phone
  /// - Checks if user is in contacts and shows appropriate action button:
  ///   - "Add to Contacts" if not in contacts
  ///   - "View Full Profile" if already in contacts
  /// - Handles errors gracefully with user-friendly messages
  void _showContactInfo() async {
    try {
      // Show loading indicator while fetching user details
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: context.colorScheme.primary),
        ),
      );

      // Verify ChatListController is available
      if (!Get.isRegistered<ChatListController>()) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load user details')),
        );
        return;
      }

      final chatListController = Get.find<ChatListController>();

      // Fetch full user details from Firestore
      final fullUserDetails = await chatListController.getUserDetails(
        widget.contact.uid,
      );
      final user =
          fullUserDetails ??
          widget.contact; // Fallback to passed contact if fetch fails

      // Check if user is in contacts
      final isInContacts = await chatListController.isUserInContacts(user.uid);

      if (!mounted) {
        Navigator.pop(context); // Close loading
        return;
      }

      // Close loading indicator
      Navigator.pop(context);

      // Show contact info modal
      showModalBottomSheet(
        context: context,
        backgroundColor: context.colorScheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final photoUrl = user.photoUrl;
          final name = user.displayName ?? 'Unknown';
          final email = user.email;
          final phone = user.phoneNumber;

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: context.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: context.colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        phone,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Divider(),
                  if (email.isNotEmpty)
                    ListTile(
                      leading: Icon(
                        Icons.email_outlined,
                        color: context.colorScheme.primary,
                      ),
                      title: const Text('Email'),
                      subtitle: Text(email),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (phone != null && phone.isNotEmpty)
                    ListTile(
                      leading: Icon(
                        Icons.phone_outlined,
                        color: context.colorScheme.primary,
                      ),
                      title: const Text('Phone'),
                      subtitle: Text(phone),
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 24),
                  // Show different button based on contact status
                  if (!isInContacts)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            Navigator.pop(context);

                            // Check if ContactsController is available
                            if (!Get.isRegistered<ContactsController>()) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Contacts feature not available',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            // Add to contacts
                            final contactsController =
                                Get.find<ContactsController>();

                            // Pre-fill the contact info
                            if (email.isNotEmpty) {
                              contactsController.textInputType.value =
                                  TextInputType.emailAddress;
                              contactsController.contactInfoController.text =
                                  email;
                            } else if (phone != null && phone.isNotEmpty) {
                              contactsController.textInputType.value =
                                  TextInputType.numberWithOptions();
                              contactsController.contactInfoController.text =
                                  phone;
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No contact information available',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            contactsController.nameController.text = name;

                            // Add contact directly
                            final success = await contactsController.addContact(
                              context,
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$name added to contacts'),
                                  backgroundColor: context.colorScheme.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to add contact: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add to Contacts'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: context.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Full profile not implemented yet'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: context.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View Full Profile'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Close loading if it's still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contact details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows more options bottom sheet
  ///
  /// Options include:
  /// - Search in chat
  /// - Mute/Unmute notifications
  /// - Change wallpaper
  /// - Block user (destructive)
  /// - Report user (destructive)
  /// - Clear chat (destructive)
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.icon.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(
                context,
                icon: Icons.search,
                label: 'Search',
                onTap: () {
                  context.pop();
                  _showSearchDialog();
                },
              ),
              _buildOption(
                context,
                icon: widget.controller.isMuted.value
                    ? Icons.notifications_off
                    : Icons.notifications_active,
                label: widget.controller.isMuted.value
                    ? 'Unmute Notifications'
                    : 'Mute Notifications',
                onTap: () {
                  context.pop();
                  _toggleMuteNotifications();
                },
              ),
              _buildOption(
                context,
                icon: Icons.wallpaper,
                label: 'Wallpaper',
                onTap: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wallpaper not implemented yet'),
                    ),
                  );
                },
              ),
              Divider(color: context.colorScheme.divider),
              _buildOption(
                context,
                icon: Icons.block,
                label: 'Block User',
                isDestructive: true,
                onTap: () {
                  context.pop();
                  _showBlockConfirmation();
                },
              ),
              _buildOption(
                context,
                icon: Icons.report_problem_outlined,
                label: 'Report User',
                isDestructive: true,
                onTap: () {
                  context.pop();
                  _showReportDialog();
                },
              ),
              _buildOption(
                context,
                icon: Icons.delete_outline,
                label: 'Clear Chat',
                isDestructive: true,
                onTap: () {
                  context.pop();
                  _showClearChatConfirmation();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Builds a single option item for the more options menu
  ///
  /// Parameters:
  /// - [icon]: Icon to display
  /// - [label]: Text label for the option
  /// - [onTap]: Callback when option is tapped
  /// - [isDestructive]: If true, displays in error color (red)
  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? context.colorScheme.error
        : context.colorScheme.textPrimary;
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? color : context.colorScheme.icon,
      ),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      visualDensity: VisualDensity.compact,
    );
  }

  /// Shows confirmation dialog before blocking a user
  /// Calls controller.blockUser() and navigates back to chat list on confirm
  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        title: Text(
          'Block User',
          style: TextStyle(color: context.colorScheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to block this user? They will not be able to send you messages.',
          style: TextStyle(color: context.colorScheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorScheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              widget.controller.blockUser();
              context.pop(); // Go back to chat list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  /// Shows report user dialog (not yet implemented)
  /// TODO: Implement user reporting functionality
  void _showReportDialog() {
    // Implement report dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report not implemented yet')));
  }

  /// Shows search dialog for searching messages in the current chat
  /// Calls controller.searchMessages() as user types
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colorScheme.surface,
          title: Text(
            'Search in Chat',
            style: TextStyle(color: context.colorScheme.textPrimary),
          ),
          content: TextField(
            style: TextStyle(color: context.colorScheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search messages...',
              hintStyle: TextStyle(color: context.colorScheme.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.colorScheme.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.colorScheme.primary),
              ),
            ),
            onChanged: (query) {
              widget.controller.searchMessages(query);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colorScheme.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Toggles mute/unmute notifications for this chat
  /// Shows a snackbar confirming the action
  void _toggleMuteNotifications() {
    widget.controller.toggleMuteNotifications();
    Get.snackbar(
      'Notifications',
      widget.controller.isMuted.value ? 'Muted' : 'Unmute',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.colorScheme.surface,
      colorText: context.colorScheme.textPrimary,
    );
  }

  /// Shows confirmation dialog before clearing all chat messages
  /// This action cannot be undone
  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        title: Text(
          'Clear Chat',
          style: TextStyle(color: context.colorScheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
          style: TextStyle(color: context.colorScheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorScheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              widget.controller.clearChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Shows delete confirmation dialog for selected messages
  ///
  /// Provides two delete options:
  /// - "Delete for Me": Removes messages only for current user
  /// - "Delete for Everyone": Removes messages for all participants (only if all selected messages are sent by current user)
  void _showDeleteConfirmation() {
    final selectedIds = widget.controller.selectedMessages;
    final messages = widget.controller.messages
        .where((m) => selectedIds.contains(m.id))
        .toList();

    // Check if all selected messages are sent by current user
    // Only show "Delete for Everyone" option if true
    final isAllMe = messages.every(
      (m) => m.senderId == widget.controller.authUsecase.currentUid,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        title: Text(
          'Delete ${messages.length} Message${messages.length == 1 ? "" : "s"}?',
          style: TextStyle(color: context.colorScheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete these messages?',
          style: TextStyle(color: context.colorScheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorScheme.textSecondary),
            ),
          ),
          if (isAllMe)
            TextButton(
              onPressed: () {
                context.pop();
                widget.controller.deleteSelectedMessagesForEveryone();
              },
              child: const Text(
                'Delete for Everyone',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () {
              context.pop();
              widget.controller.deleteSelectedMessagesForMe();
            },
            child: const Text(
              'Delete for Me',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
