import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ChatTiles extends StatelessWidget {
  const ChatTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.colorScheme.primary,
        child: const Icon(Icons.person),
      ),
      title: const AppText("Chat", fontSize: 16, fontWeight: FontWeight.w600),
      subtitle: const AppText(
        "Subtitle",
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
