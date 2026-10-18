/// One encounter, five scenes. Answers stay in the draft.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_reduced_motion.dart';
import '../data/onboarding_setup_draft.dart';
import 'encounter_interest_scene.dart';
import 'encounter_name_scene.dart';
import 'encounter_opening.dart';
import 'encounter_sky_scene.dart';
import 'encounter_welcome_scene.dart';

class EncounterFlow extends StatefulWidget {
  const EncounterFlow({
    super.key,
    required this.draft,
    required this.busy,
    required this.onChanged,
    required this.onFinish,
  });

  final OnboardingSetupDraft draft;
  final bool busy;
  final ValueChanged<OnboardingSetupDraft> onChanged;
  final ValueChanged<OnboardingSetupDraft> onFinish;

  @override
  State<EncounterFlow> createState() => _EncounterFlowState();
}

class _EncounterFlowState extends State<EncounterFlow> {
  late final PageController _pages;
  late final TextEditingController _name;
  late OnboardingSetupDraft _draft;
  Timer? _nameDebounce;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _pages = PageController(initialPage: _draft.scene.clamp(0, 4));
    _name = TextEditingController(text: _draft.name ?? '');
    _name.addListener(_onName);
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _name.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onName() {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 180), () {
      final text = _name.text.trim();
      _emit(_draft.copy(name: text.isEmpty ? null : text, setName: true));
    });
  }

  void _emit(OnboardingSetupDraft next) {
    _draft = next;
    widget.onChanged(next);
    if (mounted) setState(() {});
  }

  Future<void> _go(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final next = index.clamp(0, 4);
    _emit(_draft.copy(scene: next));
    if (!_pages.hasClients) return;
    final motion = OraclyReducedMotion.duration(
      context,
      const Duration(milliseconds: 420),
    );
    if (motion == Duration.zero) {
      _pages.jumpToPage(next);
      return;
    }
    await _pages.animateToPage(next, duration: motion, curve: Curves.easeInOutCubic);
  }

  void _toggle(String id) {
    final next = [..._draft.interests];
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _emit(_draft.copy(interests: next));
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pages,
        onPageChanged: (index) {
          if (index == _draft.scene) return;
          _emit(_draft.copy(scene: index));
        },
      children: [
        EncounterGateScene(
          busy: widget.busy,
          onMeet: () => _go(1),
          onSkip: () => widget.onFinish(_draft),
        ),
        EncounterNameScene(
          controller: _name,
          busy: widget.busy,
          onContinue: () => _go(2),
          onSkip: () => widget.onFinish(_draft),
          onBack: () => _go(0),
        ),
        EncounterInterestScene(
          selected: _draft.interests,
          busy: widget.busy,
          onToggle: _toggle,
          onContinue: () => _go(3),
          onSkip: () => widget.onFinish(_draft),
          onBack: () => _go(1),
        ),
        EncounterSkyScene(
          draft: _draft,
          busy: widget.busy,
          onChanged: _emit,
          onContinue: () => _go(4),
          onSkip: () => widget.onFinish(_draft),
          onBack: () => _go(2),
        ),
        EncounterWelcomeScene(
          draft: _draft,
          busy: widget.busy,
          onEnter: () => widget.onFinish(_draft.copy(scene: 4)),
          onBack: () => _go(3),
        ),
      ],
    );
  }
}
