/// P1 — Preview vs live truth matrix for ritual features.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/preview_capability_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/universe/oracly_tab_labels.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_kind_note.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Astrology is LOCAL catalogue LIVE - never live sky AI', () {
    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.astrology)!.isLive, isTrue);
    expect(AstrologyReferenceKindNote.label, PreviewCapabilityCopy.astrologyLabel);
    expect(AstrologyReferenceKindNote.label.toLowerCase(), isNot(contains('önizleme')));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), contains('yansıma'));
    expect(OraclyL10n.t('astro.live').toLowerCase(), contains('burç'));
    expect(OraclyL10n.t('astro.live').toLowerCase(), isNot(contains('gökyüzü')));
  });

  test('Yildizname is LOCAL archive - not preview of live AI', () {
    expect(StarMapPolishCopy.capabilityNote.toLowerCase(), contains('sembolik'));
    expect(OraclyTab.starMap.universeHint.toLowerCase(), contains('yerel'));
    final starSub = OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)!.subtitle!;
    expect(starSub.toLowerCase(), contains('yerel'));
  });

  test('Dream notes match LOCAL / LIVE / UNAVAILABLE', () {
    expect(
      DreamCopy.capabilityNote(aiConfigured: false, allowsLocalFallback: true),
      DreamCopy.previewNote,
    );
    expect(DreamCopy.previewNote.toLowerCase(), contains('katalog'));
    expect(
      DreamCopy.capabilityNote(aiConfigured: true, allowsLocalFallback: false),
      DreamCopy.previewNoteLive,
    );
    expect(DreamCopy.previewNoteLive.toLowerCase(), isNot(contains('önizleme')));
    expect(
      DreamCopy.capabilityNote(aiConfigured: false, allowsLocalFallback: false),
      DreamCopy.previewNoteNeedsOr,
    );
  });

  test('Tarot default reading is LOCAL catalogue', () {
    expect(TarotPolishCopy.sourceLocal.toLowerCase(), contains('katalog'));
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false),
      startsWith(TarotPolishCopy.sourceLocal),
    );
    expect(OraclyL10n.t('tarot.interpreting.1').toLowerCase(), contains('katalog'));
  });

  test('Coffee / Palm unavailable copy is UNAVAILABLE, not Preview', () {
    expect(CoffeeCopy.capabilityNote.toLowerCase(), contains('or'));
    expect(CoffeeCopy.capabilityNote.toLowerCase(), isNot(contains('önizleme')));
    expect(CoffeeCopy.sourceNote.toLowerCase(), contains('or'));
    expect(PalmCopy.capabilityNote.toLowerCase(), contains('or'));
    expect(PalmCopy.capabilityNote.toLowerCase(), isNot(contains('önizleme')));
    expect(PalmCopy.sourceNote.toLowerCase(), contains('or'));
  });

  test('SoulMate locked/unavailable strings do not claim a working draw', () {
    final unavailable = OraclyL10n.t('soulmate.unavailable').toLowerCase();
    final premium = OraclyL10n.t('soulmate.premium_required').toLowerCase();
    expect(
      unavailable.contains('oluşturamadım') || unavailable.contains('could not'),
      isTrue,
    );
    expect(premium, contains('premium'));
  });
}
