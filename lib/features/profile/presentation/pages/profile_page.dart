import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/auth/presentation/controllers/validator/form_validator.dart';
import 'package:chat_kare/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
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
              _buildProfilePhoto(context),
              const SizedBox(height: 32),
              _buildProfileForm(context),
              const SizedBox(height: 24),
              if (controller.isEditMode) ...[
                _buildSaveButton(context),
                const SizedBox(height: 16),
              ],
              _buildAccountSection(context, authController),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfilePhoto(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Obx(() {
            final photoUrl = controller.currentUser?.photoUrl;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: context.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: context.colorScheme.primary,
                      )
                    : null,
              ),
            );
          }),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: controller.updateProfilePhoto,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context) {
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

  Widget _buildAccountSection(
    BuildContext context,
    AuthController authController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Account'),
          const SizedBox(height: 16),
          _buildAccountOption(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            onTap: () {
              Get.snackbar(
                'Info',
                'Privacy settings coming soon',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),
          const Divider(),
          _buildAccountOption(
            context,
            icon: Icons.security_outlined,
            title: 'Security',
            onTap: () {
              Get.snackbar(
                'Info',
                'Security settings coming soon',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),
          const Divider(),
          _buildAccountOption(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Get.snackbar(
                'Info',
                'Help & Support coming soon',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),
          const Divider(),
          _buildAccountOption(
            context,
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: context.colorScheme.surface,
                  title: Text(
                    'Logout',
                    style: TextStyle(color: context.colorScheme.textPrimary),
                  ),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(color: context.colorScheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.pop();
                        authController.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? context.colorScheme.error
        : context.colorScheme.textPrimary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? color : context.colorScheme.icon,
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: context.colorScheme.icon),
      onTap: onTap,
    );
  }
}
