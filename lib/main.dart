import 'package:chat_kare/core/di/d_i.dart';
import 'package:chat_kare/core/routes/app_router.dart';
import 'package:chat_kare/core/services/auth_state_notifier.dart';
import 'package:chat_kare/core/theme/app_theme.dart';
import 'package:chat_kare/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set the background messaging handler early on, as a named top-level function

  await DI.instance.init();

  // Initialize router with AuthStateNotifier
  final authStateNotifier = Get.find<AuthStateNotifier>();
  AppRouter.instance.init(authStateNotifier);

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: AppTheme.dark(),
      theme: AppTheme.light(),
      routeInformationParser: AppRouter.instance.router.routeInformationParser,
      routerDelegate: AppRouter.instance.router.routerDelegate,
      routeInformationProvider:
          AppRouter.instance.router.routeInformationProvider,
    );
  }
}
