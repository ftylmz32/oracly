/// Surfaces one observation and records it for anti-repetition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/oracly_observation.dart';
import '../../models/surfaced_theme_record.dart';
import '../../providers/personal_discovery_providers.dart';

class OraclyObservationSurface extends ConsumerStatefulWidget {
  const OraclyObservationSurface({
    super.key,
    required this.surface,
    required this.builder,
  });

  final String surface;
  final Widget Function(BuildContext context, OraclyObservation? observation)
      builder;

  @override
  ConsumerState<OraclyObservationSurface> createState() =>
      _OraclyObservationSurfaceState();
}

class _OraclyObservationSurfaceState
    extends ConsumerState<OraclyObservationSurface> {
  String? _recordedTheme;

  @override
  Widget build(BuildContext context) {
    final observation = ref.watch(oraclyObservationProvider(widget.surface));
    _maybeRecord(observation);
    return widget.builder(context, observation);
  }

  void _maybeRecord(OraclyObservation? observation) {
    if (observation == null || observation.theme == _recordedTheme) return;
    _recordedTheme = observation.theme;
    ref.read(discoverySurfaceMemoryProvider).record(
          SurfacedThemeRecord(
            theme: observation.theme,
            surface: widget.surface,
            at: DateTime.now(),
          ),
        );
  }
}
