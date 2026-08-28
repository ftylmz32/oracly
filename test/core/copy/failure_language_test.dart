/// Error / empty / loading language — calm, localized, never technical.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/network/network_exception.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/core/security/ai_error_sanitizer.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('loading copy is feature-specific and never fake progress', () {
    expect(
      CoffeeCopy.analyzing,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.coffee)),
    );
    expect(
      PalmCopy.analyzing,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.palm)),
    );
    expect(
      DreamCopy.reflecting,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.dream)),
    );
    expect(
      SoulMateCopy.drawing,
      'Portrede öne çıkan detayları hazırlıyorum...',
    );
    expect(
      CompanionCopy.thinking,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.or)),
    );
    for (final line in [
      CoffeeCopy.analyzing,
      PalmCopy.analyzing,
      DreamCopy.reflecting,
      SoulMateCopy.drawing,
      CompanionCopy.thinking,
    ]) {
      expect(line, isNot(contains('%')));
      expect(line.toLowerCase(), isNot(contains('progress')));
    }
  });

  test('network copy is calm and always offers a retry', () {
    expect(ResilienceCopy.offline, contains('Bağlantı kurulamadı'));
    expect(CompanionCopy.offline, contains('Bağlantı kurulamadı'));
    expect(ResilienceCopy.retryAction, 'TEKRAR DENE');
    expect(CompanionCopy.retry, 'Tekrar dene');
    expect(CoffeeCopy.retry, 'TEKRAR DENE');
    expect(ResilienceCopy.offline, isNot(equals('Bir hata oluştu.')));
    expect(ResilienceCopy.temporaryFailure, contains('Geçici'));
    expect(ResilienceCopy.analysisUnavailable, contains('Analiz'));
  });

  test('journal empty is honest and feature-specific', () {
    expect(
      DiscoveryJournalCopy.emptyTitle,
      'İlk keşiflerin burada yerini bulacak.',
    );
    expect(CoffeeCopy.emptyHistory.toLowerCase(), contains('fincan'));
    expect(DreamCopy.noPreviousDreams.toLowerCase(), contains('rüya'));
  });

  test('provider failures become localized copy, never raw internals', () {
    expect(AiErrorSanitizer.guard('HTTP 500'), ResilienceCopy.aiUnavailable);
    expect(
      AiErrorSanitizer.guard('OpenAI timeout Exception'),
      ResilienceCopy.aiUnavailable,
    );
    expect(
      AiErrorSanitizer.guard('#0      Foo.bar (package:x/y.dart:12:3)'),
      ResilienceCopy.aiUnavailable,
    );
    expect(AiErrorSanitizer.guard('network'), ResilienceCopy.aiUnavailable);
    expect(AiErrorSanitizer.guard('offline'), ResilienceCopy.offline);
    expect(AiErrorSanitizer.guard('no_connection'), ResilienceCopy.offline);
    expect(AiErrorSanitizer.guard('rate_limit'), ResilienceCopy.aiRateLimited);
    expect(
      AiErrorSanitizer.guard('provider_error'),
      ResilienceCopy.aiUnavailable,
    );
    expect(
      AiErrorSanitizer.publicMessage(
        error: NetworkException.fromStatusCode(503),
      ),
      ResilienceCopy.aiUnavailable,
    );
    expect(
      AiErrorSanitizer.publicMessage(
        error: NetworkException.noConnection(),
      ),
      ResilienceCopy.offline,
    );
    final shown = AiErrorSanitizer.publicMessage(
      error: Exception('status 429 from openai proxy'),
    );
    expect(shown.toLowerCase(), isNot(contains('429')));
    expect(shown.toLowerCase(), isNot(contains('openai')));
    expect(shown.toLowerCase(), isNot(contains('proxy')));
    expect(shown.toLowerCase(), isNot(contains('exception')));
    expect(ConversationCopy.oracleUnavailable, ResilienceCopy.aiUnavailable);
  });

  test('loading and network copy exist in EN and RU', () {
    for (final code in ['en', 'ru']) {
      OraclyL10n.bind(code);
      expect(CoffeeCopy.analyzing, isNot(contains('Fincana')));
      expect(PalmCopy.analyzing, isNot(contains('Çizgileri')));
      expect(DreamCopy.reflecting, isNotEmpty);
      expect(SoulMateCopy.drawing, isNot(contains('Portrede')));
      expect(CompanionCopy.thinking, isNot(contains('Bir saniye')));
      expect(ResilienceCopy.offline, isNot(contains('Bağlantı koptu')));
      expect(ResilienceCopy.retryAction, isNot(contains('TEKRAR')));
      expect(DiscoveryJournalCopy.emptyTitle, isNot(contains('Henüz')));
    }
  });
}
