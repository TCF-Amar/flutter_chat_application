import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class AppSizes extends ThemeExtension<AppSizes> {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double radius;

  const AppSizes({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.radius,
  });

  @override
  AppSizes copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? radius,
  }) {
    return AppSizes(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      radius: radius ?? this.radius,
    );
  }

  @override
  AppSizes lerp(ThemeExtension<AppSizes>? other, double t) {
    if (other is! AppSizes) return this;
    return AppSizes(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
    );
  }
}
