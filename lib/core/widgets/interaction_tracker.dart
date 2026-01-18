import 'package:flutter/material.dart';
import '../services/auto_lock_service.dart';

/// Widget that tracks user interactions to prevent auto-lock
class InteractionTracker extends StatelessWidget {
  final Widget child;
  
  const InteractionTracker({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AutoLockService.instance.recordInteraction(),
      onPanStart: (_) => AutoLockService.instance.recordInteraction(),
      onPanUpdate: (_) => AutoLockService.instance.recordInteraction(),
      onScaleStart: (_) => AutoLockService.instance.recordInteraction(),
      onScaleUpdate: (_) => AutoLockService.instance.recordInteraction(),
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: (_) => AutoLockService.instance.recordInteraction(),
        onPointerMove: (_) => AutoLockService.instance.recordInteraction(),
        child: child,
      ),
    );
  }
}
