part of 'coffee_reading_controller.dart';

extension CoffeeReadingCapture on CoffeeReadingController {
  void startCapture() {
    _phase = CoffeePhase.capture;
    _error = null;
    _safeNotify();
  }

  void backToEntry() {
    _phase = CoffeePhase.entry;
    _image = null;
    _reading = null;
    _error = null;
    _qualityHint = null;
    _safeNotify();
  }

  Future<void> pickCamera() async {
    _applyIntake(await CoffeeImageIntake.fromCamera(_images));
  }

  Future<void> pickGallery() async {
    _applyIntake(await CoffeeImageIntake.fromGallery(_images));
  }

  Future<void> acceptCapturedPath(String path) async {
    _applyIntake(await CoffeeImageIntake.assess(CoffeeImagePick(path: path)));
  }

  void _applyIntake(CoffeeImageIntakeResult result) {
    if (result.image != null) _image = result.image;
    _error = result.error;
    _qualityHint = result.qualityHint;
    _safeNotify();
  }

  void clearImage() {
    _image = null;
    _error = null;
    _qualityHint = null;
    _safeNotify();
  }

  void reportCaptureError(String message) {
    _error = message;
    _qualityHint = null;
    _phase = CoffeePhase.capture;
    _safeNotify();
  }

  void retryCapture() {
    _phase = CoffeePhase.capture;
    _error = null;
    _safeNotify();
  }
}
