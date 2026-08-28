/// The user's hand settles, then one spoken reading follows.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_soft_reveal.dart';
import '../../../core/reading_ux/reading_long_form_scroll.dart';
import '../../../core/reading_version/services/reading_version_payload.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../copy/palm_copy.dart';
import '../models/palm_reading.dart';
import 'palm_result_actions.dart';
import 'palm_result_photo.dart';
import 'palm_result_sections.dart';

class PalmResultView extends ConsumerStatefulWidget {
  const PalmResultView({
    super.key,
    required this.reading,
    required this.onNewPalm,
    this.onReinterpret,
    this.versionReloadToken = 0,
  });

  final PalmReading reading;
  final VoidCallback onNewPalm;
  final Future<bool> Function()? onReinterpret;
  final int versionReloadToken;

  @override
  ConsumerState<PalmResultView> createState() => _PalmResultViewState();
}

class _PalmResultViewState extends ConsumerState<PalmResultView> {
  late PalmReading _display;

  @override
  void initState() {
    super.initState();
    _display = widget.reading;
  }

  @override
  void didUpdateWidget(covariant PalmResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading.id != widget.reading.id ||
        oldWidget.versionReloadToken != widget.versionReloadToken) {
      _display = widget.reading;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = _display;
    final path = reading.imagePath;
    return ReadingLongFormScroll(
      kicker: PalmCopy.overallTitle,
      // Parent chamber already applies side padding.
      padding: EdgeInsets.zero,
      children: [
        if (path != null && File(path).existsSync()) ...[
          SizedBox(height: CraftsmanshipRhythm.afterTitle),
          PalmResultPhoto(path: path),
          SizedBox(height: CraftsmanshipRhythm.betweenActs * 0.45),
        ],
        OraclySoftReveal(
          delay: const Duration(milliseconds: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PalmResultSections(reading: reading),
              PalmResultActions(
                reading: reading,
                onNewPalm: widget.onNewPalm,
                versionReloadToken: widget.versionReloadToken,
                onReinterpret: widget.onReinterpret,
                onVersionSelect: (group) {
                  final entry = group.activeEntry;
                  if (entry == null) return;
                  setState(() {
                    _display = ReadingVersionPayload.applyPalm(
                      widget.reading,
                      entry.data,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
