/// Astrology / birth chart / yıldızname OR context — only real data.
library;

import '../../../../core/l10n/l10n.dart';
import '../../../birth_chart/models/birth_profile.dart';
import '../../../star_map/models/star_map_reading.dart';
import 'oracle_reading_context.dart';

abstract final class OracleReadingContextNatal {
  OracleReadingContextNatal._();

  static OracleReadingContext astrology({
    required String id,
    required String signLabel,
    required String daily,
    String readingType = 'Günlük',
    String? personality,
    String? love,
    String? career,
    String? money,
    String? energy,
    String? emotion,
    String? advice,
    String? opportunity,
    String? caution,
  }) {
    // Compact handoff — observation + one nuance; no full catalogue dump.
    final nuance = (advice ?? personality ?? '').trim();
    final full = [
      'Burç: $signLabel',
      'Kaynak: yerel Güneş burcu kataloğu · $readingType',
      daily.trim(),
      if (nuance.isNotEmpty)
        nuance.length > 220 ? '${nuance.substring(0, 220).trimRight()}…' : nuance,
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: id,
      kind: OracleReadingKind.astrology,
      sourceLabel: 'Astroloji',
      spreadLabel: signLabel,
      deckId: 'astrology',
      deckName: 'Burç Yorumu',
      readingTitle: signLabel,
      cardsSummary: '$signLabel · $readingType',
      interpretationSummary: daily,
      fullInterpretation: full,
    );
  }

  static OracleReadingContext starMap({
    required String sectionLabel,
    required StarMapReading reading,
    BirthProfile? profile,
    List<String> sectionLines = const [],
  }) {
    final birth = profile == null
        ? OraclyL10n.t('star.handoff.no_birth')
        : birthLine(profile);
    final sun = reading.sunLabel == null
        ? OraclyL10n.t('star.handoff.general_catalog')
        : OraclyL10n.t('star.handoff.sun_from_date')
            .replaceAll('{sign}', reading.sunLabel!);
    // Compact story handoff — opened section first; never dump whole archive.
    String clip(String raw, [int max = 280]) {
      final t = raw.trim();
      if (t.length <= max) return t;
      return '${t.substring(0, max).trimRight()}…';
    }

    final opened = [
      for (final line in sectionLines)
        if (line.trim().isNotEmpty) clip(line, 220),
    ];
    final interpretation = [
      OraclyL10n.t('star.handoff.source')
          .replaceAll('{section}', sectionLabel),
      if (opened.isNotEmpty) ...opened.take(3) else clip(reading.overview.mainMessage),
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: 'star_map_$sectionLabel',
      kind: OracleReadingKind.starMap,
      sourceLabel: OraclyL10n.t('star.handoff.source_label')
          .replaceAll('{section}', sectionLabel),
      spreadLabel: sectionLabel,
      deckId: 'star-map',
      deckName: OraclyL10n.t('star.handoff.deck_name'),
      readingTitle: sectionLabel,
      cardsSummary: '$birth · $sun',
      interpretationSummary: clip(
        opened.isNotEmpty
            ? opened.first
            : reading.overview.mainMessage,
        180,
      ),
      fullInterpretation: interpretation,
    );
  }

  static OracleReadingContext birthChart({
    required String id,
    required String sunLabel,
    required String interpretation,
    BirthProfile? profile,
    String? summary,
    String? strongThemes,
    String? notableThemes,
    List<String> placements = const [],
  }) {
    final birth = profile == null ? 'Güneş $sunLabel' : birthLine(profile);
    final full = [
      'Güneş: $sunLabel',
      'Doğum: $birth',
      if ((summary ?? '').trim().isNotEmpty) 'Özet: $summary',
      if ((strongThemes ?? '').trim().isNotEmpty) 'Güçlü temalar: $strongThemes',
      if ((notableThemes ?? '').trim().isNotEmpty)
        'Dikkat çeken: $notableThemes',
      'Yorum: $interpretation',
      if (placements.isNotEmpty) 'Yerleşimler: ${placements.join(', ')}',
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: id,
      kind: OracleReadingKind.birthChart,
      sourceLabel: 'Yıldızname',
      spreadLabel: 'Güneş $sunLabel',
      deckId: 'birth-chart',
      deckName: 'Yıldızname',
      readingTitle: 'Güneş $sunLabel',
      cardsSummary: '$birth · Güneş $sunLabel (tarihten)',
      interpretationSummary: interpretation,
      fullInterpretation: full,
    );
  }

  static String birthLine(BirthProfile profile) {
    final date =
        '${profile.birthDate.day}.${profile.birthDate.month}.${profile.birthDate.year}';
    final parts = <String>[date];
    if (profile.hasKnownTime) {
      parts.add(
        '${profile.birthTime!.hour.toString().padLeft(2, '0')}:'
        '${profile.birthTime!.minute.toString().padLeft(2, '0')}',
      );
    }
    final place = profile.birthPlace.trim();
    if (place.isNotEmpty) parts.add(place);
    return parts.join(' · ');
  }
}
