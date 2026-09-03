/// User-curated ORACLY moment — explicit save only.
library;

import '../../../core/l10n/oracly_format.dart';
import '../../discovery_journal/models/discovery_journal_kind.dart';

enum FavoriteMomentSource {
  tarot,
  coffee,
  palm,
  dream,
  companion,
  dailyMessage,
  starMap,
  astrology;

  DiscoveryJournalKind get journalKind => switch (this) {
        FavoriteMomentSource.tarot => DiscoveryJournalKind.tarot,
        FavoriteMomentSource.coffee => DiscoveryJournalKind.coffee,
        FavoriteMomentSource.palm => DiscoveryJournalKind.palm,
        FavoriteMomentSource.dream => DiscoveryJournalKind.dream,
        FavoriteMomentSource.companion => DiscoveryJournalKind.companion,
        FavoriteMomentSource.dailyMessage => DiscoveryJournalKind.dailyMessage,
        FavoriteMomentSource.starMap => DiscoveryJournalKind.starMap,
        FavoriteMomentSource.astrology => DiscoveryJournalKind.astrology,
      };

  static FavoriteMomentSource? fromName(String? raw) {
    if (raw == null) return null;
    for (final value in FavoriteMomentSource.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

class FavoriteMoment {
  const FavoriteMoment({
    required this.id,
    required this.source,
    required this.sourceRef,
    required this.savedAt,
    required this.occurredAt,
    required this.quote,
    this.visualAsset,
    this.visualLabel,
    this.visualIsReversed = false,
  });

  final String id;
  final FavoriteMomentSource source;
  final String sourceRef;
  final DateTime savedAt;
  final DateTime occurredAt;
  final String quote;
  final String? visualAsset;
  final String? visualLabel;

  /// When [visualAsset] reproduces a drawn Tarot card, preserve orientation.
  /// Missing on old favorites → upright.
  final bool visualIsReversed;

  String get dateLabel => OraclyFormat.date(occurredAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'sourceRef': sourceRef,
        'savedAt': savedAt.toIso8601String(),
        'occurredAt': occurredAt.toIso8601String(),
        'quote': quote,
        if (visualAsset != null) 'visualAsset': visualAsset,
        if (visualLabel != null) 'visualLabel': visualLabel,
        if (visualIsReversed) 'visualIsReversed': true,
      };

  factory FavoriteMoment.fromJson(Map<String, dynamic> json) {
    final source = FavoriteMomentSource.fromName('${json['source']}');
    if (source == null) {
      throw FormatException('unknown favorite source: ${json['source']}');
    }
    final id = '${json['id']}'.trim();
    if (id.isEmpty) {
      throw const FormatException('favorite moment missing id');
    }
    return FavoriteMoment(
      id: id,
      source: source,
      sourceRef: '${json['sourceRef']}',
      savedAt: DateTime.tryParse('${json['savedAt']}') ?? DateTime.now(),
      occurredAt: DateTime.tryParse('${json['occurredAt']}') ?? DateTime.now(),
      quote: '${json['quote']}',
      visualAsset: json['visualAsset'] as String?,
      visualLabel: json['visualLabel'] as String?,
      visualIsReversed: json['visualIsReversed'] as bool? ?? false,
    );
  }
}