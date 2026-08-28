/// Detection rules for AI output quality.
library;

import '../copy/fortune_voice.dart';
import '../honesty/or_response_grounding.dart';
import '../personality/or_core.dart';
import '../personality/or_emotional_intelligence.dart';
import '../personality/or_natural_humor.dart';
import '../safety/or_safety_behavior.dart';
import '../safety/sensitive_topic_output_checks.dart';
import 'ai_output_quality_category.dart';
import 'ai_output_quality_context.dart';
import 'ai_output_quality_kind.dart';
import 'human_reader_guard.dart';
import 'robotic_language_detector.dart';

abstract final class AiOutputQualityChecks {
  AiOutputQualityChecks._();

  static AiOutputQualityCategory? firstFailure(
    String text, {
    required AiOutputQualityKind kind,
    AiOutputQualityContext context = const AiOutputQualityContext(),
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return AiOutputQualityCategory.brokenFormatting;
    if (_brokenFormatting(trimmed)) {
      return AiOutputQualityCategory.brokenFormatting;
    }
    if (FortuneVoice.claimsMedical(trimmed)) {
      return AiOutputQualityCategory.medicalDiagnosis;
    }
    if (SensitiveTopicOutputChecks.claimsMedicalDiagnosis(trimmed) ||
        OrSafetyBehavior.unsafeMedicalDirective(trimmed)) {
      return AiOutputQualityCategory.medicalDiagnosis;
    }
    if (OrSafetyBehavior.encouragesHarm(trimmed) ||
        OrSafetyBehavior.manipulatesDependency(trimmed) ||
        (kind == AiOutputQualityKind.companion &&
            OrCore.looksForcedPositivity(trimmed))) {
      return AiOutputQualityCategory.fearManipulation;
    }
    if (OrSafetyBehavior.pretendsToBeHuman(trimmed)) {
      return AiOutputQualityCategory.unsupportedClaim;
    }
    if (_deterministicFuture(trimmed)) {
      return AiOutputQualityCategory.deterministicFuture;
    }
    if (FortuneVoice.claimsCertainty(trimmed) ||
        _unsupportedCertainty(trimmed, kind, context)) {
      return AiOutputQualityCategory.unsupportedClaim;
    }
    if (_fearOrSensitive(trimmed)) {
      return AiOutputQualityCategory.fearManipulation;
    }
    if (SensitiveTopicOutputChecks.promisesFinancialGuarantee(trimmed) ||
        SensitiveTopicOutputChecks.givesLegalAdvice(trimmed) ||
        SensitiveTopicOutputChecks.claimsDefiniteLove(trimmed)) {
      return AiOutputQualityCategory.unsupportedClaim;
    }
    // Biography / product powers — never as fact, even with tagged context.
    if (OrResponseGrounding.claimsInventedBiography(trimmed) ||
        OrResponseGrounding.claimsInventedCapability(trimmed) ||
        OrEmotionalIntelligence.claimsDiagnosis(trimmed)) {
      return AiOutputQualityCategory.fakeMemory;
    }
    if (!context.hasMemoryEvidence &&
        (OrResponseGrounding.claimsUngroundedMemory(trimmed) ||
            OrResponseGrounding.claimsInventedDiscovery(trimmed))) {
      return AiOutputQualityCategory.fakeMemory;
    }
    if (RoboticLanguageDetector.isHeavilyRepetitive(trimmed)) {
      return AiOutputQualityCategory.repetitiveFiller;
    }
    if (kind == AiOutputQualityKind.companion &&
        OrNaturalHumor.looksLikeComedian(trimmed)) {
      return AiOutputQualityCategory.repetitiveFiller;
    }
    if (_emptyGeneric(trimmed, kind)) {
      return AiOutputQualityCategory.emptyGeneric;
    }
    if (_implementationLanguage(trimmed)) {
      return AiOutputQualityCategory.implementationLanguage;
    }
    if (_mixedLanguage(trimmed, context.localeCode)) {
      return AiOutputQualityCategory.mixedLanguage;
    }
    return null;
  }

  static bool _brokenFormatting(String text) {
    if (RegExp(r'^[\s\.\,\!\?\-–—]+$').hasMatch(text)) return true;
    if (text.contains('```') || text.contains('{"') || text.contains('":')) {
      return true;
    }
    if (RegExp(r'\{\{|\}\}|<<|>>').hasMatch(text)) return true;
    return false;
  }

  static bool _deterministicFuture(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'kesin\s+\d+\s+(gün|hafta|ay|günde)').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\d+\s+(gün|hafta|ay)\s+içinde\s+kesin').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\d+\s+(weeks?|days?|months?)\s+(from now|inside)').hasMatch(
      lower,
    )) {
      return true;
    }
    return false;
  }

  static bool _unsupportedCertainty(
    String text,
    AiOutputQualityKind kind,
    AiOutputQualityContext context,
  ) {
    final lower = text.toLowerCase();
    if (kind == AiOutputQualityKind.coffee && !context.hasVisualEvidence) {
      if (RegExp(r'fincanda\s+kesin').hasMatch(lower)) return true;
      if (RegExp(r'kesin\s+(kuş|kalp|yılan|anahtar|balık)').hasMatch(lower)) {
        return true;
      }
    }
    return lower.contains('kesinlikle şu olacak') ||
        lower.contains('garanti gelecek');
  }

  static bool _fearOrSensitive(String text) =>
      SensitiveTopicOutputChecks.predictsFear(text);

  static bool _emptyGeneric(String text, AiOutputQualityKind kind) {
    final lower = text.toLowerCase();
    const empty = [
      'genel rehberlik',
      'general guidance',
      'size nasıl yardımcı olabilirim',
      'how can i help you',
    ];
    if (empty.any((p) => lower == p || lower.startsWith('$p.'))) return true;
    // Companion chat may answer briefly (e.g. greetings); readings need more body.
    final minLen = kind == AiOutputQualityKind.companion ? 6 : 18;
    return text.length < minLen;
  }

  static bool _implementationLanguage(String text) {
    final lower = text.toLowerCase();
    return HumanReaderGuard.implementation.any(lower.contains);
  }

  static bool _mixedLanguage(String text, String localeCode) {
    if (localeCode != 'tr') return false;
    final latinWords = RegExp(r'\b[a-zA-Z]{4,}\b').allMatches(text).length;
    final turkishChars = RegExp(r'[çğıöşüÇĞİÖŞÜ]').hasMatch(text);
    if (!turkishChars || latinWords < 3) return false;
    const englishHits = [
      ' definitely ',
      ' will happen ',
      ' you should ',
      ' this means that ',
    ];
    final lower = text.toLowerCase();
    return englishHits.any(lower.contains);
  }
}
