import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/validator/form_validator.dart';
import 'package:chat_kare/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileForm extends StatelessWidget {
  final ProfileController controller;

  const ProfileForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Personal Information'),
            const SizedBox(height: 16),
            Obx(
              () => AppTextFormField(
                controller: controller.nameController,
                label: 'Display Name',
                hint: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
                enabled: controller.isEditMode,
                validator: (value) => FormValidator.validateName(value ?? ''),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => AppTextFormField(
                controller: controller.phoneController,
                label: 'Phone Number',
                hint: '9876543210',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: controller.isEditMode,
                validator: (value) =>
                    FormValidator.validatePhoneNumber(value ?? ''),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final email = controller.currentUser?.email ?? '';
              return TextFormField(
                initialValue: email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  enabled: false,
                ),
              );
            }),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Status'),
            const SizedBox(height: 16),
            Obx(
              () => AppTextFormField(
                controller: controller.statusController,
                label: 'Status Message',
                hint: 'Hey there! I am using Chat Kare',
                prefixIcon: const Icon(Icons.info_outline),
                maxLines: 2,
                enabled: controller.isEditMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: context.colorScheme.textPrimary,
      ),
    );
  }
}
