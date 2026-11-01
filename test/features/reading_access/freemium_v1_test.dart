/// Freemium V1 client experience: dark by default; only the exact server
/// daily-quota answer reads as "used today"; Premium comes from the
/// verified membership; Coffee V3 keeps its draft on a quota answer;
/// Fincan Haritası opens for members only and never deletes by itself.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/chamber_header_lead.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_rollback.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_surface.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v3/copy/coffee_v3_copy.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/presentation/coffee_v3_intro_view.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/cup_map/copy/coffee_cup_map_copy.dart';
import 'package:oracly_new/features/coffee/cup_map/models/coffee_cup_map_record.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_entry.dart';
import 'package:oracly_new/features/coffee/cup_map/providers/coffee_cup_map_providers.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/presentation/palm_landing_view.dart';
import 'package:oracly_new/features/palm/presentation/palm_tokens.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_daily_rights_section.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_hero_card.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/reading_access/copy/freemium_copy.dart';
import 'package:oracly_new/features/reading_access/freemium_rollout.dart';
import 'package:oracly_new/features/reading_access/models/reading_allowance.dart';
import 'package:oracly_new/features/reading_access/presentation/coffee_allowance_panel.dart';
import 'package:oracly_new/features/reading_access/presentation/palm_allowance_line.dart';
import 'package:oracly_new/features/reading_access/providers/reading_allowance_providers.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';

import '../../support/coffee_cup_map_test_support.dart';
import '../../support/coffee_v2_test_support.dart';
import '../../support/coffee_v3_test_support.dart';
import '../../support/fake_reading_operation_backend.dart';
import '../../support/freemium_test_support.dart';
import '../../support/layout_fonts.dart';

