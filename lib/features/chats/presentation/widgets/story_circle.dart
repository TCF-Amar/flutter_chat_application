import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class StoryCircle extends StatelessWidget {
  final String name;
  final bool isCreate;

  const StoryCircle({super.key, required this.name, this.isCreate = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StoryAvatar(context),
          const SizedBox(height: 6),
          AppText(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _StoryAvatar(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCreate
            ? null
            : LinearGradient(
                colors: [
                  context.colorScheme.primary,
                  context.colorScheme.secondary,
                ],
              ),
        color: isCreate ? context.colorScheme.success : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.background,
          ),
          child: isCreate
              ? Icon(Icons.add, size: 28, color: context.colorScheme.primary)
              : null,
        ),
      ),
    );
  }
}
