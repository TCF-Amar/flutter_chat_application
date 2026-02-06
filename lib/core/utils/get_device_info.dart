import 'dart:io';

import 'package:chat_kare/features/auth/data/models/device_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<DeviceModel> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();
  final packageInfo = await PackageInfo.fromPlatform();

  if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    return DeviceModel(
      platform: 'android',
      deviceId: android.id,
      deviceModel: android.model,
      appVersion: packageInfo.version,
    );
  } else if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    return DeviceModel(
      platform: 'ios',
      deviceId: ios.identifierForVendor!,
      deviceModel: ios.utsname.machine,
      appVersion: packageInfo.version,
    );
  } else {
    return DeviceModel(
      platform: 'web',
      deviceId: 'web',
      deviceModel: 'browser',
      appVersion: packageInfo.version,
    );
  }
}
