import 'dart:io';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class MediaPicker {
  MediaPicker._();
  static final MediaPicker instance = MediaPicker._();
  final Logger _logger = Logger();

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

  Future<File?> pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<File?> cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Photo',
            toolbarColor: const Color(0xFF6750A4), // Primary color
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Edit Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      _logger.e('Error cropping image: $e');
      return null;
    }
    return null;
  }

  Future<File?> editImage(BuildContext context, File imageFile) async {
    try {
      final Uint8List? editedBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.file(
            imageFile,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                Navigator.pop(context, bytes);
              },
              onCloseEditor: (mode) {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );

      if (editedBytes != null) {
        // Save edited image to temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final editedFile = File('${tempDir.path}/$fileName');
        await editedFile.writeAsBytes(editedBytes);
        return editedFile;
      }
    } catch (e) {
      _logger.e('Error editing image: $e');
      return null;
    }
    return null;
  }
}
