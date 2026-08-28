/// Same artwork, two decode sizes — never load 78 full faces at once.
library;

abstract final class TarotCardAsset {
  TarotCardAsset._();

  static const root = 'lib/assets/images/tarot/';
  static const thumbs = 'lib/assets/images/tarot/thumbs/';

  static const previewCapPx = 512;
  static const fullCapPx = 1536;

  /// Fan, history row, spread overview.
  static String preview(String asset) => _map(asset, thumb: true);

  /// Reveal and detail only.
  static String full(String asset) => _map(asset, thumb: false);

  static String _map(String asset, {required bool thumb}) {
    var path = asset.replaceAll('\\', '/');
    if (path.endsWith('.png')) {
      path = '${path.substring(0, path.length - 4)}.webp';
    }
    if (!thumb) return path;
    if (path.startsWith(root) && !path.startsWith(thumbs)) {
      return '$thumbs${path.substring(root.length)}';
    }
    return path;
  }
}
