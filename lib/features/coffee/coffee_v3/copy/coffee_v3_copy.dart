/// Coffee V3 four-view capture copy (Turkish — V3 is Turkish-only). Core
/// meanings are locked by the product owner; do not rephrase. Intention
/// copy is shared with Coffee V2 (`CoffeeV2Copy.intention*`).
library;

import '../models/coffee_v3_photo_slot.dart';

abstract final class CoffeeV3Copy {
  CoffeeV3Copy._();

  static const introTitle = 'Falın için 4 fotoğraf';
  static const introBody =
      'Fincanı üç farklı açıdan ve tabağını birlikte inceleyeceğiz.\n'
      'Her fotoğrafı göndermeden önce sen kontrol edebilirsin.';
  static const introSummaryHandleFar = '1 — Sap karşıdayken fincan';
  static const introSummaryTurnA = '2 — Fincanın ikinci açısı';
  static const introSummaryTurnB = '3 — Fincanın üçüncü açısı';
  static const introSummarySaucer = '4 — Tabak';
  static const introCta = 'Başlayalım';

  static const stepTitleHandleFar = 'Sap karşıdayken fincan';
  static const stepTitleTurnA = 'Fincanın ikinci açısı';
  static const stepTitleTurnB = 'Fincanın üçüncü açısı';
  static const stepTitleSaucer = 'Tabak';

  static const stepInstructionHandleFar =
      'Fincanın sapı karşı tarafta kalsın.\n'
      'İçini hafif yukarıdan çek; telve izleri ve iç duvar net görünsün.';
  static const stepInstructionTurnA =
      'Fincanı yaklaşık üçte bir tur çevir.\n'
      'İlk fotoğrafta görünmeyen iç yüzü çek.';
  static const stepInstructionTurnB =
      'Fincanı aynı yönde bir kez daha yaklaşık üçte bir tur çevir.\n'
      'Kalan iç yüzü çek.';
  static const stepInstructionSaucer =
      'Tabağın tamamı kadrajda olsun.\n'
      'Akıntı ve telve izleri görünüyorsa net görünsün.';

  static const actionTakePhoto = 'Fotoğraf çek';
  static const actionPickGallery = 'Galeriden seç';
  static const actionBack = 'Geri dön';

  static String progressLabel(int step) => '$step / 4';

  static const previewRetake = 'Tekrar çek';
  static const previewUse = 'Bu fotoğrafı kullan';

  static const reviewTitle = 'Son bir kontrol';
  static const reviewBody =
      'Dört fotoğraf da aynı fincan ve tabağa ait olmalı.\n'
      'İstersen göndermeden önce herhangi birini değiştirebilirsin.';
  static const reviewChange = 'Değiştir';
  static const reviewCta = '4 Fotoğrafı İncele';
  static const reviewCancel = 'Vazgeç ve fotoğrafları sil';

  static const duplicateMessage =
      'Bu fotoğraf zaten başka bir adımda kullanılıyor.\n'
      'Fincanı çevirip farklı bir fotoğraf ekle.';
  static const invalidPhotoMessage =
      'Bu fotoğrafı kullanamadık.\n'
      'Başka bir fotoğraf seç veya yeniden çek.';

  static const creationUnavailable =
      'Dört fotoğraflı fal şu anda başlatılamıyor.\n'
      'Fotoğrafların kayıtlı; değiştirebilir ya da vazgeçebilirsin.';
  static const createConnectionLost =
      'Falını başlatırken bağlantı koptu.\n'
      'Fotoğrafların kayıtlı; tekrar deneyebilirsin.';

  static const stagingInProgress = 'Fotoğrafların hazırlanıyor…';
  static const stagingConnectionLost =
      'Fotoğraflarını gönderirken bağlantı koptu.';
  static const stagingRetry = 'Tekrar dene';

  static int stepNumber(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupHandleFar => 1,
        CoffeeV3PhotoSlot.cupTurnA => 2,
        CoffeeV3PhotoSlot.cupTurnB => 3,
        CoffeeV3PhotoSlot.saucer => 4,
      };

  static String titleFor(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupHandleFar => stepTitleHandleFar,
        CoffeeV3PhotoSlot.cupTurnA => stepTitleTurnA,
        CoffeeV3PhotoSlot.cupTurnB => stepTitleTurnB,
        CoffeeV3PhotoSlot.saucer => stepTitleSaucer,
      };

  static String instructionFor(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupHandleFar => stepInstructionHandleFar,
        CoffeeV3PhotoSlot.cupTurnA => stepInstructionTurnA,
        CoffeeV3PhotoSlot.cupTurnB => stepInstructionTurnB,
        CoffeeV3PhotoSlot.saucer => stepInstructionSaucer,
      };
}
