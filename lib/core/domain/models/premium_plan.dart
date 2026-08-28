/// OR-1100 — Premium plan domain model.
library;

import '../../l10n/l10n.dart';

enum PremiumPlanKind { monthly, yearly, lifetime }

extension PremiumPlanKindPeriod on PremiumPlanKind {
  String get periodLabel => OraclyL10n.t(switch (this) {
        PremiumPlanKind.monthly => 'premium.plan_period.monthly',
        PremiumPlanKind.yearly => 'premium.plan_period.yearly',
        PremiumPlanKind.lifetime => 'premium.plan_period.lifetime',
      });
}

class PremiumPlanModel {
  const PremiumPlanModel({
    required this.kind,
    required this.label,
    required this.price,
    required this.subtitle,
    required this.isActive,
  });

  final PremiumPlanKind kind;
  final String label;
  final String price;
  final String subtitle;
  final bool isActive;
}
