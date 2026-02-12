import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/chat/presentation/pages/main_page.dart';
import 'package:chat_kare/features/contacts/presentation/pages/contacts_page.dart';
import 'package:chat_kare/features/home/presentation/controllers/home_controller.dart';
import 'package:chat_kare/features/notifications/presentation/pages/notifications_page.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final authController = Get.find<AuthController>();
    final List<Widget> pages = [
      MainPage(),
      NotificationsPage(),
      const Center(child: Text("Calls")),
      ContactsPage(),
    ];
    return Obx(
      () => AppScaffold(
        appBar: AppBar(
          backgroundColor: context.colorScheme.surface,
          toolbarHeight: 40,
          title: Obx(() {
            final user = authController.currentUser;
            final status = user?.status ?? '';
            final isOnline = status.toLowerCase() == 'online';

            return Row(
              children: [
                // Status indicator dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                // Status text
                if (status.isNotEmpty)
                  AppText(
                    status.capitalize ?? status,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
              ],
            );
          }),
        ),
        body: PageView(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: context.colorScheme.surface.withValues(alpha: 0.2),
          elevation: 0,
          surfaceTintColor: context.colorScheme.background,
          selectedIndex: controller.currentIndex.value,
          indicatorColor: context.colorScheme.primary.withValues(alpha: 0.5),

          onDestinationSelected: controller.onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              label: "Chats",
              selectedIcon: Icon(Icons.chat),
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none),
              label: "Notifications",
              selectedIcon: Icon(Icons.notifications),
            ),
            NavigationDestination(
              icon: Icon(Icons.call_outlined),
              label: "Calls",
              selectedIcon: Icon(Icons.call),
            ),

            NavigationDestination(icon: Icon(Icons.group), label: "Contacts"),
          ],
        ),
      ),
    );
  }
}