const _coffee = ReadingAllowanceKind.coffee;
const _palm = ReadingAllowanceKind.palm;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadLayoutFonts);
  setUp(() => OraclyL10n.bind('tr'));
  tearDown(resetFeatureFlags);

  group('rollout', () {
    test('dark by default: the flag, the surface and the build define', () {
      resetFeatureFlags();
      expect(ProductFeatureFlags.freemiumV1.defaultValue, isFalse);
      expect(ProductFeatureFlags.catalog, contains(ProductFeatureFlags.freemiumV1));
      expect(FreemiumRollout.buildRolloutEnabled, isFalse);
      expect(FreemiumRollout.enabled, isFalse);
      expect(
        FeatureFlagRollback.flag(FeatureFlagSurface.freemiumV1),
        ProductFeatureFlags.freemiumV1,
      );
      setFreemiumFlag(true);
      expect(FreemiumRollout.enabled, isTrue);
    });

    test('every Freemium string exists in TR, EN and RU', () {
      final keys = AppStringTables.all.keys.where((k) => k.startsWith('freemium.'));
      expect(keys.length, greaterThan(30));
      for (final key in keys) {
        final triple = AppStringTables.all[key]!;
        for (final code in ['tr', 'en', 'ru']) {
          OraclyL10n.bind(code);
          expect(OraclyL10n.t(key).trim(), isNotEmpty, reason: '$key/$code');
          expect(OraclyL10n.t(key), isNot(key), reason: '$key/$code');
        }
        expect(triple, isNotNull);
      }
    });

    test('no copy promises a better engine, a price or an ad', () {
      final banned = RegExp(
        r'(daha (iyi|kaliteli)|özel (yorum|motor)|yapay zek|\bAI\b|₺|TL\b|\$|reklam|better (AI|reading)|price|реклам)',
        caseSensitive: false,
      );
      for (final entry in AppStringTables.all.entries) {
        if (!entry.key.startsWith('freemium.')) continue;
        for (final code in ['tr', 'en', 'ru']) {
          OraclyL10n.bind(code);
          expect(banned.hasMatch(OraclyL10n.t(entry.key)), isFalse,
              reason: '${entry.key}/$code');
        }
      }
    });
  });

  group('only the exact server answer is "used today"', () {
    test('429 + the kind\'s own code', () {
      expect(isDailyQuotaAnswer(_coffee, httpStatus: 429, backendCode: 'coffee_daily_quota'), isTrue);
      expect(isDailyQuotaAnswer(_palm, httpStatus: 429, backendCode: 'palm_daily_quota'), isTrue);
    });

    test('rate limits, outages, lost connections and other kinds are not', () {
      expect(isDailyQuotaAnswer(_coffee, httpStatus: 429, backendCode: 'rate_limited'), isFalse);
      expect(isDailyQuotaAnswer(_coffee, httpStatus: 429, backendCode: null), isFalse);
      expect(isDailyQuotaAnswer(_coffee, httpStatus: 503, backendCode: 'coffee_daily_quota'), isFalse);
      expect(isDailyQuotaAnswer(_coffee, httpStatus: null, backendCode: null), isFalse);
      expect(isDailyQuotaAnswer(_coffee, httpStatus: 429, backendCode: 'palm_daily_quota'), isFalse);
      expect(isDailyQuotaAnswer(_palm, httpStatus: 403, backendCode: 'reading_entitlement_required'), isFalse);
    });
  });

  group('allowance view', () {
    ReadingAllowanceView view({
      bool loaded = true,
      bool busy = false,
      bool premium = false,
      PremiumEntitlementState entitlement = PremiumEntitlementState.inactive,
      bool used = false,
    }) =>
        resolveReadingAllowance(
          kind: _coffee,
          loaded: loaded,
          busy: busy,
          isPremium: premium,
          entitlement: entitlement,
          usedToday: used,
        );

    test('membership decides the tier; nothing claims an unused reading', () {
      expect(view().status, ReadingAllowanceStatus.free);
      expect(view(entitlement: PremiumEntitlementState.unavailable).status, ReadingAllowanceStatus.free);
      expect(view(entitlement: PremiumEntitlementState.unverified).status, ReadingAllowanceStatus.free);
      expect(view(premium: true).status, ReadingAllowanceStatus.premium);
      expect(view(loaded: false).status, ReadingAllowanceStatus.checking);
      expect(view(loaded: false, premium: true).status, ReadingAllowanceStatus.checking,
          reason: 'an unloaded controller is never trusted as Premium');
      expect(view(busy: true).status, ReadingAllowanceStatus.checking);
      expect(view(entitlement: PremiumEntitlementState.error).status, ReadingAllowanceStatus.checkFailed);
      expect(view(used: true).status, ReadingAllowanceStatus.usedToday);
      expect(view(used: true).canStart, isFalse);
      expect(view(used: true, premium: true).premium, isTrue);
      for (final s in [view(), view(premium: true), view(loaded: false), view(entitlement: PremiumEntitlementState.error)]) {
        expect(s.canStart, isTrue);
      }
    });

    test('a server answer lasts for its own UTC day only; clear forgets it', () {
      var now = DateTime.utc(2026, 11, 1, 23, 58);
      final signals = ReadingAllowanceSignals(now: () => now);
      signals.markUsed(_coffee);
      expect(signals.usedToday(_coffee), isTrue);
      expect(signals.usedToday(_palm), isFalse);
      now = DateTime.utc(2026, 11, 2, 0, 1);
      expect(signals.usedToday(_coffee), isFalse);
      signals.markUsed(_palm);
      signals.clear(_palm);
      expect(signals.usedToday(_palm), isFalse);
    });

    test('a new owner starts with no answers (account switch)', () {
      final container = ProviderContainer(overrides: [
        premiumStatusProvider.overrideWith((ref) => FakePremiumStatus()),
      ]);
      addTearDown(container.dispose);
      container.read(readingAllowanceSignalsProvider).markUsed(_coffee);
      expect(container.read(readingAllowanceProvider(_coffee)).status, ReadingAllowanceStatus.usedToday);
      container.invalidate(readingAllowanceSignalsProvider);
      expect(container.read(readingAllowanceProvider(_coffee)).status, ReadingAllowanceStatus.free);
    });
  });

  group('Coffee V3 create answers', () {
    late Directory temp;
    late CoffeeV3TestTransport transport;
    var sizeSeed = 9100;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('freemium_v3_');
      installCoffeeV3SupportRoot(temp.path);
      transport = CoffeeV3TestTransport(
        FakeReadingOperationBackend(immediatelyEligible: false),
        chronology: [],
      );
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    Future<CoffeeV3SubmissionController> filled() async {
      final c = CoffeeV3SubmissionController(
        flow: ReadingLiveFlow(
          operations: ReadingOperationGateway(send: transport.send),
          acceleration: ReadingAccelerationClient(send: transport.send),
          send: transport.send,
        ),
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: CoffeeV3SubmissionStore(
          LocalStorage.ephemeral(),
          ownerId: 'owner-freemium',
          requireOwner: true,
        ),
        byteLoader: RecordingByteLoader([]),
        normalizer: ownedCoffeeV3Normalizer(temp.path),
        messages: coffeeV3TestMessages,
        creationAllowed: () => true,
        newSourceRequestId: () => 'coffee-v3-freemium-src',
      );
      for (final slot in coffeeV3CanonicalSlotOrder) {
        final file = File('${temp.path}/${slot.wireValue}.jpg');
        await file.writeAsBytes(plainJpegBytes(totalSize: sizeSeed += 41));
        final r = await c.selectSlot(
          slot,
          CoffeeImagePick(path: file.path, mimeType: 'image/jpeg'),
        );
        expect(r.isSuccess, isTrue);
      }
      await c.setIntention('Aşk ve ilişkilerim hakkında');
      return c;
    }

    test('on: the quota answer keeps the draft, the request id and stages nothing', () async {
      setFreemiumFlag(true);
      transport.createError = (status: 429, code: 'coffee_daily_quota');
      final c = await filled();
      expect(await c.beginSubmission(), CoffeeV3SubmissionOutcome.dailyQuota);
      expect(c.record.isDraft, isTrue);
      expect(c.record.operationId, isNull);
      expect(c.record.sourceRequestId, 'coffee-v3-freemium-src');
      expect(transport.calls.where((call) => call.path.contains('/stage')), isEmpty);
      for (final slot in coffeeV3CanonicalSlotOrder) {
        expect(c.assetFor(slot), isNotNull, reason: 'three photos kept');
      }
    });

    test('off: the same answer behaves exactly as before (retryable)', () async {
      setFreemiumFlag(false);
      transport.createError = (status: 429, code: 'coffee_daily_quota');
      final c = await filled();
      expect(await c.beginSubmission(), CoffeeV3SubmissionOutcome.retryableFailure);
    });

    test('on: a rate limit or an outage is never "used today"', () async {
      setFreemiumFlag(true);
      for (final error in [
        (status: 429, code: 'rate_limited'),
        (status: 503, code: 'no_configuration'),
        (status: 429, code: 'palm_daily_quota'),
      ]) {
        transport.createError = error;
        final c = await filled();
        expect(await c.beginSubmission(), CoffeeV3SubmissionOutcome.retryableFailure,
            reason: error.code);
      }
    });

    test('on: the existing credit answer is unchanged', () async {
      setFreemiumFlag(true);
      transport.createError = (status: 403, code: 'reading_entitlement_required');
      final c = await filled();
      expect(await c.beginSubmission(), CoffeeV3SubmissionOutcome.entitlementRequired);
    });
  });

  group('surfaces', () {
    Widget host(Widget child, {FakePremiumStatus? premium, double scale = 1, List<Override> extra = const []}) {
      return ProviderScope(
        overrides: [
          premiumStatusProvider.overrideWith((ref) => premium ?? FakePremiumStatus()),
          ...extra,
        ],
        child: MaterialApp(
          theme: robotoDarkTheme(),
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: c!,
          ),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    testWidgets('intro: flag off is unchanged (no allowance, original CTA)', (tester) async {
      await tester.pumpWidget(host(CoffeeV3IntroView(onStart: () {})));
      expect(find.text(CoffeeV3Copy.introCta), findsOneWidget);
      expect(find.text(FreemiumCopy.freeTitle(_coffee)), findsNothing);
    });

    testWidgets('coffee plate: free shows the policy, never "ready"', (tester) async {
      await tester.pumpWidget(host(const CoffeeAllowancePanel(
        view: ReadingAllowanceView(kind: _coffee, status: ReadingAllowanceStatus.free, premium: false),
      )));
      expect(find.text(FreemiumCopy.freeTitle(_coffee)), findsOneWidget);
      expect(find.text(FreemiumCopy.freeNote), findsOneWidget);
      expect(find.textContaining('hazır'), findsNothing);
    });

    testWidgets('used card: Premium offer only for non-members; check again clears', (tester) async {
      var rechecked = 0;
      await tester.pumpWidget(host(CoffeeAllowanceUsedCard(
        view: const ReadingAllowanceView(kind: _coffee, status: ReadingAllowanceStatus.usedToday, premium: false),
        onRecheck: () => rechecked++,
      )));
      expect(find.text(FreemiumCopy.usedTitle(_coffee, premium: false)), findsOneWidget);
      expect(find.text(FreemiumCopy.seePremium), findsOneWidget);
      await tester.tap(find.text(FreemiumCopy.recheck));
      expect(rechecked, 1);
      await tester.pumpWidget(host(CoffeeAllowanceUsedCard(
        view: const ReadingAllowanceView(kind: _coffee, status: ReadingAllowanceStatus.usedToday, premium: true),
        onRecheck: () {},
      )));
      expect(find.text(FreemiumCopy.usedTitle(_coffee, premium: true)), findsOneWidget);
      expect(find.text(FreemiumCopy.seePremium), findsNothing);
    });

    testWidgets('membership failure offers a retry of the membership read', (tester) async {
      final premium = FakePremiumStatus(entitlement: PremiumEntitlementState.error);
      await tester.pumpWidget(host(
        const PalmAllowanceLine(
          view: ReadingAllowanceView(kind: _palm, status: ReadingAllowanceStatus.checkFailed, premium: false),
        ),
        premium: premium,
      ));
      await tester.tap(find.text(FreemiumCopy.retry));
      expect(premium.refreshes, 1);
    });

    testWidgets('Premium daily rights: facts only, same care stated', (tester) async {
      await tester.pumpWidget(host(const PremiumDailyRightsSection(active: false)));
      for (final text in [
        FreemiumCopy.premiumCoffeeTitle,
        FreemiumCopy.premiumPalmTitle,
        FreemiumCopy.premiumInstantTitle,
        FreemiumCopy.premiumCupMapTitle,
        FreemiumCopy.premiumSameCare,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('no overflow at $width px and 2x text', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(host(
          Column(children: [
            const CoffeeAllowancePanel(
              view: ReadingAllowanceView(kind: _coffee, status: ReadingAllowanceStatus.free, premium: false),
            ),
            CoffeeAllowanceUsedCard(
              view: const ReadingAllowanceView(kind: _coffee, status: ReadingAllowanceStatus.usedToday, premium: false),
              onRecheck: () {},
            ),
            const PalmAllowanceLine(
              view: ReadingAllowanceView(kind: _palm, status: ReadingAllowanceStatus.free, premium: false),
            ),
            const PremiumDailyRightsSection(active: false),
          ]),
          scale: 2,
        ));
        expect(tester.takeException(), isNull);
      });
    }

    group('Fincan Haritası door', () {
      late Directory temp;
      late CoffeeCupMapStore store;
      const reading = 'coffee-v3-freemium-door';

      setUp(() async {
        temp = await Directory.systemTemp.createTemp('freemium_door_');
        await installCupMapPaths(temp);
        store = CoffeeCupMapStore(await ownedStorage('owner-door'));
        await store.createIfAbsent(
          ownerId: 'owner-door',
          readingId: reading,
          photos: [
            for (final slot in coffeeV3CanonicalSlotOrder)
              CoffeeCupMapPhoto(
                slot: slot,
                path: await keptCupMapPhoto(reading, slot),
                sha256: 'fixture',
              ),
          ],
        );
      });

      tearDown(() async {
        try {
          if (await temp.exists()) await temp.delete(recursive: true);
        } catch (_) {
          // A decoded photo may still hold its file on Windows; scratch only.
        }
      });

      Future<void> pumpDoor(
        WidgetTester tester,
        FakePremiumStatus premium, {
        Size size = const Size(390, 900),
        double scale = 1,
      }) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(host(
          const CoffeeCupMapEntry(readingId: reading),
          premium: premium,
          scale: scale,
          extra: [coffeeCupMapStoreProvider.overrideWithValue(store)],
        ));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      testWidgets('off: the approved door for everyone', (tester) async {
        setFreemiumFlag(false);
        await pumpDoor(tester, FakePremiumStatus());
        expect(find.text(CoffeeCupMapCopy.entryOpen), findsOneWidget);
        expect(find.text(FreemiumCopy.cupMapLockedBody), findsNothing);
      });

      testWidgets('on + member: the approved door', (tester) async {
        setFreemiumFlag(true);
        await pumpDoor(tester, FakePremiumStatus(premium: true));
        expect(find.text(CoffeeCupMapCopy.entryOpen), findsOneWidget);
      });

      testWidgets('on + loading: no door opens, no lock is claimed', (tester) async {
        setFreemiumFlag(true);
        await pumpDoor(tester, FakePremiumStatus(loaded: false));
        expect(find.text(CoffeeCupMapCopy.entryOpen), findsNothing);
        expect(find.text(FreemiumCopy.cupMapChecking), findsOneWidget);
        expect(find.text(FreemiumCopy.cupMapDelete), findsNothing);
      });

      testWidgets('on + failed read: retry, and the photos can still be removed', (tester) async {
        setFreemiumFlag(true);
        final premium = FakePremiumStatus(entitlement: PremiumEntitlementState.error);
        await pumpDoor(tester, premium);
        expect(find.text(FreemiumCopy.cupMapCheckFailed), findsOneWidget);
        await tester.tap(find.text(FreemiumCopy.retry));
        expect(premium.refreshes, 1);
        expect(find.text(FreemiumCopy.cupMapDelete), findsOneWidget);
      });

      testWidgets('on + not a member: locked, kept, removable only on confirm', (tester) async {
        setFreemiumFlag(true);
        await pumpDoor(tester, FakePremiumStatus());
        expect(find.text(FreemiumCopy.cupMapLockedBody), findsOneWidget);
        expect(find.text(CoffeeCupMapCopy.entryOpen), findsNothing);
        final pill = find.bySemanticsLabel(FreemiumCopy.cupMapLockedCta);
        expect(pill, findsOneWidget);
        expect(tester.getSize(pill).height, greaterThanOrEqualTo(48));
        // Nothing is deleted by being locked.
        expect(await store.load(reading), isNotNull);
        await tester.tap(find.text(FreemiumCopy.cupMapDelete));
        await tester.pumpAndSettle();
        await tester.tap(find.text(FreemiumCopy.cupMapDeleteCancel));
        await tester.pumpAndSettle();
        expect(await store.load(reading), isNotNull, reason: 'cancel keeps everything');
        await tester.tap(find.text(FreemiumCopy.cupMapDelete));
        await tester.pumpAndSettle();
        await tester.tap(find.text(FreemiumCopy.cupMapDeleteConfirm));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();
        expect(await tester.runAsync(() => store.load(reading)), isNull);
      });

      group('photo labels (PO round)', () {
        bool exceeded(WidgetTester tester, String text) => tester
            .renderObject<RenderParagraph>(find.descendant(
              of: find.byType(CoffeeCupMapEntry),
              matching: find.byWidgetPredicate(
                (w) => w is RichText && w.text.toPlainText() == text,
              ),
            ))
            .didExceedMaxLines;

        for (final width in [320.0, 360.0, 390.0]) {
          for (final scale in [1.0, 2.0]) {
            for (final member in [false, true]) {
              testWidgets('$width px, ${scale}x, ${member ? 'member' : 'locked'}: no cut label, full names read',
                  (tester) async {
                setFreemiumFlag(true);
                final handle = tester.ensureSemantics();
                await pumpDoor(
                  tester,
                  FakePremiumStatus(premium: member),
                  size: Size(width, 1600),
                  scale: scale,
                );
                expect(tester.takeException(), isNull);
                final full = find.text('Fincan 1').evaluate().isNotEmpty;
                if (full) {
                  for (final label in ['Fincan 1', 'Fincan 2']) {
                    expect(exceeded(tester, label), isFalse, reason: label);
                  }
                } else {
                  expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
                  for (final label in ['1', '2']) {
                    expect(exceeded(tester, label), isFalse, reason: label);
                  }
                }
                expect(exceeded(tester, 'Tabak'), isFalse);
                for (final label in ['Fincan 1', 'Fincan 2', 'Tabak']) {
                  expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
                }
                handle.dispose();
              });
            }
          }
        }

        testWidgets('320 px at 2x uses the short labels; 390 px at 1x keeps the full ones', (tester) async {
          setFreemiumFlag(true);
          await pumpDoor(tester, FakePremiumStatus(), size: const Size(320, 1600), scale: 2);
          expect(find.text('Fincan 1'), findsNothing);
          expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
          await pumpDoor(tester, FakePremiumStatus(), size: const Size(390, 1600));
          expect(find.text('Fincan 1'), findsOneWidget);
          expect(find.text('Fincan 2'), findsOneWidget);
        });
      });
    });

    group('El Falı landing (PO round)', () {
      Widget landing({required VoidCallback onCamera, required VoidCallback onGallery, double scale = 1}) {
        return ProviderScope(
          overrides: [premiumStatusProvider.overrideWith((ref) => FakePremiumStatus())],
          child: MaterialApp(
            theme: robotoDarkTheme(),
            builder: (context, c) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: c!,
            ),
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PalmTokens.screenHorizontal,
                    PalmTokens.screenTop,
                    PalmTokens.screenHorizontal,
                    16,
                  ),
                  child: PalmLandingView(
                    hand: PalmHand.right,
                    onHand: (_) {},
                    onCamera: onCamera,
                    onGallery: onGallery,
                    allowance: const PalmAllowanceLine(
                      view: ReadingAllowanceView(kind: _palm, status: ReadingAllowanceStatus.free, premium: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      for (final locale in ['tr', 'en', 'ru']) {
        for (final width in [320.0, 360.0, 390.0]) {
          for (final scale in [1.0, 2.0]) {
            testWidgets('$locale $width px ${scale}x: the opening line is never cut', (tester) async {
              setFreemiumFlag(true);
              OraclyL10n.bind(locale);
              await tester.binding.setSurfaceSize(Size(width, 640));
              addTearDown(() => tester.binding.setSurfaceSize(null));
              await tester.pumpWidget(landing(onCamera: () {}, onGallery: () {}, scale: scale));
              await tester.pump();
              expect(tester.takeException(), isNull);
              final line = tester.renderObject<RenderParagraph>(find.descendant(
                of: find.byType(ChamberHeaderLead),
                matching: find.byType(RichText),
              ));
              expect(line.didExceedMaxLines, isFalse, reason: PalmCopy.landingLine);
            });
          }
        }
      }

      for (final size in [const Size(320, 568), const Size(320, 640), const Size(360, 740), const Size(390, 844)]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} at 2x: the whole camera button scrolls into view and taps', (tester) async {
          setFreemiumFlag(true);
          final handle = tester.ensureSemantics();
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          var camera = 0;
          var gallery = 0;
          await tester.pumpWidget(landing(
            onCamera: () => camera++,
            onGallery: () => gallery++,
            scale: 2,
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final button = find.byType(OraclyGoldButton);
          expect(button, findsOneWidget);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          final viewport = tester.getRect(find.byType(Scrollable).first);
          final rect = tester.getRect(button);
          expect(rect.top, greaterThanOrEqualTo(viewport.top - 0.5));
          expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
          expect(rect.height, greaterThanOrEqualTo(48));
          final label = tester.renderObject<RenderParagraph>(find.descendant(
            of: button,
            matching: find.text(PalmCopy.landingCameraLabel),
          ));
          expect(label.didExceedMaxLines, isFalse);
          await tester.tap(button);
          await tester.pump();
          expect(camera, 1);
          final node = tester.getSemantics(find.bySemanticsLabel(PalmCopy.landingCameraLabel));
          expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
          await tester.ensureVisible(find.text(PalmCopy.galleryLabel));
          await tester.pumpAndSettle();
          await tester.tap(find.text(PalmCopy.galleryLabel));
          await tester.pump();
          expect(gallery, 1);
          handle.dispose();
        });
      }
    });

    group('Premium hero line (PO round)', () {
      testWidgets('on: states the daily model, no quality claim; off: the shipped line', (tester) async {
        setFreemiumFlag(true);
        await tester.pumpWidget(host(const PremiumReferenceHeroCard()));
        expect(find.text(FreemiumCopy.premiumHeroLead), findsOneWidget);
        expect(find.text(PremiumCopy.heroLead), findsNothing);
        for (final locale in ['tr', 'en', 'ru']) {
          OraclyL10n.bind(locale);
          final line = FreemiumCopy.premiumHeroLead.toLowerCase();
          for (final banned in ['daha iyi', 'özel yorum', 'better', 'special', 'лучше', 'особ']) {
            expect(line.contains(banned), isFalse, reason: '$locale: $banned');
          }
        }
        OraclyL10n.bind('tr');
        expect(FreemiumCopy.premiumHeroLead, contains('ücretsiz'));
        expect(FreemiumCopy.premiumHeroLead, contains('iki'));
        setFreemiumFlag(false);
        await tester.pumpWidget(host(const PremiumReferenceHeroCard(key: ValueKey('off'))));
        expect(find.text(PremiumCopy.heroLead), findsOneWidget);
        expect(find.text(FreemiumCopy.premiumHeroLead), findsNothing);
      });
    });
  });
}
