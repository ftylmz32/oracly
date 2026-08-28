/// SPRINT-001 — Core dream entity for the ORACLY universe.
library;

import 'dream_emotion.dart';
import 'dream_insight.dart';
import 'dream_relationship.dart';
import 'dream_symbol.dart';

class DreamUnderstanding {
  const DreamUnderstanding({
    required this.symbols,
    required this.emotions,
    required this.locations,
    required this.relationships,
    required this.recurringElements,
    required this.summary,
  });

  final List<DreamSymbol> symbols;
  final List<String> emotions;
  final List<String> locations;
  final List<DreamRelationship> relationships;
  final List<String> recurringElements;
  final String summary;

  Map<String, dynamic> toJson() => {
        'symbols': symbols.map((s) => s.toJson()).toList(),
        'emotions': emotions,
        'locations': locations,
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'recurringElements': recurringElements,
        'summary': summary,
      };

  factory DreamUnderstanding.fromJson(Map<String, dynamic> json) {
    return DreamUnderstanding(
      symbols: (json['symbols'] as List<dynamic>)
          .map((e) => DreamSymbol.fromJson(e as Map<String, dynamic>))
          .toList(),
      emotions: (json['emotions'] as List<dynamic>).cast<String>(),
      locations: (json['locations'] as List<dynamic>).cast<String>(),
      relationships: (json['relationships'] as List<dynamic>)
          .map((e) => DreamRelationship.fromJson(e as Map<String, dynamic>))
          .toList(),
      recurringElements:
          (json['recurringElements'] as List<dynamic>).cast<String>(),
      summary: json['summary'] as String,
    );
  }
}

class Dream {
  const Dream({
    required this.id,
    required this.narrative,
    required this.recordedAt,
    this.tags = const [],
    this.selectedEmotions = const [],
    this.understanding,
    this.insights = const [],
    this.voiceTranscriptPending = false,
    this.fromAi = false,
  });

  final String id;
  final String narrative;
  final DateTime recordedAt;
  final List<String> tags;
  final List<DreamEmotion> selectedEmotions;
  final DreamUnderstanding? understanding;
  final List<DreamInsight> insights;
  final bool voiceTranscriptPending;
  final bool fromAi;

  bool get isAnalyzed => understanding != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'narrative': narrative,
        'recordedAt': recordedAt.toIso8601String(),
        'tags': tags,
        'selectedEmotions': selectedEmotions.map((e) => e.toJson()).toList(),
        if (understanding != null) 'understanding': understanding!.toJson(),
        'insights': insights.map((i) => i.toJson()).toList(),
        'voiceTranscriptPending': voiceTranscriptPending,
        'fromAi': fromAi,
      };

  factory Dream.fromJson(Map<String, dynamic> json) {
    return Dream(
      id: json['id'] as String,
      narrative: json['narrative'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      selectedEmotions: (json['selectedEmotions'] as List<dynamic>?)
              ?.map((e) => DreamEmotion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      understanding: json['understanding'] != null
          ? DreamUnderstanding.fromJson(
              json['understanding'] as Map<String, dynamic>,
            )
          : null,
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => DreamInsight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      voiceTranscriptPending: json['voiceTranscriptPending'] as bool? ?? false,
      fromAi: json['fromAi'] as bool? ?? false,
    );
  }

  Dream copyWith({
    DreamUnderstanding? understanding,
    List<DreamInsight>? insights,
    bool? fromAi,
  }) {
    return Dream(
      id: id,
      narrative: narrative,
      recordedAt: recordedAt,
      tags: tags,
      selectedEmotions: selectedEmotions,
      understanding: understanding ?? this.understanding,
      insights: insights ?? this.insights,
      voiceTranscriptPending: voiceTranscriptPending,
      fromAi: fromAi ?? this.fromAi,
    );
  }
}
