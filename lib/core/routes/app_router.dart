import 'package:chat_kare/core/services/auth_state_notifier.dart';

import 'package:chat_kare/features/chat/presentation/pages/chat_page.dart';
import 'package:chat_kare/features/contacts/domain/entities/contacts_entity.dart';
import 'package:chat_kare/features/profile/presentation/pages/profile_complete_page.dart';
import 'package:chat_kare/features/auth/presentation/pages/signin_page.dart';
import 'package:chat_kare/features/auth/presentation/pages/signup_page.dart';
import 'package:chat_kare/features/contacts/presentation/pages/add_contact.dart';
import 'package:chat_kare/features/home/presentation/pages/home_page.dart';
import 'package:chat_kare/features/shared/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_controller.dart';
import 'package:get/get.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final AppRouter instance = AppRouter._();
  AppRouter._();

  late final GoRouter router;

  void init(AuthStateNotifier authStateNotifier) {
    router = GoRouter(
      initialLocation: AppRoutes.splash.path,
      navigatorKey: navigatorKey,
      refreshListenable: authStateNotifier,
      redirect: (context, state) {
        final isAuthenticated = authStateNotifier.isAuthenticated;
        final isProfileCompleted = authStateNotifier.isProfileCompleted;
        final currentPath = state.matchedLocation;

        // If not authenticated and trying to access protected routes
        if (!isAuthenticated) {
          if (currentPath == AppRoutes.signin.path ||
              currentPath == AppRoutes.signup.path) {
            return null;
          }
          return AppRoutes.signin.path;
        }

        // If authenticated
        if (isAuthenticated) {
          // If profile NOT completed
          if (!isProfileCompleted) {
            // Allow user to stay on profile complete page
            if (currentPath == AppRoutes.profileComplete.path) {
              return AppRoutes.profileComplete.path;
            }
            // Redirect to profile complete page
            return AppRoutes.profileComplete.path;
          }

          // If profile IS completed
          if (isProfileCompleted) {
            // Prevent access to signin/signup
            if (currentPath == AppRoutes.signin.path ||
                currentPath == AppRoutes.signup.path ||
                currentPath == AppRoutes.profileComplete.path) {
              return AppRoutes.home.path;
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          name: AppRoutes.splash.name,
          path: AppRoutes.splash.path,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          name: AppRoutes.signin.name,
          path: AppRoutes.signin.path,
          builder: (context, state) => const SigninPage(),
        ),
        GoRoute(
          name: AppRoutes.signup.name,
          path: AppRoutes.signup.path,
          builder: (context, state) => const SignupPage(),
        ),
        GoRoute(
          name: AppRoutes.home.name,
          path: AppRoutes.home.path,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          name: AppRoutes.addContact.name,
          path: AppRoutes.addContact.path,
          builder: (context, state) => const AddContact(),
        ),
        GoRoute(
          name: AppRoutes.profileComplete.name,
          path: AppRoutes.profileComplete.path,
          builder: (context, state) => const ProfileCompletePage(),
        ),
        GoRoute(
          name: AppRoutes.chat.name,
          path: AppRoutes.chat.path,
          builder: (context, state) {
            final contact = state.extra as ContactsEntity;
            Get.lazyPut(
              () => ChatController(
                contact: contact,
                authStateNotifier: Get.find(),
              ),
            );
            return ChatPage(contact: contact);
          },
        ),
      ],
    );
  }
}
