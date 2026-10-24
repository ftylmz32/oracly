/// Purchase-screen copy. Prices come from the store, never from this file.
library;

abstract final class ReadingCommerceCopy {
  ReadingCommerceCopy._();

  static const title = 'Fal hakkı';
  static const closed =
      'Satın alma şu anda açık değil.\nHakların hesabında durur.';
  static const unavailable =
      'Mağaza bu ürünü henüz sunmuyor.\nSatın alma düğmesi bu yüzden yok.';
  static const coffee = 'Kahve falı';
  static const palm = 'El falı';
  static const pack = '3 kahve falı';
  static const buy = 'Satın al';
  static const pending =
      'Ödeme henüz tamamlanmadı.\nHak tanımlanmadı.';
  static const canceled = 'Ödeme tamamlanmadı.';
  static const failed =
      'Ödemeyi doğrulayamadık.\nSatın alma duruyor; yeniden açınca tekrar deneriz.';
  static const granted = 'Hak hesabına eklendi.';
  static const creditNeeded =
      'Bu fal bir hak ister.\nHakların ve mağazanın durumu bir sonraki ekranda.';
  static const openCredits = 'Fal haklarına bak';
  static const billingQaNotice =
      'Bu ekran yalnız QA satın alma testidir.\nGerçek fal üretilmez. Ücretli müşteri ödemesi kabul edilmez.';
  static const billingQaEntry = 'Fal Hakları — Test Satın Alımı';

  static String credits({required int coffee, required int palm}) =>
      'Kahve hakkı: $coffee\nEl falı hakkı: $palm';
}
