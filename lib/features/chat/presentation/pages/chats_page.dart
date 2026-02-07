import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/presentation/widgets/chat_tiles.dart';
import 'package:chat_kare/features/chat/presentation/widgets/story_circle.dart';
import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:chat_kare/features/home/presentation/controllers/home_controller.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final contactsController = Get.find<ContactsController>();
    return AppScaffold(
      appBar: DefaultAppBar(
        title: "Messages",
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Get.find<AuthController>().signOut();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
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
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: contactsController.contacts.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final contact = contactsController.contacts[index];
                      return ChatTiles(contact: contact);
                    },
                  ),
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
