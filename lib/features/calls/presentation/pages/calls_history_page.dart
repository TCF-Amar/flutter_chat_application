import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:chat_kare/features/shared/widgets/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallsHistoryPage extends StatelessWidget {
  const CallsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: DefaultAppBar(title: "Calls", centerTitle: false),
      body: ListView.builder(
        itemCount: _dummyCalls.length,
        itemBuilder: (context, index) {
          final call = _dummyCalls[index];
          return _CallHistoryTile(call: call);
        },
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final _CallData call;

  const _CallHistoryTile({required this.call});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(call.imageUrl),
      ),
      title: AppText(
        call.name,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.colorScheme.textPrimary,
      ),
      subtitle: Row(
        children: [
          Icon(
            call.isIncoming
                ? (call.isMissed ? Icons.call_missed : Icons.call_received)
                : Icons.call_made,
            size: 16,
            color: call.isMissed ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          AppText(
            DateFormat('MMM d, hh:mm a').format(call.time),
            fontSize: 14,
            color: Colors.grey,
          ),
        ],
      ),
      trailing: Icon(
        call.isVideo ? Icons.videocam : Icons.call,
        color: context.colorScheme.primary,
      ),
    );
  }
}

class _CallData {
  final String name;
  final String imageUrl;
  final DateTime time;
  final bool isIncoming;
  final bool isMissed;
  final bool isVideo;

  _CallData({
    required this.name,
    required this.imageUrl,
    required this.time,
    required this.isIncoming,
    this.isMissed = false,
    required this.isVideo,
  });
}

// Dummy Data
final List<_CallData> _dummyCalls = [
  _CallData(
    name: "John Doe",
    imageUrl: "https://i.pravatar.cc/150?u=1",
    time: DateTime.now().subtract(const Duration(minutes: 5)),
    isIncoming: true,
    isMissed: true,
    isVideo: false,
  ),
  _CallData(
    name: "Jane Smith",
    imageUrl: "https://i.pravatar.cc/150?u=2",
    time: DateTime.now().subtract(const Duration(hours: 1)),
    isIncoming: false,
    isVideo: true,
  ),
  _CallData(
    name: "Mike Johnson",
    imageUrl: "https://i.pravatar.cc/150?u=3",
    time: DateTime.now().subtract(const Duration(hours: 4)),
    isIncoming: true,
    isVideo: false,
  ),
  _CallData(
    name: "Emily Davis",
    imageUrl: "https://i.pravatar.cc/150?u=4",
    time: DateTime.now().subtract(const Duration(days: 1)),
    isIncoming: false,
    isVideo: true,
  ),
  _CallData(
    name: "Chris Brown",
    imageUrl: "https://i.pravatar.cc/150?u=5",
    time: DateTime.now().subtract(const Duration(days: 2)),
    isIncoming: true,
    isMissed: true,
    isVideo: false,
  ),
  _CallData(
    name: "John Doe",
    imageUrl: "https://i.pravatar.cc/150?u=1",
    time: DateTime.now().subtract(const Duration(days: 3)),
    isIncoming: true,
    isVideo: true,
  ),
];
