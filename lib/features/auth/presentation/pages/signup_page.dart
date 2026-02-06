import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chat_kare/features/auth/presentation/controllers/validator/form_validator.dart';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppText(
                  "Create Account",
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                AppText("Sign up to get started", fontSize: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // AppTextFormField(
                        //   controller: controller.signUpDisplayNameController,
                        //   hint: 'name',
                        //   label: 'Name',
                        //   prefixIcon: Icon(Icons.person),
                        //   keyboardType: TextInputType.name,

                        //   validator: (value) =>
                        //       FormValidator.validateName(value!),
                        // ),
                        // const SizedBox(height: 16),
                        AppTextFormField(
                          controller: controller.signUpEmailController,
                          hint: 'email',
                          label: 'Email',
                          prefixIcon: Icon(Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              FormValidator.validateEmail(value!),
                        ),
                        const SizedBox(height: 16),
                        AppTextFormField(
                          controller: controller.signUpPasswordController,
                          hint: 'password',
                          label: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          keyboardType: TextInputType.visiblePassword,
                          isPassword: true,
                          validator: (value) =>
                              FormValidator.validatePassword(value!),
                        ),
                        const SizedBox(height: 16),
                        AppTextFormField(
                          controller:
                              controller.signUpConfirmPasswordController,
                          hint: 'confirm password',
                          label: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock),
                          keyboardType: TextInputType.visiblePassword,
                          isPassword: true,
                          validator: (value) =>
                              FormValidator.validateConfirmPassword(
                                value!,
                                controller.signUpPasswordController.text,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => AppButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                controller.signUp();
                              }
                            },
                            isLoading: controller.isLoading,
                            child: const Text('Sign Up'),
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
                    AppText("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        context.pop();
                      },
                      child: AppText("Sign In", color: context.textColors.link),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
