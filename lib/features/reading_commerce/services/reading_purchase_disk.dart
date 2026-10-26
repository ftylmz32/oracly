import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage.dart';
import 'reading_purchase_tracker.dart';

/// Unfinished reading purchases, in secure storage, one bucket per owner
/// tag (the opaque SHA-256 owner tag also sent to the store). A session
/// only ever loads its own owner's bucket; nothing is kept when no owner is
/// known, because the store itself keeps an unfinished purchase.
///
/// The account wipe clears secure storage. That loses only this local
/// copy: the purchase was never finished (finishing needs a backend
/// grant), so the store still holds it and hands it back to its owner.
class SecureReadingPurchases implements ReadingPurchaseMemory {
  SecureReadingPurchases({
    required SecureStorage secure,
    required String? Function() currentOwnerTag,
  })
    // ignore: prefer_initializing_formals
    : _secure = secure,
      // ignore: prefer_initializing_formals
      _currentOwnerTag = currentOwnerTag;

  final SecureStorage _secure;
  final String? Function() _currentOwnerTag;
  bool _legacyCleared = false;

  /// The pre-fix plain-text list. Its entries carry no owner, so none is
  /// handed to whoever is signed in; reading purchases among them are
  /// still unfinished at the store, which redelivers them.
  static const legacyKey = 'reading_commerce_unfinished_v1';
  static const _prefix = 'or_reading_purchases_v2_';

  @override
  Future<List<ReadingPurchaseUpdate>> load() async {
    await _clearLegacy();
    final owner = _currentOwnerTag();
    if (owner == null) return const [];
    return _read(owner);
  }

  @override
  Future<void> save(ReadingPurchaseUpdate purchase) async {
    await _clearLegacy();
    final owner = purchase.ownerTag ?? _currentOwnerTag();
    if (owner == null) return;
    final next = [
      ...(await _read(owner)).where((item) => item.token != purchase.token),
      purchase.withOwner(owner),
    ];
    await _write(owner, next);
  }

  @override
  Future<void> remove(String token) async {
    final owner = _currentOwnerTag();
    if (owner == null) return;
    final next = (await _read(owner)).where((item) => item.token != token).toList();
    await _write(owner, next);
  }

  Future<List<ReadingPurchaseUpdate>> _read(String owner) async {
    final raw = await _secure.read('$_prefix$owner');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_decode)
          .whereType<ReadingPurchaseUpdate>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write(String owner, List<ReadingPurchaseUpdate> items) {
    if (items.isEmpty) return _secure.delete('$_prefix$owner');
    return _secure.write('$_prefix$owner', jsonEncode(items.map(_encode).toList()));
  }

  Future<void> _clearLegacy() async {
    if (_legacyCleared) return;
    _legacyCleared = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(legacyKey);
    } catch (_) {}
  }

  static Map<String, String> _encode(ReadingPurchaseUpdate purchase) => {
    'status': purchase.status.name,
    'productId': purchase.productId,
    'purchaseId': purchase.purchaseId,
    'token': purchase.token,
    'ownerTag': ?purchase.ownerTag,
  };

  static ReadingPurchaseUpdate? _decode(Map<String, dynamic> json) {
    final status = ReadingPurchaseStatus.values.where((item) => item.name == json['status']);
    final productId = json['productId'];
    final purchaseId = json['purchaseId'];
    final token = json['token'];
    if (status.isEmpty || productId is! String || purchaseId is! String || token is! String) {
      return null;
    }
    final owner = json['ownerTag'];
    return ReadingPurchaseUpdate(
      status: status.first,
      productId: productId,
      purchaseId: purchaseId,
      token: token,
      ownerTag: owner is String ? owner : null,
    );
  }
}
