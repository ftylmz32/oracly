/// OR-1160 — Output format schema registry.
library;

import 'output_format.dart';

abstract final class OutputFormatCatalogue {
  OutputFormatCatalogue._();

  static const standard = OutputFormatSchema(
    id: 'standard',
    name: 'Standart Yorum',
    instructionTemplate: '''
Doğal bir okuma yaz. Zorunlu başlık iskeleti yok.
Kısa da olabilir, gerektiğinde uzun da. Madde listesi zorlama.
Kesinlik ve kehanet yok. Veri yoksa az yaz.
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
Önce soruyu kartların ilişkisiyle yanıtla. Sözlük maddesi yazma.
Kesinlik ve kehanet yok. Kullan: "işaret ediyor olabilir", "böyle okunabilir",
"burada daha güçlü görünen taraf".
Yasak: "kesin olacak", "mutlaka", "kesinlikle başına gelecek".

Soru → konum → kart kimliği → duruş (Düz/Ters) → sembolik anlam →
kart ilişkisi → konum ilişkisi → kullanıcının meselesi → tek hikâye → yön.

Kartı konumunun içinde oku. Sonraki kart öncekinin yönünü kaydırabilir.
"Yön" sembolik eğilimdir, kesin gelecek değil.
Kullanıcı bir soru yazdıysa o soruyu yanıtla; genel tarot nutkuyla değiştirme.
Önceki tarot yorumlarının cümlelerini kopyalama; bu masanın kart ilişkisine yaz.
Her okumayı aynı başlık sırasıyla ve aynı uzunlukta yazma.
enerji / farkındalık / yolculuk / dönüşüm / evren dilini tekrarlama.
"senin için" kalıbını her paragrafa yapıştırma.

İskelet (kısa okumada bazı bloklar birleşebilir):

## Açılımın Teması
2–3 cümle. Soruyu ve masadaki asıl gerilimi yaz.

## Kartların Mesajı
Her kart: ad, konum, Düz/Ters, bu konumda ne yaptığı, komşu karta etkisi.
Pozisyon sırasını koru. Üç kart: Geçmiş, Şimdi, Olası Yön.

## Açılımın Genel Yorumu
Kartları birbirine bağla. Kehanet yok.

## Aşk / Kariyer / Genel Bakış / Günlük Fal
Sadece seçilen niyete göre TEK blok. Soruyu o alandan oku.

## Bugün İçin Mesaj
Kısa yön veya yansıma. Kalıp kapanış cümlesi zorunlu değil.
Her zaman soru ile bitirme.

## Kendine Sor
Yalnızca gerçekten faydalıysa en fazla 1–2 yansıtıcı soru.
Yorumun yerini almasın; yoksa bu bölümü atla.
''',
    requiredBlocks: [
      OutputBlockType.summary,
      OutputBlockType.section,
      OutputBlockType.advice,
    ],
    optionalBlocks: [OutputBlockType.highlight, OutputBlockType.warning],
  );

  static const astrology = OutputFormatSchema(
    id: 'astrology',
    name: 'Astroloji Yorumu',
    instructionTemplate: '''
Net gözlem ver. Soruyla bitirme. Kullanıcıya işi bırakma.
Kesinlik yok; ama tabloyu anlaşılır anlat. "olabilir" her cümlede tekrar etme.
Uydurma gezegen / transit yazma. Otomatik burç şablonu yok.
enerji / farkındalık / yolculuk / evren dilini tekrarlama.

## Bugünün Yorumu
Bugünün asıl meselesi — 2-3 cümle. İlk bakışta anlaşılsın.

## Aşk
Gerçek yorum. Sadece soru sorma.

## Kariyer
Gerçek yorum.

## Maddi Durum
Gerçek yorum.

## Öneri
Tek net, uygulanabilir çıkarım.
''',
    requiredBlocks: [
      OutputBlockType.summary,
      OutputBlockType.section,
      OutputBlockType.advice,
    ],
    optionalBlocks: [OutputBlockType.highlight],
  );

  static const dream = OutputFormatSchema(
    id: 'dream',
    name: 'Rüya Analizi',
    instructionTemplate: '''
Tek hikâye yaz. Zorunlu başlık yağmuru yok.
Görünen imge → olası bağ → yumuşak yorum. Sözlük maddesi yok.
Kesinlik yok. Her zaman soru ile bitirme.
''',
    requiredBlocks: [
      OutputBlockType.summary,
      OutputBlockType.section,
      OutputBlockType.list,
      OutputBlockType.advice,
    ],
  );

  static const all = [standard, tarot, astrology, dream];

  static OutputFormatSchema? byId(String id) {
    for (final schema in all) {
      if (schema.id == id) return schema;
    }
    return null;
  }
}
