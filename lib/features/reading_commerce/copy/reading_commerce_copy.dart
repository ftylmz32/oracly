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
      'Ödemeyi doğrulayamadık.\nTekrar deneyebilirsin.';
  static const granted = 'Hak hesabına eklendi.';

  static String credits({required int coffee, required int palm}) =>
      'Kahve hakkı: $coffee\nEl falı hakkı: $palm';
}
