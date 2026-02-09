import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const SwipeToReply({super.key, required this.child, required this.onReply});

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  final double _replyThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Only allow dragging to the right
    if (details.primaryDelta! > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset += details.primaryDelta!;
        // Clamp the offset to specific range to avoid dragging too far
        if (_dragOffset < 0) _dragOffset = 0;
        if (_dragOffset > 100) _dragOffset = 100;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset >= _replyThreshold) {
      widget.onReply();
    }

    // Animate back to zero
    _animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _dragOffset = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Reply Icon Background
          if (_dragOffset > 0)
            Positioned(
              left: 16,
              child: Opacity(
                opacity: (_dragOffset / _replyThreshold).clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.all(8),

                  child: Icon(
                    Icons.reply,
                    color: context.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Child with transform
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.isAnimating
                  ? _animation.value
                  : _dragOffset;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: widget.child,
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
