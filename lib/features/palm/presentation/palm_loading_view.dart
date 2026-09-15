/// Palm analysis wait — real hand hero + the shared countdown/acceleration
/// waiting screen.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../reading_operation/presentation/reading_wait_screen.dart';
import '../../reading_operation/services/reading_live_flow.dart';
import 'palm_analysis_canvas.dart';

class PalmLoadingView extends StatelessWidget {
  const PalmLoadingView({
    super.key,
    required this.message,
    this.subtitle,
    this.imagePath,
    this.onAccelerate,
    this.accelerating = false,
    this.accelerationError,
    this.accelerationCost,
    this.liveState,
  });

  final String message;
  final String? subtitle;
  final String? imagePath;
  final VoidCallback? onAccelerate;
  final bool accelerating;
  final String? accelerationError;
  final int? accelerationCost;
  final ReadingLiveState? liveState;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasHand = path != null && File(path).existsSync();
    return ReadingWaitScreen(
      liveState: liveState,
      hero: hasHand
          ? SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PalmAnalysisCanvas(path: path, contain: true),
              ),
            )
          : null,
      onAccelerate: onAccelerate,
      accelerating: accelerating,
      accelerationError: accelerationError,
      accelerationCost: accelerationCost,
    );
  }
}
