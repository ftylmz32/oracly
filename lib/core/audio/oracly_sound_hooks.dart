/// EPIC-020 — Typed sound hooks for the visual rebirth experience.
library;

import '../audio/oracly_feedback_gate.dart';
import '../audio/oracly_sound_chamber.dart';
import '../audio/oracly_sound_service.dart';

/// Semantic sound events — wire UI moments without coupling to audio internals.
enum OraclySoundHook {
  ambientHome,
  ambientTarot,
  ambientReading,
  ambientSilence,
  softTap,
  selection,
  buttonTap,
  cardSlide,
  cardFlip,
  magicReveal,
  crystalHum,
  premiumSuccess,
  journeyComplete,
}

/// Facade over [OraclySoundService] for EPIC-020 integration points.
abstract final class OraclySoundHooks {
  OraclySoundHooks._();

  static OraclySoundService? _service;

  static void bind(OraclySoundService service) => _service = service;

  static Future<void> play(OraclySoundHook hook) async {
    final service = _service;
    if (service == null) return;

    switch (hook) {
      case OraclySoundHook.ambientHome:
        await service.setChamber(OraclySoundChamber.home);
      case OraclySoundHook.ambientTarot:
        await service.setChamber(OraclySoundChamber.tarot);
      case OraclySoundHook.ambientReading:
        await service.setChamber(OraclySoundChamber.reading);
      case OraclySoundHook.ambientSilence:
        await service.setChamber(OraclySoundChamber.silence);
      case OraclySoundHook.softTap:
      case OraclySoundHook.buttonTap:
        OraclyFeedbackGate.softTap();
      case OraclySoundHook.selection:
        OraclyFeedbackGate.selection();
      case OraclySoundHook.cardSlide:
        OraclyFeedbackGate.cardMove();
      case OraclySoundHook.cardFlip:
        OraclyFeedbackGate.playCue(OraclySoundCue.cardFlip);
      case OraclySoundHook.magicReveal:
        OraclyFeedbackGate.playCue(OraclySoundCue.magicalReveal);
      case OraclySoundHook.crystalHum:
        OraclyFeedbackGate.playCue(OraclySoundCue.orbHum);
      case OraclySoundHook.premiumSuccess:
        OraclyFeedbackGate.playCue(OraclySoundCue.premiumPurchase);
      case OraclySoundHook.journeyComplete:
        OraclyFeedbackGate.playCue(OraclySoundCue.journeyComplete);
    }
  }
}
