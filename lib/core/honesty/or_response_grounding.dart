/// OR response grounding — conversation/context only; never invent as fact.
library;

import '../l10n/l10n.dart';

/// Prompt rules + detection for ungrounded OR claims.
abstract final class OrResponseGrounding {
  OrResponseGrounding._();

  static String get promptRule => switch (OraclyL10n.code) {
        'en' => promptEn,
        'ru' => promptRu,
        _ => promptTr,
      };

  /// Always injected into live chat system prompt.
  static const promptTr =
      'Yanıtı yalnızca bu sohbet ve verilen bağlamdaki gerçek izlere dayandır. '
      'Kullanıcı geçmişi, anı, keşif veya ürün yeteneği uydurma; uydurmayı olgu gibi sunma. '
      'Yansıtıcı hayal gücü olabilir — ama olasılık veya metafor olarak, kesin bilgi olarak değil.';

  static const promptEn =
      'Ground every answer in this conversation and the provided context only. '
      'Invent no user history, memories, discoveries, or product capabilities; '
      'never present invention as fact. '
      'Reflective imagination is welcome — as possibility or metaphor, never as asserted fact.';

  static const promptRu =
      'Опирай ответ только на этот разговор и данный контекст. '
      'Не выдумывай историю пользователя, память, открытия или возможности продукта; '
      'не подавай вымысел как факт. '
      'Образное размышление уместно — как возможность или метафора, не как утверждение.';

  /// Compact reminder for styleHint (every turn).
  static String get styleHintRule => switch (OraclyL10n.code) {
        'en' =>
          'Ground in this thread and tagged context only. '
              'Invent no history, memory, discovery, or product ability as fact.',
        'ru' =>
          'Только эта нить и помеченный контекст. '
              'Не выдумывай историю, память, открытие или способность продукта как факт.',
        _ =>
          'Yalnızca bu sohbet ve etiketli bağlam. '
              'Geçmiş, anı, keşif veya ürün yeteneğini olgu gibi uydurma.',
      };

  /// True when styleHint carries tagged long-term / handoff evidence.
  static bool hasContextEvidence(String? styleHint) {
    final h = (styleHint ?? '').toUpperCase();
    if (h.isEmpty) return false;
    return h.contains('FACT:') ||
        h.contains('OBSERVATION:') ||
        h.contains('INTERPRETATION:');
  }

  /// Specific life events not present in evidence — always reject.
  static bool claimsInventedBiography(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'geçen hafta annen',
      'geçen hafta baban',
      'last week your mother',
      'last week your father',
      'your sister told me',
      'kızın söylemişti',
      'eşin söylemişti',
    ];
    return markers.any(lower.contains);
  }

  /// Soft memory recall without evidence.
  static bool claimsUngroundedMemory(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'daha önce söylemiştin',
      'hatırlıyorum ki sen',
      'geçen sefer dediğin',
      'hatırladığım kadarıyla sen',
      'you told me before',
      'i remember you said',
      'as you mentioned last time',
      'biz geçen konuşmamızda',
    ];
    return markers.any(lower.contains);
  }

  static bool claimsInventedDiscovery(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'keşfinde görmüştüm',
      'falında demiştik',
      'kartında söylemiştik',
      'avucunda görmüştüm',
      'your reading showed',
      'your palm showed us',
      'in your coffee we saw',
    ];
    return markers.any(lower.contains);
  }

  /// Hallucinated product powers — always reject.
  static bool claimsInventedCapability(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'takvimine baktım',
      'takvimini okudum',
      'i checked your calendar',
      'rehberine eriştim',
      'accessed your contacts',
      'bildirimlerini gördüm',
      'i read your notifications',
      'ücretsiz premium açtım',
      'i unlocked premium for you',
      'mesajlarına cihazından baktım',
    ];
    return markers.any(lower.contains);
  }
}

