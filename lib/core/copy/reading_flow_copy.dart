/// RC-001 — Transitional copy for select → reveal → reading continuity.
library;

abstract final class ReadingFlowCopy {
  ReadingFlowCopy._();

  /// Brief breath between reveal handoff and interpretation scroll.
  static const introBreath = 'Bir an nefes al…';

  static const introPreparing = 'Yorumun sakin bir tempoda açılıyor.';

  static const revealSessionMissing =
      'Açılım oturumu bulunamadı. Lütfen yeniden başla.';

  static const readingSessionMissing =
      'Yorum yüklenemedi. Açılım oturumu sona ermiş olabilir.';
}
