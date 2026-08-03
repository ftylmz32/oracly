enum TarotSelectPhase {
  idle,
  shuffling,
  aligning,
  ready,
}

extension TarotSelectPhaseX on TarotSelectPhase {
  bool get canEditSetup =>
      this == TarotSelectPhase.idle ||
      this == TarotSelectPhase.ready;

  bool get canTapDeck => this == TarotSelectPhase.ready;

  bool get isBusy =>
      this == TarotSelectPhase.shuffling ||
      this == TarotSelectPhase.aligning;

  String hintText({required int spread}) {
    switch (this) {
      case TarotSelectPhase.idle:
        return 'Niyetini belirle, açılımı seç ve desteyi karıştır.';
      case TarotSelectPhase.shuffling:
        return 'Kartlar karıştırılıyor...';
      case TarotSelectPhase.aligning:
        return 'Kartlar enerjinle hizalanıyor...';
      case TarotSelectPhase.ready:
        return '$spread kartlık açılım için desteye dokun.';
    }
  }
}
