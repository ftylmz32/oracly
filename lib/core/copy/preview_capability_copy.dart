/// Shared preview / capability labels for catalogue-level live surfaces.
library;

import '../l10n/l10n.dart';

abstract final class PreviewCapabilityCopy {
  PreviewCapabilityCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get badge => _t('preview.badge');
  static String get dreamNote => _t('preview.dream');
  static String get dreamNoteLive => _t('preview.dream_live');
  static String get dreamNoteNeedsOr => _t('preview.dream_or');
  static String get astrologyLabel => _t('preview.astro');
  static String get astrologyDetail => _t('preview.astro_detail');
  static String get starMapNote => _t('star.capability');
  static String get birthChartNote => _t('birth.capability');
}
