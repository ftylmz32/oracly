enum TarotSelectPhase {
  idle,
  shuffling,
  aligning,
  ready,
  drawing,
  holding,
}

extension TarotSelectPhaseX on TarotSelectPhase {
  bool get canEditSetup =>
      this == TarotSelectPhase.idle ||
      this == TarotSelectPhase.ready;

  bool get canTapDeck => this == TarotSelectPhase.ready;

  bool get isBusy =>
      this == TarotSelectPhase.shuffling ||
      this == TarotSelectPhase.aligning ||
      this == TarotSelectPhase.drawing ||
      this == TarotSelectPhase.holding;

  String hintText({
    required int spread,
    required int drawnCount,
  }) {
    switch (this) {
      case TarotSelectPhase.idle:
        return 'Niyetini belirle, açılımı seç ve desteyi karıştır.';
      case TarotSelectPhase.shuffling:
        return 'Kartlar karıştırılıyor...';
      case TarotSelectPhase.aligning:
        return 'Kartlar enerjinle hizalanıyor...';
      case TarotSelectPhase.ready:
        if (drawnCount > 0) {
          return '${spread - drawnCount} kart daha seç.';
        }
        return '$spread kartlık açılım için desteye dokun.';
      case TarotSelectPhase.drawing:
        return 'Kartın seçiliyor...';
      case TarotSelectPhase.holding:
        return 'Kartın açıldı...';
    }
  }
}
