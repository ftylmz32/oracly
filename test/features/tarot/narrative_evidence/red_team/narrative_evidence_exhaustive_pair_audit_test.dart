/// Phase 3D.1E — exhaustive C(156,2) orientation-pair signal audit (test-only).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_contrasts.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_discrimination.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_profile_slice.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_transform_signals.dart';

class _Ori {
  _Ori(this.id, this.reversed, this.semantic, this.transforms);
  final String id;
  final bool reversed;
  final Set<String> semantic;
  final List<ReversedTransformKind> transforms;
}

void main() {
  test('exhaustive C(156,2) orientation pair structured metrics', () {
    final oris = <_Ori>[];
    for (final id in OraclyTarotDeck.expectedIds) {
      final profile = NarrativeTarotProfileCatalog.lookup(id)!;
      for (final rev in [false, true]) {
        final slice = TarotNarrativeProfileSlice.fromProfile(
          profile,
          isReversed: rev,
          questionKind: QuestionKind.open,
        );
        final channel = NarrativeSemanticChannel.from(
          keywordIds: slice.keywordIds,
          symbolTags: slice.symbolTags,
        );
        oris.add(_Ori(id, rev, channel.semanticIds.toSet(), slice.transforms));
      }
    }
    expect(oris.length, 156);

    var pairs = 0;
    var semanticOverlap = 0;
    var hardContrast = 0;
    var contextualOnly = 0;
    var sharedTransforms = 0;
    var ge2 = 0;
    var ge3 = 0;
    var hfOnly = 0;
    var specificOverlap = 0;
    var nanInf = 0;

    for (var i = 0; i < oris.length; i++) {
      for (var j = i + 1; j < oris.length; j++) {
        pairs++;
        final a = oris[i];
        final b = oris[j];
        final shared = a.semantic.intersection(b.semantic);
        if (shared.isNotEmpty) semanticOverlap++;
        if (shared.length >= 2) ge2++;
        if (shared.length >= 3) ge3++;

        var hasHard = false;
        var hasContextual = false;
        for (final x in a.semantic) {
          for (final y in b.semantic) {
            final c = NarrativeKeywordContrasts.between(x, y);
            if (c == NarrativeKeywordContrastClass.hard) hasHard = true;
            if (c == NarrativeKeywordContrastClass.contextual) {
              hasContextual = true;
            }
          }
        }
        if (hasHard) hardContrast++;
        if (!hasHard && hasContextual) contextualOnly++;

        final pairSignals = NarrativeTransformPairSignals.from(
          leftTransforms: a.transforms,
          rightTransforms: b.transforms,
          leftSemanticIds: a.semantic,
          rightSemanticIds: b.semantic,
        );
        if (pairSignals.effectiveSharedTransforms.isNotEmpty) {
          sharedTransforms++;
        }

        if (shared.isNotEmpty) {
          final allHf = shared.every(
            NarrativeKeywordDiscrimination.isHighFrequency,
          );
          if (allHf) {
            hfOnly++;
          } else {
            specificOverlap++;
          }
          for (final id in shared) {
            final w = NarrativeKeywordDiscrimination.weight(id);
            if (w.isNaN || w.isInfinite) nanInf++;
          }
        }
      }
    }

    expect(pairs, 12090);
    expect(nanInf, 0);
    expect(semanticOverlap, greaterThan(0));
    expect(hardContrast, greaterThan(0));
    expect(ge2, greaterThan(0));

    // ignore: avoid_print
    print({
      'pairs': pairs,
      'semanticOverlap': semanticOverlap,
      'hardContrast': hardContrast,
      'contextualOnly': contextualOnly,
      'sharedTransforms': sharedTransforms,
      'ge2': ge2,
      'ge3': ge3,
      'hfOnly': hfOnly,
      'specificOverlap': specificOverlap,
      'nanInf': nanInf,
    });
  });
}
