/// Helpers for OR context bucket picking — keep engine slim.
library;

import '../data/companion_intent.dart';
import '../models/memory.dart';
import 'or_long_term_memory_boundaries.dart';

abstract final class OrContextBucketHelpers {
  OrContextBucketHelpers._();

  static const memoryCap = 120;
  static const featureCap = 360;
  static const preferenceCap = 220;

  static bool looksFeature(String body) {
    if (body.contains('\n')) return true;
    const markers = [
      'Tarot',
      'Kahve',
      'El',
      'Astroloji',
      'Yildizname',
      'Yıldızname',
      'Ruya',
      'Rüya',
      'Soru:',
      'Günlük',
      'Gunluk',
      'Keşif',
      'Kesif',
      'İzler:',
      'Tema:',
    ];
    return markers.any(body.contains);
  }

  static String? relevantSaved(List<Memory> memories, String current) {
    if (memories.isEmpty) return null;
    final msg = current.toLowerCase();
    final wantsRecall =
        msg.contains('hatırl') ||
        msg.contains('hatirl') ||
        msg.contains('remember') ||
        msg.contains('daha önce') ||
        msg.contains('daha once') ||
        msg.contains('demiştim') ||
        msg.contains('söylemiştim');
    if (!wantsRecall && current.length < 16) return null;
    Memory? best;
    var bestScore = 0;
    for (final m in memories) {
      final content = m.content.trim();
      if (content.length < 12) continue;
      final score = tokenScore(msg, content.toLowerCase());
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    // Always require genuine overlap — never invent or dump the first note.
    if (best == null || bestScore < 1) return null;
    if (!wantsRecall && bestScore < 2 && !_hasLongHit(msg, best.content)) {
      return null;
    }
    return cap(best.content, memoryCap);
  }

  static bool _hasLongHit(String msg, String note) {
    for (final w in note.toLowerCase().split(RegExp(r'[^a-züğışöçâîû0-9]+'))) {
      if (w.length >= 6 && msg.contains(w)) return true;
    }
    return false;
  }

  static int tokenScore(String msg, String note) {
    var score = 0;
    for (final w
        in note
            .split(RegExp(r'[^a-züğışöçâîû0-9]+'))
            .where((w) => w.length >= 4)
            .take(10)) {
      if (msg.contains(w)) score += w.length >= 6 ? 2 : 1;
    }
    return score;
  }

  static bool sharesToken(String msg, String note) {
    final words = note
        .split(RegExp(r'[^a-züğışöçâîû0-9]+'))
        .where((w) => w.length >= 4)
        .take(8);
    var hits = 0;
    for (final w in words) {
      if (!msg.contains(w)) continue;
      hits++;
      if (w.length >= 6 || hits >= 2) return true;
    }
    return false;
  }

  static String cap(String text, int max) {
    final t = text.trim();
    if (t.length <= max) return t;
    final cut = t.substring(0, max);
    final space = cut.lastIndexOf(' ');
    return '${space > max ~/ 2 ? cut.substring(0, space) : cut}…';
  }

  static String? stableNameFact(String? userName, String current) {
    final name = userName?.trim();
    if (name == null || name.isEmpty) return null;
    if (!CompanionIntent.isGreeting(current)) return null;
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.fact,
      'Kullanıcının adı: $name.',
    );
  }

  static String? preferenceWhenAsked(String current) {
    final msg = current.toLowerCase();
    final asks =
        msg.contains('nasıl konuş') ||
        msg.contains('üslub') ||
        msg.contains('tonun') ||
        msg.contains('how you speak') ||
        msg.contains('your tone');
    if (!asks) return null;
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.preference,
      'Üslup tercihine saygı göster; emretme.',
    );
  }
}
