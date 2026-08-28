/// Pause ambient loops when the app is not in the foreground.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/oracly_quiet_motion.dart';

void tarotSyncAmbient(
  BuildContext context,
  AnimationController controller, {
  bool reverse = false,
  double rest = 0.5,
}) {
  if (!context.mounted) return;
  final life = SchedulerBinding.instance.lifecycleState;
  final inactive = life == AppLifecycleState.paused ||
      life == AppLifecycleState.hidden ||
      life == AppLifecycleState.detached;
  if (inactive) {
    controller.stop();
    return;
  }
  OraclyQuietMotion.ambient(
    context,
    controller,
    reverse: reverse,
    rest: rest,
  );
}
