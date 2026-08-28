/// Binds Yıldızname to real discovery themes. Never invents natal data.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/reading/human_reader.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../copy/star_map_polish_copy.dart';
import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_reading_presentation.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'star_map_archive_story.dart';

abstract final class StarMapPersonalization {
  StarMapPersonalization._();

  static StarMapReading overlay({
    required StarMapReading base,
    PersonalDiscoveryProfile? discovery,
    required DateTime day,
    List<String> selectedThemes = const [],
  }) {
    final themes = selectedThemes.isNotEmpty
        ? selectedThemes
        : (discovery?.observedRecurringLabels ?? const <String>[]);
    final sun = base.sunLabel ?? '';
    final seed = day.year * 17 + day.month * 29 + day.day + sun.length;
    final focus = themes.isEmpty ? '' : _focus(themes, day);
    return StarMapReading(
      overview: StarMapOverview(
        whatItSays: base.overview.whatItSays,
        dominantEnergy: base.overview.dominantEnergy,
        mainMessage: StarMapArchiveStory.composeToday(
          sign: sun,
          catalog: base.overview.mainMessage,
          life: focus,
          seed: seed,
        ),
      ),
      skyMessage: StarMapSkyMessage(
        today: StarMapArchiveStory.composeSky(
          sign: sun,
          catalog: base.skyMessage.today,
          life: focus,
          seed: seed,
        ),
        interpretation: HumanReader.guard(base.skyMessage.interpretation),
        advice: HumanReader.guard(base.skyMessage.advice),
      ),
      karmic: base.karmic,
      planets: base.planets,
      isPersonalized: base.isPersonalized,
      sunLabel: base.sunLabel,
      innerThemesLine: themes.isEmpty
          ? PersonalThemeCopy.insufficient
          : PersonalThemeCopy.recurring(themes),
      recurringThemesLine: themes.isEmpty
          ? PersonalThemeCopy.insufficient
          : PersonalThemeCopy.crossModal(themes),
      todayReflection: themes.isEmpty
          ? PersonalThemeCopy.insufficient
          : StarMapArchiveStory.composeToday(
              sign: sun,
              catalog: base.overview.mainMessage,
              life: focus,
              seed: seed,
            ),
    );
  }

  static List<StarMapResultSection> innerThemeSections(StarMapReading reading) {
    final hasHistory = !StarMapReadingPresentation.isInsufficient(
          reading.innerThemesLine,
        ) ||
        !StarMapReadingPresentation.isInsufficient(reading.recurringThemesLine);

    final sections = <StarMapResultSection>[
      StarMapResultSection(
        title: StarMapPolishCopy.todayReflectionTitle,
        body: StarMapReadingPresentation.todayBody(reading),
      ),
    ];

    if (hasHistory) {
      sections.addAll([
        StarMapResultSection(
          title: StarMapPolishCopy.karmicResultTitle,
          body: StarMapReadingPresentation.innerBody(reading),
        ),
        StarMapResultSection(
          title: StarMapPolishCopy.journeyTitle,
          body: StarMapReadingPresentation.journeyBody(reading),
        ),
        StarMapResultSection(
          title: StarMapPolishCopy.karmicAsk,
          body: StarMapReadingPresentation.thresholdBody(reading),
        ),
      ]);
    } else {
      // First archive entry — do not invent chapter history.
      sections.add(
        StarMapResultSection(
          title: StarMapPolishCopy.journeyTitle,
          body: StarMapPolishCopy.journeyEmpty,
        ),
      );
    }

    sections.add(
      StarMapResultSection(
        title: StarMapPolishCopy.leftQuestionTitle,
        body: StarMapReadingPresentation.questionBody(reading),
      ),
    );
    return sections;
  }

  static String _focus(List<String> themes, DateTime day) {
    final clean = [
      for (final raw in themes)
        DiscoveryTheme.resolve(raw)?.localized ?? raw.trim(),
    ].where((e) => e.isNotEmpty).toList();
    if (clean.isEmpty) return '';
    if (clean.length == 1) return clean.first;
    final a = clean[day.day % clean.length];
    final b = clean[(day.day + 1) % clean.length];
    if (a == b) return a;
    return '$a ${OraclyL10n.t('birth.conj_and')} $b';
  }
}
