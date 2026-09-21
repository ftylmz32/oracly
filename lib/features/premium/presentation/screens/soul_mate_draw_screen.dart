library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../features/birth_chart/providers/birth_information_provider.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../reading_operation/models/reading_failure_code.dart';
import '../../copy/soul_mate_copy.dart';
import '../../../discovery_journal/providers/discovery_journal_providers.dart';
import '../../providers/premium_providers.dart';
import '../../providers/soul_mate_providers.dart';
import '../../services/premium_access.dart';
import '../../services/soul_mate_dev_access.dart';
import '../../data/soul_mate_interpretation_catalogue.dart';
import '../../services/soul_mate_draw_action.dart';
import '../../services/soul_mate_draw_port.dart';
import '../../services/soul_mate_draw_validation.dart';
import '../../services/soul_mate_reading_orchestrator.dart';
import '../../../reading_operation/providers/reading_live_provider.dart';
import 'soul_mate_draw_finish.dart';
import 'soul_mate_birth_picker.dart';
import 'soul_mate_draw_body.dart';
import 'soul_mate_draw_persistence.dart';
import 'soul_mate_draw_preview.dart';
import 'soul_mate_draw_shell.dart';

class SoulMateDrawScreen extends ConsumerStatefulWidget {
  const SoulMateDrawScreen({super.key, this.operationId});

  /// Exact durable completion target from push/deep-link navigation.
  final String? operationId;

  @override
  ConsumerState<SoulMateDrawScreen> createState() => _SoulMateDrawScreenState();
}

class _SoulMateDrawScreenState extends ConsumerState<SoulMateDrawScreen> {
  final _name = TextEditingController();
  final _intention = TextEditingController();
  DateTime? _birth;
  SoulMateGenderPref? _gender;
  bool _busy = false;
  bool _drawLock = false;
  bool _freshNext = false;
  bool _prefilledBirth = false;
  String? _statusMessage;
  SoulMateDrawResult? _result;
  String? _savedId;
  SoulMateReadingParts? _interpretation;
  bool _interpretationBusy = false;
  bool _interpretationFailed = false;
  SoulMateDrawRequest? _lastRequest;
  final _orchestrator = SoulMateReadingOrchestrator();
  Timer? _pollTimer;
  int _pollToken = 0;
  bool _staleLegacy = false;
  DateTime? _activeSince;
  String? _targetOperationId;

