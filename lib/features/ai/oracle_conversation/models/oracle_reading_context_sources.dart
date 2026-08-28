/// OR'a Sor context builders for non-tarot readings.
library;

import '../../../birth_chart/models/birth_profile.dart';
import '../../../coffee/models/coffee_reading.dart';
import '../../../palm/models/palm_reading.dart';
import '../../../star_map/models/star_map_reading.dart';
import '../services/oracle_reading_context_text.dart';
import 'oracle_reading_context.dart';
import 'oracle_reading_context_natal.dart';

export 'oracle_reading_context_natal.dart';

extension OracleReadingContextSources on OracleReadingContext {
  static OracleReadingContext coffee(CoffeeReading reading) {
    final symbols = reading.symbols.map((s) => s.name).take(6).toList();
    String clip(String raw, [int max = 220]) =>
        OracleReadingContextText.shortSummary(raw, maxLen: max);
    final full = [
      if (reading.visualObservation.trim().isNotEmpty)
        'Görülen: ${clip(reading.visualObservation, 160)}',
      if (reading.overall.trim().isNotEmpty) 'Genel: ${clip(reading.overall, 280)}',
      if (symbols.isNotEmpty) 'İzler: ${symbols.join(', ')}',
      if (reading.love.trim().isNotEmpty) 'Aşk: ${clip(reading.love, 140)}',
      if (reading.career.trim().isNotEmpty)
        'Kariyer: ${clip(reading.career, 140)}',
      if (reading.money.trim().isNotEmpty) 'Para: ${clip(reading.money, 140)}',
      if (reading.nearFuture.trim().isNotEmpty)
        'Yön: ${clip(reading.nearFuture, 140)}',
      if (reading.takeaway.trim().isNotEmpty) 'Dikkat: ${clip(reading.takeaway, 160)}',
    ].where((e) => e.trim().isNotEmpty).join('\n\n');
    return OracleReadingContext(
      sessionId: reading.id,
      kind: OracleReadingKind.coffee,
      sourceLabel: 'Kahve Falı',
      spreadLabel: 'Fincan',
      deckId: 'coffee',
      deckName: 'Kahve Falı',
      readingTitle: 'Fincan yorumu',
      cardsSummary:
          symbols.isEmpty ? clip(reading.overall, 120) : symbols.join(', '),
      interpretationSummary: clip(reading.overall),
      fullInterpretation: full,
      cardNames: symbols,
    );
  }

  static OracleReadingContext palm(PalmReading reading) {
    final symbols = reading.symbols.take(6).toList();
    String clip(String raw, [int max = 220]) =>
        OracleReadingContextText.shortSummary(raw, maxLen: max);
    final full = [
      'El: ${reading.hand.label}',
      if (reading.overall.trim().isNotEmpty) 'Genel: ${clip(reading.overall, 280)}',
      if (reading.heartLine.trim().isNotEmpty) 'Kalp: ${clip(reading.heartLine, 120)}',
      if (reading.headLine.trim().isNotEmpty) 'Zihin: ${clip(reading.headLine, 120)}',
      if (reading.lifeLine.trim().isNotEmpty) 'Yaşam: ${clip(reading.lifeLine, 120)}',
      if (reading.fateLine.trim().isNotEmpty) 'Yön: ${clip(reading.fateLine, 120)}',
      if (symbols.isNotEmpty) 'İzler: ${symbols.join(', ')}',
      if (reading.themes.isNotEmpty)
        'Temalar: ${reading.themes.take(4).join(', ')}',
      if (reading.takeaway.trim().isNotEmpty)
        'En önemli işaret: ${clip(reading.takeaway, 160)}',
    ].where((e) => e.trim().isNotEmpty).join('\n\n');
    return OracleReadingContext(
      sessionId: reading.id,
      kind: OracleReadingKind.palm,
      sourceLabel: 'El Falı',
      spreadLabel: reading.hand.label,
      deckId: 'palm',
      deckName: 'El Falı',
      readingTitle: 'El yorumu',
      cardsSummary:
          symbols.isEmpty ? clip(reading.overall, 120) : symbols.join(', '),
      interpretationSummary: clip(reading.overall),
      fullInterpretation: full,
      cardNames: symbols,
    );
  }

  static OracleReadingContext dailyMessage({
    required String text,
    required String dayKey,
    String? theme,
    String? sunSign,
  }) {
    final themeLine = (theme ?? '').trim();
    final full = [
      if (themeLine.isNotEmpty) 'Tema: $themeLine',
      if ((sunSign ?? '').trim().isNotEmpty) 'Güneş: ${sunSign!.trim()}',
      'Mesaj: $text',
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: 'daily_$dayKey',
      kind: OracleReadingKind.dailyMessage,
      sourceLabel: 'Günün Mesajı',
      spreadLabel: themeLine.isEmpty ? 'Günün mesajı' : themeLine,
      deckId: 'daily-message',
      deckName: 'Günün Mesajı',
      readingTitle: themeLine.isEmpty ? 'Günün mesajı' : themeLine,
      cardsSummary: themeLine.isEmpty ? text : themeLine,
      interpretationSummary: OracleReadingContextText.shortSummary(text),
      fullInterpretation: full,
    );
  }

