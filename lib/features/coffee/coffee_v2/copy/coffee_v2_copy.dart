/// Locked Coffee V2 guided-capture copy (Phase 2C2). Every string here is
/// architect-locked verbatim — do not rephrase.
library;

import '../models/coffee_v2_photo_slot.dart';

abstract final class CoffeeV2Copy {
  CoffeeV2Copy._();

  static const introTitle = 'Falın için 3 fotoğraf';
  static const introBody =
      'Fincanın iki farklı tarafını ve tabağını birlikte inceleyeceğiz.\n'
      'Her fotoğrafı göndermeden önce sen kontrol edebilirsin.';
  static const introSummaryPrimary = '1 — Fincanın ilk yüzü';
  static const introSummarySecondary = '2 — Fincanın diğer yüzü';
  static const introSummarySaucer = '3 — Tabak';
  static const introCta = 'Başlayalım';

  static const stepTitlePrimary = 'Fincanın ilk yüzü';
  static const stepTitleSecondary = 'Fincanın diğer yüzü';
  static const stepTitleSaucer = 'Tabak';

  static const stepInstructionPrimary =
      'Fincanın içini hafif yukarıdan çek.\n'
      'Telve izleri ve fincanın iç duvarı net görünsün.';
  static const stepInstructionSecondary =
      'Fincanı yaklaşık yarım tur çevir.\n'
      'İlk fotoğrafta görünmeyen tarafı göster.';
  static const stepInstructionSaucer =
      'Tabağın tamamı kadrajda olsun.\n'
      'Akıntı ve telve izleri görünüyorsa net görünsün.';

  static const actionTakePhoto = 'Fotoğraf çek';
  static const actionPickGallery = 'Galeriden seç';

  static String progressLabel(int step) => '$step / 3';

  static const previewRetake = 'Tekrar çek';
  static const previewUse = 'Bu fotoğrafı kullan';

  static const reviewTitle = 'Son bir kontrol';
  static const reviewBody =
      'Üç fotoğraf da aynı fincan ve tabağa ait olmalı.\n'
      'İstersen herhangi birini değiştirebilirsin.';
  static const reviewChange = 'Değiştir';
  static const reviewCta = '3 Fotoğrafı İncele';

  static const duplicateSecondaryMessage =
      'Bu fotoğraf ilk fotoğrafla aynı.\n'
      'Fincanı çevirip diğer tarafını ekle.';
  static const duplicateSaucerMessage =
      'Bu fotoğraf zaten kullanılıyor.\n'
      'Tabak için farklı bir fotoğraf seç.';

  static const invalidPhotoMessage =
      'Bu fotoğrafı kullanamadık.\n'
      'Başka bir fotoğraf seç veya yeniden çek.';

  static const draftRecoveredNote = 'Kaldığın yerden devam ediyoruz.';

  static const stagingInProgress = 'Fotoğrafların hazırlanıyor…';
  static const stagingConnectionLost =
      'Fotoğraflarını gönderirken bağlantı koptu.';
  static const stagingRetry = 'Tekrar dene';

  static int stepNumber(CoffeeV2PhotoSlot slot) => switch (slot) {
        CoffeeV2PhotoSlot.cupPrimary => 1,
        CoffeeV2PhotoSlot.cupSecondary => 2,
        CoffeeV2PhotoSlot.saucer => 3,
      };

  static String titleFor(CoffeeV2PhotoSlot slot) => switch (slot) {
        CoffeeV2PhotoSlot.cupPrimary => stepTitlePrimary,
        CoffeeV2PhotoSlot.cupSecondary => stepTitleSecondary,
        CoffeeV2PhotoSlot.saucer => stepTitleSaucer,
      };

  static String instructionFor(CoffeeV2PhotoSlot slot) => switch (slot) {
        CoffeeV2PhotoSlot.cupPrimary => stepInstructionPrimary,
        CoffeeV2PhotoSlot.cupSecondary => stepInstructionSecondary,
        CoffeeV2PhotoSlot.saucer => stepInstructionSaucer,
      };
}
