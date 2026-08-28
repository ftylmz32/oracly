/// Follow-up decision types for OR clarifying questions.
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
