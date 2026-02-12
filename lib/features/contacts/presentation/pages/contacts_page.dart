import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/core/services/firebase_services.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_snackbar.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ContactsController>();
    final fs = Get.find<FirebaseServices>();
    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshContacts();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: AppTextFormField(
                controller: controller.searchController,
                onChanged: (value) {
                  controller.findContacts();
                },
                hint: "Search",
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView(
                  children: [
                    ListTile(
                      onTap: () {
                        context.push(AppRoutes.addContact.path);
                      },
                      leading: CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.person_add_alt_1),
                      ),
                      title: const AppText("New Contact"),
                    ),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (controller.contacts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: AppText("No contacts yet")),
                        );
                      }
                      final contacts = controller.searchResults.isEmpty
                          ? controller.contacts
                          : controller.searchResults;
                      return Column(
                        children: [
                          ...contacts.map((contact) {
                            // first show owner contact

                            return GestureDetector(
                              onDoubleTap: () => AppSnackbar.success(
                                message: 'Contact selected',
                              ),
                              onLongPressUp: () =>
                                  AppSnackbar.success(message: 'Contact long'),
                              child: ListTile(
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const AppText("Delete Contact"),
                                        content: const AppText(
                                          "Are you sure you want to delete this contact?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              context.pop();
                                            },
                                            child: const AppText("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              controller.deleteContact();
                                              context.pop();
                                            },
                                            child: const AppText("Delete"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onTap: () {
                                  context.push(
                                    AppRoutes.chat.path,
                                    extra: contact,
                                  );
                                  // AppSnackbar.success(
                                  //   message: 'Contact tapped',
                                  // );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: context.colorScheme.primary,
                                  radius: 24,
                                  backgroundImage:
                                      contact.photoUrl != null &&
                                          contact.photoUrl!.isNotEmpty
                                      ? NetworkImage(contact.photoUrl!)
                                      : null,
                                  child:
                                      contact.photoUrl == null ||
                                          contact.photoUrl!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    AppText(contact.displayName.toString()),
                                    if (fs.currentUser?.uid == contact.uid)
                                      const AppText(
                                        " (You)",
                                        color: Colors.grey,
                                      ),
                                  ],
                                ),
                                subtitle:
                                    (contact.email.isNotEmpty ||
                                        contact.phoneNumber != null)
                                    ? AppText(
                                        contact.phoneNumber != null
                                            ? contact.phoneNumber!
                                            : contact.email,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
