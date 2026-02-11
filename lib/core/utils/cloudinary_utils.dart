import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

class CloudinaryUtils {
  static const String uploadPreset = "ml_default";
  static const String cloudName =
      "dnhvzcxfw"; // Replace with your actual cloud name
  static final Logger _log = Logger();

  static Future<String?> uploadFile({
    required File file,
    bool isVideo = false,
  }) async {
    try {
      path.basename(file.path);
      final resourceType = isVideo ? 'video' : 'image';

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = isVideo ? "chat_videos" : "chat_images"
        // ..fields['public_id'] = fileName.split('.').first // Optional: let Cloudinary generate ID or handle collisions
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log.i("Upload success: $data");
        return data['url'];
      } else {
        _log.e("Upload failed with status: ${response.statusCode}");
        _log.e("Response body: ${response.body}");
        return null;
      }
    } catch (e, s) {
      _log.e("Cloudinary upload failed", error: e, stackTrace: s);
      return null;
    }
  }
}

enum ResourceType { image, video }
