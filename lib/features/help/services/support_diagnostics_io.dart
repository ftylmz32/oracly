/// Native OS label for diagnostics share (no device id).
library;

import 'dart:io' show Platform;

String? operatingSystemLabel() {
  try {
    return Platform.operatingSystemVersion;
  } catch (_) {
    return null;
  }
}
