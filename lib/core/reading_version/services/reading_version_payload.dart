/// Maps feature readings into version payloads.
library;

import '../../../features/coffee/models/coffee_reading.dart';
import '../../../features/dream/models/dream.dart';
import '../../../features/palm/models/palm_reading.dart';
import '../models/reading_version_kind.dart';

abstract final class ReadingVersionPayload {
  ReadingVersionPayload._();

  static Map<String, dynamic> tarot(String summary) => {'summary': summary};

  static Map<String, dynamic> coffee(CoffeeReading reading) => {
        'overall': reading.overall,
        'love': reading.love,
        'career': reading.career,
        'money': reading.money,
        'nearFuture': reading.nearFuture,
        'takeaway': reading.takeaway,
        'visualObservation': reading.visualObservation,
      };

  static Map<String, dynamic> palm(PalmReading reading) => {
        'overall': reading.overall,
        'lifeLine': reading.lifeLine,
        'headLine': reading.headLine,
        'heartLine': reading.heartLine,
        'fateLine': reading.fateLine,
        'takeaway': reading.takeaway,
        'symbols': reading.symbols,
        'themes': reading.themes,
      };

  static Map<String, dynamic> dream(Dream dream, String analysis) => {
        'analysis': analysis,
        'payload': dream.toJson(),
      };

  static String tarotSummary(Map<String, dynamic> data) =>
      '${data['summary'] ?? ''}';

  static CoffeeReading applyCoffee(CoffeeReading base, Map<String, dynamic> data) {
    return base.copyWith(
      overall: '${data['overall'] ?? base.overall}',
      love: '${data['love'] ?? base.love}',
      career: '${data['career'] ?? base.career}',
      money: '${data['money'] ?? base.money}',
      nearFuture: '${data['nearFuture'] ?? base.nearFuture}',
      takeaway: '${data['takeaway'] ?? base.takeaway}',
      visualObservation:
          '${data['visualObservation'] ?? base.visualObservation}',
    );
  }

  static PalmReading applyPalm(PalmReading base, Map<String, dynamic> data) {
    List<String> list(Object? raw, List<String> fallback) {
      if (raw is! List) return fallback;
      return [
        for (final item in raw)
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ];
    }

    return PalmReading(
      id: base.id,
      createdAt: base.createdAt,
      hand: base.hand,
      overall: '${data['overall'] ?? base.overall}',
      lifeLine: '${data['lifeLine'] ?? base.lifeLine}',
      headLine: '${data['headLine'] ?? base.headLine}',
      heartLine: '${data['heartLine'] ?? base.heartLine}',
      fateLine: '${data['fateLine'] ?? base.fateLine}',
      takeaway: '${data['takeaway'] ?? base.takeaway}',
      symbols: list(data['symbols'], base.symbols),
      themes: list(data['themes'], base.themes),
      imagePath: base.imagePath,
    );
  }

  static Dream? applyDream(Dream? base, Map<String, dynamic> data) {
    final payload = data['payload'];
    if (payload is Map<String, dynamic>) {
      return Dream.fromJson(payload);
    }
    if (base == null) return null;
    return base;
  }

  static String dreamAnalysis(Map<String, dynamic> data) =>
      '${data['analysis'] ?? ''}';

  static ReadingVersionKind kindFor(String feature) => switch (feature) {
        'tarot' => ReadingVersionKind.tarot,
        'coffee' => ReadingVersionKind.coffee,
        'palm' => ReadingVersionKind.palm,
        'dream' => ReadingVersionKind.dream,
        _ => ReadingVersionKind.tarot,
      };
}

