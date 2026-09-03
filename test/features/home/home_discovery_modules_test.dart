/// Home discovery — reference 3×2 core + Dream secondary extension.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_module_visual.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('core discovery is reference 3×2 six doors', () {
    final modules = HomeReferenceModules.list();
    expect(modules, hasLength(6));
    expect(modules.map((m) => m.id).toList(), [
      OraclyFeatureId.coffee,
      OraclyFeatureId.palm,
      OraclyFeatureId.astrology,
      OraclyFeatureId.starMap,
      OraclyFeatureId.soulMate,
      OraclyFeatureId.tarot,
    ]);
    expect(modules.map((m) => HomeDiscoveryCopy.title(m.id)).toList(), [
      'Kahve Falı',
      'El Falı',
      'Astroloji',
      'Yıldızname',
      'Ruh Eşi',
      'Tarot',
    ]);
  });

  test('Dream stays reachable as secondary extension', () {
    final dream = HomeReferenceModules.dreamExtension;
    expect(dream.id, OraclyFeatureId.dream);
    expect(dream.visual, HomeModuleVisual.dream);
    expect(dream.isNew, isTrue);
    expect(HomeDiscoveryCopy.title(dream.id), 'Rüya Analizi');
  });
}
