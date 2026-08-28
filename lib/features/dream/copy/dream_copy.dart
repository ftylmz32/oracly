/// Dream Analysis user-facing copy.
library;

import '../../../core/copy/preview_capability_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';

abstract final class DreamCopy {
  DreamCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('dream.screen_title');
  static String get previewNote => PreviewCapabilityCopy.dreamNote;
  static String get previewNoteLive => PreviewCapabilityCopy.dreamNoteLive;
  static String get previewNoteNeedsOr => PreviewCapabilityCopy.dreamNoteNeedsOr;

  static String capabilityNote({
    required bool aiConfigured,
    required bool allowsLocalFallback,
  }) {
    if (aiConfigured) return previewNoteLive;
    if (allowsLocalFallback) return previewNote;
    return previewNoteNeedsOr;
  }

  static String get entryHeadline => _t('dream.entry_headline');
  static String get entryDescription => _t('dream.entry_body');
  static String get narrativeHint => _t('dream.narrative_hint');
  static String get narrativeHelper => _t('dream.helper');
  static String get narrativeTooShort => _t('dream.too_short');
  static String get emotionsLabel => _t('dream.emotions_label');
  static String get tagsLabel => _t('dream.tags');
  static String get tagHint => _t('dream.tag_hint');
  static String get voiceLabel => _t('dream.voice');
  static String get voiceComingSoon => _t('dream.voice_soon');
  static String get voiceFailed => _t('dream.voice_failed');
  static String get voiceListening => _t('dream.voice_listen');
  static String get voiceStop => _t('dream.voice_stop');
  static String get voiceReviewTitle => _t('dream.voice_review');
  static String get voiceListenAgain => _t('dream.voice_again');
  static String get voicePermissionDenied => _t('dream.voice_denied');
  static String get voicePermissionPermanent => _t('dream.voice_permanent');
  static String get voiceMicUnavailable => _t('dream.voice_mic');
  static String get voiceSpeechUnavailable => _t('dream.voice_speech');
  static String get voiceSpeechError => _t('dream.voice_error');
  static String get voiceEmpty => _t('dream.voice_empty');
  static String get beginAnalysis => _t('dream.begin');
  static String get saveAndClose => _t('dream.save_close');
  static String get newDream => _t('dream.new');
  static String get phaseUnderstanding => _t('dream.summary');
  static String get phaseUnderstandingSubtitle => _t('dream.phase_sum_sub');
  static String get phaseReflection => _t('dream.interpretation');
  static String get phaseReflectionSubtitle => _t('dream.phase_int_sub');
  static String get phaseConnection => _t('dream.phase_conn');
  static String get phaseConnectionSubtitle => _t('dream.phase_conn_sub');
  static String get phaseClosing => _t('dream.step');
  static String get summaryTitle => _t('dream.summary');
  static String get interpretationTitle => _t('dream.interpretation');
  static String get symbolsHighlightTitle => _t('dream.symbols');
  static String get emotionalMeaningTitle => _t('dream.emotion');
  static String get themesTitle => _t('dream.life');
  static String get lifeReflectionTitle => _t('dream.life');
  static String get conclusionTitle => _t('dream.step');
  static String get optionalQuestionTitle => _t('dream.ask');
  static String get deepenWithOr => _t('dream.deepen_or');
  static String get disclaimer => _t('dream.disclaimer');
  static String get sourceLocal => _t('dream.source_local');
  static String get sourceAi => _t('dream.source_ai');

  static String readingFootnote({required bool fromAi}) {
    final source = fromAi ? sourceAi : sourceLocal;
    return '$source $disclaimer';
  }

  static String get analysisFailed => _t('dream.failed');
  static String get retry => _t('dream.retry');
  static String get symbolsTitle => _t('dream.symbols_title');
  static String get emotionsTitle => _t('dream.emotions_title');
  static String get locationsTitle => _t('dream.locations');
  static String get relationshipsTitle => _t('dream.relationships');
  static String get recurringTitle => _t('dream.recurring');
  static String get noSymbols => _t('dream.no_symbols');
  static String get noLocations => _t('dream.no_locations');
  static String get noRelationships => _t('dream.no_rel');
  static String get noRecurring => _t('dream.no_recurring');
  static String get organizing =>
      OrLivingVoice.thinking(surface: OrLivingSurface.dream);
  static String get reflecting => organizing;
  static String get reflectiveQuestion => _t('dream.ask');
  static String get calmingTakeaway => _t('dream.step');
  static String get previousDreams => _t('dream.previous');
  static String get noPreviousDreams => _t('dream.no_previous');
}
