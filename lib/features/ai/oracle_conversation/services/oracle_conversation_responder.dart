/// OR-1190 / RC-002 — Context-aware oracle responses (reflective companion).
library;

import '../../../../core/copy/conversation_copy.dart';
import '../../services/conversation_response_guard.dart';
import '../models/oracle_reading_context.dart';

abstract final class OracleConversationSuggestions {
  OracleConversationSuggestions._();

  static const chips = ConversationCopy.oracleSuggestions;
}

class OracleConversationResponder {
  const OracleConversationResponder();

  Future<String> respond({
    required OracleReadingContext context,
    required String userMessage,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
    return ConversationResponseGuard.polish(
      _buildResponse(context, userMessage),
    );
  }

  Stream<String> respondStream({
    required OracleReadingContext context,
    required String userMessage,
  }) async* {
    final full = await respond(context: context, userMessage: userMessage);
    final tokens = full.split(RegExp(r'(?<=\s)'));
    for (final token in tokens) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      yield token;
    }
  }

  String _buildResponse(OracleReadingContext context, String question) {
    final q = question.toLowerCase();
    final primary = context.cardNames.isNotEmpty
        ? context.cardNames.first
        : context.readingTitle;
    final spread = context.spreadLabel;

    if (_matches(q, ['aşk', 'ilişki', 'sevgi', 'partner'])) {
      return _reflectiveBlock(
        title: 'Kalp alanı',
        observation:
            '**$spread** açılımında **$primary** duygusal bağda nazik bir '
            'açıklık ihtiyacına işaret ediyor olabilir.\n\n'
            'İlişkideysen, kendi ihtiyaçlarını duymak önemli; '
            'yalnızsan, kendine karşı şefkat yeni bir frekans açabilir.',
        question: 'Kalbinde en çok hangi duygu oturuyor — ona bir cümle ayırır mısın?',
        nudge: 'Bugün küçük bir içtenlik hareketi — bir mesaj, bir nefes, bir sınır — yeterli olabilir.',
      );
    }

    if (_matches(q, ['kariyer', 'iş', 'meslek', 'para'])) {
      return _reflectiveBlock(
        title: 'Yön ve odak',
        observation:
            '**$primary** kariyer alanında netlik ve sabırlı ilerleme '
            'temasını taşıyor olabilir.\n\n'
            'Aceleci kararlar yerine, önceliklerini sadeleştirmek '
            'zihnini toparlayabilir.',
        question: 'Şu an en çok hangi adım seni geriyor — onu tek kelimeyle adlandırır mısın?',
        nudge: 'Önceliklerini üç maddeye indir; en hafif olanı bugün seç.',
      );
    }

    if (_matches(q, ['uyarı', 'dikkat', 'tehlike', 'sakın'])) {
      return _reflectiveBlock(
        title: 'Dikkat edilebilecek alan',
        observation:
            'Bu açılım, **aşırı kontrol veya sabırsızlık** eğilimine '
            'nazikçe bakmanı önerebilir.\n\n'
            'Sonucu zorlamak yerine, nefes almak kararlarını netleştirebilir.',
        question: 'Son günlerde acele ettiğin bir an var mı — o an sana ne hissettirdi?',
        nudge: 'Bir gece uyku, sonra net bir niyetle küçük bir adım yeterli olabilir.',
      );
    }

    if (_matches(q, ['zaman', 'ne zaman', 'tarih', 'süre'])) {
      return _reflectiveBlock(
        title: 'Zaman ve hazırlık',
        observation:
            'Kartlar kesin bir tarih vermez; **zamanlama hazırlığınla** '
            'hizalanır.\n\n'
            'Şu anki enerji, sabırlı bir bekleyiş ve içsel netlik '
            'dönemine işaret ediyor olabilir.',
        question: 'Hazır hissettiğinde nasıl bir adım atmak isterdin?',
        nudge: 'Kendi ritmine güven — acele etmek zorunda değilsin.',
      );
    }

    if (_matches(q, ['mesaj', 'anlam', 'ne demek', 'açıkla', 'hissettiriyor'])) {
      return _reflectiveBlock(
        title: 'Kart mesajı',
        observation:
            '**$primary** senin için şunu fısıldıyor olabilir:\n\n'
            '${context.interpretationSummary}\n\n'
            'Bütününde mesaj, **iç sesine alan açmak** ve dış gürültüyü '
            'azaltmak olabilir.',
        question: 'Bu mesajın hangi kısmı sana en çok dokundu?',
        nudge: '${ConversationCopy.closingWhisper.split('.').first.trim()}.',
      );
    }

    if (_matches(q, ['adım', 'sonraki', 'ne yapmalı', 'yol', 'taşıyabilirim'])) {
      return _reflectiveBlock(
        title: 'Küçük bir adım',
        observation:
            '**$spread** açılımın, küçük ama tutarlı bir eylemin '
            'anlam yaratabileceğini hatırlatıyor olabilir.\n\n'
            'Büyük kararlar yerine, bugün yapılabilecek tek bir şey '
            'yeterli olabilir.',
        question: 'Bugün atabileceğin en küçük adım ne olurdu?',
        nudge: 'Niyetini yaz — görünür kılmak bazen yeterli bir başlangıçtır.',
      );
    }

    if (_matches(q, ['dikkatimi çekti', 'netleşmek', 'geri çekilsem'])) {
      return _reflectiveBlock(
        title: 'Kendi bakışın',
        observation:
            'Sorun, kartların ışığında kendi iç sesine alan açıyor.\n\n'
            '**$primary** enerjisi, dış cevaplar yerine kendi farkındalığına '
            'güvenmeyi nazikçe hatırlatıyor olabilir.',
        question: 'Şu an duyduğun en net iç cümle ne?',
        nudge: 'Cevabı zaten yakınında olabilir — acele etme.',
      );
    }

    return _reflectiveBlock(
      title: 'Birlikte bakış',
      observation:
          '**$spread** açılımın ışığında sorunu duydum.\n\n'
          'Kartların özeti:\n${context.cardsSummary}\n\n'
          'Genel rehberlik: ${context.interpretationSummary}',
      question: 'Bu açılımda seni en çok hangi kelime veya görüntü yakaladı?',
      nudge: 'Kalbin cevabı zaten yakınında olabilir — bir an durup dinlemek yeterli olabilir.',
    );
  }

  bool _matches(String q, List<String> keys) =>
      keys.any((k) => q.contains(k));

  String _reflectiveBlock({
    required String title,
    required String observation,
    required String question,
    required String nudge,
  }) {
    return '## $title\n\n'
        '$observation\n\n'
        '**Düşünmek için:** $question\n\n'
        '**Yumuşak bir nudge:** $nudge\n\n'
        '**Sakin kapanış:** ${ConversationCopy.closingWhisper.split('.').first.trim()}.';
  }
}
