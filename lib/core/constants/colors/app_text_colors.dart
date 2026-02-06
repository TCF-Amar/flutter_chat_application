import 'package:flutter/material.dart';

@immutable
class AppTextColors extends ThemeExtension<AppTextColors> {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color link;
  final Color white;
  final Color black;

  const AppTextColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.link,
    required this.white,
    required this.black,
  });

  @override
  AppTextColors copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? link,
    Color? white,
    Color? black,
  }) {
    return AppTextColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      link: link ?? this.link,
      white: white ?? this.white,
      black: black ?? this.black,
    );
  }

  @override
  AppTextColors lerp(ThemeExtension<AppTextColors>? other, double t) {
    if (other is! AppTextColors) return this;
    return AppTextColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      link: Color.lerp(link, other.link, t)!,
      white: Colors.white,
      black: Colors.black,
    );
  }
}
