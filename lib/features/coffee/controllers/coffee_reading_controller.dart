/// Kahve Falı state machine.
library;

import 'package:flutter/foundation.dart';

import '../../../core/audio/oracly_feedback_gate.dart';
import '../../../core/logging/analysis_debug_log.dart';
import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';
import '../services/coffee_analysis_port.dart';
import '../services/coffee_experience_service.dart';
import '../services/coffee_image_input_port.dart';
import '../services/coffee_image_intake.dart';

part 'coffee_reading_controller_capture.dart';

enum CoffeePhase { entry, capture, analyzing, result, error }

class CoffeeReadingController extends ChangeNotifier {
  CoffeeReadingController({
    required this._experience,
    required this._images,
  });

  final CoffeeExperienceService _experience;
  final CoffeeImageInputPort _images;
  bool _disposed = false;

  CoffeePhase _phase = CoffeePhase.entry;
  CoffeeImagePick? _image;
  CoffeeReading? _reading;
  String? _error;
  String? _qualityHint;
  List<CoffeeReading> _history = const [];
  bool _versionAdded = false;
  int _versionReloadToken = 0;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  CoffeePhase get phase => _phase;
  CoffeeImagePick? get image => _image;
  CoffeeReading? get reading => _reading;
  String? get errorMessage => _error;
  String? get qualityHint => _qualityHint;
  List<CoffeeReading> get history => _history;
  bool get lastVersionAdded => _versionAdded;
  int get versionReloadToken => _versionReloadToken;
  CoffeeImageInputPort get images => _images;
  bool get analysisAvailable => _experience.analysisAvailable;

  Future<void> loadHistory() async {
    _history = _experience.history();
    _safeNotify();
  }

  Future<void> analyze() async {
    if (_phase == CoffeePhase.analyzing) return;
    final image = _image;
    if (image == null) {
      _error = CoffeeCopy.imageRequired;
      _safeNotify();
      return;
    }
    _phase = CoffeePhase.analyzing;
    _error = null;
    _safeNotify();
    try {
      _reading = await _experience.analyze(image);
      _phase = CoffeePhase.result;
      OraclyFeedbackGate.successfulAnalysis();
      await loadHistory();
    } on CoffeeAnalysisException catch (e) {
      logAnalysisFailure(feature: 'CoffeeAnalysis', stage: 'analyze', error: e);
      _error = e.message;
      _phase = CoffeePhase.error;
    } catch (error) {
      logAnalysisFailure(
        feature: 'CoffeeAnalysis',
        stage: 'analyze',
        error: error,
      );
      _error = CoffeeCopy.analysisFailed;
      _phase = CoffeePhase.error;
    }
    _safeNotify();
  }

  Future<void> reinterpret() async {
    if (_phase == CoffeePhase.analyzing) return;
    final current = _reading;
    final image = _image;
    if (current == null || image == null) {
      throw StateError('coffee reinterpret failed');
    }
    _phase = CoffeePhase.analyzing;
    _error = null;
    _safeNotify();
    try {
      final result = await _experience.reinterpret(
        current: current,
        image: image,
      );
      _versionAdded = result.versionAdded;
      if (result.versionAdded) {
        _reading = result.reading;
        _versionReloadToken++;
      }
      _phase = CoffeePhase.result;
      OraclyFeedbackGate.successfulAnalysis();
    } on CoffeeAnalysisException catch (e) {
      logAnalysisFailure(
        feature: 'CoffeeAnalysis',
        stage: 'reinterpret',
        error: e,
      );
      _error = e.message;
      _phase = CoffeePhase.error;
    } catch (error) {
      logAnalysisFailure(
        feature: 'CoffeeAnalysis',
        stage: 'reinterpret',
        error: error,
      );
      _error = CoffeeCopy.analysisFailed;
      _phase = CoffeePhase.error;
    }
    _safeNotify();
    if (_phase != CoffeePhase.result) {
      throw StateError('coffee reinterpret failed');
    }
  }

  void openSaved(CoffeeReading reading) {
    _reading = reading;
    _image = reading.imagePath == null
        ? null
        : CoffeeImagePick(path: reading.imagePath!);
    _error = null;
    _phase = CoffeePhase.result;
    _safeNotify();
  }
}
