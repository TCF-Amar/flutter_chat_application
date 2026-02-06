import 'package:flutter/material.dart';

import 'package:chat_kare/core/constants/colors/app_color_scheme.dart';
import 'package:chat_kare/core/constants/colors/app_size.dart';
import 'package:chat_kare/core/constants/colors/app_text_colors.dart';

/// Extension to easily access theme extensions from BuildContext
extension ThemeExtensions on BuildContext {
  /// Access the app's color scheme
  AppColorScheme get colorScheme {
    return Theme.of(this).extension<AppColorScheme>()!;
  }

  /// Access the app's sizes
  AppSizes get sizes {
    return Theme.of(this).extension<AppSizes>()!;
  }

  /// Access the app's text colors
  AppTextColors get textColors {
    return Theme.of(this).extension<AppTextColors>()!;
  }

  // screen hight
  double get screenHeight {
    return MediaQuery.of(this).size.height;
  }

  // screen width
  double get screenWidth {
    return MediaQuery.of(this).size.width;
  }
}
