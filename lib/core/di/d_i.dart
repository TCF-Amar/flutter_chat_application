import 'package:chat_kare/core/di/core_di.dart';
import 'package:chat_kare/features/auth/presentation/bindings/auth_binding.dart';
import 'package:chat_kare/features/contacts/presentation/bindings/contacts_binding.dart';
import 'package:chat_kare/features/home/presentation/bindings/home_binding.dart';
import 'package:chat_kare/features/profile/presentation/bindings/profile_binding.dart';
import 'package:logger/logger.dart';

class DI {
  static final DI instance = DI._();
  DI._();
  final log = Logger();

  Future<void> init() async {
    await _initCoreDependencies();
    await _initFeaturesDependencies();
  }

  Future<void> _initCoreDependencies() async {
    await CoreDi.instance.init();
  }

  Future<void> _initFeaturesDependencies() async {
    await AuthBinding.init();
    await HomeBinding.init();
    await ContactsBinding.init();
    await ProfileBinding.init();
  }
}
