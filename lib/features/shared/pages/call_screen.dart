import 'package:flutter/material.dart';

OverlayEntry? overlayEntry;

void showIncomingCallBanner() {
  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          child: Container(
            color: Colors.red,
            child: const Center(
              child: Text(
                'Incoming Call',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    },
  );
}
