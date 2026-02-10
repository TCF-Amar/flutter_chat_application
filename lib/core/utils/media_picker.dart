import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MediaPicker {
  MediaPicker._();
  static final MediaPicker instance = MediaPicker._();

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickMedia() async {
    final XFile? media = await _picker.pickMedia();
    if (media != null) {
      return File(media.path);
    }
    return null;
  }

  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<File?> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      return File(video.path);
    }
    return null;
  }

  Future<File?> pickVideoFromCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      return File(video.path);
    }
    return null;
  }

  Future<List<File>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      return images.map((image) => File(image.path)).toList();
    }
    return [];
  }

  // pick document
  Future<File?> pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
