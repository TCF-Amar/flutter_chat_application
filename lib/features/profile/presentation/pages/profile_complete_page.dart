import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/auth/presentation/controllers/validator/form_validator.dart';
import 'package:chat_kare/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCompletePage extends GetView<ProfileController> {
  const ProfileCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return AppScaffold(
      appBar: const DefaultAppBar(title: "Complete Profile"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText(
                "Please complete your profile to continue.",
                fontSize: 16,
                textAlign: TextAlign.center,
              ),
              AppText(
                authController.currentUser?.email ?? "",
                fontSize: 16,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppTextFormField(
                controller: controller.nameController,
                label: "Display Name*",
                hint: "Enter your name",
                prefixIcon: const Icon(Icons.person),
                validator: (value) => FormValidator.validateName(value ?? ""),
              ),
              const SizedBox(height: 24),
              AppTextFormField(
                controller: controller.phoneController,
                hint: "9876543210",
                label: "Phone number*",
                maxLength: 10,
                prefixIcon: Icon(Icons.phone_android),
                keyboardType: TextInputType.numberWithOptions(),
                validator: (value) =>
                    FormValidator.validatePhoneNumber(value ?? ""),
              ),
              const SizedBox(height: 10),
              Obx(
                () => AppButton(
                  isLoading: controller.isLoading,
                  onPressed: controller.completeProfile,
                  child: const Text(
                    "Save & Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  authController.signOut();
                },
                child: Text("SignIn with another email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
