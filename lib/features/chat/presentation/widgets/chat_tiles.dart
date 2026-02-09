import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatTiles extends StatelessWidget {
  final ContactsEntity contact;
  const ChatTiles({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        context.pushNamed(AppRoutes.chat.name, extra: contact);
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.colorScheme.primary,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: contact.photoUrl != null && contact.photoUrl!.isNotEmpty
              ? Image.network(
                  contact.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: context.colorScheme.primary,
                    );
                  },
                )
              : Icon(Icons.person, color: context.colorScheme.surface),
        ),
      ),
      title: AppText(contact.name, fontSize: 16, fontWeight: FontWeight.w600),
      subtitle: AppText(
        contact.phoneNumber ?? "",
        fontSize: 12,
        // fontWeight: FontWeight.w600,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText(
            "12:00 PM",
            fontSize: 12,
            color: context.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          Badge(
            label: Text('1', style: TextStyle(color: Colors.white)),
            backgroundColor: context.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
