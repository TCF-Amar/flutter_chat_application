import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/presentation/widgets/story_circle.dart';
import 'package:chat_kare/features/chat/presentation/controllers/chat_list_controller.dart';
import 'package:chat_kare/features/chat/presentation/widgets/recent_chat_tile.dart';
import 'package:chat_kare/features/home/presentation/controllers/home_controller.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final chatListController = Get.find<ChatListController>();
    return AppScaffold(
      appBar: DefaultAppBar(
        title: "Messages",
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Get.find<AuthController>().signOut(),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );
              } else if (value == 'profile') {
                context.pushNamed(AppRoutes.profile.name);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                const PopupMenuItem(
                  value: 'new_group',
                  child: Text('New Group'),
                ),
                const PopupMenuItem(
                  value: 'new_broadcast',
                  child: Text('New Broadcast'),
                ),
                const PopupMenuItem(
                  value: 'linked_devices',
                  child: Text('Linked Devices'),
                ),
                const PopupMenuItem(
                  value: 'starred_messages',
                  child: Text('Starred Messages'),
                ),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "fab1",
            onPressed: () {},
            backgroundColor: context.colorScheme.primary,
            child: const Icon(Icons.add_a_photo),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "fab2",
            onPressed: () {
              controller.pageController.jumpToPage(3);
            },
            backgroundColor: context.colorScheme.primary,
            child: const Icon(Icons.add_comment),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    "Stories",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _AddStoryCircle();
                        }
                        return StoryCircle(name: 'name $index');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const AppText(
                      "Chats",
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Obx(() {
                    if (chatListController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (chatListController.chats.isEmpty) {
                      return const Center(child: AppText("No recent chats"));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: chatListController.chats.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final chat = chatListController.chats[index];
                        return RecentChatTile(chat: chat);
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStoryCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.primary,
      ),
      child: Icon(Icons.add, size: 28, color: context.colorScheme.surface),
    );
  }
}
