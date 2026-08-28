/// Local beats for respectful disagreement — kind, never patronizing.
library;

import '../../../core/l10n/l10n.dart';
import 'companion_intent.dart';

enum CompanionDirectnessKind {
  none,
  disagree,
  slowDown,
  overthink,
  unconvincing,
}

abstract final class CompanionDirectness {
  CompanionDirectness._();

  static CompanionDirectnessKind detect(String text) {
    if (CompanionIntent.isOverconfident(text)) {
      return CompanionDirectnessKind.disagree;
    }
    final t = text.toLowerCase();
    if (_overthink(t)) return CompanionDirectnessKind.overthink;
    if (_rush(t)) return CompanionDirectnessKind.slowDown;
    if (_unconvincing(t)) return CompanionDirectnessKind.unconvincing;
    return CompanionDirectnessKind.none;
  }

  static String? line(CompanionDirectnessKind kind) => switch (kind) {
        CompanionDirectnessKind.none => null,
        CompanionDirectnessKind.disagree => OraclyL10n.t('or.disagree'),
        CompanionDirectnessKind.slowDown => OraclyL10n.t('or.direct.slow'),
        CompanionDirectnessKind.overthink => OraclyL10n.t('or.direct.overthink'),
        CompanionDirectnessKind.unconvincing =>
          OraclyL10n.t('or.direct.unconvincing'),
      };

  static bool _overthink(String t) {
    if (t.contains('?') && t.length < 40) return false;
    return t.contains('sürekli düşün') ||
        t.contains('kafamda dön') ||
        t.contains('düşünmekten') ||
        t.contains('overthink') ||
        t.contains("can't stop thinking") ||
        t.contains("cannot stop thinking") ||
        t.contains('зациклил') ||
        (t.contains('düşünüyorum') &&
            (t.contains('ama') || t.contains('hiç') || t.length > 60));
  }

  static bool _rush(String t) {
    return t.contains('hemen istifa') ||
        t.contains('yarın bırak') ||
        t.contains('acele karar') ||
        t.contains('hemen karar') ||
        t.contains('right now i should quit') ||
        t.contains('quit tomorrow') ||
        t.contains('сейчас уволиться') ||
        (t.contains('hemen') &&
            (t.contains('iş') || t.contains('bırak') || t.contains('karar')));
  }

  static bool _unconvincing(String t) {
    if (t.contains('?')) return false;
    return t.contains('hiç şüphem yok') ||
        t.contains('kesinlikle haklıyım') ||
        t.contains('tek doğru bu') ||
        t.contains('no doubt i am right') ||
        t.contains('i am definitely right') ||
        t.contains('я точно прав');
  }
}
