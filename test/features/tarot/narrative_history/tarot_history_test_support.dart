/// Shared builders for Phase 4A historical recurrence tests.
library;

import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_00.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_01.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_profile_slice.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

final nowFixed = DateTime.utc(2026, 9, 23, 12);

TarotNarrativeRequest baseRequest({
  String readingId = 'cur_r',
  String sessionId = 'cur_s',
  String? questionRaw = 'Should I stay in this relationship?',
  String? topic,
  QuestionKind? forceKind,
  List<TarotNarrativeCardEvidence>? cards,
  RequestBounds bounds = RequestBounds.defaults,
}) {
  final question = forceKind == null
      ? NarrativeQuestionGrounding.from(rawQuestion: questionRaw, topic: topic)
      : QuestionGrounding(
          rawText: questionRaw,
          topic: topic,
          kind: forceKind,
          hasRealQuestion: questionRaw != null && questionRaw.trim().isNotEmpty,
        );
  final resolved = cards ?? [cardEvidence(kNarrativeMajor00, positionIndex: 0)];
  return TarotNarrativeRequest(
    narrativeTarotVersion: TarotNarrativeRequest.currentNarrativeVersion,
    languageCode: 'en',
    sessionId: sessionId,
    readingId: readingId,
    question: question,
    spread: ClassicalSpreadSemantics.byLegacyTypeName('single'),
    cards: resolved,
    relationships: const [],
    memory: TarotNarrativeMemoryEvidence.empty,
    recurringCards: const [],
    recurringThemes: const [],
    bounds: bounds,
  );
}

TarotNarrativeCardEvidence cardEvidence(
  NarrativeCardProfile profile, {
  required int positionIndex,
  String positionKey = 'sign',
  bool isReversed = false,
  int? ritualCardId,
}) {
  final slice = TarotNarrativeProfileSlice.fromProfile(
    profile,
    isReversed: isReversed,
    questionKind: QuestionKind.open,
  );
  return TarotNarrativeCardEvidence(
    canonicalCardId: profile.canonicalCardId,
    ritualCardId: ritualCardId ?? positionIndex,
    isReversed: isReversed,
    positionKey: positionKey,
    positionIndex: positionIndex,
    displayName: profile.canonicalCardId,
    profileSlice: slice,
    imageAsset: 'assets/test.png',
  );
}

TarotHistoricalReadingRecord histReading({
  required String readingId,
  required DateTime at,
  String spreadId = 'single',
  String? sessionId,
  String? ownerId,
  QuestionKind? questionKind,
  String? topicId,
  String? intentionSummary,
  String? interpretationSummary,
  List<TarotHistoricalCardOccurrence>? cards,
  String cardId = 'major_00',
  bool isReversed = false,
  bool orientationKnown = true,
  String? positionKey = 'sign',
  int? positionIndex = 0,
}) {
  return TarotHistoricalReadingRecord(
    readingId: readingId,
    sessionId: sessionId,
    ownerId: ownerId,
    occurredAt: at,
    spreadId: spreadId,
    questionKind: questionKind,
    topicId: topicId,
    intentionSummary: intentionSummary,
    interpretationSummary: interpretationSummary,
    cards:
        cards ??
        [
          TarotHistoricalCardOccurrence(
            canonicalCardId: cardId,
            isReversed: isReversed,
            orientationKnown: orientationKnown,
            positionKey: positionKey,
            positionIndex: positionIndex,
          ),
        ],
  );
}

String get major00 => kNarrativeMajor00.canonicalCardId;
String get major01 => kNarrativeMajor01.canonicalCardId;
String get major06 => kNarrativeMajor06.canonicalCardId;
