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
    this.cleanCheckUtc,
  });

  final String ownerTag;
  final String platform;
  final String productId;

  /// Unique per launched purchase sheet.
  final String attemptId;
  final DateTime sinceUtc;

  /// SHA-256 of the store's own id for the transaction once it reported
  /// one (Play purchase token). Only ever compared, never sent anywhere;
  /// the raw token itself lives in secure storage.
  final String? storeRef;

  /// The store finished it while another account was signed in; its proof
  /// waits in the owner's parked slot.
  final bool parked;

  /// Last time a successful store query showed no transaction at all for
  /// this product. Not proof of anything on its own; it only gates the
  /// user's same-plan retry of an attempt with no token.
  final DateTime? cleanCheckUtc;

  PremiumPurchaseAttempt copyWith({
    String? storeRef,
    bool? parked,
    DateTime? cleanCheckUtc,
    bool clearCleanCheck = false,
  }) => PremiumPurchaseAttempt(
    ownerTag: ownerTag,
    platform: platform,
    productId: productId,
    attemptId: attemptId,
    sinceUtc: sinceUtc,
    storeRef: storeRef ?? this.storeRef,
    parked: parked ?? this.parked,
    cleanCheckUtc: clearCleanCheck ? null : (cleanCheckUtc ?? this.cleanCheckUtc),
  );

  Map<String, Object?> toJson() => {
    'o': ownerTag,
    'f': platform,
    'p': productId,
    'a': attemptId,
    's': sinceUtc.toIso8601String(),
    if (storeRef != null) 'r': storeRef,
    if (parked) 'k': true,
    if (cleanCheckUtc != null) 'c': cleanCheckUtc!.toIso8601String(),
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
    final clean = DateTime.tryParse('${json['c'] ?? ''}');
    return PremiumPurchaseAttempt(
      ownerTag: owner,
      platform: platform,
      productId: product,
      attemptId: attempt,
      sinceUtc: since.toUtc(),
      storeRef: ref is String && ref.isNotEmpty ? ref : null,
      parked: json['k'] == true,
      cleanCheckUtc: clean?.toUtc(),
    );
  }
}

class PremiumPurchaseAttemptStore {
  PremiumPurchaseAttemptStore(this._storage, this._secure);

  final LocalStorage _storage;
  final SecureStorage _secure;

  static const ledgerKey = 'or_premium_purchase_attempts_v1';
  static const _parkedPrefix = 'or_premium_parked_receipt_v1_';
  static const _pendingTokenPrefix = 'or_premium_pending_token_v1_';

  /// Why each lock was released, newest last. No token, no uid.
  static const auditKey = 'or_premium_purchase_audit_v1';
  static const _auditLimit = 50;

  /// What the ledger keeps to match a store transaction: never the raw id.
  static String refHash(String ref) =>
      sha256.convert(utf8.encode('oracly.premium.storeref:$ref')).toString();

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

  Future<void> release(
    bool Function(PremiumPurchaseAttempt) where, {
    String why = 'released',
  }) async {
    final current = all();
    final released = [
      for (final a in current)
        if (where(a)) a,
    ];
    if (released.isEmpty) return;
    await _write([
      for (final a in current)
        if (!where(a)) a,
    ]);
    await _audit(released, why);
    for (final a in released) {
      try {
        await _secure.delete('$_pendingTokenPrefix${a.attemptId}');
      } catch (_) {}
    }
  }

  /// The store's own token for an unfinished transaction, kept so its
  /// owner's backend can ask the store about it. Secure storage only.
  Future<void> savePendingToken(String attemptId, String token) =>
      _secure.write('$_pendingTokenPrefix$attemptId', token);

  Future<String?> readPendingToken(String attemptId) async {
    final token = await _secure.read('$_pendingTokenPrefix$attemptId');
    return token == null || token.isEmpty ? null : token;
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
    await release((a) => a.ownerTag == tag, why: 'account_deleted');
    await clearParked(tag);
  }

  /// Release reasons for support and review. Best effort: an audit write
  /// failure never blocks or undoes a release.
  List<Map<String, Object?>> auditTrail() {
    final raw = _storage.getString(auditKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      return [
        for (final e in list is List ? list : const [])
          if (e is Map) Map<String, Object?>.from(e),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _audit(List<PremiumPurchaseAttempt> released, String why) async {
    try {
      final at = DateTime.now().toUtc().toIso8601String();
      final entries = [
        ...auditTrail(),
        for (final a in released)
          {
            'at': at,
            'why': why,
            'owner': a.ownerTag.substring(0, 12),
            'product': a.productId,
            'attempt': a.attemptId,
            'hadToken': a.storeRef != null,
          },
      ];
      final kept = entries.length > _auditLimit
          ? entries.sublist(entries.length - _auditLimit)
          : entries;
      await _storage.setString(auditKey, jsonEncode(kept));
    } catch (_) {}
  }
}
