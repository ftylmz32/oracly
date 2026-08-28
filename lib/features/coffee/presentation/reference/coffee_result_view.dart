/// After vision: the real cup, then one continuous spoken reading.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feature_flags/feature_flag_rollback.dart';
import '../../../../core/feature_flags/feature_flag_surface.dart';
import '../../../../core/reading_ux/reading_long_form_scroll.dart';
import '../../../../core/reading_version/services/reading_version_payload.dart';
import '../../../personal_discovery/services/personal_theme_extractor.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_reading.dart';
import 'coffee_reference_tokens.dart';
import 'coffee_result_actions.dart';
import 'coffee_result_markers.dart';
import 'coffee_result_hero_bleed.dart';
import 'coffee_result_photo.dart';
import 'coffee_result_sections.dart';
import 'coffee_result_stable.dart';

class CoffeeResultView extends ConsumerStatefulWidget {
  const CoffeeResultView({
    super.key,
    required this.reading,
    required this.onNewCup,
    this.onReinterpret,
    this.versionReloadToken = 0,
  });

  final CoffeeReading reading;
  final VoidCallback onNewCup;
  final Future<bool> Function()? onReinterpret;
  final int versionReloadToken;

  @override
  ConsumerState<CoffeeResultView> createState() => _CoffeeResultViewState();
}

class _CoffeeResultViewState extends ConsumerState<CoffeeResultView> {
  late CoffeeReading _display;
  Uint8List? _cupBytes;
  final Map<int, GlobalKey> _markKeys = {};

  @override
  void initState() {
    super.initState();
    _display = widget.reading;
    _loadCupBytes(widget.reading.imagePath);
  }

  GlobalKey _keyFor(int index) =>
      _markKeys.putIfAbsent(index, GlobalKey.new);

  void _scrollToMark(CoffeeGroundedMark mark) {
    final ctx = _keyFor(mark.index).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  @override
  void didUpdateWidget(covariant CoffeeResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading.id != widget.reading.id ||
        oldWidget.versionReloadToken != widget.versionReloadToken) {
      _display = widget.reading;
      _loadCupBytes(widget.reading.imagePath);
    }
  }

  Future<void> _loadCupBytes(String? path) async {
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _cupBytes = null);
      return;
    }
    final file = File(path);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _cupBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final reading = _display;
    final path = reading.imagePath;
    final marks = CoffeeGroundedMarks.from(reading.symbols);
    final markKeys = {
      for (final mark in marks) mark.index: _keyFor(mark.index),
    };
    final themes = PersonalThemeExtractor.labelsIn([
      reading.overall,
      reading.career,
      reading.love,
      reading.nearFuture,
    ]);
    return ReadingLongFormScroll(
      kicker: CoffeeCopy.overallTitle,
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      children: [
        if (path != null && File(path).existsSync()) ...[
          SizedBox(height: CoffeeReferenceTokens.leadToHero),
          CoffeeResultHeroBleed(
            child: CoffeeResultPhoto(
              path: path,
              marks: marks,
              onMarkTap: _scrollToMark,
            ),
          ),
          SizedBox(height: CoffeeReferenceTokens.gap * 2.5),
        ],
        FeatureFlagRollback.useExperimental(FeatureFlagSurface.coffeeResult)
            ? CoffeeResultSections(reading: reading, markKeys: markKeys)
            : CoffeeResultStable(reading: reading, markKeys: markKeys),
        CoffeeResultActions(
          reading: reading,
          themes: themes,
          onNewCup: widget.onNewCup,
          versionReloadToken: widget.versionReloadToken,
          onReinterpret: widget.onReinterpret,
          cupImage: _cupBytes,
          onVersionSelect: (group) {
            final entry = group.activeEntry;
            if (entry == null) return;
            setState(() {
              _display = ReadingVersionPayload.applyCoffee(
                widget.reading,
                entry.data,
              );
            });
          },
        ),
      ],
    );
  }
}
