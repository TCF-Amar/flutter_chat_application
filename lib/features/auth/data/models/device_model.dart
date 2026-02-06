
class DeviceModel {
  final String platform;
  final String deviceId;
  final String deviceModel;
  final String appVersion;

  DeviceModel({
    required this.platform,
    required this.deviceId,
    required this.deviceModel,
    required this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'appVersion': appVersion,
    };
  }
}
