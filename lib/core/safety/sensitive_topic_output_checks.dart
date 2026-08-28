/// Blocks AI output that crosses sensitive-topic lines.
library;

abstract final class SensitiveTopicOutputChecks {
  SensitiveTopicOutputChecks._();

  static bool blocksOutput(String text) =>
      claimsMedicalDiagnosis(text) ||
      promisesFinancialGuarantee(text) ||
      givesLegalAdvice(text) ||
      claimsDefiniteLove(text) ||
      predictsFear(text);

  static bool claimsMedicalDiagnosis(String text) {
    final lower = text.toLowerCase();
    const hits = [
      'hastalığın',
      'teşhis',
      'şu hastalık',
      'you have this illness',
      'diagnosed with',
      'диагноз',
    ];
    return hits.any(lower.contains);
  }

  static bool promisesFinancialGuarantee(String text) {
    final lower = text.toLowerCase();
    return lower.contains('garanti kazan') ||
        lower.contains('kesin kazanç') ||
        lower.contains('guaranteed profit') ||
        lower.contains('guaranteed return');
  }

  static bool givesLegalAdvice(String text) {
    final lower = text.toLowerCase();
    return lower.contains('dava kazanacaksın') ||
        lower.contains('you will win the lawsuit') ||
        lower.contains('hukuki olarak yapmalısın');
  }

  static bool claimsDefiniteLove(String text) {
    final lower = text.toLowerCase();
    return lower.contains('kesin seni seviyor') ||
        lower.contains('definitely loves you') ||
        lower.contains('точно любит тебя');
  }

  static bool predictsFear(String text) {
    final lower = text.toLowerCase();
    const hits = [
      'felaket',
      'tehlike kapıda',
      'kaçınılması gerek',
      'asla geri dönemez',
      'korkmalısın',
      'berbat olacak',
      'ölüm tarihin',
      'hastalık kapıda',
      'you will die',
      'disaster awaits',
      'катастрофа жд',
    ];
    return hits.any(lower.contains);
  }
}

