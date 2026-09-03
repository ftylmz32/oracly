/// Kahve Falı state machine.
library;

import 'dart:io';

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
  int _generation = 0;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
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
    final token = ++_generation;
    _phase = CoffeePhase.analyzing;
    _error = null;
    _safeNotify();
    try {
      final reading = await _experience.analyze(image);
      if (_disposed || token != _generation) return;
      _reading = reading;
      _phase = CoffeePhase.result;
      OraclyFeedbackGate.successfulAnalysis();
      await loadHistory();
    } on CoffeeAnalysisException catch (e) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(feature: 'CoffeeAnalysis', stage: 'analyze', error: e);
      _error = e.message;
      _phase = CoffeePhase.error;
    } catch (error) {
      if (_disposed || token != _generation) return;
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
    final token = ++_generation;
    _phase = CoffeePhase.analyzing;
    _error = null;
    _safeNotify();
    try {
      final result = await _experience.reinterpret(
        current: current,
        image: image,
      );
      if (_disposed || token != _generation) return;
      _versionAdded = result.versionAdded;
      if (result.versionAdded) {
        _reading = result.reading;
        _versionReloadToken++;
      }
      _phase = CoffeePhase.result;
      OraclyFeedbackGate.successfulAnalysis();
    } on CoffeeAnalysisException catch (e) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'CoffeeAnalysis',
        stage: 'reinterpret',
        error: e,
      );
      _error = e.message;
      _phase = CoffeePhase.error;
    } catch (error) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'CoffeeAnalysis',
        stage: 'reinterpret',
        error: error,
      );
      _error = CoffeeCopy.analysisFailed;
      _phase = CoffeePhase.error;
    }
    _safeNotify();
    if (_disposed || token != _generation) return;
    if (_phase != CoffeePhase.result) {
      throw StateError('coffee reinterpret failed');
    }
  }

  void openSaved(CoffeeReading reading) {
    final path = reading.imagePath;
    final exists = path != null && File(path).existsSync();
    _reading = exists
        ? reading
        : CoffeeReading(
            id: reading.id,
            createdAt: reading.createdAt,
            overall: reading.overall,
            love: reading.love,
            career: reading.career,
            money: reading.money,
            nearFuture: reading.nearFuture,
            takeaway: reading.takeaway,
            visualObservation: reading.visualObservation,
            symbols: reading.symbols,
          );
    _image = exists ? CoffeeImagePick(path: path) : null;
    _error = null;
    _phase = CoffeePhase.result;
    _safeNotify();
  }
}
