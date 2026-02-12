import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chat_kare/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:chat_kare/features/profile/presentation/widgets/profile_form.dart';
import 'package:chat_kare/features/profile/presentation/widgets/profile_header.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colorScheme.icon),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: context.colorScheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isEditMode ? Icons.close : Icons.edit,
                color: context.colorScheme.icon,
              ),
              onPressed: controller.toggleEditMode,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              ProfileHeader(controller: controller),
              const SizedBox(height: 32),
              ProfileForm(controller: controller),
              const SizedBox(height: 24),
              if (controller.isEditMode) ...[
                _buildSaveButton(context),
                const SizedBox(height: 16),
              ],
              ProfileAccountSection(authController: authController),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(
        () => AppButton(
          isLoading: controller.isLoading,
          onPressed: controller.updateProfile,
          child: const Text(
            'Save Changes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
