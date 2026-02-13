import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CloudinaryUtils {
  static const String uploadPreset = "ml_default";
  static const String cloudName =
      "dnhvzcxfw"; // Replace with your actual cloud name
  static final Logger _log = Logger();

  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    bool isVideo = false,
    String? resourceType, // 'image', 'video', 'raw', 'auto'
    Function(double)? onProgress,
  }) async {
    try {
      final rType = resourceType ?? (isVideo ? 'video' : 'image');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$rType/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = isVideo
            ? "chat_videos"
            : (rType == 'raw' ? "chat_docs" : "chat_images")
        // ..fields['public_id'] = fileName.split('.').first // Optional: let Cloudinary generate ID or handle collisions
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();

      // Track upload progress
      int totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      List<int> responseBytes = [];
      await for (var chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0 && onProgress != null) {
          double progress = receivedBytes / totalBytes;
          onProgress(progress);
        }
      }

      final responseBody = String.fromCharCodes(responseBytes);

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        _log.i("Upload success: $data");
        return {'success': true, 'url': data['url']};
      } else {
        _log.e("Upload failed with status: ${streamedResponse.statusCode}");
        _log.e("Response body: $responseBody");
        return {
          'success': false,
          'error': 'Upload failed with status ${streamedResponse.statusCode}',
        };
      }
    } catch (e, s) {
      _log.e("Cloudinary upload failed", error: e, stackTrace: s);
      return {'success': false, 'error': e.toString()};
    }
  }
}

enum ResourceType { image, video }
