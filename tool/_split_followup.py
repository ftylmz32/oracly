from pathlib import Path
import re

def w(path, text):
    Path(path).write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")
    print(path, len(text.splitlines()))

w(
    "lib/features/companion/data/companion_short_followup.dart",
    '''/// Short thread-continuing cues — never restart the conversation.
library;

abstract final class CompanionShortFollowUp {
  CompanionShortFollowUp._();

  static bool matches(String text) {
    final bare = _bare(text);
    if (bare.isEmpty || bare.length > 48) return false;
    const exact = {
      'peki', 'neden', 'niye', 'devam', 'nasıl', 'nasil', 'evet', 'hayır',
      'hayir', 'tamam', 'ok', 'okay', 'why', 'so', 'and', 'continue', 'go on',
      'потом', 'почему', 'дальше',
    };
    if (exact.contains(bare)) return true;
    final t = text.trim().toLowerCase();
    if (RegExp(r'emin misin|are you sure|точно ли').hasMatch(t)) return true;
    if (RegExp(r'^(peki|ama|yani|şimdi|simdi|well|but|so|а|и)\\b').hasMatch(t) &&
        t.length <= 56) {
      return true;
    }
    if (RegExp(r'^(neden|niye|why|почему)\\b').hasMatch(t) && t.length <= 40) {
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
''',
)

path = Path("lib/features/companion/data/companion_intent.dart")
text = path.read_text(encoding="utf-8")
text = re.sub(
    r"\n  /// Short thread-continuing cues.*?return false;\n  }\n",
    "\n  static bool isShortFollowUp(String text) =>\n"
    "      CompanionShortFollowUp.matches(text);\n\n",
    text,
    count=1,
    flags=re.S,
)
if "import 'companion_short_followup.dart';" not in text:
    text = text.replace(
        "library;\n\n",
        "library;\n\nimport 'companion_short_followup.dart';\n\n",
        1,
    )
path.write_text(text, encoding="utf-8", newline="\n")
print("intent", len(text.splitlines()))
assert "static bool isShortFollowUp" in text
