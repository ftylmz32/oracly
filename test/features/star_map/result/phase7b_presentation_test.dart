/// Phase 7B — typed presentation projection, localized chrome, truthful scope.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_payload.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_section.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_chrome.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';
import 'package:oracly_new/features/star_map/result/yildizname_scope_resolver.dart';

import '../../../support/yildizname_result_fixtures.dart';

const _locales = ['tr', 'en', 'ru'];

/// Every user-visible string a presentation exposes as chrome.
List<String> _chrome(YildiznameResultPresentation p) => [
  p.title,
  for (final s in p.sections) s.title,
  if (p.scopeDisclosure != null) ...[
    p.scopeDisclosure!.kicker,
    p.scopeDisclosure!.body,
  ],
];

/// Chrome + prose — everything a reader can see.
List<String> _visible(YildiznameResultPresentation p) => [
  ..._chrome(p),
  for (final s in p.sections) s.body,
];

const _forbidden = <String>[
  'theme.',
  'yth_',
  'factRef',
  'semanticFingerprint',
  'evidenceFingerprint',
  'reducedNatal',
  'fullNatalEphemeris',
  'tropicalSunSign',
  'yid_',
  'yildizname_policy',
  'calc-fixture',
  'contractVersion',
  'serializerVersion',
];

final _rawKindNames = <String>{
  for (final k in YildiznameSectionKind.values) ...[k.name, k.wireName],
  'summary',
  'reflection',
  'closing',
  'reflectionPrompt',
  'closingMessage',
};

void _expectClean(Iterable<String> strings) {
  for (final s in strings) {
    for (final f in _forbidden) {
      expect(s.contains(f), isFalse, reason: '"$s" leaks "$f"');
    }
    expect(_rawKindNames.contains(s.trim()), isFalse, reason: 'raw title "$s"');
    expect(
      RegExp(r'^[a-z]+([A-Z][a-z]+)+$').hasMatch(s.trim()),
      isFalse,
      reason: 'camelCase identifier "$s"',
    );
    expect(
      RegExp(r'^[a-z]+(_[a-z]+)+$').hasMatch(s.trim()),
      isFalse,
      reason: 'snake_case identifier "$s"',
    );
  }
}

