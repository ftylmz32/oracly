/// Decode-time pixel cap — never downscale assets on disk.
library;

/// Pixel edge for [Image.cacheWidth] / [Image.cacheHeight].
///
/// Pass only one axis so Flutter keeps native aspect.
int? oraclyDecodeCachePx(
  double? logical,
  double devicePixelRatio, {
  int maxPx = 2048,
}) {
  final cap = maxPx < 1 ? 1 : maxPx;
  // Unbounded layout must still cap decode — never full master resolution.
  if (logical == null || !logical.isFinite || logical <= 0) return cap;
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) return cap;
  return (logical * devicePixelRatio).round().clamp(1, cap);
}
