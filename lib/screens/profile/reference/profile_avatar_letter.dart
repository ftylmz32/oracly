/// First visible initial — no invented portrait.
library;

abstract final class ProfileAvatarLetter {
  ProfileAvatarLetter._();

  static String of(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Y';
    final first = trimmed[0];
    return switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
  }
}
