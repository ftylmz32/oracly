library;

import '../../features/coffee/models/coffee_reading.dart';
import '../../features/birth_chart/models/birth_chart.dart';
import '../../features/birth_chart/models/chart_insight.dart';
import '../../features/palm/models/palm_reading.dart';
import '../../features/premium/models/soul_mate_saved_result.dart';
import '../domain/models/dream_record.dart';
import '../domain/models/reading.dart';
import 'oracly_memory.dart';

abstract final class OraclyMemoryFactory {
  /// A completed Yildizname/Birth Chart journey, not the underlying profile.
  /// Daily catalogue astrology and raw placements must never call this seam.
  static OraclyMemory birthChart(BirthChart chart) {
    final interpreted = chart.insights
        .where(
          (item) => const {
            ChartInsightKind.corePersonality,
            ChartInsightKind.relationships,
            ChartInsightKind.careerPurpose,
            ChartInsightKind.emotionalPatterns,
            ChartInsightKind.lifeThemes,
          }.contains(item.kind),
        )
        .map((item) => item.body.trim())
        .where((body) => body.isNotEmpty)
        .join(' ');
    final themeText = chart.lifeThemes
        .map((theme) => '${theme.title} ${theme.body}')
        .join(' ');
    final authoritativeText = interpreted.isNotEmpty ? interpreted : themeText;
    return OraclyMemory(
      id: 'reading:birthChart:${chart.id}',
      kind: OraclyMemoryKind.reading,
      source: OraclyMemorySource(
        id: chart.id,
        type: OraclyReadingType.birthChart,
        occurredAt: chart.generatedAt,
        resultRef: chart.id,
      ),
      summary: _clip(authoritativeText),
      themes: _themes('$authoritativeText $themeText'),
      evidence: chart.lifeThemes
          .map((theme) => theme.title.trim())
          .where((title) => title.isNotEmpty)
          .take(5)
          .toList(),
      confidence: .72,
    );
  }

  static OraclyMemory tarot(ReadingModel r) => OraclyMemory(
    id: 'reading:tarot:${r.id}',
    kind: OraclyMemoryKind.reading,
    source: OraclyMemorySource(
      id: r.id,
      type: OraclyReadingType.tarot,
      occurredAt: r.createdAt,
      resultRef: r.id,
    ),
    summary: _clip(r.aiSummary),
    themes: _themes('${r.intention ?? ''} ${r.aiSummary}'),
    evidence: [
      ...r.cards.map((c) => '${c.cardName}${c.isReversed ? ' (ters)' : ''}'),
      if (r.cards.isEmpty && r.cardName.trim().isNotEmpty) r.cardName,
    ],
    intentions: [
      if (r.intention?.trim().isNotEmpty == true) r.intention!.trim(),
    ],
    advice: [
      if (r.journal.summaryExcerpt?.trim().isNotEmpty == true)
        r.journal.summaryExcerpt!.trim(),
    ],
  );

  static OraclyMemory coffee(CoffeeReading r) => OraclyMemory(
    id: 'reading:coffee:${r.id}',
    kind: OraclyMemoryKind.reading,
    source: OraclyMemorySource(
      id: r.id,
      type: OraclyReadingType.coffee,
      occurredAt: r.createdAt,
      resultRef: r.id,
    ),
    summary: _clip(r.overall),
    themes: _themes(r.fullText),
    evidence: [
      if (r.visualObservation.trim().isNotEmpty)
        _clip(r.visualObservation, 100),
      ...r.symbols.map((s) => s.name.trim()).where((s) => s.isNotEmpty),
    ],
    advice: [if (r.takeaway.trim().isNotEmpty) _clip(r.takeaway, 120)],
  );

  static OraclyMemory palm(PalmReading r) => OraclyMemory(
    id: 'reading:palm:${r.id}',
    kind: OraclyMemoryKind.reading,
    source: OraclyMemorySource(
      id: r.id,
      type: OraclyReadingType.palm,
      occurredAt: r.createdAt,
      resultRef: r.id,
    ),
    summary: _clip(r.overall),
    themes: {...r.themes, ..._themes(r.fullText)}.take(8).toList(),
    evidence: r.symbols.take(8).toList(),
    advice: [if (r.takeaway.trim().isNotEmpty) _clip(r.takeaway, 120)],
  );

  static OraclyMemory dream(DreamRecord r) => OraclyMemory(
    id: 'reading:dream:${r.id}',
    kind: OraclyMemoryKind.reading,
    source: OraclyMemorySource(
      id: r.id,
      type: OraclyReadingType.dream,
      occurredAt: r.createdAt,
      resultRef: r.id,
    ),
    summary: _clip(r.analysis),
    themes: {...r.tags, ..._themes('${r.text} ${r.analysis}')}.take(8).toList(),
    emotionalThemes: r.emotions.take(5).toList(),
  );

  static OraclyMemory soulmate(SoulMateSavedResult r) {
    final text = [
      r.parts.energy,
      r.parts.attraction,
      r.parts.dynamics,
      r.parts.feeling,
      r.parts.yourSide,
      r.parts.meeting,
    ].join(' ');
    return OraclyMemory(
      id: 'reading:soulmate:${r.id}',
      kind: OraclyMemoryKind.reading,
      source: OraclyMemorySource(
        id: r.id,
        type: OraclyReadingType.soulmate,
        occurredAt: r.createdAt,
        resultRef: r.id,
      ),
      summary: _clip(text),
      themes: _themes(text),
      intentions: [
        if (r.intention?.trim().isNotEmpty == true) r.intention!.trim(),
      ],
      confidence: r.hasAuthoritativeInterpretation ? .8 : .45,
    );
  }

  static String _clip(String value, [int max = 300]) {
    final v = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return v.length <= max ? v : v.substring(0, max);
  }

  /// Conservative deterministic concepts; unknown prose is not promoted to a fact.
  static List<String> _themes(String value) {
    final lower = value.toLowerCase();
    const concepts = <String, List<String>>{
      'kariyer': ['kariyer', 'iş', 'meslek', 'çalışma'],
      'karar': ['karar', 'seçim', 'iki yol', 'yol ayrımı'],
      'ilişki': ['ilişki', 'aşk', 'partner', 'yakınlık'],
      'değişim': ['değişim', 'dönüşüm', 'yenilik'],
      'sınır': ['sınır', 'mesafe', 'korunma'],
      'iletişim': ['iletişim', 'konuşma', 'haber', 'mesaj'],
      'belirsizlik': ['belirsiz', 'kararsız', 'net değil'],
      'özgüven': ['özgüven', 'kendine güven', 'cesaret'],
    };
    return [
      for (final e in concepts.entries)
        if (e.value.any(lower.contains)) e.key,
    ];
  }
}
