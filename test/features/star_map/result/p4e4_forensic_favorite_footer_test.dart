/// P4E.4 — production footer stays on Wrap; forensic footer keeps the row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_colors.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_footer.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_footer_forensic.dart';
import 'package:oracly_new/features/star_map/result/yildizname_favorite_action.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions.dart';

import '../../../test_helpers/provider_scope_harness.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('production footer leaves the live wrap', (tester) async {
    await _pump(tester, StarMapResultFooter(actions: _actions()));
    expect(_link(tester).forensicLegacyRow, isFalse);
    expect(_layout<Wrap>(tester), findsOneWidget);
    expect(_layout<Row>(tester), findsNothing);
  });

  testWidgets('forensic footer requests the legacy row', (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => Column(
          children: StarMapResultFooterForensic.actionCluster(
            actions: _actions(),
            palette: AppColors.of(context),
            feedback: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    expect(_link(tester).forensicLegacyRow, isTrue);
    expect(_layout<Row>(tester), findsOneWidget);
    expect(_layout<Wrap>(tester), findsNothing);
  });
}

SaveFavoriteMomentLink _link(WidgetTester tester) {
  return tester.widget<SaveFavoriteMomentLink>(
    find.byType(SaveFavoriteMomentLink),
  );
}

Finder _layout<T extends Widget>(WidgetTester tester) {
  return find.descendant(
    of: find.byType(SaveFavoriteMomentLink),
    matching: find.byType(T),
  );
}

YildiznameResultActions _actions() {
  return YildiznameResultActions(
    canonicalInsight: 'Sakin bir iz.',
    copyText: 'Sakin bir iz.',
    share: DiscoveryShareBuilder.starMap(),
    favorite: YildiznameFavoriteAction(
      artifactId: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      occurredAt: DateTime.utc(2026, 1, 10),
      title: 'Gökyüzü',
      insight: 'Sakin bir iz.',
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  final storage = await yildiznameVisualOpenStorage();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: MaterialApp(theme: AppTheme.dark, home: home),
    ),
  );
  await tester.pump();
}
