import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

/// Phase 3B4 authoring guards — assertion patterns only, not isolated nouns.
void main() {
  String blobOf(String id) {
    final p = NarrativeTarotProfileCatalog.lookup(id)!;
    final buf = StringBuffer();
    for (final f in p.semanticFields) {
      buf
        ..writeln(f.tr)
        ..writeln(f.en)
        ..writeln(f.ru);
    }
    return buf.toString();
  }

  test('Pentacles reject financial certainty and advice patterns', () {
    final patterns = <RegExp>[
      RegExp(r'\byou will (become |be )?rich\b', caseSensitive: false),
      RegExp(r'\bmoney is coming\b', caseSensitive: false),
      RegExp(r'\bguaranteed profit\b', caseSensitive: false),
      RegExp(
        r'\bthis investment will (profit|succeed)\b',
        caseSensitive: false,
      ),
      RegExp(r'\b(buy|sell) (now|this|the asset)\b', caseSensitive: false),
      RegExp(r'\byou will go bankrupt\b', caseSensitive: false),
      RegExp(
        r'\byou will inherit (money|wealth|property)\b',
        caseSensitive: false,
      ),
      RegExp(r'\btake a loan\b', caseSensitive: false),
      RegExp(
        r'\bthis business will (definitely )?succeed\b',
        caseSensitive: false,
      ),
      RegExp(
        r'zengin olacaksın|para gelecek|iflas edeceksin',
        caseSensitive: false,
      ),
      RegExp(r'miras alacaksın|kredi çek', caseSensitive: false),
      RegExp(
        r'ты станешь богат|деньги придут|обанкротишься',
        caseSensitive: false,
      ),
      RegExp(r'унаследуешь деньги|возьми кредит', caseSensitive: false),
    ];
    for (final p in NarrativeTarotProfileCatalog.pentaclesProfiles) {
      final text = blobOf(p.canonicalCardId);
      for (final re in patterns) {
        expect(
          re.hasMatch(text),
          isFalse,
          reason: '${p.canonicalCardId} matched ${re.pattern}',
        );
      }
    }
  });

  test('Pentacles reject medical diagnosis and treatment assertions', () {
    final patterns = <RegExp>[
      RegExp(
        r'\byou have (a |an )?(disease|illness|deficiency)\b',
        caseSensitive: false,
      ),
      RegExp(r'\byou (are|will be) pregnant\b', caseSensitive: false),
      RegExp(r'\byou will recover\b', caseSensitive: false),
      RegExp(r'\bstop (your )?medication\b', caseSensitive: false),
      RegExp(r'\byour illness is caused\b', caseSensitive: false),
      RegExp(r'hastasın|hamilesin|ilacı bırak', caseSensitive: false),
      RegExp(r'ты (больн|беременн)|брось лекарств', caseSensitive: false),
    ];
    for (final p in NarrativeTarotProfileCatalog.pentaclesProfiles) {
      final text = blobOf(p.canonicalCardId);
      for (final re in patterns) {
        expect(
          re.hasMatch(text),
          isFalse,
          reason: '${p.canonicalCardId} matched ${re.pattern}',
        );
      }
    }
  });

  test('pentacles_05 hardship safety — strain without fate predictions', () {
    final text = blobOf('pentacles_05').toLowerCase();
    expect(
      text.contains('scarcity') ||
          text.contains('kıtlık') ||
          text.contains('нехват') ||
          text.contains('outside') ||
          text.contains('eşik'),
      isTrue,
    );
    expect(RegExp(r'\bbankrupt').hasMatch(text), isFalse);
    expect(RegExp(r'\bhomeless').hasMatch(text), isFalse);
    expect(RegExp(r'\byou will lose (your )?job\b').hasMatch(text), isFalse);
    expect(RegExp(r'\bmedical crisis\b').hasMatch(text), isFalse);
    expect(RegExp(r'iflas|evsiz|işsiz kalacaksın').hasMatch(text), isFalse);
    expect(RegExp(r'банкрот|бездомн|потеряешь работу').hasMatch(text), isFalse);
  });

  test(
    'pentacles_07 investment safety — cultivation without market advice',
    () {
      final text = blobOf('pentacles_07').toLowerCase();
      expect(
        text.contains('patience') ||
            text.contains('sabır') ||
            text.contains('терпени') ||
            text.contains('ripe') ||
            text.contains('cultivat'),
        isTrue,
      );
      expect(RegExp(r'\b(buy|sell) now\b').hasMatch(text), isFalse);
      expect(
        RegExp(r'\bhold (this|the) (asset|stock)\b').hasMatch(text),
        isFalse,
      );
      expect(RegExp(r'\bdouble down\b').hasMatch(text), isFalse);
      expect(RegExp(r'\broi\b').hasMatch(text), isFalse);
      expect(RegExp(r'\bguaranteed (profit|return)\b').hasMatch(text), isFalse);
      expect(
        RegExp(r'al şimdi|sat şimdi|getiri garant').hasMatch(text),
        isFalse,
      );
      expect(
        RegExp(r'купи сейчас|продай сейчас|гарантированн').hasMatch(text),
        isFalse,
      );
    },
  );

  test(
    'pentacles_10 legacy safety — structure without inheritance guarantee',
    () {
      final text = blobOf('pentacles_10').toLowerCase();
      expect(
        text.contains('lineage') ||
            text.contains('legacy') ||
            text.contains('soy') ||
            text.contains('род') ||
            text.contains('structure') ||
            text.contains('kök'),
        isTrue,
      );
      expect(RegExp(r'\byou will inherit\b').hasMatch(text), isFalse);
      expect(
        RegExp(r'\bfamily (money|wealth) is coming\b').hasMatch(text),
        isFalse,
      );
      expect(
        RegExp(r'\byou will own (property|land)\b').hasMatch(text),
        isFalse,
      );
      expect(
        RegExp(r'miras alacaksın|mülk sahibi olacaksın').hasMatch(text),
        isFalse,
      );
      expect(
        RegExp(r'ты унаследуешь|получишь наследство').hasMatch(text),
        isFalse,
      );
    },
  );
}
