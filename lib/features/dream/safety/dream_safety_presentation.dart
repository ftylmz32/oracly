/// Ephemeral local safety guidance shown instead of a reading. Holds no
/// narrative, is never a Dream, and is never saved, versioned or shared.
library;

import '../../../core/l10n/l10n.dart';
import 'dream_safety_concern.dart';

class DreamSafetyPresentation {
  const DreamSafetyPresentation({
    required this.concern,
    required this.language,
  });

  final DreamSafetyConcern concern;

  /// Operation language captured when the concern was found.
  final String language;

  String get title => _t('dream.safety.${concern.code}.title');
  String get body => _t('dream.safety.${concern.code}.body');
  String get editLabel => _t('dream.safety.action.edit');
  String get newDreamLabel => _t('dream.safety.action.new');

  String _t(String key) => OraclyL10n.t(key, languageCode: language);
}
