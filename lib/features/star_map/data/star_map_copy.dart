/// Date-aware Yıldızname copy. Planet catalogue stays symbolic, not natal.
library;

import '../../../core/l10n/l10n.dart';
import '../copy/star_map_polish_copy.dart';
import '../models/star_map_reading.dart';
import '../services/star_map_insight_locale.dart';

abstract final class StarMapCopy {
  StarMapCopy._();

  static String get whatItDoes => StarMapPolishCopy.capabilityNote;

  static StarMapOverview overview(int tone, {String? sunLabel}) {
    final i = tone % 3;
    final energy = OraclyL10n.t('star.voice.energy.$i');
    final message = OraclyL10n.t('star.voice.message.$i');
    final head = sunLabel == null
        ? whatItDoes
        : OraclyL10n.t('star.voice.head')
            .replaceAll('{sign}', sunLabel)
            .replaceAll('{note}', whatItDoes);
    return StarMapOverview(
      whatItSays: head,
      dominantEnergy: energy,
      mainMessage: message,
    );
  }

  static StarMapSkyMessage skyMessage(int tone, {String? sunLabel}) {
    final i = tone % 3;
    final body = OraclyL10n.t('star.voice.sky.$i');
    final today = sunLabel == null
        ? body
        : OraclyL10n.t('star.voice.sun_for')
            .replaceAll('{sign}', sunLabel)
            .replaceAll('{body}', body);
    return StarMapSkyMessage(
      today: today,
      interpretation: OraclyL10n.t('star.voice.interp.$i'),
      advice: OraclyL10n.t('star.voice.advice.$i'),
    );
  }

  static StarMapKarmicReading karmic(int theme) {
    final i = theme % 6;
    return StarMapKarmicReading(
      theme: OraclyL10n.t('star.karmic.$i.theme'),
      learning: OraclyL10n.t('star.karmic.$i.learning'),
      interpretation: OraclyL10n.t('star.karmic.$i.interpretation'),
      takeaway: OraclyL10n.t('star.karmic.$i.takeaway'),
      promptQuestion: OraclyL10n.t('star.karmic.$i.prompt'),
    );
  }

  static List<StarMapPlanetInfluence> planets(int tone) {
    final shift = tone % 3;
    const ids = [
      'sun',
      'moon',
      'mercury',
      'venus',
      'mars',
      'jupiter',
      'saturn',
    ];
    final polarities = <StarMapPolarity>[
      StarMapPolarity.balanced,
      shift == 2 ? StarMapPolarity.challenging : StarMapPolarity.balanced,
      shift == 1 ? StarMapPolarity.challenging : StarMapPolarity.supportive,
      StarMapPolarity.supportive,
      shift == 0 ? StarMapPolarity.challenging : StarMapPolarity.balanced,
      StarMapPolarity.supportive,
      shift == 2 ? StarMapPolarity.supportive : StarMapPolarity.challenging,
    ];
    return [
      for (var i = 0; i < ids.length; i++)
        StarMapPlanetInfluence(
          nameTr: StarMapInsightLocale.planetName(ids[i]),
          influence: StarMapInsightLocale.planetInfluence(ids[i]),
          explanation: StarMapInsightLocale.planetNote(ids[i], shift),
          polarity: polarities[i],
        ),
    ];
  }
}
