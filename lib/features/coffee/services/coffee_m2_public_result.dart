/// Restores a completed `m2_public_v1` Coffee result WITHOUT the legacy chain
/// (OpenAiServiceResults → CoffeeVisionParser → CoffeeReadingParser →
/// CoffeeFortuneComposer). The server already gated this reading; the client
/// only validates the shape and keeps `overall` verbatim — no trim, scrub,
/// rewrite, length floor, visual requirement or invented symbols.
library;

import '../copy/coffee_copy.dart';
import '../models/coffee_reading.dart';
import '../models/coffee_result_contract.dart';
import 'coffee_analysis_port.dart';

abstract final class CoffeeM2PublicResult {
  CoffeeM2PublicResult._();

  static const _emptyLanes = ['visualObservation', 'love', 'career', 'money', 'nearFuture', 'takeaway'];

  /// Throws [CoffeeAnalysisException] for any malformed `m2_public_v1` body.
  static CoffeeReading restore({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) {
    final overall = result['overall'];
    final symbols = result['symbols'];
    final valid = result['coffeeResultContract'] == coffeeM2PublicV1ResultContract &&
        overall is String &&
        overall.trim().isNotEmpty &&
        _emptyLanes.every((lane) => result[lane] == '') &&
        symbols is List &&
        symbols.isEmpty;
    if (!valid) throw CoffeeAnalysisException(CoffeeCopy.analysisFailed);
    return CoffeeReading(
      id: resultId,
      createdAt: persistedAt,
      imagePath: null,
      coffeeResultContract: coffeeM2PublicV1ResultContract,
      overall: overall,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      visualObservation: '',
      symbols: const [],
    );
  }
}
