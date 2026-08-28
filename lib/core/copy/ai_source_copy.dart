/// Live vs local honesty labels for metadata / Ask OR / non-OR surfaces.
/// Canonical OR chat ([CompanionReferenceScreen]) must not render these.
library;

import '../l10n/l10n.dart';

abstract final class AiSourceCopy {
  AiSourceCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get homeChatTitle => _t(L10nKeys.aiChat);
  static String get homeChatAppBar => _t('or.screen_title');
  static String get sourceLive => _t('ai.source_live');
  static String get sourceLocal => _t('ai.source_local');
  static String get surfaceLive => _t('ai.surface_live');
  static String get surfaceLocal => _t('ai.surface_local');
  static String get orAskLive => _t('ai.or_ask_live');
  static String get orAskLocal => _t('ai.or_ask_local');
  static String get thinkingLive => _t('or.thinking');
  static String get thinkingLocal => _t('ai.thinking_local');
  static const metaLive = 'ai';
  static const metaLocal = 'local';

  static String footnote({required bool fromAi}) =>
      fromAi ? sourceLive : sourceLocal;

  static String surfaceNote({required bool fromAi}) =>
      fromAi ? surfaceLive : surfaceLocal;

  static String orAskFootnote({required bool fromAi}) =>
      fromAi ? orAskLive : orAskLocal;

  static String thinking({required bool fromAi}) =>
      fromAi ? thinkingLive : thinkingLocal;

  static Map<String, String> tag({required bool fromAi}) => {
        'source': fromAi ? metaLive : metaLocal,
      };

  static bool isLive(Map<String, String> metadata) =>
      metadata['source'] == metaLive;

  static bool isLocal(Map<String, String> metadata) =>
      metadata['source'] == metaLocal;
}
