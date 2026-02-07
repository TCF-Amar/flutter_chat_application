import 'package:flutter/material.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String title;
  final Widget? titleWidget;
  final bool centerTitle;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? surfaceTintColor;

  const DefaultAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.surfaceTintColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? context.colorScheme.background,
      elevation: 0,
      surfaceTintColor: surfaceTintColor ?? context.colorScheme.background,
      title:
          titleWidget ??
          AppText(title, fontSize: 20, fontWeight: FontWeight.bold),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
