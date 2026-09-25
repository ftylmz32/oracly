/// Phase 2 — product distinction + product registry snapshot (test-only).
library;

enum ContractProductOwner { yildizname, astrology }

abstract final class YildiznameProductDistinction {
  YildiznameProductDistinction._();

  static ContractProductOwner ownerOf(String factKind) {
    switch (factKind) {
      case 'natalBaseline':
      case 'birthChart':
      case 'dailySymbolicArchiveLeaf':
        return ContractProductOwner.yildizname;
      case 'currentTransitSky':
      case 'transitToNatal':
      case 'genericDailyHoroscopePrimary':
        return ContractProductOwner.astrology;
      default:
        return ContractProductOwner.astrology;
    }
  }

  static bool primaryYildiznameOutputOk(String kind) =>
      kind != 'genericDailyHoroscopePrimary';

  /// Frozen registry expectations (read-only contract).
  static const yildiznameRoute = '/star-map';
  static const yildiznameRealm = 'understand';
  static const yildiznameLive = true;
  static const yildiznamePremium = false;
  static const astrologySeparate = true;
}
