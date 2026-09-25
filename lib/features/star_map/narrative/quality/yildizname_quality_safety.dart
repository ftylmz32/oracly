/// Safety sentinels — death, medical, legal, fatalism, diagnosis, absolutes.
library;

import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';

abstract final class YildiznameQualitySafety {
  YildiznameQualitySafety._();

  static final patterns = <RegExp>[
    // Death / lifespan (avoid ASCII-only \\b for Turkish stems)
    RegExp(r'(ölüm zaman|ölümünü|will die|certain death|lifespan|умрешь)',
        caseSensitive: false),
    // Medical
    RegExp(
      r'\b(kanser|cancer diagnosis|diagnose[sd]?|tıbbi teşhis|медицинск)',
      caseSensitive: false,
    ),
    RegExp(r'\b(bipolarsın|narcissistic personality|kişilik bozukluğu)\b',
        caseSensitive: false),
    // Pregnancy
    RegExp(r'\b(hamile|pregnancy.*(sure|certain)|беременн)',
        caseSensitive: false),
    // Financial / legal guarantee
    RegExp(
      r'\b(garanti(?:li)?\s+kazanç|financial guarantee|legal outcome|'
      r'kesin mahkeme|юридическ.*(гарант|исход))',
      caseSensitive: false,
    ),
    // Soulmate guarantee
    RegExp(
      r'\b(soulmate.*(guaranteed|certain)|kesin ruh eşi|гарантированн.*супруг)',
      caseSensitive: false,
    ),
    // Fatalism
    RegExp(
      r'\b(kaçınılmaz kader|unavoidable destiny|неизбежная судьба|'
      r'kaderin yazdığı kesin)',
      caseSensitive: false,
    ),
    // Karmic FACT claims
    RegExp(
      r'\b(geçmiş yaşamında kesin|bu karmanın cezası|karmic punishment)',
      caseSensitive: false,
    ),
    // Absolutist personality
    RegExp(r'\b(sen her zaman|sen asla|kesinlikle böylesin|'
        r'you always|you never|ты всегда|ты никогда)\b',
        caseSensitive: false),
  ];

  static void validate(YildiznameNarrativeStructuredResult result) {
    final prose = result.visibleProse;
    for (final re in patterns) {
      if (re.hasMatch(prose)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.safety,
          re.pattern,
        );
      }
    }
  }
}
