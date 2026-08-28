/// What free vs Premium may surface — never invents journey value.
library;

class OracleJourneyDepthAccess {
  const OracleJourneyDepthAccess({
    required this.allowBasicNextAction,
    required this.allowBasicObservation,
    required this.allowSoftPremiumInvite,
    required this.allowDeepOrContext,
    required this.allowThemeHistory,
    required this.allowJourneyArchive,
    required this.allowFullCrossFeature,
  });

  /// Free + Premium: evidence-backed NextAction stays visible.
  final bool allowBasicNextAction;

  /// Free + Premium: basic observation never withheld for curiosity.
  final bool allowBasicObservation;

  /// Soft invite only when real journeyDepth exists and user is free.
  final bool allowSoftPremiumInvite;

  final bool allowDeepOrContext;
  final bool allowThemeHistory;
  final bool allowJourneyArchive;
  final bool allowFullCrossFeature;

  static const freeBasic = OracleJourneyDepthAccess(
    allowBasicNextAction: true,
    allowBasicObservation: true,
    allowSoftPremiumInvite: false,
    allowDeepOrContext: false,
    allowThemeHistory: false,
    allowJourneyArchive: false,
    allowFullCrossFeature: false,
  );
}
