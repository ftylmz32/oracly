/// Persisted coffee reading — analysis text, optional image path.
library;

import 'coffee_symbol.dart';

class CoffeeReading {
  const CoffeeReading({
    required this.id,
    required this.createdAt,
    required this.overall,
    required this.love,
    required this.career,
    required this.money,
    required this.nearFuture,
    required this.takeaway,
    this.imagePath,
    this.visualObservation = '',
    this.symbols = const [],
  });

  final String id;
  final DateTime createdAt;
  final String? imagePath;
  final String overall;
  final String love;
  final String career;
  final String money;
  final String nearFuture;
  final String takeaway;
  final String visualObservation;
  final List<CoffeeSymbol> symbols;

  String get fullText => [
        visualObservation,
        overall,
        love,
        career,
        money,
        nearFuture,
        for (final s in symbols) '${s.name}: ${s.interpretation}',
        takeaway,
      ].where((e) => e.trim().isNotEmpty).join('\n\n');

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'imagePath': imagePath,
        'overall': overall,
        'love': love,
        'career': career,
        'money': money,
        'nearFuture': nearFuture,
        'takeaway': takeaway,
        'visualObservation': visualObservation,
        'symbols': symbols.map((s) => s.toJson()).toList(),
      };

  factory CoffeeReading.fromJson(Map<String, dynamic> json) {
    return CoffeeReading(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
      overall: json['overall'] as String? ?? '',
      love: json['love'] as String? ?? '',
      career: json['career'] as String? ?? '',
      money: json['money'] as String? ?? '',
      nearFuture: json['nearFuture'] as String? ?? '',
      takeaway: json['takeaway'] as String? ?? '',
      visualObservation: json['visualObservation'] as String? ?? '',
      symbols: (json['symbols'] as List<dynamic>? ?? [])
          .map((e) => CoffeeSymbol.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CoffeeReading copyWith({
    String? overall,
    String? love,
    String? career,
    String? money,
    String? nearFuture,
    String? takeaway,
    String? visualObservation,
  }) {
    return CoffeeReading(
      id: id,
      createdAt: createdAt,
      imagePath: imagePath,
      overall: overall ?? this.overall,
      love: love ?? this.love,
      career: career ?? this.career,
      money: money ?? this.money,
      nearFuture: nearFuture ?? this.nearFuture,
      takeaway: takeaway ?? this.takeaway,
      visualObservation: visualObservation ?? this.visualObservation,
      symbols: symbols,
    );
  }
}
