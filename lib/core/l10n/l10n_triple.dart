/// One production string in every supported language — all three required.
library;

class L10nTriple {
  const L10nTriple(this.tr, this.en, this.ru);

  final String tr;
  final String en;
  final String ru;

  String of(String code) {
    return switch (code) {
      'en' => en,
      'ru' => ru,
      _ => tr,
    };
  }
}
