import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/auth/presentation/controllers/validator/form_validator.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                "Welcome Back",
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 4),
              AppText("Sign in to your account", fontSize: 16),
              const SizedBox(height: 4),
              AppText(
                "Let's start chatting",
                fontSize: 14,
                color: context.textColors.link,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      AppTextFormField(
                        controller: controller.signInEmailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        label: "Email",
                        validator: (value) =>
                            FormValidator.validateEmail(value!),
                      ),
                      const SizedBox(height: 16),
                      AppTextFormField(
                        controller: controller.signInPasswordController,
                        hint: 'Password',
                        keyboardType: TextInputType.visiblePassword,
                        label: "Password",
                        isPassword: true,
                        validator: (value) =>
                            FormValidator.validatePassword(value!),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => AppButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              controller.signIn();
                            }
                          },
                          isLoading: controller.isLoading,
                          child: const Text('Sign In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    const SizedBox(width: 8),
                    AppText("Or"),
                    const SizedBox(width: 8),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText("Don't have an account? "),
                  InkWell(
                    onTap: () {
                      controller.clear();
                      context.push(AppRoutes.signup.path);
                    },
                    child: AppText(
                      "Sign Up",
                      fontWeight: FontWeight.bold,
                      color: context.textColors.link,
                    ),
                  ),
                  AppText("Or"),
                  InkWell(
                    onTap: () {
                      // controller.userExistsByPhone("8435876462");
                    },
                    child: AppText(
                      "Sign In with Phone",
                      fontWeight: FontWeight.bold,
                      color: context.textColors.link,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
