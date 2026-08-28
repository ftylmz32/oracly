/// Abandons an in-flight quality session when the feature screen leaves.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/quality/quality_feature.dart';
import '../../../core/quality/quality_signal_recorder.dart';
import '../providers/quality_loop_providers.dart';

class QualityLoopGate extends ConsumerStatefulWidget {
  const QualityLoopGate({
    super.key,
    required this.feature,
    required this.child,
    this.startOnInit = false,
  });

  final QualityFeature feature;
  final Widget child;
  final bool startOnInit;

  @override
  ConsumerState<QualityLoopGate> createState() => _QualityLoopGateState();
}

class _QualityLoopGateState extends ConsumerState<QualityLoopGate> {
  QualitySignalRecorder? _recorder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recorder = ref.read(qualitySignalRecorderProvider);
      if (widget.startOnInit) {
        _recorder?.started(widget.feature);
      }
    });
  }

  @override
  void dispose() {
    _recorder?.abandonedIfOpen(widget.feature);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
