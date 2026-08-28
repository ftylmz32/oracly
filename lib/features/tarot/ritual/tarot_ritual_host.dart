/// Continuous ritual host — shuffle → cut → draw → reveal without route reset.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models/reading_session.dart';
import '../presentation/screens/reading_screen.dart';
import '../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../shared/constants/tarot_routes.dart';
import '../shared/tarot_scope.dart';
import 'tarot_ritual_controller.dart';
import 'tarot_ritual_scene.dart';
import 'tarot_ritual_stage.dart';

class TarotRitualHost extends StatefulWidget {
  const TarotRitualHost({super.key});

  @override
  State<TarotRitualHost> createState() => _TarotRitualHostState();
}

class _TarotRitualHostState extends State<TarotRitualHost>
    with TickerProviderStateMixin {
  late final TarotRitualController _c;
  late final AnimationController _extract;
  late final AnimationController _flip;

  @override
  void initState() {
    super.initState();
    _c = TarotRitualController();
    _extract = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (!mounted) return;
    await _c.bootstrap(context);
    if (!mounted) return;
    final session = TarotScope.of(context).reading.session;
    if (session?.flowStep == ReadingFlowStep.reveal &&
        session?.currentCard != null) {
      _c.active = RevealCardData.fromDrawnCard(session!.currentCard!);
      _c.setVisual(
        _c.visual.copyWith(stage: TarotRitualStage.reveal, extractionProgress: 1),
      );
      await _flip.forward(from: 0);
      if (!mounted) return;
      await _settle();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _extract.dispose();
    _flip.dispose();
    super.dispose();
  }

  Future<void> _onDraw() async {
    final ok = await _c.commitDraw(context);
    if (!ok || !mounted) return;
    await _extract.forward(from: 0);
    if (!mounted) return;
    await _flip.forward(from: 0);
    if (!mounted) return;
    await _settle();
  }

  Future<void> _settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    final openReading = await _c.settleAfterReveal(context);
    _extract.value = 0;
    _flip.value = 0;
    if (!mounted) return;
    if (openReading) {
      if (_c.leaving) return;
      _c.leaving = true;
      await Navigator.of(context).pushReplacement(
        readingRitualRoute<void>(
          page: const ReadingScreen(),
          settings: const RouteSettings(name: TarotRoutes.reading),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TarotRitualScene(
      controller: _c,
      extract: _extract,
      flip: _flip,
      onShuffleComplete: _c.completeShuffle,
      onCutComplete: () => unawaited(_c.completeCut(context)),
      onDrawCommit: () => unawaited(_onDraw()),
    );
  }
}
