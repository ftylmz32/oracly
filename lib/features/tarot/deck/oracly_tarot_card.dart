/// One ORACLY tarot card — structured, localized, engine-ready.
library;

import '../../../core/l10n/l10n_triple.dart';
import 'oracly_tarot_assets.dart';
import 'oracly_tarot_enums.dart';
import 'oracly_tarot_keywords.dart';
import 'oracly_tarot_meanings.dart';
import 'oracly_tarot_relations.dart';

class OraclyTarotCard {
  const OraclyTarotCard({
    required this.id,
    required this.name,
    required this.arcana,
    required this.suit,
    required this.number,
    required this.uprightKeywords,
    required this.reversedKeywords,
    required this.meanings,
    required this.relationshipWithOtherCards,
    required this.visualAsset,
    this.cardBackAsset = OraclyTarotAssets.cardBack,
  });

  final String id;
  final L10nTriple name;
  final OraclyTarotArcana arcana;
  final OraclyTarotSuit suit;
  final int number;
  final OraclyTarotKeywords uprightKeywords;
  final OraclyTarotKeywords reversedKeywords;
  final OraclyTarotMeanings meanings;
  final OraclyTarotRelations relationshipWithOtherCards;
  final String visualAsset;
  final String cardBackAsset;

  String get nameTr => name.tr;
  String get nameEn => name.en;
  String get nameRu => name.ru;

  L10nTriple get symbolicMeaning => meanings.symbolicMeaning;
  L10nTriple get loveMeaning => meanings.loveMeaning;
  L10nTriple get careerMeaning => meanings.careerMeaning;
  L10nTriple get moneyMeaning => meanings.moneyMeaning;
  L10nTriple get personalMeaning => meanings.personalMeaning;
  L10nTriple get challengeMeaning => meanings.challengeMeaning;
  L10nTriple get guidanceMeaning => meanings.guidanceMeaning;
  L10nTriple get futureDirectionMeaning => meanings.futureDirectionMeaning;

  bool get isMajor => arcana == OraclyTarotArcana.major;
  bool get isMinor => arcana == OraclyTarotArcana.minor;

  Iterable<String> get userFacingCopy sync* {
    yield name.tr;
    yield name.en;
    yield name.ru;
    yield* uprightKeywords.tr;
    yield* uprightKeywords.en;
    yield* uprightKeywords.ru;
    yield* reversedKeywords.tr;
    yield* reversedKeywords.en;
    yield* reversedKeywords.ru;
    for (final field in meanings.fields) {
      yield field.tr;
      yield field.en;
      yield field.ru;
    }
    yield relationshipWithOtherCards.note.tr;
    yield relationshipWithOtherCards.note.en;
    yield relationshipWithOtherCards.note.ru;
  }

  bool get isComplete =>
      id.trim().isNotEmpty &&
      name.tr.trim().isNotEmpty &&
      name.en.trim().isNotEmpty &&
      name.ru.trim().isNotEmpty &&
      uprightKeywords.isComplete &&
      reversedKeywords.isComplete &&
      meanings.isComplete &&
      relationshipWithOtherCards.isComplete &&
      visualAsset.trim().isNotEmpty &&
      cardBackAsset.trim().isNotEmpty;
}
