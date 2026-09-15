/// Coffee analysis wait — real cup hero + the shared countdown/acceleration
/// waiting screen.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../reading_operation/presentation/reading_wait_screen.dart';
import '../../../reading_operation/services/reading_live_flow.dart';
import 'coffee_cup_wait.dart';

class CoffeeLoadingView extends StatelessWidget {
  const CoffeeLoadingView({
    super.key,
    required this.message,
    this.subtitle,
    this.imagePath,
    this.onRetry,
    this.onAccelerate,
    this.accelerating = false,
    this.accelerationError,
    this.accelerationCost,
    this.liveState,
  });

  final String message;
  final String? subtitle;
  final String? imagePath;
  final VoidCallback? onRetry;
  final VoidCallback? onAccelerate;
  final bool accelerating;
  final String? accelerationError;
  final int? accelerationCost;
  final ReadingLiveState? liveState;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasCup = path != null && File(path).existsSync();
    return ReadingWaitScreen(
      liveState: liveState,
      hero: hasCup
          ? CoffeeCupWait(message: '', path: path, fixedHeight: 140)
          : null,
      onAccelerate: onAccelerate,
      accelerating: accelerating,
      accelerationError: accelerationError,
      accelerationCost: accelerationCost,
    );
  }
}
