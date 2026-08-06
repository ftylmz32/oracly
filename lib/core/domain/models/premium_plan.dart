/// OR-1100 — Premium plan domain model.
library;

enum PremiumPlanKind { monthly, yearly, lifetime }

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
