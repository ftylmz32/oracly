/// Device-level ledger of store purchases that are not finished for their
/// owner yet: launched, reported PENDING by the store, or finished while a
/// different account was signed in (proof parked for its owner).
///
/// It deliberately survives the account-boundary wipe: the store bills the
/// device's store account, so an unfinished purchase must keep blocking a
/// second charge whoever signs in next. Each entry carries only an opaque
/// owner tag (SHA-256 of the uid, also sent to Play as the obfuscated
/// account id), never the raw uid. A parked receipt sits in secure storage
/// under its owner's tag and is only ever handed back to that owner.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../features/premium/models/premium_purchase_credentials.dart';
import '../data/datasources/local_storage.dart';
import '../data/datasources/storage_result.dart';
import 'secure_storage.dart';

class PremiumPurchaseAttempt {
  const PremiumPurchaseAttempt({
    required this.ownerTag,
    required this.platform,
    required this.productId,
    required this.attemptId,
    required this.sinceUtc,
    this.storeRef,
    this.parked = false,
  });

  final String ownerTag;
  final String platform;
  final String productId;

  /// Unique per launched purchase sheet.
  final String attemptId;
  final DateTime sinceUtc;

  /// The store's own id for the transaction once it reported one (Play
  /// purchase token). Used only to match later store answers.
  final String? storeRef;

  /// The store finished it while another account was signed in; its proof
  /// waits in the owner's parked slot.
  final bool parked;

  PremiumPurchaseAttempt copyWith({String? storeRef, bool? parked}) =>
      PremiumPurchaseAttempt(
        ownerTag: ownerTag,
        platform: platform,
        productId: productId,
        attemptId: attemptId,
        sinceUtc: sinceUtc,
        storeRef: storeRef ?? this.storeRef,
        parked: parked ?? this.parked,
      );

  Map<String, Object?> toJson() => {
    'o': ownerTag,
    'f': platform,
    'p': productId,
    'a': attemptId,
    's': sinceUtc.toIso8601String(),
    if (storeRef != null) 'r': storeRef,
    if (parked) 'k': true,
  };

  static PremiumPurchaseAttempt? fromJson(Object? json) {
    if (json is! Map) return null;
    final owner = json['o'];
    final platform = json['f'];
    final product = json['p'];
    final attempt = json['a'];
    final since = DateTime.tryParse('${json['s']}');
    if (owner is! String ||
        platform is! String ||
        product is! String ||
        attempt is! String ||
        since == null) {
      return null;
    }
    final ref = json['r'];
    return PremiumPurchaseAttempt(
      ownerTag: owner,
      platform: platform,
      productId: product,
      attemptId: attempt,
      sinceUtc: since.toUtc(),
      storeRef: ref is String && ref.isNotEmpty ? ref : null,
      parked: json['k'] == true,
    );
  }
}

class PremiumPurchaseAttemptStore {
  PremiumPurchaseAttemptStore(this._storage, this._secure);

  final LocalStorage _storage;
  final SecureStorage _secure;

  static const ledgerKey = 'or_premium_purchase_attempts_v1';
  static const _parkedPrefix = 'or_premium_parked_receipt_v1_';

  /// Opaque, stable per-account tag. Never reversible to the uid.
  static String ownerTag(String uid) =>
      sha256.convert(utf8.encode('oracly.premium.owner:$uid')).toString();

  /// Readable entries. A ledger that exists but cannot be read still holds
  /// (see [holdsAny]); it is never treated as empty.
  List<PremiumPurchaseAttempt> all() {
    final raw = _storage.getString(ledgerKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final entry in list) ?PremiumPurchaseAttempt.fromJson(entry)];
    } catch (_) {
      return const [];
    }
  }

  /// Any unfinished purchase on this device, for any owner. Fails closed: a
  /// ledger value that cannot be parsed still counts.
  bool get holdsAny {
    final raw = _storage.getString(ledgerKey);
    if (raw == null || raw.isEmpty) return false;
    return all().isNotEmpty || !_parses(raw);
  }

  static bool _parses(String raw) {
    try {
      return jsonDecode(raw) is List;
    } catch (_) {
      return false;
    }
  }

  Future<void> _write(List<PremiumPurchaseAttempt> attempts) async {
    if (attempts.isEmpty) {
      await _storage.remove(ledgerKey).requireDurable(ledgerKey);
      return;
    }
    await _storage
        .setString(
          ledgerKey,
          jsonEncode([for (final a in attempts) a.toJson()]),
        )
        .requireDurable(ledgerKey);
  }

  /// Durable before any store sheet opens. Throws when it did not land.
  Future<void> begin(PremiumPurchaseAttempt attempt) =>
      _write([...all(), attempt]);

  Future<void> replace(PremiumPurchaseAttempt attempt) => _write([
    for (final a in all())
      if (a.attemptId == attempt.attemptId) attempt else a,
  ]);

  Future<void> release(bool Function(PremiumPurchaseAttempt) where) async {
    final current = all();
    final kept = [
      for (final a in current)
        if (!where(a)) a,
    ];
    if (kept.length != current.length) await _write(kept);
  }

  /// Keeps [proof] for [ownerTag] only. Throws when nothing durable landed.
  Future<void> park(String ownerTag, PremiumPurchaseCredentials proof) async {
    await _secure.write(
      '$_parkedPrefix$ownerTag',
      jsonEncode({
        'platform': proof.platform,
        'productId': proof.productId,
        'token': proof.purchaseToken,
        if (proof.transactionId != null) 'txn': proof.transactionId,
      }),
    );
    final readBack = await readParked(ownerTag);
    if (readBack?.purchaseToken != proof.purchaseToken) {
      throw StateError('parked purchase proof not durable');
    }
  }

  Future<PremiumPurchaseCredentials?> readParked(String ownerTag) async {
    final raw = await _secure.read('$_parkedPrefix$ownerTag');
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final creds = PremiumPurchaseCredentials(
        platform: '${json['platform']}',
        productId: '${json['productId']}',
        purchaseToken: '${json['token']}',
        transactionId: json['txn'] is String ? json['txn'] as String : null,
      );
      return creds.isComplete ? creds : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearParked(String ownerTag) =>
      _secure.delete('$_parkedPrefix$ownerTag');

  /// Account deletion: drop everything recorded for this account only.
  Future<void> forgetOwner(String uid) async {
    final tag = ownerTag(uid);
    await release((a) => a.ownerTag == tag);
    await clearParked(tag);
  }
}
