import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText("Notifications Page"),
            Obx(
              () => AppButton(
                isLoading: authController.isLoading,
                onPressed: () {
                  authController.signOut();
                },
                child: Text("Click"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
