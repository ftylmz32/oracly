/// Human cup/sky/chart reader — one voice, real facts only.
library;

import '../l10n/l10n.dart';
import 'human_reader_compose.dart';
import 'human_reader_guard.dart';
import 'human_reader_notice.dart';
import 'robotic_language_rewrite.dart';

export 'human_reader_guard.dart';
export 'human_reader_notice.dart';

abstract final class HumanReader {
  HumanReader._();

  static String write(HumanReaderNotice notice) {
    return HumanReaderCompose.build(notice);
  }

  static String guard(String text) =>
      RoboticLanguageRewrite.bounded(HumanReaderGuard.scrub(text));

  static bool looksGeneric(String text) =>
      HumanReaderGuard.looksGeneric(text);

  static String vesselCup() => OraclyL10n.t('reader.vessel.cup');

  static String vesselSky() => OraclyL10n.t('reader.vessel.sky');

  static String vesselChart() => OraclyL10n.t('reader.vessel.chart');

  static String vesselPalm() => OraclyL10n.t('reader.vessel.palm');

  static String vesselSpread() => OraclyL10n.t('reader.vessel.spread');
}