  static OracleReadingContext discoveryJournal({
    required String id,
    required String title,
    String preview = '',
    List<String> themes = const [],
    String kindLabel = 'Keşif',
  }) {
    String clip(String raw, [int max = 220]) {
      final t = raw.trim();
      if (t.length <= max) return t;
      return '${t.substring(0, max).trimRight()}…';
    }

    final summary = clip(preview.trim().isEmpty ? title : preview, 180);
    final themeLine = themes.isEmpty
        ? ''
        : 'Temalar: ${themes.take(4).join(', ')}';
    final full = [
      'Kaynak: Keşif Günlüğü · $kindLabel',
      'Keşif: ${clip(title, 120)}',
      if (summary.isNotEmpty) summary,
      if (themeLine.isNotEmpty) themeLine,
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: id,
      kind: OracleReadingKind.discoveryJournal,
      sourceLabel: 'Keşif Günlüğü · $kindLabel',
      spreadLabel: kindLabel,
      deckId: 'discovery-journal',
      deckName: 'Keşif Günlüğü',
      readingTitle: title,
      cardsSummary: themes.isEmpty ? title : themes.take(3).join(', '),
      interpretationSummary: summary,
      fullInterpretation: full,
      cardNames: themes.take(4).toList(),
    );
  }

  static OracleReadingContext dream({
    required String id,
    required String narrative,
    required String analysis,
    List<String> symbols = const [],
    String? emotionalTheme,
    String? fullInterpretation,
  }) {
    final full = [
      'Rüya: $narrative',
      if (symbols.isNotEmpty) 'Semboller: ${symbols.join(', ')}',
      if ((emotionalTheme ?? '').trim().isNotEmpty)
        'Duygusal tema: $emotionalTheme',
      'Yorum: $analysis',
      if ((fullInterpretation ?? '').trim().isNotEmpty) fullInterpretation!,
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: id,
      kind: OracleReadingKind.dream,
      sourceLabel: 'Rüya',
      spreadLabel: 'Rüya',
      deckId: 'dream',
      deckName: 'Rüya',
      readingTitle: 'Rüya yorumu',
      cardsSummary: narrative,
      interpretationSummary: analysis,
      fullInterpretation: full,
      cardNames: symbols,
    );
  }

  static OracleReadingContext astrology({
    required String id,
    required String signLabel,
    required String daily,
    String readingType = 'Günlük',
    String? personality,
    String? love,
    String? career,
    String? money,
    String? energy,
    String? emotion,
    String? advice,
    String? opportunity,
    String? caution,
  }) =>
      OracleReadingContextNatal.astrology(
        id: id,
        signLabel: signLabel,
        daily: daily,
        readingType: readingType,
        personality: personality,
        love: love,
        career: career,
        money: money,
        energy: energy,
        emotion: emotion,
        advice: advice,
        opportunity: opportunity,
        caution: caution,
      );

  static OracleReadingContext starMap({
    required String sectionLabel,
    required StarMapReading reading,
    BirthProfile? profile,
    List<String> sectionLines = const [],
  }) =>
      OracleReadingContextNatal.starMap(
        sectionLabel: sectionLabel,
        reading: reading,
        profile: profile,
        sectionLines: sectionLines,
      );

  static OracleReadingContext birthChart({
    required String id,
    required String sunLabel,
    required String interpretation,
    BirthProfile? profile,
    String? summary,
    String? strongThemes,
    String? notableThemes,
    List<String> placements = const [],
  }) =>
      OracleReadingContextNatal.birthChart(
        id: id,
        sunLabel: sunLabel,
        interpretation: interpretation,
        profile: profile,
        summary: summary,
        strongThemes: strongThemes,
        notableThemes: notableThemes,
        placements: placements,
      );

  /// Soul Mate portrait — compact symbolic concept for OR (never raw image/prompt).
  static OracleReadingContext soulMate({
    required String id,
    required String interpretation,
    String? name,
  }) {
    final who = (name ?? '').trim();
    String clip(String raw, [int max = 280]) {
      final t = raw.trim();
      if (t.length <= max) return t;
      return '${t.substring(0, max).trimRight()}…';
    }

    final summary = clip(interpretation, 200);
    final full = [
      'Kaynak: sembolik Ruh Eşi portresi — yaratıcı yansıma, kesin kimlik değil',
      if (who.isNotEmpty) 'İsim ilhamı: $who',
      summary,
    ].join('\n\n');
    return OracleReadingContext(
      sessionId: id,
      kind: OracleReadingKind.soulMate,
      sourceLabel: 'Ruh Eşi',
      spreadLabel: 'Sembolik portre',
      deckId: 'soulmate',
      deckName: 'Ruh Eşi',
      readingTitle: who.isEmpty ? 'Sembolik portre' : who,
      cardsSummary: who.isEmpty ? 'Sembolik portre' : who,
      interpretationSummary: summary,
      fullInterpretation: full,
    );
  }
}