import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chat_kare/features/profile/presentation/widgets/profile_photo_preview_dialog.dart';
import 'package:chat_kare/features/profile/presentation/widgets/profile_photo_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileController controller;
  final Logger _logger = Logger();

  ProfileHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Obx(() {
            final photoUrl = controller.currentUser?.photoUrl;
            _logger.i('Photo URL: $photoUrl');
            return GestureDetector(
              onTap: () {
                if (photoUrl != null) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4,
                            child: Image.network(photoUrl, fit: BoxFit.contain),
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.primary.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: context.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: context.colorScheme.primary,
                        )
                      : null,
                ),
              ),
            );
          }),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) => ProfilePhotoSelectionSheet(
                    onPhotoSelected: (file) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => Obx(
                          () => ProfilePhotoPreviewDialog(
                            file: file,
                            isLoading: controller.isLoading,
                            onUpload: () async {
                              await controller.uploadProfilePhoto(file);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
