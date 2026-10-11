/// Coffee V3 three-photo capture copy (Turkish — V3 is Turkish-only): two
/// cup views + one saucer, never a fourth photo. Intention copy is shared
/// with Coffee V2 (`CoffeeV2Copy.intention*`).
library;

import '../models/coffee_v3_photo_slot.dart';

abstract final class CoffeeV3Copy {
  CoffeeV3Copy._();

  static const introTitle = 'Falın için 3 fotoğraf';
  static const introBody =
      'Fincanını iki farklı taraftan ve tabağını birlikte inceleyeceğiz.\n'
      'Her fotoğrafı göndermeden önce sen kontrol edebilirsin.';
  static const introSummaryCupA = '1 — Fincanın bir tarafı';
  static const introSummaryCupB = '2 — Fincanın diğer tarafı';
  static const introSummarySaucer = '3 — Tabak';
  static const introCta = 'Başlayalım';

  static const stepTitleCupA = 'Fincanın bir tarafı';
  static const stepTitleCupB = 'Fincanın diğer tarafı';
  static const stepTitleSaucer = 'Tabak';

  static const stepInstructionCupA =
      'Fincanın içini hafif yukarıdan çek; sapı da kadrajda görünsün.\n'
      'Telve izleri ve iç duvar net görünsün.';
  static const stepInstructionCupB =
      'Fincanı yaklaşık yarım tur çevir.\n'
      'İlk fotoğrafta görünmeyen iç yüzü çek; sapı yine görünsün.';
  static const stepInstructionSaucer =
      'Tabağın tamamı kadrajda olsun.\n'
      'Akıntı ve telve izleri görünüyorsa net görünsün.';

  static const actionTakePhoto = 'Fotoğraf çek';
  static const actionPickGallery = 'Galeriden seç';
  static const actionBack = 'Geri dön';

  static String progressLabel(int step) => '$step / 3';

  static const previewRetake = 'Tekrar çek';
  static const previewUse = 'Bu fotoğrafı kullan';

  static const reviewTitle = 'Son bir kontrol';
  static const reviewBody =
      'Üç fotoğraf da aynı fincan ve tabağa ait olmalı.\n'
      'İstersen göndermeden önce herhangi birini değiştirebilirsin.';
  static const reviewChange = 'Değiştir';
  static const reviewCta = '3 Fotoğrafı İncele';
  static const reviewCancel = 'Vazgeç ve fotoğrafları sil';

  static const duplicateMessage =
      'Bu fotoğraf zaten başka bir adımda kullanılıyor.\n'
      'Fincanı çevirip farklı bir fotoğraf ekle.';
  static const invalidPhotoMessage =
      'Bu fotoğrafı kullanamadık.\n'
      'Başka bir fotoğraf seç veya yeniden çek.';

  static const creationUnavailable =
      'Üç fotoğraflı fal şu anda başlatılamıyor.\n'
      'Fotoğrafların kayıtlı; değiştirebilir ya da vazgeçebilirsin.';
  static const createConnectionLost =
      'Falını başlatırken bağlantı koptu.\n'
      'Fotoğrafların kayıtlı; tekrar deneyebilirsin.';

  static const stagingInProgress = 'Fotoğrafların hazırlanıyor…';
  static const stagingConnectionLost =
      'Fotoğraflarını gönderirken bağlantı koptu.';
  static const stagingRetry = 'Tekrar dene';

  static int stepNumber(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupViewA => 1,
        CoffeeV3PhotoSlot.cupViewB => 2,
        CoffeeV3PhotoSlot.saucer => 3,
      };

  static String titleFor(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupViewA => stepTitleCupA,
        CoffeeV3PhotoSlot.cupViewB => stepTitleCupB,
        CoffeeV3PhotoSlot.saucer => stepTitleSaucer,
      };

  static String instructionFor(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupViewA => stepInstructionCupA,
        CoffeeV3PhotoSlot.cupViewB => stepInstructionCupB,
        CoffeeV3PhotoSlot.saucer => stepInstructionSaucer,
      };
}
