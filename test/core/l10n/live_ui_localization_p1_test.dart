/// Live UI localization — Tarot ritual, Dream, About surfaces (TR / EN / RU).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_catalogue.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_locale.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_copy.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';

void main() {
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  group('Tarot ritual chrome', () {
    const keys = {
      'tarot.ritual.deck_ready': 'Desten hazır.',
      'tarot.ritual.deck_ready_sub': 'Karıştır, kes, kartını çek.',
      'tarot.ritual.deck_preparing': 'Desten hazırlanıyor',
      'tarot.ritual.intention_title': 'Niyetin',
      'tarot.ritual.intention_sub': 'Bir soru getir',
      'tarot.ritual.intention_skip': 'Niyetsiz devam et',
      'tarot.ritual.pick_spread': 'Açılımı Seç',
      'tarot.ritual.spread_sub': 'Kartların düzenini seç.',
      'tarot.ritual.draw_hint': 'Kartı yukarı çek',
      'tarot.card.keywords': 'Anahtar Kelimeler',
      'tarot.card.related': 'İlgili Kartlar',
      'tarot.card.symbolism': 'Sembolizm',
      'tarot.card.meanings': 'Anlamlar',
      'journal.personal_reflection': 'Kişisel Yansıma',
      'journal.reflection_prompt': 'Bu an senin için ne ifade ediyor?',
      'history.journey': 'Kişisel Yolculuk',
      'history.journey_echo_themes': 'Yolculuğunda yankılanan temalar',
    };

    test('TR preserves canonical Turkish copy', () {
      OraclyL10n.bind(AppLocale.tr);
      for (final e in keys.entries) {
        expect(OraclyL10n.t(e.key), contains(e.value));
      }
      expect(
        TarotRitualCopy.prompt(TarotRitualStage.deckReady),
        'Desten hazır.',
      );
      expect(
        TarotRitualCopy.prompt(TarotRitualStage.shuffle),
        contains('karıştır'),
      );
      expect(TarotSpreadType.threeCard.label, 'Üç Kart');
      expect(RitualSpreadSlots.labels3, ['GEÇMİŞ', 'ŞİMDİ', 'GELECEK']);
      expect(OraclyL10n.t(L10nKeys.confirm), 'Onayla');
      expect(OraclyL10n.t(L10nKeys.back), 'Geri');
      expect(OraclyL10n.t('ritual.thought.title'), 'Bugün için bir düşünce');
      expect(OraclyL10n.t(L10nKeys.dream), 'Rüya');
    });

    test('EN is not Turkish for ritual surfaces', () {
      OraclyL10n.bind(AppLocale.en);
      expect(OraclyL10n.t('tarot.ritual.deck_ready'), 'Your deck is ready.');
      expect(OraclyL10n.t('tarot.ritual.intention_title'), 'Your intention');
      expect(OraclyL10n.t('tarot.card.meanings'), 'Meanings');
      expect(OraclyL10n.t('journal.personal_reflection'), 'Personal reflection');
      expect(OraclyL10n.t(L10nKeys.back), 'Back');
      expect(OraclyL10n.t(L10nKeys.ok), 'OK');
      expect(OraclyL10n.t(L10nKeys.dismiss), 'Dismiss');
      expect(OraclyL10n.t(L10nKeys.confirm), 'Confirm');
      expect(OraclyL10n.t('tarot.card.meta.arcana'), 'Arcana');
      expect(OraclyL10n.t('journal.reflection_prompt'), isNot(contains('senin')));
      expect(TarotRitualCopy.prompt(TarotRitualStage.draw), isNot(contains('çek')));
      expect(TarotSpreadType.single.label, 'One Card');
      expect(RitualSpreadSlots.labels3, ['PAST', 'NOW', 'AHEAD']);
      expect(OraclyL10n.t('ritual.thought.later'), 'Maybe later');
      expect(OraclyL10n.t('oracle.header.current'), 'Current reading');
      expect(
        CardDetailLocale.keywords(CardDetailCatalogue.forId(0)),
        contains('threshold'),
      );
      expect(
        CardDetailLocale.meaning(
          cardId: 0,
          sections: CardDetailCatalogue.forId(0).meanings,
          key: 'love',
        ),
        contains('bond'),
      );
    });

    test('RU is not Turkish for ritual surfaces', () {
      OraclyL10n.bind(AppLocale.ru);
      expect(OraclyL10n.t('tarot.ritual.deck_ready'), 'Колода готова.');
      expect(OraclyL10n.t('tarot.card.symbolism'), 'Символика');
      expect(OraclyL10n.t(L10nKeys.back), 'Назад');
      expect(OraclyL10n.t(L10nKeys.ok), 'Готово');
      expect(OraclyL10n.t(L10nKeys.confirm), 'Подтвердить');
      expect(OraclyL10n.t('tarot.card.meta.zodiac'), 'Знак');
      expect(TarotSpreadType.single.label, 'Одна карта');
      expect(RitualSpreadSlots.labels3, ['ПРОШЛОЕ', 'СЕЙЧАС', 'БУДУЩЕЕ']);
      expect(OraclyL10n.t('ritual.thought.title'), 'Мысль на сегодня');
      expect(
        CardDetailLocale.keywords(
          CardDetailCatalogue.forId(0),
        ).first,
        isNot(contains(RegExp(r'[ğüşıöçĞÜŞİÖÇ]'))),
      );
    });
  });

  group('Dream + About chrome', () {
    test('TR dream actions and semantics', () {
      OraclyL10n.bind(AppLocale.tr);
      expect(DreamCopy.writeDream, 'Rüyanı Yaz');
      expect(DreamCopy.voiceTell, 'Sesli Anlat');
      expect(DreamCopy.charCount(42), '42 karakter');
      expect(OraclyL10n.t(L10nKeys.dream), 'Rüya');
    });

    test('EN dream actions and semantics', () {
      OraclyL10n.bind(AppLocale.en);
      expect(DreamCopy.writeDream, 'Write your dream');
      expect(DreamCopy.voiceTell, 'Tell by voice');
      expect(DreamCopy.charCount(42), '42 characters');
      expect(OraclyL10n.t(L10nKeys.dream), 'Dream');
    });

    test('RU dream actions and semantics', () {
      OraclyL10n.bind(AppLocale.ru);
      expect(DreamCopy.writeDream, 'Напиши сон');
      expect(DreamCopy.voiceTell, 'Расскажи голосом');
      expect(DreamCopy.charCount(42), '42 символов');
      expect(OraclyL10n.t(L10nKeys.dream), 'Сон');
    });
  });
}
