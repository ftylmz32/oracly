/// Opaque durable Yıldızname artifact ids (`yid_<32 hex>`).
library;

import 'dart:math';

typedef YildiznameArtifactIdGenerator = String Function();

abstract final class YildiznameArtifactId {
  YildiznameArtifactId._();

  static final RegExp _valid = RegExp(r'^yid_[0-9a-f]{32}$');

  static YildiznameArtifactIdGenerator generator = secure;

  static bool isValid(String id) => _valid.hasMatch(id);

  static String generate() => generator();

  static String secure() {
    final r = Random.secure();
    final buf = StringBuffer('yid_');
    for (var i = 0; i < 32; i++) {
      buf.write(r.nextInt(16).toRadixString(16));
    }
    return buf.toString();
  }

  /// Test helper — restores [Random.secure] generator after [body].
  static T withGenerator<T>(
    YildiznameArtifactIdGenerator next,
    T Function() body,
  ) {
    final prev = generator;
    generator = next;
    try {
      return body();
    } finally {
      generator = prev;
    }
  }
}
