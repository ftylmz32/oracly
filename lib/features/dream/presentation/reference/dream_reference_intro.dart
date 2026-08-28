/// Dream Analysis intro — wording matches AI / catalogue / fail-closed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/preview_capability_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../ai/production/oracly_ai_providers.dart';
import '../../copy/dream_copy.dart';

class DreamReferenceIntro extends ConsumerWidget {
  const DreamReferenceIntro({super.key, this.note});

  final String? note;

  static String get copy => PreviewCapabilityCopy.dreamNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = note ?? _noteFor(ref);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: OraclyChrome.bodySecondary(size: 12).copyWith(
        height: 1.22,
        color: Colors.white.withValues(alpha: 0.72),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _noteFor(WidgetRef ref) {
    final ai = ref.watch(oraclyAiServiceProvider);
    return DreamCopy.capabilityNote(
      aiConfigured: ai.isConfigured,
      allowsLocalFallback: ai.allowsLocalFallback,
    );
  }
}
