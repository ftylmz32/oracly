part of 'palm_reading_controller.dart';

mixin PalmReadingAnalysis on PalmReadingCapture {
  Future<void> analyze() async {
    if (_phase == PalmPhase.analyzing) return;
    final image = _image;
    if (image == null) {
      _lastError = PalmAnalysisError(
        PalmAnalysisErrorKind.missingImage,
        PalmCopy.imageRequired,
      );
      _error = PalmCopy.imageRequired;
      safeNotify();
      return;
    }
    final token = ++_generation;
    _phase = PalmPhase.analyzing;
    _error = null;
    _lastError = null;
    safeNotify();
    try {
      final reading = await _experience.analyze(image, hand: _hand);
      if (_disposed || token != _generation) return;
      _reading = reading;
      _image = CoffeeImagePick(
        path: reading.imagePath ?? image.path,
        mimeType: 'image/jpeg',
      );
      _phase = PalmPhase.result;
      OraclyFeedbackGate.successfulAnalysis();
    } on PalmAnalysisException catch (e) {
      if (_disposed || token != _generation) return;
      _setAnalysisError('analyze', e.error, e);
    } catch (error) {
      if (_disposed || token != _generation) return;
      _setAnalysisError(
        'analyze',
        PalmAnalysisError(
          PalmAnalysisErrorKind.unknown,
          PalmCopy.analysisFailed,
        ),
        error,
      );
    }
    safeNotify();
  }

  Future<void> reinterpret() async {
    if (_phase == PalmPhase.analyzing) return;
    final current = _reading;
    final image = _image;
    if (current == null || image == null) {
      throw StateError('palm reinterpret failed');
    }
    final token = ++_generation;
    _phase = PalmPhase.analyzing;
    _error = null;
    _lastError = null;
    safeNotify();
    try {
      final result = await _experience.reinterpret(
        current: current,
        image: image,
        hand: _hand,
      );
      if (_disposed || token != _generation) return;
      _versionAdded = result.versionAdded;
      if (result.versionAdded) {
        _reading = result.reading;
        _versionReloadToken++;
      }
      _phase = PalmPhase.result;
      OraclyFeedbackGate.successfulAnalysis();
    } on PalmAnalysisException catch (e) {
      if (_disposed || token != _generation) return;
      _setAnalysisError('reinterpret', e.error, e);
    } catch (error) {
      if (_disposed || token != _generation) return;
      _setAnalysisError(
        'reinterpret',
        PalmAnalysisError(
          PalmAnalysisErrorKind.unknown,
          PalmCopy.analysisFailed,
        ),
        error,
      );
    }
    safeNotify();
    if (_phase != PalmPhase.result) {
      throw StateError('palm reinterpret failed');
    }
  }

  Future<void> retryAnalysis() async {
    final path = _image?.path;
    if (path != null && await PalmImageArchive.exists(path)) {
      await analyze();
      return;
    }
    retryCapture();
  }

  void _setAnalysisError(String stage, PalmAnalysisError err, Object logged) {
    logAnalysisFailure(
      feature: 'PalmAnalysis',
      stage: stage,
      error: logged,
      kind: err.kind.name,
    );
    _lastError = err;
    _error = err.message;
    _phase = PalmPhase.error;
  }
}
