/// SPRINT-003 — Listen → reflect → suggest response engine.
library;

import '../../../features/ai/services/conversation_response_guard.dart';
import '../models/insight_request.dart';
import '../models/reflection_context.dart';

class CompanionResponse {
  const CompanionResponse({
    required this.body,
    this.suggestions = const [],
  });

  final String body;
  final List<String> suggestions;
}

class CompanionResponder {
  const CompanionResponder();

  CompanionResponse respond({
    required InsightRequest request,
    required ReflectionContext context,
  }) {
    final text = request.text.trim();
    final listen = _listen(text);
    final reflect = _reflect(text, request, context);
    final suggest = _suggest(text, request, context);

    final body = ConversationResponseGuard.polish(
      '$listen\n\n$reflect\n\n$suggest',
    );

    return CompanionResponse(
      body: body,
      suggestions: _followUpSuggestions(request),
    );
  }

  String _listen(String text) {
    if (text.length < 20) {
      return 'Söylediğin kısa ama yoğun — dinliyorum.';
    }
    final excerpt = text.length > 80 ? '${text.substring(0, 80)}…' : text;
    return 'Paylaştığın şeyi duydum: "$excerpt"';
  }

  String _reflect(
    String text,
    InsightRequest request,
    ReflectionContext context,
  ) {
    final lower = text.toLowerCase();

    if (context.savedMemories.isNotEmpty) {
      final memory = context.savedMemories.first;
      if (lower.contains('hatırl') || lower.contains('daha önce')) {
        return 'Kaydettiğin bir not var: "${memory.content}". '
            'Bu, bugünkü düşüncenle nasıl bağ kuruyor olabilir?';
      }
    }

    return switch (request.kind) {
      InsightRequestKind.dream ||
      InsightRequestKind.tarot ||
      InsightRequestKind.birthChart =>
        'Bu deneyim sana kişisel bir dil kullanıyor. '
            'Hazır anlamlara sığdırmak yerine, sana en çok hangi kısım dokundu?',
      InsightRequestKind.goals =>
        'Hedefler bazen net, bazen sisli olur. '
            'Şu an net olan ve belirsiz olan arasındaki çizgi nerede?',
      InsightRequestKind.emotionalPattern =>
        'Duygusal kalıplar genellikle fark edilmeden tekrar eder. '
            'Bedeninde bu konuşma nerede yankı buluyor?',
      _ =>
        'Bu düşünce bir yön gösteriyor olabilir — '
            'henüz bir cevap aramadan, ne hissettiğine bir an bakmak faydalı olabilir.',
    };
  }

  String _suggest(
    String text,
    InsightRequest request,
    ReflectionContext context,
  ) {
    if (context.recurringThemes.isNotEmpty) {
      return 'İstersen ${context.recurringThemes.first.toLowerCase()} '
          'temasına da birlikte bakabiliriz — zorunluluk yok, sadece bir davet.';
    }
    return 'İstersen bir adım geri çekilip "Bana en çok ne soruyor?" '
        'diye sorabilirsin. Cevabı aceleyle aramaya gerek yok.';
  }

  List<String> _followUpSuggestions(InsightRequest request) {
    return switch (request.kind) {
      InsightRequestKind.dream => [
        'Rüyada en çok hangi an kaldı?',
        'Bu rüya gün içinde neyi hatırlattı?',
      ],
      InsightRequestKind.tarot => [
        'Açılımda en çok hangi kart durdu?',
        'Bu mesajı bir cümleyle nasıl özetlerdin?',
      ],
      InsightRequestKind.birthChart => [
        'Haritanda en tanıdık gelen kısım hangisi?',
        'Bugün hangi yönün daha baskın?',
      ],
      _ => [
        'Biraz daha açmak ister misin?',
        'Bedeninde bunu nerede hissediyorsun?',
      ],
    };
  }
}
