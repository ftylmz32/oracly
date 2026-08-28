/// Stable emblem seed — same identity, same mark. Never time-based.
library;

abstract final class ProfileAvatarSeed {
  ProfileAvatarSeed._();

  static int of(String identity) {
    final text = identity.trim().toLowerCase();
    var hash = 2166136261;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static double unit(int seed, int lane) {
    return ((seed >> (lane % 24)) & 255) / 255.0;
  }
}
