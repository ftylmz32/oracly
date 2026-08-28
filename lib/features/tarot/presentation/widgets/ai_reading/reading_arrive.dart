/// Sequential card arrival — previous faces settle, never bounce.
library;

import 'package:flutter/material.dart';

import 'reading_premium_animations.dart';

class ReadingArrive extends StatelessWidget {
  const ReadingArrive({
    super.key,
    required this.progress,
    required this.child,
    this.settle = 1,
  });

  final double progress;
  final double settle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 12),
        child: Transform.scale(
          scale: settle,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class ReadingStoryArrive extends StatelessWidget {
  const ReadingStoryArrive({
    super.key,
    required this.index,
    required this.count,
    required this.master,
    required this.child,
  });

  final int index;
  final int count;
  final double master;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ReadingArrive(
      progress: readingStoryArrive(index, master),
      settle: readingStorySettle(index, master, count),
      child: child,
    );
  }
}

class ReadingTileArrive extends StatelessWidget {
  const ReadingTileArrive({
    super.key,
    required this.index,
    required this.master,
    required this.child,
  });

  final int index;
  final double master;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ReadingArrive(
      progress: readingCardTileArrive(index, master),
      settle: 1,
      child: child,
    );
  }
}
