/// Equality for [YildiznameResultPresentation].
part of 'yildizname_result_presentation.dart';

bool _presentationEquals(
  YildiznameResultPresentation a,
  YildiznameResultPresentation b,
) {
  if (a.source != b.source ||
      a.scope != b.scope ||
      a.title != b.title ||
      a.scopeDisclosure != b.scopeDisclosure ||
      a.artifactId != b.artifactId ||
      a.createdAtUtc != b.createdAtUtc ||
      a.chromeLanguage != b.chromeLanguage ||
      a.factSnapshot != b.factSnapshot ||
      a.continuity != b.continuity ||
      a.forensicFlatSections != b.forensicFlatSections ||
      a.forensicLegacyActionOrder != b.forensicLegacyActionOrder ||
      a.forensicHideHistoricalStatus != b.forensicHideHistoricalStatus ||
      a.actions != b.actions ||
      !listEquals(a.sections, b.sections) ||
      a.planets.length != b.planets.length) {
    return false;
  }
  for (var i = 0; i < a.planets.length; i++) {
    final x = a.planets[i];
    final y = b.planets[i];
    if (x.nameTr != y.nameTr ||
        x.influence != y.influence ||
        x.explanation != y.explanation ||
        x.polarity != y.polarity) {
      return false;
    }
  }
  return true;
}

int _presentationHash(YildiznameResultPresentation p) => Object.hash(
  p.source,
  p.scope,
  p.title,
  p.scopeDisclosure,
  p.artifactId,
  p.createdAtUtc,
  p.chromeLanguage,
  p.factSnapshot,
  p.continuity,
  p.forensicFlatSections,
  p.forensicLegacyActionOrder,
  p.forensicHideHistoricalStatus,
  p.actions,
  Object.hashAll(p.sections),
  p.planets.length,
);
