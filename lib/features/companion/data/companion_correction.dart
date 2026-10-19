/// User correction cues — adapt immediately, never defend.
library;

abstract final class CompanionCorrection {
  CompanionCorrection._();

  static bool matches(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty || t.length > 160) return false;
    const cues = [
      'yanlış anlad',
      'yanlis anlad',
      'yanlış okud',
      'yanlis okud',
      'onu demek istemed',
      'onu demek istemiyorum',
      'kastettiğim',
      'kastettigim',
      'demek istediğim',
      'demek istedigim',
      "that's not what i meant",
      'that is not what i meant',
      'you misunderstood',
      'не то имел',
      'ты неправильно понял',
      'ты не так понял',
    ];
    if (cues.any(t.contains)) return true;
    if (RegExp(r'^hayır[,.]?\s+onu\b').hasMatch(t)) return true;
    if (RegExp(r'^hayir[,.]?\s+onu\b').hasMatch(t)) return true;
    if (RegExp(r'^no[,.]?\s+(that|i)\b').hasMatch(t) &&
        (t.contains('mean') || t.contains('said'))) {
      return true;
    }
    final namesCause = RegExp(r'(aslında|aslinda|sebebi|nedeni)').hasMatch(t);
    final deniesTopic = RegExp(
      r'(kahve|fincan|tarot|aşk|ask|ilişki|iliski|sevg|rüya|ruya|'
      r'iş|kariyer|meslek)(?:[a-züğışöçâîû]{0,8})?\s+(değil|degil)\b',
    ).hasMatch(t);
    if (namesCause && deniesTopic) return true;
    return false;
  }

  static const styleHintTr =
      'Kullanıcı düzeltme yaptı. Savunma yok; kısa kabul et '
      '("Tamam, orayı yanlış okudum") ve düzeltilmiş bağlama devam et. '
      'Sohbeti sıfırlama; genel selam yok.';
}
