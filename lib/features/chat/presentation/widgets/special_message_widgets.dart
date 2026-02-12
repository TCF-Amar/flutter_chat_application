import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

//* Widgets for special message types (location and document).
//*
//* These message types require external app integration:
//* - Location: Opens in map application
//* - Document: Opens in file viewer

//* Displays a location message with interactive map link.
//*
//* The message text should contain a valid map URL.
//* Tapping opens the location in an external map app.
class LocationMessageWidget extends StatelessWidget {
  final ChatsEntity message;
  final bool isMe;

  const LocationMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(message.text);
        // Attempt to launch in external map app
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback - try direct launch
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: isMe ? Colors.white : Colors.red),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'View Location',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//* Displays a document/file message.
//*
//* Shows file icon and name, opens in external viewer on tap.
class DocumentMessageWidget extends StatelessWidget {
  final ChatsEntity message;
  final bool isMe;

  const DocumentMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (message.mediaUrl == null || message.mediaUrl!.isEmpty) return;
        final uri = Uri.parse(message.mediaUrl!);
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // Try launching directly if canLaunch returns false (some devices/schemes)
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching url: $e');
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.text.isNotEmpty ? message.text : 'Document',
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
