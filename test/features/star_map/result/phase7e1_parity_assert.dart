/// Phase 7E.1 — explicit parity assertions (no overloaded single equality).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';

void phase7e1AssertPresentationParity(
  YildiznameResultPresentation live,
  YildiznameResultPresentation reopen,
) {
  expect(live.scope, reopen.scope);
  expect(live.title, reopen.title);
  expect(live.scopeDisclosure, reopen.scopeDisclosure);
  expect(live.sections, reopen.sections);
  expect(live.factSnapshot, reopen.factSnapshot);
  expect(live.artifactId, reopen.artifactId);
  expect(live.createdAtUtc, reopen.createdAtUtc);
  expect(live.chromeLanguage, reopen.chromeLanguage);
  expect(live.source, isNot(reopen.source));
}

void phase7e1AssertActionParity(
  YildiznameResultActions live,
  YildiznameResultActions reopen,
) {
  expect(live.canonicalInsight, reopen.canonicalInsight);
  expect(live.copyText, reopen.copyText);
  phase7e1AssertShareableParity(live, reopen);
  phase7e1AssertFavoriteParity(live, reopen);
  expect(live.continuationThemes, reopen.continuationThemes);
  expect(live.hasOr, isTrue);
  expect(reopen.hasOr, isTrue);
  expect(
    live.orContext!.toMetadata(),
    reopen.orContext!.toMetadata(),
  );
}

void phase7e1AssertShareableParity(
  YildiznameResultActions live,
  YildiznameResultActions reopen,
) {
  expect(live.share.kind, reopen.share.kind);
  expect(live.share.typeLabel, reopen.share.typeLabel);
  expect(live.share.highlight, reopen.share.highlight);
  expect(live.share.subjectLabel, reopen.share.subjectLabel);
  expect(live.share.caption, reopen.share.caption);
  expect(live.share.visualAsset, reopen.share.visualAsset);
  expect(live.share.visualIsReversed, reopen.share.visualIsReversed);
}

void phase7e1AssertFavoriteParity(
  YildiznameResultActions live,
  YildiznameResultActions reopen,
) {
  expect(live.hasFavorite, isTrue);
  expect(reopen.hasFavorite, isTrue);
  expect(live.favorite!.artifactId, reopen.favorite!.artifactId);
  expect(live.favorite!.favoriteId, reopen.favorite!.favoriteId);
  expect(live.favorite!.occurredAt, reopen.favorite!.occurredAt);
  expect(live.favorite!.title, reopen.favorite!.title);
  expect(live.favorite!.insight, reopen.favorite!.insight);
}
