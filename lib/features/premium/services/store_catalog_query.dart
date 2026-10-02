/// Bounded store availability + catalogue query that keeps the real outcome.
library;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/store_catalog_snapshot.dart';
import 'store_iap_client.dart';

class StoreAvailability {
  const StoreAvailability({
    required this.available,
    this.timedOut = false,
    this.exceptionType,
  });

  final bool available;
  final bool timedOut;
  final String? exceptionType;
}

class StoreCatalogAttempt {
  const StoreCatalogAttempt(this.products, this.snapshot);

  /// Only products whose id was requested — the purchasable truth.
  final List<ProductDetails> products;
  final StoreCatalogSnapshot snapshot;
}

class StoreCatalogLoad {
  const StoreCatalogLoad(this.storeAvailable, this.products, this.snapshot);

  final bool storeAvailable;
  final List<ProductDetails> products;
  final StoreCatalogSnapshot snapshot;
}

abstract final class StoreCatalogQuery {
  StoreCatalogQuery._();

  static const availabilityTimeout = Duration(seconds: 2);
  static const queryTimeout = Duration(seconds: 8);

  /// A cold App Store/Play Billing connection on a fresh install can miss
  /// the first product query entirely even though the next attempt, moments
  /// later, succeeds — so a full miss is retried once before it is accepted.
  static const retryDelay = Duration(milliseconds: 300);

  /// Availability check, then at most two catalogue queries. [onAvailable]
  /// runs before the first query (purchase-stream listener attach).
  static Future<StoreCatalogLoad> load(
    StoreIapClient iap,
    Set<String> ids, {
    required void Function() onAvailable,
  }) async {
    final availability = await checkAvailability(iap);
    if (!availability.available) {
      return StoreCatalogLoad(false, const [], unavailableSnapshot(availability));
    }
    onAvailable();
    var result = await query(iap, ids, attempt: 1);
    if (result.products.isEmpty) {
      await Future<void>.delayed(retryDelay);
      result = await query(iap, ids, attempt: 2);
    }
    return StoreCatalogLoad(true, result.products, result.snapshot);
  }

  static Future<StoreAvailability> checkAvailability(StoreIapClient iap) async {
    var timedOut = false;
    try {
      final available = await iap.isAvailable().timeout(
        availabilityTimeout,
        onTimeout: () {
          timedOut = true;
          return false;
        },
      );
      return StoreAvailability(available: available, timedOut: timedOut);
    } catch (error) {
      return StoreAvailability(
        available: false,
        exceptionType: StoreCatalogSnapshot.exceptionType(error),
      );
    }
  }

  static StoreCatalogSnapshot unavailableSnapshot(StoreAvailability check) {
    return StoreCatalogSnapshot(
      at: DateTime.now().toUtc(),
      storeAvailable: false,
      availabilityTimedOut: check.timedOut,
      availabilityExceptionType: check.exceptionType,
    );
  }

  /// A timeout or thrown query is recorded as such — never disguised as a
  /// store "not found" answer the store did not give.
  static Future<StoreCatalogAttempt> query(
    StoreIapClient iap,
    Set<String> ids, {
    required int attempt,
  }) async {
    ProductDetailsResponse? response;
    var timedOut = false;
    String? exceptionType;
    try {
      response = await iap.queryProductDetails(ids).timeout(
        queryTimeout,
        onTimeout: () {
          timedOut = true;
          return ProductDetailsResponse(
            productDetails: const [],
            notFoundIDs: const [],
          );
        },
      );
    } catch (error) {
      exceptionType = StoreCatalogSnapshot.exceptionType(error);
    }
    final returned = response?.productDetails ?? const <ProductDetails>[];
    final snapshot = StoreCatalogSnapshot(
      at: DateTime.now().toUtc(),
      storeAvailable: true,
      requestedIds: ids,
      returnedIds: returned.map((p) => p.id),
      notFoundIds: timedOut ? const [] : response?.notFoundIDs ?? const [],
      errorCode: response?.error?.code,
      errorMessage: response?.error?.message,
      queryTimedOut: timedOut,
      queryExceptionType: exceptionType,
      attempt: attempt,
    );
    return StoreCatalogAttempt(
      [for (final p in returned) if (ids.contains(p.id)) p],
      snapshot,
    );
  }
}
