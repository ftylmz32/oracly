/// Job-change intent cues for OR continuity.
library;

abstract final class CompanionJobChange {
  CompanionJobChange._();

  static bool matches(String text) {
    final t = text.toLowerCase();
    return t.contains('iş değiştir') ||
        t.contains('işimi değiştir') ||
        t.contains('işimi bırak') ||
        t.contains('iş bırak') ||
        t.contains('istifa') ||
        t.contains('ayrılmayı') ||
        t.contains('ayrilmayi') ||
        RegExp(r'iş.{0,12}değiş').hasMatch(t) ||
        RegExp(r'iş.{0,16}bırak').hasMatch(t) ||
        RegExp(r'iş.{0,20}ayr').hasMatch(t) ||
        t.contains('job change') ||
        t.contains('change jobs') ||
        t.contains('quit my job') ||
        t.contains('leave my job') ||
        (t.contains('смен') && t.contains('работ'));
  }
}
