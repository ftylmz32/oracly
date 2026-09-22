import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';

/// Shared constants for Phase 3C.5B FR-M03 regression tests.
const kFrM03Targets = <String>[
  'cups_11',
  'swords_11',
  'swords_13',
  'swords_14',
  'wands_11',
];

const kFrM03ExpectedTransforms = <String, List<ReversedTransformKind>>{
  'cups_11': [ReversedTransformKind.excess, ReversedTransformKind.distortion],
  'swords_11': [
    ReversedTransformKind.excess,
    ReversedTransformKind.misdirection,
  ],
  'swords_13': [
    ReversedTransformKind.deficiency,
    ReversedTransformKind.distortion,
  ],
  'swords_14': [
    ReversedTransformKind.deficiency,
    ReversedTransformKind.distortion,
  ],
  'wands_11': [
    ReversedTransformKind.misdirection,
    ReversedTransformKind.excess,
  ],
};

String frM03Normalize(String raw) {
  var s = raw.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'''[.,;:!?\-—–"'()\[\]]+'''), '');
  return s.trim();
}

String frM03RevEn(String id) => NarrativeTarotProfileCatalog.lookup(
  id,
)!.reversed.expression.en.toLowerCase();
