/// Home discovery grid — seven core doors, master order.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_module_visual.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('home modules match seven discovery doors', () {
    final modules = HomeReferenceModules.list();
    expect(modules, hasLength(7));
    expect(modules.map((m) => m.id).toList(), [
      OraclyFeatureId.coffee,
      OraclyFeatureId.palm,
      OraclyFeatureId.astrology,
      OraclyFeatureId.starMap,
      OraclyFeatureId.soulMate,
      OraclyFeatureId.tarot,
      OraclyFeatureId.dream,
    ]);
    expect(modules.map((m) => HomeDiscoveryCopy.title(m.id)).toList(), [
      'Kahve Falı',
      'El Falı',
      'Astroloji',
      'Yıldızname',
      'Ruh Eşi',
      'Tarot',
      'Rüya Analizi',
    ]);
    expect(modules.last.visual, HomeModuleVisual.dream);
    expect(modules.last.isNew, isTrue);
  });
}
