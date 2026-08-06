/// SPRINT-004 — Personal insight categories — observation only.
library;

enum InsightCategory {
  recurringTheme,
  emotionalShift,
  meaningfulReflection,
  symbolRecurrence,
  growthMilestone,
  reflectionConsistency,
}

extension InsightCategoryLabels on InsightCategory {
  String get sectionLabel => switch (this) {
        InsightCategory.recurringTheme => 'Yankılanan temalar',
        InsightCategory.emotionalShift => 'Duygusal geçişler',
        InsightCategory.meaningfulReflection => 'Anlamlı yansımalar',
        InsightCategory.symbolRecurrence => 'Sembol tekrarları',
        InsightCategory.growthMilestone => 'Büyüme anları',
        InsightCategory.reflectionConsistency => 'Yansıma ritmi',
      };
}
