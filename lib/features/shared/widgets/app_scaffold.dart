import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;

  // Layout
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;

  // UI Control
  final bool safeArea;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;

  // Behavior
  final bool resizeToAvoidBottomInset;
  final bool scrollable;

  // State
  final bool isLoading;
  final Widget? loadingWidget;

  // System UI
  final SystemUiOverlayStyle? statusBarStyle;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.safeArea = true,
    this.padding,
    this.backgroundColor,
    this.backgroundGradient,
    this.resizeToAvoidBottomInset = true,
    this.scrollable = false,
    this.isLoading = false,
    this.loadingWidget,
    this.statusBarStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    // Scroll handling
    if (scrollable) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      );
    }

    // Padding
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    // SafeArea
    if (safeArea) {
      content = SafeArea(child: content);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          statusBarStyle ??
          SystemUiOverlayStyle(
            statusBarColor: context.colorScheme.background,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            appBar:
                appBar ??
                AppBar(
                  toolbarHeight: 0,
                  backgroundColor: context.colorScheme.background,
                  elevation: 0,
                  systemOverlayStyle:
                      statusBarStyle ??
                      SystemUiOverlayStyle(
                        statusBarColor: context.colorScheme.background,
                        statusBarIconBrightness: isDark
                            ? Brightness.light
                            : Brightness.dark,
                        statusBarBrightness: isDark
                            ? Brightness.dark
                            : Brightness.light,
                      ),
                ),
            drawer: drawer,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            backgroundColor: backgroundColor ?? context.colorScheme.background,
            body: Container(
              decoration: BoxDecoration(
                color: backgroundGradient == null
                    ? (backgroundColor ?? context.colorScheme.background)
                    : null,
                gradient: backgroundGradient,
              ),
              child: content,
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: context.colorScheme.background.withOpacity(0.8),
                alignment: Alignment.center,
                child: loadingWidget ?? const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
