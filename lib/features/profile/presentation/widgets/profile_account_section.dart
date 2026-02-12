import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileAccountSection extends StatelessWidget {
  final AuthController authController;

  const ProfileAccountSection({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
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
             
            },
          ),
          const Divider(),
          _buildAccountOption(
            context,
            icon: Icons.security_outlined,
            title: 'Security',
            onTap: () {
            
            },
          ),
          const Divider(),
          _buildAccountOption(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
             
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
