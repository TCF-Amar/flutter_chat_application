import 'package:flutter/material.dart';
import 'package:chat_kare/core/constants/app_fonts.dart';
import 'package:chat_kare/core/constants/colors/app_color_scheme.dart';
import 'package:chat_kare/core/constants/colors/app_colors.dart';
import 'package:chat_kare/core/constants/colors/app_size.dart';
import 'package:chat_kare/core/constants/colors/app_text_colors.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      cardTheme: const CardThemeData(color: AppColors.cardLight),

      fontFamily: AppFonts.primary,
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.textLight,
        displayColor: AppColors.textLight,
        fontFamily: AppFonts.primary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundLight,
        ),
      ),
      extensions: const [
        AppTextColors(
          primary: AppColors.textLight,
          secondary: AppColors.textSecondaryLight,
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          link: AppColors.info,
          white: AppColors.backgroundLight,
          black: AppColors.foregroundLight,
        ),
        AppColorScheme(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          accent: AppColors.accent,
          background: AppColors.backgroundLight,
          foreground: AppColors.foregroundLight,
          surface: AppColors.surfaceLight,
          card: AppColors.cardLight,
          border: AppColors.borderLight,
          divider: AppColors.dividerLight,

          icon: AppColors.iconLight,
          disabled: AppColors.disabledLight,
          shadow: AppColors.shadowLight,
          overlay: AppColors.overlayLight,
          badge: AppColors.badgeLight,
          textPrimary: AppColors.textLight,
          textSecondary: AppColors.textSecondaryLight,
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          info: AppColors.info,
        ),
        AppSizes(xs: 4.0, sm: 8.0, md: 16.0, lg: 24.0, xl: 32.0, radius: 12.0),
      ],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      cardTheme: const CardThemeData(color: AppColors.cardDark),

      fontFamily: AppFonts.primary,
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
        fontFamily: AppFonts.primary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
      ),
      extensions: const [
        AppTextColors(
          primary: AppColors.textDark,
          secondary: AppColors.textSecondaryDark,
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          link: AppColors.info,
          white: AppColors.backgroundLight,
          black: AppColors.foregroundLight,
        ),
        AppColorScheme(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          accent: AppColors.accent,
          foreground: AppColors.foregroundDark,
          background: AppColors.backgroundDark,
          surface: AppColors.surfaceDark,
          card: AppColors.cardDark,
          border: AppColors.borderDark,
          divider: AppColors.dividerDark,
          icon: AppColors.iconDark,
          disabled: AppColors.disabledDark,
          shadow: AppColors.shadowDark,
          overlay: AppColors.overlayDark,
          badge: AppColors.badgeDark,
          textPrimary: AppColors.textDark,
          textSecondary: AppColors.textSecondaryDark,
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          info: AppColors.info,
        ),
        AppSizes(xs: 4.0, sm: 8.0, md: 16.0, lg: 24.0, xl: 32.0, radius: 12.0),
      ],
    );
  }
}
