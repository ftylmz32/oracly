part of 'palm_reading_controller.dart';

mixin PalmReadingCapture on ChangeNotifier {
  late PalmExperienceService _experience;
  late CoffeeImageInputPort _images;

  PalmPhase _phase = PalmPhase.entry;
  PalmHand _hand = PalmHand.right;
  CoffeeImagePick? _image;
  PalmReading? _reading;
  String? _error;
  PalmAnalysisError? _lastError;
  String? _qualityHint;
  bool _versionAdded = false;
  int _versionReloadToken = 0;
  bool _disposed = false;
  int _generation = 0;

  void bindCapture(
    PalmExperienceService experience,
    CoffeeImageInputPort images,
  ) {
    _experience = experience;
    _images = images;
  }

  void markDisposed() {
    _disposed = true;
    _generation++;
  }

  void safeNotify() {
    if (!_disposed && hasListeners) notifyListeners();
  }

  PalmPhase get phase => _phase;
  PalmHand get hand => _hand;
  CoffeeImagePick? get image => _image;
  PalmReading? get reading => _reading;
  String? get errorMessage => _error;
  PalmAnalysisError? get lastError => _lastError;
  String? get qualityHint => _qualityHint;
  CoffeeImageInputPort get images => _images;
  bool get analysisAvailable => _experience.analysisAvailable;
  bool get lastVersionAdded => _versionAdded;
  int get versionReloadToken => _versionReloadToken;

  void selectHand(PalmHand hand) {
    _hand = hand;
    safeNotify();
  }

  void startCapture() {
    _phase = PalmPhase.capture;
    _error = null;
    _lastError = null;
    safeNotify();
  }

  void backToEntry() {
    _generation++;
    _phase = PalmPhase.entry;
    _image = null;
    _reading = null;
    _error = null;
    _lastError = null;
    _qualityHint = null;
    safeNotify();
  }

  Future<void> pickCamera() async {
    _applyIntake(await PalmImageIntake.fromCamera(_images));
  }

  Future<void> pickGallery() async {
    _applyIntake(await PalmImageIntake.fromGallery(_images));
  }

  Future<void> acceptCapturedPath(String path) async {
    _applyIntake(await PalmImageIntake.assess(CoffeeImagePick(path: path)));
  }

  void _applyIntake(PalmImageIntakeResult result) {
    if (result.image != null) _image = result.image;
    _error = result.error;
    _lastError = result.error == null
        ? null
        : PalmAnalysisError(
            PalmAnalysisErrorKind.unsupportedImage,
            result.error!,
          );
    _qualityHint = result.qualityHint;
    safeNotify();
  }

  void reportCaptureError(String message) {
    _error = message;
    _lastError = PalmAnalysisError(
      PalmAnalysisErrorKind.unsupportedImage,
      message,
    );
    _qualityHint = null;
    _phase = PalmPhase.capture;
    safeNotify();
  }

  void retryCapture() {
    _generation++;
    _phase = PalmPhase.capture;
    _error = null;
    _lastError = null;
    safeNotify();
  }

  /// Test-only: set a ready JPEG without intake/normalize (avoids plugin hangs).
  @visibleForTesting
  void debugSetImageForTest(CoffeeImagePick image) {
    _image = image;
    _error = null;
    _lastError = null;
    _qualityHint = null;
    safeNotify();
  }
}
