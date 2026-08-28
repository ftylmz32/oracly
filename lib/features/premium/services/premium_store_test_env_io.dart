import 'dart:io' show Platform;

/// True under `flutter test` (VM sets FLUTTER_TEST).
bool get premiumStoreUnderFlutterTest =>
    Platform.environment.containsKey('FLUTTER_TEST');