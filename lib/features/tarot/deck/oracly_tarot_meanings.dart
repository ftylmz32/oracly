/// Structured meanings — fields the engine combines. Never one blob.
library;

import '../../../core/l10n/l10n_triple.dart';

class OraclyTarotMeanings {
  const OraclyTarotMeanings({
    required this.symbolicMeaning,
    required this.loveMeaning,
    required this.careerMeaning,
    required this.moneyMeaning,
    required this.personalMeaning,
    required this.challengeMeaning,
    required this.guidanceMeaning,
    required this.futureDirectionMeaning,
  });

  final L10nTriple symbolicMeaning;
  final L10nTriple loveMeaning;
  final L10nTriple careerMeaning;
  final L10nTriple moneyMeaning;
  final L10nTriple personalMeaning;
  final L10nTriple challengeMeaning;
  final L10nTriple guidanceMeaning;
  final L10nTriple futureDirectionMeaning;

  Iterable<L10nTriple> get fields => [
        symbolicMeaning,
        loveMeaning,
        careerMeaning,
        moneyMeaning,
        personalMeaning,
        challengeMeaning,
        guidanceMeaning,
        futureDirectionMeaning,
      ];

  bool get isComplete => fields.every(_filled);

  static bool _filled(L10nTriple t) =>
      t.tr.trim().isNotEmpty &&
      t.en.trim().isNotEmpty &&
      t.ru.trim().isNotEmpty;
}
