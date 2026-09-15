/// Real backend Tarot AI E2E evidence — captured 2026-09-06 during the
/// Full App Completion audit: a genuine authenticated call to the local
/// backend (`/v1/ai/complete`, operation `tarot_reading`), real Firebase
/// Auth (anonymous, project `oracly-7f613`), real OpenAI (gpt-4o) response.
/// This test proves the client-side parse/render path handles that exact
/// real output correctly — grounded to the sent cards, no invented cards,
/// no fallback markers.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/ai_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';

// Verbatim `data.text` field from the real backend response (HTTP 200).
const _realBackendResponseText = '''
## Açılımın Teması
Bu açılım, kariyer yolculuğunuzun üç önemli aşamasını ele alıyor: geçmişteki başlangıçlar, şu anki zorluklar ve gelecekteki umut verici yönelimler.

## Kartların Mesajı
Geçmişte aldığınız riskler ve yaptığınız yeni başlangıçlar, şimdi karşılaştığınız zorlukların temelini atmış olabilir. Şu anki durum, beklenmedik değişimlerle dolu olabilir, ancak bu durum gelecekteki olumlu gelişmelerin yolunu açacaktır.

## Kariyer
Geçmişte kariyerinizde yeni bir yola adım atmışsınız. Bu dönem, özgürlük ve yeniliklerle doluydu. Şu anda ise, işinizde ani ve beklenmedik değişikliklerle karşı karşıya olabilirsiniz. Bu süreçte bazı şeylerin yıkılması, daha sağlam bir yapı kurmanız için bir fırsat olabilir. Gelecekte ise, umut dolu bir dönem sizi bekliyor. İlham ve yenilenme ile dolu bir süreçte, kariyerinizde şifalanma ve yeniden yapılanma görebilirsiniz.

## Genel Bakış
Geçmişteki saflık ve spontanlık, şu anki zorlukların temelini atmış olabilir. Ancak bu zorluklar, gelecekte daha umut dolu ve ilham verici bir kariyer yolunun kapılarını açabilir.

## Ruhsal
Ruhsal olarak, geçmişte attığınız adımlar özgürlüğünüze ve içsel yolculuğunuza yeni bir boyut katmış olabilir. Şu anda yaşadığınız kriz, ruhsal bir uyanış ve dönüşüm sürecine işaret ediyor. Gelecekte ise, içsel huzur ve ilham bulma şansınız yüksek.

## Tavsiye
Geçmişteki deneyimlerinizden ders alarak şu anki zorluklarla yüzleşin. Değişim korkutucu olabilir, ancak bu süreç size daha büyük fırsatlar ve umutlar sunacaktır.

## Kendine Sor
Geçmişte hangi riskler kariyer yolculuğunuza katkıda bulundu? Şu anki değişimlerden nasıl dersler çıkarabilirsiniz?

## Genel Enerji
Kariyerinizdeki yolculuk, inişli çıkışlı bir seyir izlemiş olsa da, genel enerji olumlu bir dönüşüm ve yenilenme sürecine işaret ediyor.

## Bugün İçin Mesaj
Bugün, yaşadığınız zorlukların sizi nerelere taşıyabileceğini düşünün ve geleceğinizdeki umut verici olasılıkları göz önünde bulundurun.

## Sonuç
Geçmişin özgür ve yenilikçi ruhu, şu anda karşılaştığınız krizlerle birleşerek gelecekte daha umut dolu ve ilham verici bir kariyer yolculuğu için zemin hazırlıyor. Şu anki zorluklar, sizi daha güçlü ve motive bir geleceğe taşıyacak.
''';

void main() {
  test('real backend Tarot response parses into a grounded, non-fallback result', () {
    final executor = AiInterpretationExecutor(
      ai: const UnconfiguredOraclyAiService(),
    );
    final result = executor.parseAiResponse(_request(), _realBackendResponseText);

    expect(result.source, InterpretationSource.ai);
    expect(result.career.toLowerCase(), contains('kariyer'));
    expect(result.summary, isNotEmpty);
    expect(result.advice, isNotEmpty);
    expect(result.closingMessage, isNotEmpty);

    // Grounded to the exact cards sent — never a card that wasn't drawn.
    const otherCards = ['Death', 'The Lovers', 'Ölüm', 'Aşıklar'];
    for (final other in otherCards) {
      expect(result.rawText, isNot(contains(other)));
    }

    // No local-fallback marker leaked into a real AI-sourced result.
    expect(result.rawText?.toLowerCase(), isNot(contains('yerel yansıma')));

    // Round-trips through persistence (JSON) without losing the AI source
    // or grounded content — proves the client persistence path is sound.
    final restored = InterpretationResult.fromJson(result.toJson());
    expect(restored.source, InterpretationSource.ai);
    expect(restored.career, result.career);
  });
}

InterpretationRequest _request() {
  return InterpretationRequest(
    requestId: 'audit-e2e-1',
    createdAt: DateTime(2026, 9, 6),
    context: ReadingContext(
      sessionId: 'audit-e2e-session',
      spreadType: TarotSpreadType.threeCard,
      spreadLabel: 'Geçmiş-Şimdi-Gelecek',
      deckId: 'rider-waite',
      language: 'tr',
      readingDate: DateTime(2026, 9, 6),
      userQuestion: 'Kariyerimde önümüzdeki dönem nasıl şekillenecek?',
      readingTheme: 'career',
      cards: const [
        ReadingCardContext(
          cardId: 0,
          cardName: 'The Fool',
          positionIndex: 0,
          positionLabel: 'Geçmiş',
          positionKey: 'past',
          isReversed: false,
          uprightMeaning: 'Yeni başlangıçlar, saflık, spontanlık.',
          reversedMeaning: 'Düşüncesizlik.',
          keywords: ['başlangıç', 'özgürlük', 'risk'],
        ),
        ReadingCardContext(
          cardId: 15,
          cardName: 'The Tower',
          positionIndex: 1,
          positionLabel: 'Şimdi',
          positionKey: 'now',
          isReversed: true,
          uprightMeaning: 'Ani yıkım, beklenmedik değişim.',
          reversedMeaning: 'Kaçınılan kriz.',
          keywords: ['kriz', 'yıkım', 'uyanış'],
        ),
        ReadingCardContext(
          cardId: 16,
          cardName: 'The Star',
          positionIndex: 2,
          positionLabel: 'Gelecek',
          positionKey: 'future',
          isReversed: false,
          uprightMeaning: 'Umut, iyileşme, ilham.',
          reversedMeaning: 'Umutsuzluk.',
          keywords: ['umut', 'şifa', 'ilham'],
        ),
      ],
    ),
  );
}
