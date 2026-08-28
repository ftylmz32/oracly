/// Current feature/stage for crash context — never user content.
library;

abstract final class CrashFeatureContext {
  CrashFeatureContext._();

  static String? _feature;
  static String? _stage;

  static void set({String? feature, String? stage}) {
    final f = feature?.trim();
    final s = stage?.trim();
    _feature = (f == null || f.isEmpty) ? null : f;
    _stage = (s == null || s.isEmpty) ? null : s;
  }

  static void clear() {
    _feature = null;
    _stage = null;
  }

  static Map<String, String> snapshot() => {
        if (_feature != null) 'feature': _feature!,
        if (_stage != null) 'stage': _stage!,
      };

  static void applyScreen(String screenName) {
    final mapped = _screenMap[screenName];
    if (mapped == null) {
      set(feature: screenName);
      return;
    }
    set(feature: mapped.$1, stage: mapped.$2);
  }

  static const _screenMap = <String, (String, String?)>{
    'tarot_home': ('tarot', 'entry'),
    'tarot_home_start': ('tarot', 'spread_select'),
    'reading': ('tarot', 'reading'),
    'coffee': ('coffee', 'entry'),
    'palm': ('palm', 'entry'),
    'dream': ('dream', 'entry'),
    'companion': ('or', 'chat'),
    'premium': ('premium', 'view'),
    'soulmate': ('soulmate', 'draw'),
    'settings': ('settings', 'view'),
    'privacy': ('settings', 'privacy'),
  };
}
