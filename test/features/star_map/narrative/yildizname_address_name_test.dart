/// The preferred name on the Yıldızname wire: sanitized, optional, and
/// invisible to readers who never gave one.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/onboarding/services/onboarding_birth_profile.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_grounding.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_address_name.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_canonical.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_wire_contract.dart';

BirthChart _chart() => EvidenceAwareNatalChartCalculator().calculate(
      OnboardingBirthProfile.build(
        birthDate: DateTime(1992, 4, 5),
        birthPlace: 'İstanbul',
        birthTime: DateTime(1992, 4, 5, 14, 30),
        birthTimeKnown: true,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sanitize', () {
    test('keeps natural names', () {
      expect(YildiznameAddressName.sanitize('  Ayşe '), 'Ayşe');
      expect(YildiznameAddressName.sanitize('Ayşe Nur'), 'Ayşe Nur');
      expect(YildiznameAddressName.sanitize('Ayşe Nur Yılmaz'), 'Ayşe Nur');
      expect(YildiznameAddressName.sanitize("O'Neil"), "O'Neil");
      expect(YildiznameAddressName.sanitize('Işıl'), 'Işıl');
    });

    test('drops anything that is not a name', () {
      expect(YildiznameAddressName.sanitize(null), isNull);
      expect(YildiznameAddressName.sanitize('   '), isNull);
      expect(YildiznameAddressName.sanitize('user123'), isNull);
      expect(YildiznameAddressName.sanitize('a@b.com'), isNull);
      expect(YildiznameAddressName.sanitize('{name}'), isNull);
      expect(YildiznameAddressName.sanitize('A' * 40), isNull);
      // A second word that is not a name is left out, not sent.
      expect(YildiznameAddressName.sanitize('Ayşe 2'), 'Ayşe');
    });
  });

  group('wire and fingerprint', () {
    test('a nameless request is byte-identical to the pre-name contract', () {
      final chart = _chart();
      final before = YildiznameRequestFactory.fromEvidence(
        evidence: chart.natalEvidence!,
        languageCode: 'tr',
      );
      final blank = YildiznameRequestFactory.fromEvidence(
        evidence: chart.natalEvidence!,
        languageCode: 'tr',
        addressName: '  ',
      );
      expect(before.toProviderJson().containsKey('addressName'), isFalse);
      expect(
        YildiznameRequestCanonical.encode(blank),
        YildiznameRequestCanonical.encode(before),
      );
      expect(
        YildiznameRequestFingerprint.of(blank),
        YildiznameRequestFingerprint.of(before),
      );
    });

    test('a name reaches the wire and changes only the prose fingerprint', () {
      final chart = _chart();
      final plain = YildiznameRequestFactory.fromEvidence(
        evidence: chart.natalEvidence!,
        languageCode: 'tr',
      );
      final named = YildiznameRequestFactory.fromEvidence(
        evidence: chart.natalEvidence!,
        languageCode: 'tr',
        addressName: 'Ayşe',
      );
      final wire = YildiznameWireContract.payload(named);
      expect((wire['narrative'] as Map)['addressName'], 'Ayşe');
      expect(
        YildiznameRequestFingerprint.of(named),
        isNot(YildiznameRequestFingerprint.of(plain)),
      );
      expect(
        YildiznameRequestFingerprint.factsOnly(named),
        YildiznameRequestFingerprint.factsOnly(plain),
      );
    });
  });

  group('names that are also sign names', () {
    test('vocative and genitive uses are not sign claims', () {
      const prose = 'başak, haritanda güneş koç burcunda. başak\'ın sesi net.';
      final masked =
          YildiznameQualityGrounding.maskAddressName(prose, 'Başak');
      expect(masked, isNot(contains('başak')));
    });

    test('a real sign claim stays visible to grounding', () {
      const prose = 'güneş başak burcunda; ay başak\'ta.';
      final masked =
          YildiznameQualityGrounding.maskAddressName(prose, 'Başak');
      expect(masked, prose);
    });
  });
}
