/// Long-running proxy HTTP wait — longer than a single-call abort, under
/// Cloud Run's ~180s ceiling. Named for its original Soulmate image-draw
/// use; also shared by Coffee/Palm analysis, whose server-side two-call
/// (vision observer + writer) pipeline runs on the same order of
/// magnitude.
library;

/// Client keeps listening after the call returns, without waiting forever.
abstract final class SoulmateClientTimeout {
  SoulmateClientTimeout._();

  /// Observed Cloud Run ceiling minus a small margin.
  static const ceiling = Duration(seconds: 175);

  /// Still listening when the image abort response arrives.
  static const grace = Duration(seconds: 15);

  static Duration wait(Duration imageTimeout) {
    final imageSec = imageTimeout.inSeconds.clamp(30, 160);
    final seconds = imageSec + grace.inSeconds;
    return Duration(seconds: seconds.clamp(45, ceiling.inSeconds));
  }
}
