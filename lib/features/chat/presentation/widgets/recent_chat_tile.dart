import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/data/models/chat_meta_data.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_list_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RecentChatTile extends StatelessWidget {
  final ChatMetaData chat;
  const RecentChatTile({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatListController>();
    return ListTile(
      onTap: () {
        final contact = controller.getContactFromChat(chat);
        context.pushNamed(AppRoutes.chat.name, extra: contact);
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.colorScheme.primary,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child:
              chat.receiverPhotoUrl != null && chat.receiverPhotoUrl!.isNotEmpty
              ? Image.network(
                  chat.receiverPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: context.colorScheme.surface,
                    );
                  },
                )
              : Icon(Icons.person, color: context.colorScheme.surface),
        ),
      ),
      title: AppText(
        chat.receiverName,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      subtitle: AppText(
        chat.lastMessage,
        fontSize: 12,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            DateFormat('hh:mm a').format(chat.lastMessageTime),
            fontSize: 12,
            color: context.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
