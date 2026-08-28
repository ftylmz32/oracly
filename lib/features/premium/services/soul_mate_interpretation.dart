/// Deterministic local note for a portrait. Never claimed as AI.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/reading/human_reader.dart';
import '../data/soul_mate_interpretation_catalogue.dart';
import 'soul_mate_draw_port.dart';
import 'soul_mate_season.dart';

abstract final class SoulMateInterpretation {
  SoulMateInterpretation._();

  static String forRequest(SoulMateDrawRequest request) {
    return partsFor(request).joined;
  }

  static SoulMateReadingParts partsFor(SoulMateDrawRequest request) {
    final seed = [
      request.name.trim().toLowerCase(),
      request.birthDate.toIso8601String().split('T').first,
      request.gender?.name ?? '',
      (request.intention ?? '').trim().toLowerCase(),
    ].join('|');
    final raw = SoulMateInterpretationCatalogue.forInputs(
      name: request.name,
      intention: (request.intention ?? '').trim(),
      season: SoulMateSeason.label(request.birthDate),
      preference: _preference(request.gender),
      tone: seed.hashCode.abs(),
    );
    return SoulMateReadingParts(
      energy: HumanReader.guard(raw.energy),
      attraction: HumanReader.guard(raw.attraction),
      dynamics: HumanReader.guard(raw.dynamics),
      feeling: HumanReader.guard(raw.feeling),
      yourSide: HumanReader.guard(raw.yourSide),
    );
  }

  static String _preference(SoulMateGenderPref? gender) {
    return switch (gender) {
      SoulMateGenderPref.feminine => OraclyL10n.t('soulmate.gender_feminine'),
      SoulMateGenderPref.masculine => OraclyL10n.t('soulmate.gender_masculine'),
      null => '',
    };
  }
}
