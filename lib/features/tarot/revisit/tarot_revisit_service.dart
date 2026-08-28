/// Resolves a calm revisit offer from saved readings only.
library;

import '../../../core/domain/models/reading.dart';
import '../copy/tarot_revisit_copy.dart';
import '../history/tarot_history_privacy.dart';
import '../reading/reading_ask.dart';
import 'tarot_revisit_context.dart';

abstract final class TarotRevisitService {
  TarotRevisitService._();

  static TarotRevisitContext? fromHistory(
    List<ReadingModel> readings, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    for (final reading in readings) {
      if (reading.aiSummary.trim().isEmpty) continue;
      if (!_isOlder(reading.createdAt, clock)) continue;
      final context = _contextFrom(reading);
      if (context != null) return context;
    }
    return null;
  }

  /// OR chat — prior reading on the same topic, never same-day surveillance.
  static TarotRevisitContext? forConversation({
    required String? conversationTopic,
    required List<ReadingModel> readings,
    DateTime? now,
  }) {
    final topic = conversationTopic?.trim();
    if (topic == null ||
        topic.isEmpty ||
        _isVagueTopic(topic)) {
      return null;
    }
    final clock = now ?? DateTime.now();
    for (final reading in readings) {
      if (reading.aiSummary.trim().isEmpty) continue;
      if (!_isOlder(reading.createdAt, clock)) continue;
      if (!_topicMatches(topic, reading)) continue;
      return _contextFrom(reading);
    }
    return null;
  }

  static TarotRevisitContext? _contextFrom(ReadingModel reading) {
    final topic = _topicLabel(reading);
    final spread = TarotHistoryPrivacy.spreadTitle(reading.spreadType);
    final question = TarotHistoryPrivacy.questionSummary(reading.intention);
    if (topic == null && question == null) return null;
    return TarotRevisitContext(
      reading: reading,
      topicLabel: topic,
      spreadLabel: spread,
      questionHint: question,
    );
  }

  static String priorExcerpt(ReadingModel reading) =>
      TarotHistoryPrivacy.shortInsight(reading);

  static bool _topicMatches(String conversationTopic, ReadingModel reading) {
    final readingKey = _topicKey(reading);
    if (readingKey == null) return false;
    return switch (conversationTopic) {
      'iş' => readingKey == _TopicKey.career ||
          readingKey == _TopicKey.decision,
      'ilişki' => readingKey == _TopicKey.love,
      _ => false,
    };
  }

  static bool _isOlder(DateTime at, DateTime now) =>
      at.year != now.year || at.month != now.month || at.day != now.day;

  static _TopicKey? _topicKey(ReadingModel reading) {
    final stored = TarotHistoryPrivacy.persistTopic(
      reading.readingType,
      reading.intention,
    )?.toLowerCase();
    if (stored != null) {
      return switch (stored) {
        'career' || 'kariyer' => _TopicKey.career,
        'love' || 'aşk' => _TopicKey.love,
        'daily' => _TopicKey.daily,
        'general' || 'genel' => _TopicKey.general,
        _ => null,
      };
    }
    final q = (reading.intention ?? '').toLowerCase();
    if (_has(q, const ['kariyer', 'iş', 'career', 'job', 'work'])) {
      return _TopicKey.career;
    }
    if (_has(q, const ['aşk', 'ilişki', 'love', 'relationship'])) {
      return _TopicKey.love;
    }
    return switch (ReadingAsk.kind(reading.intention)) {
      ReadingAskKind.decision => _TopicKey.decision,
      ReadingAskKind.relationship => _TopicKey.love,
      ReadingAskKind.guidance => _TopicKey.guidance,
      ReadingAskKind.other => null,
    };
  }

  static String? _topicLabel(ReadingModel reading) {
    final stored = TarotHistoryPrivacy.persistTopic(
      reading.readingType,
      reading.intention,
    )?.toLowerCase();
    if (stored != null) {
      return switch (stored) {
        'career' || 'kariyer' => TarotRevisitCopy.topicCareer,
        'love' || 'aşk' => TarotRevisitCopy.topicLove,
        'daily' => TarotRevisitCopy.topicDaily,
        'general' || 'genel' => TarotRevisitCopy.topicGeneral,
        _ => _titleCase(stored),
      };
    }
    final q = (reading.intention ?? '').toLowerCase();
    if (_has(q, const ['kariyer', 'iş', 'career', 'job', 'work'])) {
      return TarotRevisitCopy.topicCareer;
    }
    if (_has(q, const ['aşk', 'ilişki', 'love', 'relationship'])) {
      return TarotRevisitCopy.topicLove;
    }
    return switch (ReadingAsk.kind(reading.intention)) {
      ReadingAskKind.decision => TarotRevisitCopy.topicDecision,
      ReadingAskKind.relationship => TarotRevisitCopy.topicLove,
      ReadingAskKind.guidance => TarotRevisitCopy.topicGuidance,
      ReadingAskKind.other => null,
    };
  }

  static bool _isVagueTopic(String topic) =>
      topic == 'kararsızlık' || topic == 'sıkıntı';

  static bool _has(String hay, List<String> needles) =>
      needles.any(hay.contains);

  static String _titleCase(String raw) {
    if (raw.isEmpty) return raw;
    final first = raw.substring(0, 1);
    return '${first.toUpperCase()}${raw.substring(1)}';
  }
}

enum _TopicKey { career, love, decision, guidance, daily, general }
