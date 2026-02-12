import 'package:flutter/material.dart';

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  // Brand colors
  final Color primary;
  final Color secondary;
  final Color accent;

  // Surface colors
  final Color background;
  final Color foreground;
  final Color surface;
  final Color card;

  // UI element colors
  final Color border;
  final Color divider;
  final Color icon;
  final Color disabled;
  final Color shadow;
  final Color overlay;
  final Color badge;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;

  // Semantic colors
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.surface,
    required this.card,
    required this.border,
    required this.divider,
    required this.icon,
    required this.disabled,
    required this.shadow,
    required this.overlay,
    required this.badge,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  // Factory constructor for light theme
  factory AppColorScheme.light() {
    return const AppColorScheme(
      primary: Color(0xFF0050F5),
      secondary: Color(0xFF8B5CF6),
      accent: Color(0xFF06B6D4),
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF000000),
      surface: Color(0xFFF9FAFB),
      card: Color(0xFFFFFFFF),
      border: Color(0xFFE5E7EB),
      divider: Color(0xFFF3F4F6),
      icon: Color(0xFF4B5563),
      disabled: Color(0xFF9CA3AF),
      shadow: Color(0x1A000000),
      overlay: Color(0x0D000000),
      badge: Color(0xFFEF4444),
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      success: Color(0xFF22C55E),
      warning: Color(0xFFF59E0B),
      error: Color(0xFFEF4444),
      info: Color(0xFF3B82F6),
    );
  }

  // Factory constructor for dark theme
  factory AppColorScheme.dark() {
    return const AppColorScheme(
      primary: Color(0xFF0050F5),
      secondary: Color(0xFF8B5CF6),
      accent: Color(0xFF06B6D4),
      background: Color(0xFF0F172A),
      foreground: Color(0xFFFFFFFF),
      surface: Color(0xFF1E293B),
      card: Color(0xFF334155),
      border: Color(0xFF475569),
      divider: Color(0xFF334155),
      icon: Color(0xFFCBD5E1),
      disabled: Color(0xFF64748B),
      shadow: Color(0x33000000),
      overlay: Color(0x1AFFFFFF),
      badge: Color(0xFFF87171),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      success: Color(0xFF22C55E),
      warning: Color(0xFFF59E0B),
      error: Color(0xFFEF4444),
      info: Color(0xFF3B82F6),
    );
  }

  @override
  AppColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? foreground,
    Color? surface,
    Color? card,
    Color? border,
    Color? divider,
    Color? icon,
    Color? disabled,
    Color? shadow,
    Color? overlay,
    Color? badge,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      icon: icon ?? this.icon,
      disabled: disabled ?? this.disabled,
      shadow: shadow ?? this.shadow,
      overlay: overlay ?? this.overlay,
      badge: badge ?? this.badge,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