void main() {
  group('A — Narrative reduced artifact', () {
    final artifact = yildiznameFixtureNarrativeArtifact();
    final p = YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');

    test('typed source / scope', () {
      expect(p.source, YildiznameResultSource.narrativeArtifact);
      expect(p.isHistoricalArtifact, isTrue);
      expect(p.scope, YildiznameResultScope.reduced);
      expect(p.artifactId, artifact.id);
      expect(p.createdAtUtc, artifact.createdAtUtc);
      expect(p.planets, isEmpty);
    });

    test(
      'localized title + summary / chapter / reflection / closing chrome',
      () {
        expect(p.title, 'Yıldızname');
        expect(p.sections.map((s) => s.title), [
          'Özet',
          'Kimlik',
          'Üzerine düşün',
          'Kapanış',
        ]);
      },
    );

    test('semantic roles are typed and ordered', () {
      expect(p.sections.map((s) => s.role), [
        YildiznameSectionRole.summary,
        YildiznameSectionRole.chapter,
        YildiznameSectionRole.reflection,
        YildiznameSectionRole.closing,
      ]);
    });

    test(
      'reduced disclosure — no fake Ascendant / houses / degrees claims',
      () {
        final d = p.scopeDisclosure!;
        expect(d.scope, YildiznameResultScope.reduced);
        expect(d.evidence.hasAscendant, isFalse);
        expect(d.evidence.hasHouses, isFalse);
        expect(d.body, contains('kişiselleştirilmiş'));
        expect(d.body, contains('dahil edilmedi'));
        expect(d.body.contains('derece'), isFalse);
        expect(d.body.contains('°'), isFalse);
      },
    );

    test(
      'nothing raw or technical is visible',
      () => _expectClean(_visible(p)),
    );
  });

  group('B — Narrative full artifact with rich evidence', () {
    final artifact = yildiznameFixtureNarrativeArtifact(
      id: 'yid_dddddddddddddddddddddddddddddddd',
      scope: YildiznameNarrativeScope.full,
    );
    final p = YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');

    test('full disclosure without an exhaustive promise', () {
      expect(p.scope, YildiznameResultScope.full);
      final d = p.scopeDisclosure!;
      expect(d.evidence.fullLayersComplete, isTrue);
      expect(d.body, YildiznameResultChrome.scopeBody(d.evidence, 'tr'));
      // General wording only — no layer is promised by name.
      for (final layer in const [
        'Yükselen',
        'Ay ',
        'Ascendant',
        'Moon',
        'Rising',
      ]) {
        expect(d.body.contains(layer), isFalse, reason: layer);
      }
    });

    test('kind chapters localize; no raw strings; no planet / fact cards', () {
      expect(p.sections.map((s) => s.title), [
        'Özet',
        'Kimlik',
        'Duygusal dünya',
        'Açılar ve evler',
        'Üzerine düşün',
        'Kapanış',
      ]);
      expect(p.planets, isEmpty);
      _expectClean(_visible(p));
    });
  });

  group('C / D — FULL with omitted layers', () {
    for (final locale in _locales) {
      test('houses omitted → disclosure never claims houses [$locale]', () {
        final p = YildiznameArtifactPresentation.of(
          yildiznameFixtureNarrativeArtifact(
            scope: YildiznameNarrativeScope.full,
            houses: false,
          ),
          chromeLocale: locale,
        );
        final d = p.scopeDisclosure!;
        expect(p.scope, YildiznameResultScope.full);
        expect(d.evidence.hasHouses, isFalse);
        expect(d.evidence.fullLayersComplete, isFalse);
        expect(
          d.body,
          YildiznameResultChrome.scopeBody(
            const YildiznameResolvedScope(scope: YildiznameResultScope.full),
            locale,
          ),
          reason: 'partial FULL copy',
        );
        for (final layer in const [
          'evler',
          'houses',
          'дома',
          'Yükselen',
          'Ascendant',
          'Асцендент',
        ]) {
          expect(
            d.body.toLowerCase().contains(layer.toLowerCase()),
            isFalse,
            reason: '$layer in "${d.body}"',
          );
        }
      });

      test(
        'ascendant omitted → disclosure never claims Ascendant [$locale]',
        () {
          final p = YildiznameArtifactPresentation.of(
            yildiznameFixtureNarrativeArtifact(
              scope: YildiznameNarrativeScope.full,
              ascendant: false,
            ),
            chromeLocale: locale,
          );
          final d = p.scopeDisclosure!;
          expect(d.evidence.hasAscendant, isFalse);
          for (final layer in const [
            'Yükselen',
            'Ascendant',
            'Rising',
            'Асцендент',
          ]) {
            expect(
              d.body.toLowerCase().contains(layer.toLowerCase()),
              isFalse,
              reason: '$layer in "${d.body}"',
            );
          }
        },
      );
    }

    test('complete FULL and partial FULL differ in wording', () {
      final complete = YildiznameArtifactPresentation.of(
        yildiznameFixtureNarrativeArtifact(
          scope: YildiznameNarrativeScope.full,
        ),
        chromeLocale: 'en',
      );
      final partial = YildiznameArtifactPresentation.of(
        yildiznameFixtureNarrativeArtifact(
          scope: YildiznameNarrativeScope.full,
          aspects: false,
        ),
        chromeLocale: 'en',
      );
      expect(
        partial.scopeDisclosure!.body,
        isNot(complete.scopeDisclosure!.body),
      );
      expect(partial.scopeDisclosure!.body, contains('Only the layers'));
    });
  });

  group('E — conflicting / incomplete metadata is fail-closed', () {
    Map<String, dynamic> payloadOf(YildiznameArtifact a) =>
        Map<String, dynamic>.from(a.payload);

    test('scope full + fidelity reducedNatal → reduced disclosure', () {
      final base = yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
      );
      final conflicted = yildiznameFixtureRawNarrativeArtifact(
        payload: payloadOf(base),
        scope: 'full',
        fidelity: 'reducedNatal',
      );
      final p = YildiznameArtifactPresentation.of(
        conflicted,
        chromeLocale: 'tr',
      );
      expect(p.scope, YildiznameResultScope.reduced);
      expect(p.scopeDisclosure!.evidence.hasAscendant, isFalse);
    });

    test('artifact claims full but stores only a reduced request', () {
      final reduced = yildiznameFixtureNarrativeArtifact();
      final p = YildiznameArtifactPresentation.of(
        yildiznameFixtureRawNarrativeArtifact(
          payload: payloadOf(reduced),
          scope: 'full',
          fidelity: 'fullNatalEphemeris',
        ),
        chromeLocale: 'en',
      );
      expect(p.scope, YildiznameResultScope.reduced);
    });

    test('unproven metadata falls back to the lightest disclosure', () {
      final p = YildiznameArtifactPresentation.of(
        yildiznameFixtureRawNarrativeArtifact(
          payload: const {
            'result': {
              'summary': {'text': 'Saklı özet.'},
            },
          },
          scope: 'full',
        ),
        chromeLocale: 'tr',
      );
      expect(p.scope, YildiznameResultScope.legacy);
      expect(p.sections.single.body, 'Saklı özet.');
    });
  });

  group('F / G — legacy', () {
    YildiznameArtifact legacyArtifact() =>
        YildiznameArtifactFactory.createLegacy(
          ownerId: 'o1',
          id: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          title: 'Gökyüzü Mesajı',
          sections: const [
            StarMapResultSection(
              title: 'Gökyüzü',
              body: 'Bugün sakin bir nefes.',
            ),
            StarMapResultSection(title: 'Anlam', body: 'İç sesini dinle.'),
          ],
          sectionKind: YildiznameLegacySectionKind.skyMessage,
          locale: 'tr',
          planets: const [
            StarMapPlanetInfluence(
              nameTr: 'Güneş',
              influence: 'odak',
              explanation: 'Sembolik katalog.',
              polarity: StarMapPolarity.balanced,
            ),
          ],
          sunSignId: 'leo',
          dayKey: '2026-01-10',
          createdAtUtc: DateTime.utc(2026, 1, 10),
        );

    test('legacy artifact reopen keeps symbolic, lighter semantics', () {
      final p = YildiznameArtifactPresentation.of(
        legacyArtifact(),
        chromeLocale: 'tr',
      );
      expect(p.source, YildiznameResultSource.legacyArtifact);
      expect(p.scope, YildiznameResultScope.legacy);
      expect(p.title, 'Gökyüzü Mesajı');
      expect(p.sections.first.body, 'Bugün sakin bir nefes.');
      expect(p.planets.single.nameTr, 'Güneş');
      final d = p.scopeDisclosure!;
      expect(d.body, contains('sembolik'));
      expect(d.body, contains('Kesin bir gök haritası hesabı değildir'));
      expect(d.evidence.hasAscendant, isFalse);
      expect(d.evidence.hasHouses, isFalse);
    });

    for (final locale in _locales) {
      test(
        'legacy disclosure carries no natal-precision language [$locale]',
        () {
          final p = YildiznameArtifactPresentation.of(
            legacyArtifact(),
            chromeLocale: locale,
          );
          final body = p.scopeDisclosure!.body.toLowerCase();
          for (final claim in const [
            'moon',
            'ay burcu',
            'луна',
            'rising',
            'yükselen burç hesab',
            'houses were',
            'derece',
            'degrees',
            'градус',
          ]) {
            expect(body.contains(claim), isFalse, reason: '$claim in "$body"');
          }
        },
      );
    }

    test('legacy live is live, typed, and symbolic', () {
      final p = YildiznameResultPresentation.legacyLive(
        title: 'Gökyüzü Mesajı',
        sections: const [
          StarMapResultSection(
            title: 'Gökyüzü',
            body: 'Bugün sakin bir nefes.',
          ),
        ],
        chromeLanguage: 'en',
      );
      expect(p.source, YildiznameResultSource.legacyLive);
      expect(p.isHistoricalArtifact, isFalse);
      expect(p.scope, YildiznameResultScope.legacy);
      expect(p.scopeDisclosure!.kicker, 'What this reading rests on');
      expect(p.scopeDisclosure!.body, contains('symbolic'));
    });

    test('legacy artifact without a stored title uses the product label', () {
      final a = YildiznameArtifactFactory.createLegacy(
        ownerId: 'o1',
        title: '',
        sections: const [StarMapResultSection(title: 'x', body: 'y')],
        sectionKind: YildiznameLegacySectionKind.skyMessage,
        locale: 'tr',
      );
      final p = YildiznameArtifactPresentation.of(a, chromeLocale: 'ru');
      expect(p.title, 'Йылдызнаме');
    });
  });

  group('H — stored prose is immutable', () {
    test('every body equals the stored accepted text, byte for byte', () {
      final artifact = yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
        summary: '  Boşluklu   özet metni.  ',
        sectionTexts: const [
          'İlk bölüm — “tırnaklı” metin.',
          'İkinci bölüm\nçok satırlı.',
          'Üçüncü bölüm.',
        ],
      );
      final result = YildiznameNarrativePayload.resultOf(artifact.payload)!;
      final expected = <String>[
        result['summary']['text'] as String,
        for (final s in result['sections'] as List) s['text'] as String,
        result['reflectionPrompt']['text'] as String,
        result['closingMessage']['text'] as String,
      ];
      for (final locale in _locales) {
        final p = YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: locale,
        );
        expect(
          p.sections.map((s) => s.body).toList(),
          expected,
          reason: locale,
        );
      }
    });

    test('projection never mutates or re-seals the artifact', () {
      final artifact = yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
      );
      final hashBefore = artifact.contentHash;
      final payloadBefore = YildiznameArtifactCanonicalCopy.of(artifact);
      for (final locale in _locales) {
        YildiznameArtifactPresentation.of(artifact, chromeLocale: locale);
      }
      YildiznameArtifactIntegrity.verify(artifact);
      expect(artifact.contentHash, hashBefore);
      expect(YildiznameArtifactCanonicalCopy.of(artifact), payloadBefore);
    });
  });

  group('I — result locale vs chrome locale', () {
    test('Cyrillic prose under English chrome stays Cyrillic', () {
      final artifact = yildiznameFixtureNarrativeArtifact(
        languageCode: 'ru',
        summary: 'Солнце во Льве несёт терпеливый фокус.',
        sectionTexts: const ['Спокойная ясность в области идентичности.'],
        reflection: 'Какой фокус сегодня честнее?',
        closing: 'Вернись к своему ритму.',
      );
      final p = YildiznameArtifactPresentation.of(artifact, chromeLocale: 'en');
      expect(artifact.resultLocale, 'ru');
      expect(p.chromeLanguage, 'en');
      expect(p.sections.map((s) => s.title), [
        'Summary',
        'Identity',
        'To reflect on',
        'Closing',
      ]);
      expect(p.sections.first.body, 'Солнце во Льве несёт терпеливый фокус.');
      expect(p.title, 'Yıldızname');
    });

    test('Turkish prose under Russian chrome stays Turkish', () {
      final p = YildiznameArtifactPresentation.of(
        yildiznameFixtureNarrativeArtifact(),
        chromeLocale: 'ru',
      );
      expect(p.title, 'Йылдызнаме');
      expect(p.sections.map((s) => s.title), [
        'Кратко',
        'Идентичность',
        'Для размышления',
        'Завершение',
      ]);
      expect(p.sections.first.body, contains('Güneş Leo'));
    });

    test('chrome follows the bound app language by default', () {
      expect(YildiznameResultChrome.language('en'), 'en');
      expect(YildiznameResultChrome.language('ru-RU'), 'ru');
      expect(YildiznameResultChrome.language('xx'), 'tr');
    });
  });

  group('J — unknown / future section kinds', () {
    test('raw identifier never shown; valid prose preserved', () {
      final base = yildiznameFixtureNarrativeArtifact();
      final payload = Map<String, dynamic>.from(base.payload);
      payload['result'] = {
        ...Map<String, dynamic>.from(payload['result'] as Map),
        'sections': [
          {
            'kind': 'wisdom_of_the_ages',
            'text': 'Gelecekteki bir bölümün geçerli metni.',
            'factRefs': ['placement.sun'],
            'themeRefs': ['theme.0'],
          },
          {'kind': 7, 'text': 'Sayısal tür, geçerli metin.'},
          {'text': 'Türü olmayan, geçerli metin.'},
          {'kind': 'core_identity', 'text': ''},
        ],
      };
      final artifact = yildiznameFixtureRawNarrativeArtifact(
        payload: payload,
        scope: 'reduced',
        fidelity: 'reducedNatal',
      );
      for (final locale in _locales) {
        final p = YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: locale,
        );
        final neutral = YildiznameResultChrome.neutralChapterTitle(locale);
        final chapters = p.sections
            .where((s) => s.role == YildiznameSectionRole.chapter)
            .toList();
        expect(chapters, hasLength(3), reason: 'empty prose skipped');
        expect(chapters.map((s) => s.title), everyElement(neutral));
        expect(chapters.map((s) => s.body), [
          'Gelecekteki bir bölümün geçerli metni.',
          'Sayısal tür, geçerli metin.',
          'Türü olmayan, geçerli metin.',
        ]);
        for (final s in _visible(p)) {
          expect(s.contains('wisdom_of_the_ages'), isFalse);
          expect(s.contains('placement.sun'), isFalse);
        }
        _expectClean(_chrome(p));
      }
    });
  });

  group('K — internal identifiers never surface', () {
    final artifacts = <String, YildiznameArtifact>{
      'reduced': yildiznameFixtureNarrativeArtifact(),
      'full': yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
      ),
      'full-partial': yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
        houses: false,
        ascendant: false,
      ),
      'legacy-scope': yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.legacy,
      ),
    };
    for (final e in artifacts.entries) {
      for (final locale in _locales) {
        test('${e.key} [$locale]', () {
          final p = YildiznameArtifactPresentation.of(
            e.value,
            chromeLocale: locale,
          );
          _expectClean(_visible(p));
          expect(p.artifactId, e.value.id, reason: 'internal only');
          for (final s in _chrome(p)) {
            expect(s.contains(e.value.id), isFalse);
          }
        });
      }
    }
  });

  group('L — roles are typed and deterministic', () {
    test('every role maps to distinct localized chrome per locale', () {
      for (final locale in _locales) {
        final titles = {
          for (final role in YildiznameSectionRole.values)
            role: YildiznameResultChrome.roleTitle(role, locale),
        };
        expect(titles.values.toSet(), hasLength(titles.length), reason: locale);
        _expectClean(titles.values);
      }
    });

    test('chapter ordering follows the stored order', () {
      final p = YildiznameArtifactPresentation.of(
        yildiznameFixtureNarrativeArtifact(
          scope: YildiznameNarrativeScope.full,
          kinds: const [
            YildiznameSectionKind.practicalReflection,
            YildiznameSectionKind.coreIdentity,
            YildiznameSectionKind.archiveEcho,
          ],
        ),
        chromeLocale: 'en',
      );
      expect(p.sections.map((s) => s.title), [
        'Summary',
        'Practical reflection',
        'Identity',
        'Archive echo',
        'To reflect on',
        'Closing',
      ]);
    });
  });

  group('M — deterministic projection', () {
    test('same artifact → equal presentation, every locale', () {
      final artifact = yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
        houses: false,
      );
      for (final locale in _locales) {
        final a = YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: locale,
        );
        final b = YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: locale,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      }
    });

    test('different chrome locale → different chrome, equal prose', () {
      final artifact = yildiznameFixtureNarrativeArtifact();
      final tr = YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      );
      final en = YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'en',
      );
      expect(tr, isNot(en));
      expect(
        tr.sections.map((s) => s.body).toList(),
        en.sections.map((s) => s.body).toList(),
      );
    });

    test('live projection matches artifact projection (Phase 8 parity)', () {
      final request = yildiznameFixtureRequest(
        scope: YildiznameNarrativeScope.full,
      );
      final result = yildiznameFixtureResult(
        scope: YildiznameNarrativeScope.full,
        kinds: const [YildiznameSectionKind.coreIdentity],
      );
      final artifact = YildiznameArtifactFactory.createNarrative(
        ownerId: 'o',
        request: request,
        result: result,
        id: 'yid_ffffffffffffffffffffffffffffffff',
        createdAtUtc: DateTime.utc(2026, 2, 1),
      );
      final stored = YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      );
      final live = YildiznameArtifactPresentation.narrativeLive(
        request: request,
        result: result,
        artifactId: artifact.id,
        createdAtUtc: artifact.createdAtUtc,
        chromeLocale: 'tr',
      );
      expect(live.source, YildiznameResultSource.narrativeLive);
      expect(live.isHistoricalArtifact, isFalse);
      expect(live.title, stored.title);
      expect(live.scope, stored.scope);
      expect(live.scopeDisclosure, stored.scopeDisclosure);
      expect(live.sections, stored.sections);
    });
  });

  group('N — old / incomplete artifacts stay reopenable', () {
    test('no scope, fidelity, locale or request → still projects', () {
      final artifact = yildiznameFixtureRawNarrativeArtifact(
        resultLocale: null,
        payload: const {
          'result': {
            'summary': {'text': 'Eski kayıt özeti.'},
            'sections': [
              {'kind': 'core_identity', 'text': 'Eski kayıt bölümü.'},
            ],
          },
        },
      );
      final p = YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
      expect(p.sections.map((s) => s.title), ['Özet', 'Kimlik']);
      expect(p.scope, YildiznameResultScope.legacy);
      expect(p.scopeDisclosure, isNotNull);
      expect(p.title, 'Yıldızname');
    });

    test('empty payload / missing result → empty sections, no throw', () {
      for (final payload in <Map<String, dynamic>>[
        const {},
        const {'request': <String, dynamic>{}},
        const {'result': 'not-a-map'},
      ]) {
        final p = YildiznameArtifactPresentation.of(
          yildiznameFixtureRawNarrativeArtifact(payload: payload),
          chromeLocale: 'en',
        );
        expect(p.sections, isEmpty);
        expect(p.title, 'Yıldızname');
        expect(p.scopeDisclosure, isNotNull);
      }
    });

    test('summaryQuote keeps its stored-prose contract', () {
      final artifact = yildiznameFixtureNarrativeArtifact();
      expect(
        YildiznameArtifactPresentation.summaryQuote(artifact),
        'Güneş Leo konumunda sabırlı bir odak taşır.',
      );
    });
  });

  group('localization completeness — no raw-key fallback', () {
    const roleKeys = [
      'star.result.role.summary',
      'star.result.role.reflection',
      'star.result.role.closing',
      'star.result.chapter.neutral',
      'star.result.scope.kicker',
      'star.result.scope.legacy',
      'star.result.scope.reduced',
      'star.result.scope.full',
      'star.result.scope.full_partial',
      'star.result.chapter.identity',
      'star.result.chapter.emotional',
      'star.result.chapter.mind',
      'star.result.chapter.relationships',
      'star.result.chapter.drive',
      'star.result.chapter.angles',
      'star.result.chapter.patterns',
      'star.result.chapter.strengths',
      'star.result.chapter.echo',
      'star.result.chapter.practice',
    ];

    test('every result key exists in TR, EN and RU', () {
      for (final key in roleKeys) {
        final triple = AppStringTables.all[key];
        expect(triple, isNotNull, reason: key);
        for (final v in [triple!.tr, triple.en, triple.ru]) {
          expect(v.trim(), isNotEmpty, reason: key);
          expect(v, isNot(key));
        }
      }
    });

    test('all 10 section kinds localize in all locales, never raw', () {
      for (final locale in _locales) {
        final seen = <String>{};
        for (final kind in YildiznameSectionKind.values) {
          final title = YildiznameResultChrome.chapterTitle(kind, locale);
          expect(title.startsWith('star.result'), isFalse, reason: '$kind');
          expect(title, isNot(kind.name));
          expect(title, isNot(kind.wireName));
          expect(seen.add(title), isTrue, reason: 'duplicate title $title');
        }
        expect(
          YildiznameResultChrome.chapterTitle(null, locale),
          YildiznameResultChrome.neutralChapterTitle(locale),
        );
      }
    });

    test('chrome for each locale is in that locale only', () {
      final cyrillic = RegExp(r'[А-Яа-яЁё]');
      for (final kind in YildiznameSectionKind.values) {
        expect(
          cyrillic.hasMatch(YildiznameResultChrome.chapterTitle(kind, 'ru')),
          isTrue,
        );
        expect(
          cyrillic.hasMatch(YildiznameResultChrome.chapterTitle(kind, 'tr')),
          isFalse,
        );
        expect(
          cyrillic.hasMatch(YildiznameResultChrome.chapterTitle(kind, 'en')),
          isFalse,
        );
      }
    });
  });
}

/// Canonical-ish payload snapshot for immutability checks.
abstract final class YildiznameArtifactCanonicalCopy {
  static String of(YildiznameArtifact a) =>
      '${a.payload}|${a.contentHash}|${a.scope}|${a.fidelity}|'
      '${a.semanticFingerprint}|${a.evidenceFingerprint}';
}
