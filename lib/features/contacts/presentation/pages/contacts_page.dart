import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
// import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // appBar: DefaultAppBar(title: "Contacts"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppTextFormField(
              controller: TextEditingController(),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
