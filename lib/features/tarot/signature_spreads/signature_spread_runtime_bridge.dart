/// Phase 5D — Signature ↔ TarotSpreadType runtime bridge (launch only).
library;

import '../domain/models/tarot_spread.dart';
import 'signature_spread_catalog.dart';
import 'signature_spread_definition.dart';

abstract final class SignatureSpreadRuntimeBridge {
  SignatureSpreadRuntimeBridge._();

  static SignatureSpreadDefinition? definitionFor(TarotSpreadType type) {
    return switch (type) {
      TarotSpreadType.single =>
        SignatureSpreadCatalog.bySpreadId('classical.single'),
      TarotSpreadType.threeCard =>
        SignatureSpreadCatalog.bySpreadId('classical.threeCard'),
      TarotSpreadType.fiveCard =>
        SignatureSpreadCatalog.bySpreadId('classical.fiveCard'),
      TarotSpreadType.crossroads =>
        SignatureSpreadCatalog.bySpreadId('signature.crossroads'),
      TarotSpreadType.sevenCard || TarotSpreadType.celticCross => null,
    };
  }

  static TarotSpreadType? runtimeFor(String spreadId) {
    return switch (spreadId) {
      'classical.single' => TarotSpreadType.single,
      'classical.threeCard' => TarotSpreadType.threeCard,
      'classical.fiveCard' => TarotSpreadType.fiveCard,
      'signature.crossroads' => TarotSpreadType.crossroads,
      _ => null,
    };
  }

  /// Launch bridge pairs only (seven/celtic excluded).
  static const launchRuntimeTypes = <TarotSpreadType>[
    TarotSpreadType.single,
    TarotSpreadType.threeCard,
    TarotSpreadType.fiveCard,
    TarotSpreadType.crossroads,
  ];
}
