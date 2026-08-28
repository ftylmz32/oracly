/// El Falı state machine.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../coffee/models/coffee_image_pick.dart';
import '../../coffee/services/coffee_image_input_port.dart';
import '../../../core/audio/oracly_feedback_gate.dart';
import '../../../core/logging/analysis_debug_log.dart';
import '../copy/palm_copy.dart';
import '../models/palm_analysis_error.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';
import '../services/palm_analysis_port.dart';
import '../services/palm_experience_service.dart';
import '../services/palm_image_archive.dart';
import '../services/palm_image_intake.dart';

part 'palm_reading_controller_capture.dart';
part 'palm_reading_controller_analysis.dart';

enum PalmPhase { entry, capture, analyzing, result, error }

class PalmReadingController extends ChangeNotifier
    with PalmReadingCapture, PalmReadingAnalysis {
  PalmReadingController({
    required PalmExperienceService experience,
    required CoffeeImageInputPort images,
  }) {
    bindCapture(experience, images);
  }

  @override
  void dispose() {
    markDisposed();
    super.dispose();
  }

  void openSaved(PalmReading reading) {
    final path = reading.imagePath;
    final exists = path != null && File(path).existsSync();
    _reading = exists ? reading : reading.copyWith(clearImagePath: true);
    _image = exists
        ? CoffeeImagePick(path: path, mimeType: 'image/jpeg')
        : null;
    _error = null;
    _lastError = null;
    _phase = PalmPhase.result;
    safeNotify();
  }
}
