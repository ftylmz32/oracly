/// SPRINT-004 — Personal insight categories — observation only.
library;

import '../../../core/l10n/l10n.dart';

enum InsightCategory {
  recurringTheme,
  emotionalShift,
  meaningfulReflection,
  symbolRecurrence,
  growthMilestone,
  reflectionConsistency,
}

extension InsightCategoryLabels on InsightCategory {
  String get sectionLabel => OraclyL10n.t(switch (this) {
    InsightCategory.recurringTheme => 'insights.cat.theme',
    InsightCategory.emotionalShift => 'insights.cat.shift',
    InsightCategory.meaningfulReflection => 'insights.cat.reflection',
    InsightCategory.symbolRecurrence => 'insights.cat.symbol',
    InsightCategory.growthMilestone => 'insights.cat.growth',
    InsightCategory.reflectionConsistency => 'insights.cat.rhythm',
  });
}
