/// Optional cup focus from the provider — never invented client-side.
library;

/// Normalized rect in image space (0–1). Absent or invalid → no marker.
class CoffeeSymbolFocus {
  const CoffeeSymbolFocus({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final double x;
  final double y;
  final double w;
  final double h;

  /// Rejects missing, out-of-bounds, or whole-frame “fake” boxes.
  bool get isReliable {
    if (w < 0.04 || h < 0.04) return false;
    if (w > 0.82 || h > 0.82) return false;
    if (x < -0.01 || y < -0.01) return false;
    if (x + w > 1.02 || y + h > 1.02) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};

  static CoffeeSymbolFocus? tryParse(Map<String, dynamic> json) {
    final raw = json['focus'] ??
        json['bbox'] ??
        json['box'] ??
        json['region'] ??
        json['konum'] ??
        json['spatial'];
    final parsed = _fromRaw(raw);
    if (parsed == null || !parsed.isReliable) return null;
    return parsed;
  }

  static CoffeeSymbolFocus? _fromRaw(Object? raw) {
    if (raw is List && raw.length >= 4) {
      return _nums(raw[0], raw[1], raw[2], raw[3]);
    }
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m.containsKey('left') || m.containsKey('l')) {
        final l = _n(m['left'] ?? m['l']);
        final t = _n(m['top'] ?? m['t']);
        final r = _n(m['right'] ?? m['r']);
        final b = _n(m['bottom'] ?? m['b']);
        if ([l, t, r, b].any((e) => e == null)) return null;
        return _nums(l!, t!, r! - l, b! - t);
      }
      return _nums(
        m['x'] ?? m['left'],
        m['y'] ?? m['top'],
        m['w'] ?? m['width'],
        m['h'] ?? m['height'],
      );
    }
    return null;
  }

  static CoffeeSymbolFocus? _nums(Object? x, Object? y, Object? w, Object? h) {
    final nx = _n(x);
    final ny = _n(y);
    final nw = _n(w);
    final nh = _n(h);
    if ([nx, ny, nw, nh].any((e) => e == null)) return null;
    return CoffeeSymbolFocus(x: nx!, y: ny!, w: nw!, h: nh!);
  }

  static double? _n(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }
}
