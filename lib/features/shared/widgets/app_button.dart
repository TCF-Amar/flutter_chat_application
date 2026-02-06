import 'package:chat_kare/core/constants/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppButtonType { filled, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 48,
    this.radius = 12,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.disabledColor,
    this.icon,
    this.type = AppButtonType.filled,
    this.gradient,
    this.elevation = 0,
    this.textStyle,
    this.enableHaptic = true,
  });

  final VoidCallback? onPressed;
  final Widget child;

  final bool isLoading;
  final bool isEnabled;

  final double? width;
  final double height;
  final double radius;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? disabledColor;

  final Widget? icon;
  final AppButtonType type;
  final Gradient? gradient;
  final double elevation;

  final TextStyle? textStyle;
  final bool enableHaptic;

  bool get _isDisabled => !isEnabled || isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: (!_isDisabled && type == AppButtonType.filled)
                ? gradient
                : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ElevatedButton(
            onPressed: _isDisabled
                ? null
                : () {
                    if (enableHaptic) {
                      HapticFeedback.lightImpact();
                    }
                    onPressed?.call();
                  },
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(elevation),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return disabledColor ?? theme.disabledColor;
                }
                if (type == AppButtonType.text) return Colors.transparent;
                if (gradient != null) return Colors.transparent;
                return backgroundColor ?? AppColors.primary;
              }),
              foregroundColor: WidgetStateProperty.all(
                textColor ?? Colors.white,
              ),
              textStyle: WidgetStateProperty.all(
                textStyle ?? theme.textTheme.labelLarge,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                  side: type == AppButtonType.outlined
                      ? BorderSide(
                          color: borderColor ?? theme.colorScheme.primary,
                        )
                      : BorderSide.none,
                ),
              ),
            ),
            child: _buildChild(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? AppColors.borderDark,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon!, const SizedBox(width: 8), child],
      );
    }

    return child;
  }
}
