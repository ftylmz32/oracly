library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../features/birth_chart/providers/birth_information_provider.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../copy/soul_mate_copy.dart';
import '../../providers/premium_providers.dart';
import '../../providers/soul_mate_saved_provider.dart';
import '../../services/premium_access.dart';
import '../../services/soul_mate_dev_access.dart';
import '../../services/soul_mate_draw_port.dart';
import '../../services/soul_mate_draw_validation.dart';
import '../../services/soul_mate_paid_draw.dart';
import 'soul_mate_birth_picker.dart';
import 'soul_mate_draw_body.dart';
import 'soul_mate_draw_persistence.dart';
import 'soul_mate_draw_preview.dart';
import 'soul_mate_draw_shell.dart';

class SoulMateDrawScreen extends ConsumerStatefulWidget {
  const SoulMateDrawScreen({super.key});

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
  bool _prefilledBirth = false;
  String? _statusMessage;
  SoulMateDrawResult? _result;
  String? _savedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSaved());
  }

  @override
  void dispose() {
    _name.dispose();
    _intention.dispose();
    super.dispose();
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
    setState(() {
      _result = null;
      _statusMessage = null;
      _busy = false;
      _savedId = null;
    });
  }

  void _retry() {
    setState(() => _statusMessage = null);
    _draw();
  }

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
    if (!SoulMateDevAccess.allows(context)) {
      PremiumAccess.prompt(context);
      return;
    }
    _drawLock = true;
    try {
      setState(() {
        _busy = true;
        _statusMessage = SoulMateCopy.drawing;
        _result = null;
      });
      final request = SoulMateDrawRequest(
        name: _name.text.trim(),
        birthDate: _birth!,
        gender: _gender,
        intention: _intention.text.trim().isEmpty
            ? null
            : _intention.text.trim(),
      );
      // Capture before await — dispose must not lose a successful paid draw.
      final resultService = ref.read(soulMateResultServiceProvider);
      final result = await SoulMatePaidDraw.run(
        ref: ref,
        context: context,
        request: request,
      );
      if (result == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _result = result;
          _statusMessage = SoulMatePaidDraw.messageFor(result);
        });
      }
      // Persist after UI update — disk I/O must not leave the chamber waiting.
      if (result.hasPortrait) {
        final savedId = await SoulMateDrawPersistence.persistWithService(
          service: resultService,
          request: request,
          imageBytes: result.imageBytes!,
          onSaved: mounted
              ? () {
                  ref.invalidate(soulMateSavedResultProvider);
                  ref.invalidate(soulMateSavedPortraitProvider);
                }
              : null,
        );
        if (mounted && savedId != null) {
          setState(() => _savedId = savedId);
        }
      }
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

  @override
  Widget build(BuildContext context) {
    ref.watch(premiumStatusProvider);
    ref.watch(birthInformationProvider);
    _maybePrefillBirth();
    final locked = !SoulMateDevAccess.allows(context);
    return SoulMateDrawShell(
      body: locked
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
            ),
    );
  }
}
