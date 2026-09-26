/// Phase 8B — Narrative live loading/error/ready host (not a result owner).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/l10n/l10n.dart';
import '../../artifacts/yildizname_artifact_providers.dart';
import '../../narrative/live/yildizname_live_error_copy.dart';
import '../../narrative/live/yildizname_live_execution.dart';
import '../../narrative/live/yildizname_live_orchestrator_providers.dart';
import '../../narrative/live/yildizname_pending_narrative_completion.dart';
import '../../narrative/live/yildizname_prepared_live_execution.dart';
import 'star_map_error_state.dart';
import 'star_map_loading_cinema.dart';
import 'star_map_reference_result_screen.dart';

enum _Phase { loading, error, ready }

class StarMapNarrativeLiveScreen extends ConsumerStatefulWidget {
  const StarMapNarrativeLiveScreen({super.key, this.prepared});

  /// Route-prepared transaction; consumed once by the first execution only.
  final YildiznamePreparedLiveExecution? prepared;

  @override
  ConsumerState<StarMapNarrativeLiveScreen> createState() =>
      _StarMapNarrativeLiveScreenState();
}

class _StarMapNarrativeLiveScreenState
    extends ConsumerState<StarMapNarrativeLiveScreen> {
  _Phase _phase = _Phase.loading;
  YildiznameLiveExecutionKind? _errorKind;
  YildiznamePendingNarrativeCompletion? _pending;
  YildiznameResultPresentation? _presentation;
  YildiznamePreparedLiveExecution? _initial;
  bool _loggedCompletion = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _initial = widget.prepared;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFresh());
  }

  Future<void> _runFresh() async {
    setState(() {
      _phase = _Phase.loading;
      _errorKind = null;
      _pending = null;
      _presentation = null;
    });
    final orch = ref.read(yildiznameLiveOrchestratorProvider);
    final prepared = _initial;
    _initial = null;
    final exec = prepared != null
        ? await orch.executePrepared(prepared)
        : await orch.execute(languageCode: OraclyL10n.depend(context));
    if (!mounted) return;
    _apply(exec);
  }

  Future<void> _onRetry() async {
    if (_running) return;
    _running = true;
    try {
      final pending = _pending;
      if (pending != null) {
        setState(() => _phase = _Phase.loading);
        final orch = ref.read(yildiznameLiveOrchestratorProvider);
        final exec = await orch.retryPersistence(pending);
        if (!mounted) return;
        _apply(exec);
        return;
      }
      await _runFresh();
    } finally {
      _running = false;
    }
  }

  void _apply(YildiznameLiveExecution exec) {
    if (exec.isReady && exec.presentation != null) {
      ref.invalidate(yildiznameArtifactHistoryProvider);
      if (!_loggedCompletion) {
        _loggedCompletion = true;
        ref.read(analyticsServiceProvider).logStarMapCompleted();
      }
      setState(() {
        _phase = _Phase.ready;
        _presentation = exec.presentation;
        _pending = null;
        _errorKind = null;
      });
      return;
    }
    if (exec.isLegacy) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _phase = _Phase.error;
      _errorKind = exec.kind;
      _pending = exec.pending;
      _presentation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.ready && _presentation != null) {
      return StarMapReferenceResultScreen(presentation: _presentation!);
    }
    final kind = _errorKind ?? YildiznameLiveExecutionKind.generationFailed;
    final body = _phase == _Phase.error
        ? StarMapErrorState(
            message: YildiznameLiveErrorCopy.messageFor(kind),
            onRetry: YildiznameLiveErrorCopy.retryMeaningful(kind)
                ? _onRetry
                : null,
          )
        : const StarMapLoadingCinema();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: body),
    );
  }
}
