/// OR-1180 — Structured tarot interpretation result.
library;

import 'package:flutter/foundation.dart';

enum InterpretationSectionKey {
  summary,
  love,
  career,
  money,
  health,
  spiritualGuidance,
  advice,
  warnings,
  luckyEnergy,
  dailyFocus,
  closingMessage,
}

@immutable
class InterpretationSection {
  const InterpretationSection({
    required this.key,
    required this.title,
    required this.content,
  });

  final InterpretationSectionKey key;
  final String title;
  final String content;

  Map<String, dynamic> toJson() => {
        'key': key.name,
        'title': title,
        'content': content,
      };

  factory InterpretationSection.fromJson(Map<String, dynamic> json) {
    return InterpretationSection(
      key: InterpretationSectionKey.values.byName(json['key'] as String),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

@immutable
class InterpretationResult {
  const InterpretationResult({
    required this.requestId,
    required this.sessionId,
    required this.summary,
    required this.love,
    required this.career,
    required this.money,
    required this.health,
    required this.spiritualGuidance,
    required this.advice,
    required this.warnings,
    required this.luckyEnergy,
    required this.dailyFocus,
    required this.closingMessage,
    required this.generatedAt,
    this.source = InterpretationSource.local,
    this.rawText,
    this.fromCache = false,
  });

  final String requestId;
  final String sessionId;
  final String summary;
  final String love;
  final String career;
  final String money;
  final String health;
  final String spiritualGuidance;
  final String advice;
  final String warnings;
  final String luckyEnergy;
  final String dailyFocus;
  final String closingMessage;
  final DateTime generatedAt;
  final InterpretationSource source;
  final String? rawText;
  final bool fromCache;

  List<InterpretationSection> get sections => [
        InterpretationSection(
          key: InterpretationSectionKey.summary,
          title: 'Özet',
          content: summary,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.love,
          title: 'Aşk',
          content: love,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.career,
          title: 'Kariyer',
          content: career,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.money,
          title: 'Para',
          content: money,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.health,
          title: 'Sağlık',
          content: health,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.spiritualGuidance,
          title: 'Ruhsal Rehberlik',
          content: spiritualGuidance,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.advice,
          title: 'Tavsiye',
          content: advice,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.warnings,
          title: 'Uyarılar',
          content: warnings,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.luckyEnergy,
          title: 'Şans Enerjisi',
          content: luckyEnergy,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.dailyFocus,
          title: 'Günlük Odak',
          content: dailyFocus,
        ),
        InterpretationSection(
          key: InterpretationSectionKey.closingMessage,
          title: 'Kapanış',
          content: closingMessage,
        ),
      ];

  String? sectionContent(InterpretationSectionKey key) {
    for (final section in sections) {
      if (section.key == key) return section.content;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'sessionId': sessionId,
        'summary': summary,
        'love': love,
        'career': career,
        'money': money,
        'health': health,
        'spiritualGuidance': spiritualGuidance,
        'advice': advice,
        'warnings': warnings,
        'luckyEnergy': luckyEnergy,
        'dailyFocus': dailyFocus,
        'closingMessage': closingMessage,
        'generatedAt': generatedAt.toIso8601String(),
        'source': source.name,
        'rawText': rawText,
        'fromCache': fromCache,
      };

  factory InterpretationResult.fromJson(Map<String, dynamic> json) {
    return InterpretationResult(
      requestId: json['requestId'] as String,
      sessionId: json['sessionId'] as String,
      summary: json['summary'] as String? ?? '',
      love: json['love'] as String? ?? '',
      career: json['career'] as String? ?? '',
      money: json['money'] as String? ?? '',
      health: json['health'] as String? ?? '',
      spiritualGuidance: json['spiritualGuidance'] as String? ?? '',
      advice: json['advice'] as String? ?? '',
      warnings: json['warnings'] as String? ?? '',
      luckyEnergy: json['luckyEnergy'] as String? ?? '',
      dailyFocus: json['dailyFocus'] as String? ?? '',
      closingMessage: json['closingMessage'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      source: InterpretationSource.values.byName(
        json['source'] as String? ?? 'local',
      ),
      rawText: json['rawText'] as String?,
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }

  InterpretationResult copyWith({
    bool? fromCache,
    InterpretationSource? source,
    String? rawText,
  }) {
    return InterpretationResult(
      requestId: requestId,
      sessionId: sessionId,
      summary: summary,
      love: love,
      career: career,
      money: money,
      health: health,
      spiritualGuidance: spiritualGuidance,
      advice: advice,
      warnings: warnings,
      luckyEnergy: luckyEnergy,
      dailyFocus: dailyFocus,
      closingMessage: closingMessage,
      generatedAt: generatedAt,
      source: source ?? this.source,
      rawText: rawText ?? this.rawText,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

enum InterpretationSource { local, ai, cache }
