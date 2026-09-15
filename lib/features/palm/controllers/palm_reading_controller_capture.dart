part of 'palm_reading_controller.dart';

mixin PalmReadingCapture on ChangeNotifier {
  late PalmExperienceService _experience;
  late CoffeeImageInputPort _images;
  ReadingFeatureRunner? _live;
  ReadingPendingOperationStore? _pendingStore;
  ReadingLiveState? liveState;

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
  bool _accelerating = false;
  String? _accelerationError;
  int? _accelerationCost;
  String? _accelerationCostFor;
  String? _accelerationPriceToken;
  Future<void> Function(int balance)? _acceptAuthoritativeBalance;
  int _generation = 0;
  Timer? _resumeTimer;

  void bindCapture(
    PalmExperienceService experience,
    CoffeeImageInputPort images, {
    ReadingFeatureRunner? live,
    ReadingPendingOperationStore? pendingStore,
    Future<void> Function(int balance)? acceptAuthoritativeBalance,
  }) {
    _experience = experience;
    _images = images;
    _live = live;
    _pendingStore = pendingStore;
    _acceptAuthoritativeBalance = acceptAuthoritativeBalance;
  }

  void markDisposed() {
    _disposed = true;
    _generation++;
    _resumeTimer?.cancel();
  }

  void safeNotify() {
    if (!_disposed && hasListeners) notifyListeners();
  }

  /// Server-quoted Gem cost for THIS operation. Null until fetched (or if
  /// the fetch fails) -- never a locally invented fallback number.
  int? get accelerationCost => _accelerationCost;

  Future<void> refreshAccelerationCost(
    ReadingFeatureRunner live,
    String operationId,
  ) async {
    if (_accelerationCostFor == operationId && _accelerationCost != null) {
      return;
    }
    final quote = await live.flow.quoteAcceleration(operationId);
    if (_disposed || liveState?.snapshot?.operationId != operationId) return;
    if (quote == null) return;
    _accelerationCostFor = operationId;
    _accelerationCost = quote.canonicalCost;
    _accelerationPriceToken = quote.priceToken;
    safeNotify();
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
