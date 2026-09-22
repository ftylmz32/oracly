/// Phase 2 CONTRACT HARNESS — hard-fail scanners (offline).
library;

import 'narrative_tarot_v2_hard_failures.dart';
import 'narrative_tarot_v2_text.dart';

abstract final class Ntv2HardScan {
  static void scanBeatRefs(
    List<Map> beats, {
    required Set<String> drawn,
    required Set<String> positions,
    required Set<String> relIds,
    required Set<String> memRefs,
    required Set<String> recIds,
    required Set<String> hard,
  }) {
    for (final b in beats) {
      for (final id in (b['cardIds'] as List? ?? const []).cast<String>()) {
        if (!Ntv2TextHeuristics.isCanonicalCardId(id)) {
          hard.add(Ntv2HardFailure.unknownCardRef);
        }
        if (!drawn.contains(id)) {
          hard.add(Ntv2HardFailure.undrawnCardRef);
        }
      }
      for (final p in (b['positionKeys'] as List? ?? const []).cast<String>()) {
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
      r'appeared\s+(\d+)|(\d+)\s+(?:times|kez|raza)',
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
    final trChars = RegExp(r'[ğüşöçıİĞÜŞÖÇ]').allMatches(text).length;
    final cyr = RegExp(r'[А-Яа-яЁё]').allMatches(text).length;
    final latin = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (locale == 'tr') {
      final enStock = Ntv2TextHeuristics.englishStockDensity(text);
      if (trChars == 0 && latin > 60 && enStock >= 2) {
        hard.add(Ntv2HardFailure.languageMismatch);
      }
    } else if (locale == 'en') {
      if (trChars > 8) hard.add(Ntv2HardFailure.languageMismatch);
    } else if (locale == 'ru') {
      if (cyr < 5 && latin > 40) {
        hard.add(Ntv2HardFailure.languageMismatch);
      }
    }
  }
}
