/// Opens the ORACLY chamber camera — same universe, never a naked OS picker.
library;

import 'package:flutter/material.dart';

import '../../core/navigation/immersive/chamber_transition_personality.dart';
import '../../core/navigation/oracly_page_transitions.dart';
import 'oracly_capture_kind.dart';
import 'oracly_chamber_camera_screen.dart';

abstract final class OraclyChamberCamera {
  OraclyChamberCamera._();

  static Future<String?> open(
    BuildContext context, {
    required OraclyCaptureKind kind,
  }) {
    final personality = kind == OraclyCaptureKind.coffee
        ? ChamberTransitionPersonality.coffee
        : ChamberTransitionPersonality.chamber;
    return Navigator.of(context).push<String>(
      OraclyPageTransitions.chamber(
        personality: personality,
        page: OraclyChamberCameraScreen(kind: kind),
      ),
    );
  }
}