  @override
  void initState() {
    super.initState();
    final target = widget.operationId?.trim();
    _targetOperationId =
        target == null || target.isEmpty ? null : target;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeOrRestore());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _name.dispose();
    _intention.dispose();
    super.dispose();
  }

  Future<void> _resumeOrRestore() async {
    final exactOperationId = _targetOperationId;
    if (exactOperationId != null) {
      final exact = await SoulMateReadingOrchestrator.recoverDurableOperation(
        ref,
        exactOperationId,
      );
      if (!mounted) return;
      // Exact deep links never attach to some other active SoulMate job
      // and never fall back to an unrelated previously-saved portrait.
      await _applyDurable(exact);
      return;
    }

    final runner = ref.read(soulMateGenerationRunnerProvider);
    final owner = SoulMateDrawAction.ownerOf(ref);
    final inflight = runner.currentFor(owner);
    if (inflight != null) {
      setState(() {
        _busy = true;
        _statusMessage = SoulMateCopy.drawing;
      });
      final result = await inflight;
      final finished = await SoulMateDrawFinish.apply(
        result: result,
        savedId: _savedId,
      );
      if (mounted) _show(finished);
      final savedId = await SoulMateDrawFinish.persist(
        ref: ref,
        result: result,
        request: null,
        formRequest: _requestFromForm(),
        ownerId: owner,
        mounted: mounted,
      );
      if (mounted && savedId != null) setState(() => _savedId = savedId);
      return;
    }

    // SMD1 §12 resolution order, item 1-2: a server-authoritative durable
    // operation (this build's own submissions) always takes priority over
    // the legacy passive check below — it actively resumes (polls) rather
    // than parking forever.
    final durable = await SoulMateReadingOrchestrator.recoverDurable(ref);
    if (!mounted) return;
    if (durable.kind != SoulMateDurableKind.none) {
      await _applyDurable(durable);
      return;
    }

    // SMD1 §11/§12 item 3-4: legacy (pre-SMD1, executionMode-absent)
    // operation. `processing` here can never resolve on its own — no
    // durable worker ever touches a legacy Soulmate record, and the
    // original client process that would have executed it is gone. This
    // is deliberately NOT the same as the durable `active` branch above:
    // it must never show an indefinite spinner or auto-call a provider.
    final recovery = await SoulMateReadingOrchestrator.recoverActive(ref);
    if (recovery.kind == SoulMateRecoveryKind.processing) {
      if (!mounted) return;
      // The error/retry state hides the form entirely (see
      // SoulMateDrawBody), so a controlled retry must not depend on the
      // user re-typing name/birth/etc. — refill from whatever the stale
      // operation itself already saved server-side (BATCH 5G's structured
      // input, saved by the legacy flow too), when available.
      final legacyOperationId = recovery.operationId;
      final savedFields = legacyOperationId == null
          ? null
          : await ref
                .read(readingOperationInputGatewayProvider)
                ?.get(legacyOperationId);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _staleLegacy = true;
        _statusMessage = SoulMateCopy.failureUnavailable;
        if (savedFields != null) {
          _name.text = savedFields['name'] ?? _name.text;
          _intention.text = savedFields['intention'] ?? _intention.text;
          final savedBirth = savedFields['birthIso'];
          if (savedBirth != null) {
            _birth = DateTime.tryParse(savedBirth) ?? _birth;
          }
          _gender = savedFields['gender'] == 'feminine'
              ? SoulMateGenderPref.feminine
              : savedFields['gender'] == 'masculine'
              ? SoulMateGenderPref.masculine
              : _gender;
        }
      });
      // A controlled retry always starts a brand-new durable operation —
      // reusing the stale record's own sourceRequestId would just return
      // that SAME stuck legacy record (see _draw()/SMD1 §11).
      _freshNext = true;
      return;
    }
    await _restoreSaved();
  }

  /// SMD1 — applies a [SoulMateDurableOutcome] from either a fresh
  /// submission or a recovery poll. `active` schedules exactly one more
  /// poll; every other kind stops polling.
  Future<void> _applyDurable(SoulMateDurableOutcome outcome) async {
    if (!mounted) return;
    _staleLegacy = false;
    switch (outcome.kind) {
      case SoulMateDurableKind.ready:
        _pollTimer?.cancel();
        setState(() {
          _activeSince = null;
          _busy = false;
          _result = outcome.draw;
          _statusMessage = null;
          _interpretation = outcome.interpretation;
          _interpretationBusy = false;
          _interpretationFailed = outcome.interpretation == null;
          if (outcome.savedId != null) _savedId = outcome.savedId;
        });
        try {
          ref.invalidate(discoveryJournalEntriesProvider);
        } catch (_) {}
      case SoulMateDurableKind.active:
        setState(() {
          _busy = true;
          _statusMessage = SoulMateCopy.drawing;
          _activeSince = outcome.activeSince ?? _activeSince ?? DateTime.now();
        });
        _scheduleDurablePoll();
      case SoulMateDurableKind.failed:
        _pollTimer?.cancel();
        // R3.1 — only definite entitlement denial triggers Premium self-heal.
        // Unrelated / unknown / missing codes keep Premium state untouched.
        final entitlementDenied = outcome.failureCode.isEntitlementDenial;
        var stillPremium = true;
        if (entitlementDenied) {
          stillPremium =
              await PremiumAccess.healAfterEntitlementDenial(context);
          if (!mounted) return;
        }
        setState(() {
          _activeSince = null;
          _busy = false;
          _statusMessage = entitlementDenied && !stillPremium
              ? SoulMateCopy.premiumRequired
              : SoulMateCopy.failureTemporary;
        });
        if (entitlementDenied && !stillPremium) {
          PremiumAccess.prompt(context);
        }
      case SoulMateDurableKind.unavailable:
        _pollTimer?.cancel();
        setState(() {
          _activeSince = null;
          _busy = false;
          _statusMessage = SoulMateCopy.unavailable;
        });
      case SoulMateDurableKind.none:
        _pollTimer?.cancel();
    }
  }

  /// Server state is the only authority — keep observing indefinitely
  /// rather than inferring failure from elapsed time or a retry count
  /// (SMD1 §9: the 28s "taking longer" threshold changes copy, never
  /// operation validity).
  void _scheduleDurablePoll() {
    _pollTimer?.cancel();
    final token = ++_pollToken;
    _pollTimer = Timer(const Duration(seconds: 3), () {
      unawaited(() async {
        if (!mounted || token != _pollToken) return;
        final exactOperationId = _targetOperationId;
        final outcome = exactOperationId == null
            ? await SoulMateReadingOrchestrator.recoverDurable(ref)
            : await SoulMateReadingOrchestrator.recoverDurableOperation(
                ref,
                exactOperationId,
              );
        if (!mounted || token != _pollToken) return;
        await _applyDurable(outcome);
      }());
    });
  }

  Future<void> _restoreSaved() async {
    final restored = await SoulMateDrawPersistence.restore(ref);
    if (!mounted || restored == null || _result != null || _busy) return;
    setState(() {
      _name.text = restored.name;
      _intention.text = restored.intention;
      _birth = restored.birthDate;
      _gender = restored.gender;
      _result = restored.result;
      _savedId = restored.savedId;
      _interpretation = restored.interpretation;
      _interpretationFailed = restored.interpretation == null;
      _interpretationBusy = false;
    });
  }

  void _maybePrefillBirth() {
    if (_prefilledBirth || _birth != null) return;
    final profile = ref.read(birthInformationProvider).valueOrNull;
    final date = profile?.birthDate;
    if (date == null) return;
    _prefilledBirth = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _birth != null) return;
      setState(() => _birth = date);
    });
  }

  Future<void> _pickBirth() async {
    final picked = await pickSoulMateBirthDate(context, current: _birth);
    if (picked == null || !mounted) return;
    setState(() => _birth = picked);
  }

  void _redraw() {
    _freshNext = true;
    setState(() {
      _result = null;
      _statusMessage = null;
      _busy = false;
      _savedId = null;
      _interpretation = null;
      _interpretationBusy = false;
      _interpretationFailed = false;
    });
  }

  Future<void> _retryInterpretation() async {
    final request = _lastRequest ?? _requestFromForm();
    final result = _result;
    if (request == null || result == null || !result.hasPortrait) return;
    if (!_orchestrator.canRetryInterpretation) return;
    if (mounted) {
      setState(() {
        _interpretationBusy = true;
        _interpretationFailed = false;
      });
    }
    final interpretation = await _orchestrator.retryInterpretation(
      ref: ref,
      request: request,
      portrait: result,
      ownerId: SoulMateDrawAction.ownerOf(ref),
    );
    if (!mounted) return;
    if (interpretation != null) {
      setState(() {
        _interpretation = interpretation;
        _interpretationBusy = false;
        _interpretationFailed = false;
      });
      try {
        ref.invalidate(discoveryJournalEntriesProvider);
      } catch (_) {}
      return;
    }
    setState(() {
      _interpretationBusy = false;
      _interpretationFailed = true;
    });
  }

  void _retry() {
    _freshNext = false;
    setState(() => _statusMessage = null);
    unawaited(_draw());
  }

  /// SMD1 — every new submission from this build is server-authoritative:
  /// this only creates the durable operation and saves its input, then
  /// returns. Portrait, interpretation, and persistence all happen in the
  /// durable worker; completion is discovered by [_applyDurable]'s polling,
  /// never awaited inline here (SMD1 §1/§6 — the client must not own any
  /// part of that chain).
  Future<void> _draw() async {
    if (_busy || _drawLock) return;
    final error = SoulMateDrawValidation.missingField(
      name: _name.text,
      birth: _birth,
    );
    if (error != null) {
      OraclySnackBar.show(context, message: error);
      return;
    }
    // R3 — never trust a stale Premium badge for a paid durable submission.
    if (!await SoulMateDevAccess.allowsFresh(context)) return;
    if (!mounted) return;
    _drawLock = true;
    try {
      // A stale-legacy operation (SMD1 §11) must always retry with a
      // brand-new operation — `_retry()` resets `_freshNext` before
      // calling here, so `_staleLegacy` is captured first, independently
      // of `_freshNext`.
      final fresh = _freshNext || _staleLegacy;
      _freshNext = false;
      setState(() {
        _busy = true;
        _activeSince = DateTime.now();
        _staleLegacy = false;
        _statusMessage = SoulMateCopy.drawing;
        _result = null;
        _interpretation = null;
        _interpretationBusy = false;
        _interpretationFailed = false;
      });
      final request = SoulMateDrawRequest(
        name: _name.text.trim(),
        birthDate: _birth!,
        gender: _gender,
        intention: _intention.text.trim().isEmpty
            ? null
            : _intention.text.trim(),
      );
      _lastRequest = request;
      final outcome = await _orchestrator.drawDurable(
        ref: ref,
        request: request,
        fresh: fresh,
      );
      if (!mounted) return;
      await _applyDurable(outcome);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = ResilienceCopy.temporaryFailure;
      });
    } finally {
      _drawLock = false;
    }
  }

  void _show(SoulMateDrawFinish finished) {
    setState(() {
      _busy = finished.busy;
      _result = finished.result ?? _result;
      _statusMessage = finished.statusMessage;
      if (finished.savedId != null) _savedId = finished.savedId;
    });
  }

  SoulMateDrawRequest? _requestFromForm() {
    final birth = _birth;
    if (birth == null || _name.text.trim().isEmpty) return null;
    return SoulMateDrawRequest(
      name: _name.text.trim(),
      birthDate: birth,
      gender: _gender,
      intention: _intention.text.trim().isEmpty ? null : _intention.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(premiumStatusProvider);
    ref.watch(birthInformationProvider);
    _maybePrefillBirth();
    final locked = !SoulMateDevAccess.allows(context);
    // Saved portraits remain readable after entitlement lapses — Premium
    // gates only fresh draw/redraw (allowsFresh on those actions).
    final showLockedPreview = locked && _result == null;
    return SoulMateDrawShell(
      body: showLockedPreview
          ? const SoulMateDrawPreview()
          : SoulMateDrawBody(
              nameController: _name,
              intentionController: _intention,
              birthDate: _birth,
              onPickBirth: _pickBirth,
              gender: _gender,
              onGender: (value) => setState(() => _gender = value),
              busy: _busy,
              statusMessage: _statusMessage,
              result: _result,
              savedId: _savedId,
              onDraw: _draw,
              onRedraw: _redraw,
              onRetry: _retry,
              interpretation: _interpretation,
              interpretationBusy: _interpretationBusy,
              interpretationFailed: _interpretationFailed,
              onRetryInterpretation: _retryInterpretation,
              activeSince: _activeSince,
            ),
    );
  }
}
