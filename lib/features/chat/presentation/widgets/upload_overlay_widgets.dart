import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

//* Reusable overlay widgets for media upload states.
//*
//* Provides consistent UI for:
//* - Upload progress with cancel action
//* - Upload failure with retry action

//* Overlay displayed while a media message is uploading.
//*
//* Shows:
//* - Circular progress indicator with percentage
//* - Cancel button to abort the upload
class UploadingOverlay extends StatelessWidget {
  final ChatsEntity message;
  final VoidCallback onCancel;

  const UploadingOverlay({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress indicator
            CircularProgressIndicator(
              value: message.uploadProgress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 8),

            // Progress percentage
            AppText(
              '${(message.uploadProgress * 100).toInt()}%',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),

            // Cancel button
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              label: const AppText('Cancel', fontSize: 12, color: Colors.white),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//* Overlay displayed when a media upload fails.
//*
//* Shows:
//* - Error icon
//* - Error message (custom or default)
//* - Retry button to attempt upload again
class FailedOverlay extends StatelessWidget {
  final ChatsEntity message;
  final VoidCallback onRetry;

  const FailedOverlay({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),

            // Error message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppText(
                message.uploadError ?? 'Upload failed',
                fontSize: 12,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Retry button
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const AppText('Retry', fontSize: 12, color: Colors.white),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
