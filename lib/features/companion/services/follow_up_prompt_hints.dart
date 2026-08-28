/// Follow-up prompt hints — ask rare, never mechanical.
library;

import 'follow_up_decision.dart';

abstract final class FollowUpPromptHints {
  FollowUpPromptHints._();

  static String forDecision(FollowUpDecision d) => switch (d.mode) {
        FollowUpMode.answerOnly =>
          'Bu turda soru ile bitirme. Doğal kapat. '
              '"İstersen...", "Ne düşünüyorsun?", "Nasıl hissediyorsun?" '
              'kalıplarını mekanik kullanma. Hazır empati cümlesi yok.',
        FollowUpMode.reflect =>
          'Önce kullanıcının bu sohbette söylediğine bağlanıp kısa gözlem yaz; '
              'verilmiş bilgiyi yeniden sorma; önceki mesajı olduğu gibi tekrarlama. '
              'Soru ile bitirme. Terapist gibi derinlemesine sorma. Hazır empati yok: "Seni anlıyorum", "Buradayım". '
              '"İstersen / Ne düşünüyorsun / Nasıl hissediyorsun" tekrarı yok.',
        FollowUpMode.ask => _ask(d.localKind),
      };

  static String _ask(FollowUpLocalKind kind) => switch (kind) {
        FollowUpLocalKind.jobTimeline =>
          'Tek netleştirici soru: ne zamandır düşünüyor. Genel probe yok.',
        FollowUpLocalKind.fearClarify =>
          'Tek netleştirici soru: değişim korkusu mu, yanlış karar korkusu mu. '
              'Mekanik "nasıl hissediyorsun" yok.',
        FollowUpLocalKind.undecidedScope =>
          'Tek netleştirici soru: konu iş mi, genel mi.',
        FollowUpLocalKind.moodOpen =>
          'Tek netleştirici soru: neye takıldı — somut. Genel his sorusu yok.',
        FollowUpLocalKind.explore =>
          'Kullanıcı keşfe açık. En fazla bir somut soru; '
              '"istersen anlat" kalıbı yok.',
        _ =>
          'Yalnızca eksik bağlam gerçekten önemliyse bir netleştirici soru. '
              'Her yanıta soru ekleme. Mekanik probe yok.',
      };
}
