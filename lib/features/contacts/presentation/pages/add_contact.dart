import 'package:chat_kare/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class AddContact extends StatelessWidget {
  const AddContact({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ContactsController>();
    return AppScaffold(
      appBar: DefaultAppBar(title: "Add Contact"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              AppTextFormField(
                prefixIcon: Icon(Icons.person),
                controller: controller.nameController,
                hint: "Name",
                label: "Name",
              ),
              SizedBox(height: 20),
              Obx(
                () => AppTextFormField(
                  controller: controller.contactInfoController,
                  focusNode: controller.contactInfoFocusNode,
                  prefixIcon:
                      controller.textInputType.value ==
                          TextInputType.emailAddress
                      ? Icon(Icons.alternate_email)
                      : Icon(Icons.numbers),
                  hint:
                      controller.textInputType.value ==
                          TextInputType.emailAddress
                      ? "Email"
                      : "Phone Number",
                  keyboardType: controller.textInputType.value,
                  suffixIcon: IconButton(
                    icon:
                        controller.textInputType.value ==
                            TextInputType.emailAddress
                        ? Icon(Icons.keyboard_alt)
                        : Icon(Icons.phone_android),
                    onPressed: () {
                      controller.toggleInputType();
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              AppButton(
                onPressed: () {
                  context.pop();
                },
                child: AppText("Add Contact"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
