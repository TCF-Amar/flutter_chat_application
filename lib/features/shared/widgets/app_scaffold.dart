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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          statusBarStyle ??
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            appBar:
                appBar ??
                AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent),
            drawer: drawer,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,

            backgroundColor: backgroundGradient == null
                ? backgroundColor
                : Colors.transparent,
            body: Container(
              decoration: BoxDecoration(
                color: backgroundGradient == null ? backgroundColor : null,
                gradient: backgroundGradient,
              ),
              child: content,
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(128),
                alignment: Alignment.center,
                child: loadingWidget ?? const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
