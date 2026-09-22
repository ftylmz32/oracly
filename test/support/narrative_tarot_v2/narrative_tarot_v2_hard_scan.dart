/// Phase 2 CONTRACT HARNESS — hard-fail scanners (offline).
library;

import 'narrative_tarot_v2_hard_failures.dart';
import 'narrative_tarot_v2_language.dart';
import 'narrative_tarot_v2_text.dart';

abstract final class Ntv2HardScan {
  static void scanBeatRefs(
    List<Map> beats, {
    required Map<String, String> positionByCard,
    required Set<String> drawn,
    required Set<String> positions,
    required Set<String> relIds,
    required Set<String> memRefs,
    required Set<String> recIds,
    required Set<String> hard,
  }) {
    for (final b in beats) {
      final cardIds = (b['cardIds'] as List? ?? const []).cast<String>();
      final positionKeys = (b['positionKeys'] as List? ?? const [])
          .cast<String>();

      for (final id in cardIds) {
        if (!Ntv2TextHeuristics.isCanonicalCardId(id)) {
          hard.add(Ntv2HardFailure.unknownCardRef);
        }
        if (!drawn.contains(id)) {
          hard.add(Ntv2HardFailure.undrawnCardRef);
        }
      }
      for (final p in positionKeys) {
        if (!positions.contains(p)) {
          hard.add(Ntv2HardFailure.unknownPositionRef);
        }
      }
      for (final id
          in (b['relationshipEvidenceIds'] as List? ?? const [])
              .cast<String>()) {
        if (!relIds.contains(id)) {
          hard.add(Ntv2HardFailure.unknownRelationshipEvidence);
        }
      }
      for (final id
          in (b['memoryEvidenceRefs'] as List? ?? const []).cast<String>()) {
        if (!memRefs.contains(id)) {
          hard.add(Ntv2HardFailure.unknownMemoryEvidence);
        }
      }
      for (final id
          in (b['recurringEvidenceIds'] as List? ?? const []).cast<String>()) {
        if (!recIds.contains(id)) {
          hard.add(Ntv2HardFailure.unknownRecurrenceEvidence);
        }
      }

      _checkBeatPairing(
        cardIds,
        positionKeys,
        positionByCard: positionByCard,
        hard: hard,
      );
    }
  }

  static void scanCardDetails(
    List<Map> details, {
    required Map<String, String> positionByCard,
    required Map<String, bool> orientation,
    required Set<String> drawn,
    required Set<String> positions,
    required Set<String> hard,
  }) {
    for (final d in details) {
      final id = '${d['canonicalCardId'] ?? ''}';
      final pos = '${d['positionKey'] ?? ''}';
      final rev = d['isReversed'] == true;

      if (!Ntv2TextHeuristics.isCanonicalCardId(id)) {
        hard.add(Ntv2HardFailure.unknownCardRef);
      }
      if (!drawn.contains(id)) {
        hard.add(Ntv2HardFailure.undrawnCardRef);
      }
      if (pos.isNotEmpty && !positions.contains(pos)) {
        hard.add(Ntv2HardFailure.unknownPositionRef);
      }
      if (drawn.contains(id) &&
          positions.contains(pos) &&
          positionByCard[id] != null &&
          positionByCard[id] != pos) {
        hard.add(Ntv2HardFailure.spreadFactMismatch);
      }
      if (orientation.containsKey(id) && orientation[id] != rev) {
        hard.add(Ntv2HardFailure.orientationMismatch);
      }
    }
  }

  static void _checkBeatPairing(
    List<String> cardIds,
    List<String> positionKeys, {
    required Map<String, String> positionByCard,
    required Set<String> hard,
  }) {
    if (cardIds.isEmpty || positionKeys.isEmpty) return;

    if (cardIds.length == 1 && positionKeys.length == 1) {
      final actual = positionByCard[cardIds.first];
      if (actual != null && actual != positionKeys.first) {
        hard.add(Ntv2HardFailure.spreadFactMismatch);
      }
      return;
    }

    final allowed = <String>{
      for (final id in cardIds)
        if (positionByCard[id] != null) positionByCard[id]!,
    };
    for (final p in positionKeys) {
      if (allowed.isNotEmpty && !allowed.contains(p)) {
        hard.add(Ntv2HardFailure.spreadFactMismatch);
        break;
      }
    }
  }

  static void checkRecurrence(
    String text,
    Map<String, int> recCounts,
    Set<String> recIds,
    Set<String> hard,
  ) {
    final lower = text.toLowerCase();
    final claimed = <int>[];
    for (final m in RegExp(
      r'appeared\s+(\d+)|(\d+)\s+(?:times|kez|раза)',
      caseSensitive: false,
    ).allMatches(text)) {
      claimed.add(int.parse(m.group(1) ?? m.group(2)!));
    }
    if (claimed.isNotEmpty) {
      if (recCounts.isEmpty) {
        hard.add(Ntv2HardFailure.fabricatedRecurrence);
      } else {
        for (final n in claimed) {
          if (!recCounts.values.contains(n)) {
            hard.add(Ntv2HardFailure.recurrenceCountMismatch);
          }
        }
      }
    } else if (recIds.isEmpty &&
        (lower.contains('keeps happening') ||
            lower.contains('this keeps happening'))) {
      hard.add(Ntv2HardFailure.fabricatedRecurrence);
    }
  }

  static void checkCertaintySafety(String text, Set<String> hard) {
    if (Ntv2TextHeuristics.safety.hasMatch(text)) {
      hard.add(Ntv2HardFailure.safetyViolation);
      return;
    }
    if (Ntv2TextHeuristics.certainty.hasMatch(text)) {
      hard.add(Ntv2HardFailure.unsupportedCertainty);
    }
  }

  static void checkMemoryPrivacy(
    List<Map> beats,
    Set<String> foreignRefs,
    Set<String> deletedRefs,
    Set<String> hard,
  ) {
    final used = {
      for (final b in beats)
        ...((b['memoryEvidenceRefs'] as List? ?? const []).cast<String>()),
    };
    if (used.any(foreignRefs.contains)) {
      hard.add(Ntv2HardFailure.foreignAccountEvidence);
    }
    if (used.any(deletedRefs.contains)) {
      hard.add(Ntv2HardFailure.deletedEvidenceUsed);
    }
  }

  static void checkLanguage(String locale, String text, Set<String> hard) {
    if (Ntv2LanguageContract.isMismatch(locale, text)) {
      hard.add(Ntv2HardFailure.languageMismatch);
    }
  }
}
