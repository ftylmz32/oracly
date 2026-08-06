/// SPRINT-002 — Human-readable chart insight for phased presentation.
library;

enum ChartInsightKind {
  bigThree,
  corePersonality,
  strengths,
  growthAreas,
  relationships,
  careerPurpose,
  emotionalPatterns,
  lifeThemes,
}

class ChartInsight {
  const ChartInsight({
    required this.kind,
    required this.title,
    required this.body,
    this.glossaryTerm,
    this.glossaryExplanation,
  });

  final ChartInsightKind kind;
  final String title;
  final String body;
  final String? glossaryTerm;
  final String? glossaryExplanation;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'title': title,
        'body': body,
        if (glossaryTerm != null) 'glossaryTerm': glossaryTerm,
        if (glossaryExplanation != null)
          'glossaryExplanation': glossaryExplanation,
      };

  factory ChartInsight.fromJson(Map<String, dynamic> json) {
    return ChartInsight(
      kind: ChartInsightKind.values.byName(json['kind'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      glossaryTerm: json['glossaryTerm'] as String?,
      glossaryExplanation: json['glossaryExplanation'] as String?,
    );
  }
}
