/// OR-1160 — Output format schema registry.
library;

import 'output_format.dart';

abstract final class OutputFormatCatalogue {
  OutputFormatCatalogue._();

  static const standard = OutputFormatSchema(
    id: 'standard',
    name: 'Standart Yorum',
    instructionTemplate: '''
Yanıtını aşağıdaki yapıda ver:
## Özet
Kısa genel özet.

## Detay
Ana yorum metni.

## Tavsiye
Pratik rehberlik maddeleri.

## Uyarı
{{#if showWarnings}}Dikkat edilmesi gereken noktalar.{{/if}}
''',
    requiredBlocks: [
      OutputBlockType.summary,
      OutputBlockType.section,
      OutputBlockType.advice,
    ],
    optionalBlocks: [OutputBlockType.warning, OutputBlockType.highlight],
  );

  static const tarot = OutputFormatSchema(
    id: 'tarot',
    name: 'Tarot Yorumu',
    instructionTemplate: '''
EPIC-013 — Yansıtıcı okuma yapısı. Kesinlik kullanma.

## Öne Çıkanlar
Kartlarda dikkat çeken gözlemler — ne belirdi, nasıl bir ton var.

## Ne Temsil Edebilir
Aşk, kariyer ve maddi alanlar için olası yorumlar ("olabilir", "hissediliyor olabilir").

## Düşünmeye Değer Sorular
Kullanıcıyı kendi deneyimine davet eden 2–4 nazik soru.

## Nazik Pratik Öneri
Küçük, baskısız bir adım — bağımlılık yaratma.

## Sakin Kapanış
Tek cümle — kullanıcıyla kalan sessiz yansıma. Tahmin, uyarı veya geri dön baskısı yok.
Kullanıcı huzurla ayrılabilsin; "bu birkaç dakikaya değerdi" hissi bırak.
''',
    requiredBlocks: [
      OutputBlockType.summary,
      OutputBlockType.section,
      OutputBlockType.advice,
    ],
    optionalBlocks: [OutputBlockType.highlight, OutputBlockType.warning],
  );

  static const dream = OutputFormatSchema(
    id: 'dream',
    name: 'Rüya Analizi',
    instructionTemplate: '''
## Rüya Özeti
## Semboller
## Psikolojik Katman
## Mesaj
## Tavsiye
''',
    requiredBlocks: [
      OutputBlockType.summary,
      OutputBlockType.section,
      OutputBlockType.list,
      OutputBlockType.advice,
    ],
  );

  static const all = [standard, tarot, dream];

  static OutputFormatSchema? byId(String id) {
    for (final schema in all) {
      if (schema.id == id) return schema;
    }
    return null;
  }
}
