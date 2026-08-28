/// Maps a companion message to an insight request kind.
library;

import '../models/conversation.dart';
import '../models/insight_request.dart';

abstract final class CompanionInsightClassify {
  CompanionInsightClassify._();

  static InsightRequest fromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('rüya')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.dream,
        conversationTopic: ConversationTopic.dream,
      );
    }
    if (lower.contains('kart') ||
        lower.contains('tarot') ||
        lower.contains('açılım')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.tarot,
        conversationTopic: ConversationTopic.tarot,
      );
    }
    if (lower.contains('harita') ||
        lower.contains('burç') ||
        lower.contains('yükselen') ||
        lower.contains('astroloji') ||
        lower.contains('yıldızname') ||
        lower.contains('gezegen')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.birthChart,
        conversationTopic: ConversationTopic.birthChart,
      );
    }
    if (lower.contains('kahve') ||
        lower.contains('fincan') ||
        lower.contains('coffee')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.openReflection,
        conversationTopic: ConversationTopic.reflection,
      );
    }
    if (lower.contains('aşk') || lower.contains('ilişki')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.emotionalPattern,
        conversationTopic: ConversationTopic.reflection,
      );
    }
    if (lower.contains('enerji') || lower.contains('energy')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.emotionalPattern,
        conversationTopic: ConversationTopic.reflection,
      );
    }
    if (lower.contains('hedef')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.goals,
        conversationTopic: ConversationTopic.goals,
      );
    }
    if (lower.contains('günlük') || lower.contains('yazdım')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.journal,
        conversationTopic: ConversationTopic.journal,
      );
    }
    if (lower.contains('ritüel')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.ritual,
        conversationTopic: ConversationTopic.ritual,
      );
    }
    if (lower.contains('duygu') || lower.contains('hissed')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.emotionalPattern,
        conversationTopic: ConversationTopic.reflection,
      );
    }
    return InsightRequest(text: text);
  }
}
