from pathlib import Path

def w(path, text):
    Path(path).write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")
    print(path, len(text.splitlines()))

w("lib/features/companion/data/companion_job_change.dart", '''/// Job-change intent cues for OR continuity.
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
''')

intent = Path("lib/features/companion/data/companion_intent.dart").read_text(encoding="utf-8")
intent = intent.replace(
    "import 'companion_short_followup.dart';\n",
    "import 'companion_job_change.dart';\nimport 'companion_short_followup.dart';\n",
)
# replace isJobChange body
start = intent.index("  static bool isJobChange(String text) {")
end = intent.index("  static bool isShortFollowUp")
intent = intent[:start] + (
    "  static bool isJobChange(String text) => CompanionJobChange.matches(text);\n\n"
) + intent[end:]
intent = intent.replace("\n\n\n  static bool isAdvice", "\n\n  static bool isAdvice")
Path("lib/features/companion/data/companion_intent.dart").write_text(intent, encoding="utf-8", newline="\n")
print("intent", len(intent.splitlines()))

# Split follow-up types
w("lib/features/companion/services/follow_up_decision.dart", '''/// Follow-up decision types for OR clarifying questions.
library;

import 'follow_up_prompt_hints.dart';

enum FollowUpMode { ask, reflect, answerOnly }

enum FollowUpLocalKind {
  none,
  jobTimeline,
  fearClarify,
  undecidedScope,
  moodOpen,
  explore,
  reflectOnly,
}

class FollowUpDecision {
  const FollowUpDecision({
    required this.mode,
    this.localKind = FollowUpLocalKind.none,
    this.forceTrailingQuestion,
  });

  final FollowUpMode mode;
  final FollowUpLocalKind localKind;
  final bool? forceTrailingQuestion;

  bool get allowTrailingQuestion =>
      forceTrailingQuestion ?? mode == FollowUpMode.ask;

  String get promptHint => FollowUpPromptHints.forDecision(this);
}
''')

# Fix circular import: follow_up_prompt_hints imports contextual which imports decision
# Keep FollowUpDecision in contextual OR make prompt hints import decision only.

# Better: keep enums in follow_up_decision without importing prompt hints —
# promptHint method can stay as extension or on ContextualFollowUpPolicy.

w("lib/features/companion/services/follow_up_decision.dart", '''/// Follow-up decision types for OR clarifying questions.
library;

enum FollowUpMode { ask, reflect, answerOnly }

enum FollowUpLocalKind {
  none,
  jobTimeline,
  fearClarify,
  undecidedScope,
  moodOpen,
  explore,
  reflectOnly,
}

class FollowUpDecision {
  const FollowUpDecision({
    required this.mode,
    this.localKind = FollowUpLocalKind.none,
    this.forceTrailingQuestion,
  });

  final FollowUpMode mode;
  final FollowUpLocalKind localKind;
  final bool? forceTrailingQuestion;

  bool get allowTrailingQuestion =>
      forceTrailingQuestion ?? mode == FollowUpMode.ask;
}
''')

policy = Path("lib/features/companion/services/contextual_followup_policy.dart").read_text(encoding="utf-8")
# Remove enums/class, import decision + use promptHint via FollowUpPromptHints
policy = policy.replace(
    "import 'follow_up_prompt_hints.dart';\n",
    "import 'follow_up_decision.dart';\nimport 'follow_up_prompt_hints.dart';\n",
)
policy = policy.replace(
    """enum FollowUpMode { ask, reflect, answerOnly }

enum FollowUpLocalKind {
  none,
  jobTimeline,
  fearClarify,
  undecidedScope,
  moodOpen,
  explore,
  reflectOnly,
}

class FollowUpDecision {
  const FollowUpDecision({
    required this.mode,
    this.localKind = FollowUpLocalKind.none,
    this.forceTrailingQuestion,
  });

  final FollowUpMode mode;
  final FollowUpLocalKind localKind;
  final bool? forceTrailingQuestion;

  bool get allowTrailingQuestion =>
      forceTrailingQuestion ?? mode == FollowUpMode.ask;

  String get promptHint => FollowUpPromptHints.forDecision(this);
}

""",
    "export 'follow_up_decision.dart';\n\n",
)
# Add extension or update promptHint call sites — CompanionThreadMemory uses followUp.promptHint
# Add getter via extension in follow_up_decision after prompt hints, or patch call sites.

Path("lib/features/companion/services/contextual_followup_policy.dart").write_text(policy, encoding="utf-8", newline="\n")
print("policy", len(policy.splitlines()))

# Update follow_up_prompt_hints to import decision
hints = Path("lib/features/companion/services/follow_up_prompt_hints.dart").read_text(encoding="utf-8")
hints = hints.replace(
    "import 'contextual_followup_policy.dart';\n",
    "import 'follow_up_decision.dart';\n",
)
Path("lib/features/companion/services/follow_up_prompt_hints.dart").write_text(hints, encoding="utf-8", newline="\n")

# Patch promptHint usages — companion_thread_memory
mem = Path("lib/features/companion/services/companion_thread_memory.dart").read_text(encoding="utf-8")
if "followUp.promptHint" in mem:
    mem = mem.replace(
        "followUp.promptHint",
        "FollowUpPromptHints.forDecision(followUp)",
    )
    if "follow_up_prompt_hints.dart" not in mem:
        mem = mem.replace(
            "import 'contextual_followup_policy.dart';\n",
            "import 'contextual_followup_policy.dart';\nimport 'follow_up_prompt_hints.dart';\n",
        )
    Path("lib/features/companion/services/companion_thread_memory.dart").write_text(mem, encoding="utf-8", newline="\n")
    print("thread memory patched")

# companion_responder may use promptHint too
for p in Path("lib/features/companion").rglob("*.dart"):
    t = p.read_text(encoding="utf-8")
    if ".promptHint" in t and "FollowUpPromptHints" not in t and p.name != "follow_up_prompt_hints.dart":
        print("still uses promptHint:", p)
