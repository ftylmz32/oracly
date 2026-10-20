import 'package:shared_preferences/shared_preferences.dart';

import 'reading_purchase_tracker.dart';

class DiskReadingPurchases implements ReadingPurchaseMemory {
  static const _key = 'reading_commerce_unfinished_v1';

  @override
  Future<List<ReadingPurchaseUpdate>> load() async {
    final prefs = await _prefs();
    if (prefs == null) return const [];
    return (prefs.getStringList(_key) ?? const [])
        .map(_decode)
        .whereType<ReadingPurchaseUpdate>()
        .toList();
  }

  @override
  Future<void> save(ReadingPurchaseUpdate purchase) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    final next = [
      ...(await load()).where((item) => item.token != purchase.token),
      purchase,
    ];
    await prefs.setStringList(_key, next.map(_encode).toList());
  }

  @override
  Future<void> remove(String token) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    final next = (await load()).where((item) => item.token != token);
    await prefs.setStringList(_key, next.map(_encode).toList());
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  static String _encode(ReadingPurchaseUpdate purchase) =>
      '${purchase.status.name}\u0000${purchase.productId}\u0000${purchase.purchaseId}\u0000${purchase.token}';

  static ReadingPurchaseUpdate? _decode(String raw) {
    final parts = raw.split('\u0000');
    if (parts.length != 4) return null;
    final status = ReadingPurchaseStatus.values.where((item) => item.name == parts[0]);
    if (status.isEmpty) return null;
    return ReadingPurchaseUpdate(
      status: status.first,
      productId: parts[1],
      purchaseId: parts[2],
      token: parts[3],
    );
  }
}
