import 'dart:io';

import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class CloudinaryUtils {
  static const String uploadPreset = "ml_default";

  static Future<String?> upload(File file) async {
    Cloudinary cloud = Cloudinary.fromCloudName(cloudName: "dnhvzcxfw");
    final response = await cloud.uploader().upload(
      file,
      params: UploadParams(uploadPreset: uploadPreset),
    );
    print(response?.data);
    return response?.data?.secureUrl;
  }
}
