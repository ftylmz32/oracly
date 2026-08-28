/// Short thread-continuing cues — never restart the conversation.
library;

abstract final class CompanionShortFollowUp {
  CompanionShortFollowUp._();

  static bool matches(String text) {
    final bare = _bare(text);
    if (bare.isEmpty || bare.length > 56) return false;
    const exact = {
      'peki', 'neden', 'niye', 'devam', 'nasıl', 'nasil', 'evet', 'hayır',
      'hayir', 'tamam', 'ok', 'okay', 'why', 'so', 'and', 'continue', 'go on',
      'sonra', 'yani', 'şimdi', 'simdi', 'потом', 'почему', 'дальше',
    };
    if (exact.contains(bare)) return true;
    final t = text.trim().toLowerCase();
    if (RegExp(r'emin misin|are you sure|точно ли').hasMatch(t)) return true;
    if (RegExp(r'yani diyorsun|yani diyor|so you.?re saying|то есть ты').hasMatch(t)) {
      return true;
    }
    if (RegExp(r'bunu nasıl|nasıl yap|how (do|can) i|как (мне )?сдела').hasMatch(t) &&
        t.length <= 72) {
      return true;
    }
    if (RegExp(r'sen olsan|what would you|if you were|а ты бы').hasMatch(t) &&
        t.length <= 80) {
      return true;
    }
    if (RegExp(r'^(peki|ama|yani|şimdi|simdi|sonra|well|but|so|а|и)\b').hasMatch(t) &&
        t.length <= 56) {
      return true;
    }
    if (RegExp(r'^(neden|niye|why|почему)\b').hasMatch(t) && t.length <= 40) {
      return true;
    }
    return false;
  }

  static String _bare(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[.!?…,]+$'), '')
      .trim();
}
