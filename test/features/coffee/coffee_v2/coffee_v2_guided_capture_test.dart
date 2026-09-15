/// Coffee V2 guided-capture UX — Phase 2C2 §29-§33 required widget tests
/// (A-AM). Zero real provider/network calls: `readingOperationSenderProvider`
/// is overridden with a fully in-memory fake backend, and every photo
/// selection goes through a scripted fake `CoffeeImageInputPort` — never
/// the real `image_picker`/camera platform channel.
///
/// Real `dart:io` file work (normalization/checksum/byte-loading) still
/// runs for real against fixture files on disk. In this test environment,
/// awaiting that work directly inside a `testWidgets` body — or relying on
/// a widget's fire-and-forget `onPressed` handler to finish it before the
/// next plain `pump()` — never resolves; `tester.runAsync` combined with
/// interleaved real delays and pumps is required, matching the pattern
/// `test/visual/hub_reference_capture_test.dart` already uses for its own
/// real-async `toImage()` step. `drain`/`tapAndDrain` below encapsulate
/// that pattern once for every call site that touches real files.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/copy/coffee_v2_copy.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_asset.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_submission_record.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_thumbnail.dart';
import 'package:oracly_new/features/coffee/coffee_v2/providers/coffee_v2_providers.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_checksum.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_pick_exception.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

class _ScriptedCoffeeImages implements CoffeeImageInputPort {
  String? nextPath;
  String? nextError;

  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;

  @override
  Future<CoffeeImagePick?> pickFromCamera() => _pick();
  @override
  Future<CoffeeImagePick?> pickFromGallery() => _pick();

  Future<CoffeeImagePick?> _pick() async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw CoffeeImagePickException(error);
    }
    final path = nextPath;
    nextPath = null;
    if (path == null) return null;
    return CoffeeImagePick(path: path, mimeType: 'image/jpeg');
  }
}

class _FakeCompletedAnalysis
    implements CoffeeAnalysisPort, CoffeeCompletedAnalysisPort {
  const _FakeCompletedAnalysis();

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    throw StateError('unused in Coffee V2 — analysis is server-owned');
  }

  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) {
    return CoffeeReading.fromJson({
      ...result,
      'id': resultId,
      'createdAt': persistedAt.toIso8601String(),
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late FakeReadingOperationBackend backend;
  late LocalStorage storage;
  late _ScriptedCoffeeImages images;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_guided_capture_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    backend = FakeReadingOperationBackend();
    images = _ScriptedCoffeeImages();
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// Lets real `dart:io`/isolate-driven async work started earlier (a
  /// fire-and-forget widget callback, a provider's un-awaited `boot()`)
  /// actually complete, then reflects it in the widget tree.
  Future<void> drain(WidgetTester tester, {int iterations = 15}) async {
    await tester.runAsync(() async {
      for (var i = 0; i < iterations; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });
  }

  /// A tap whose handler does real file I/O (normalize/checksum/byte-load)
  /// needs the tap itself inside the SAME `runAsync` block as the drain —
  /// otherwise the tap's fire-and-forget Future is orphaned relative to
  /// plain `pump()` calls made outside `runAsync`.
  Future<void> tapAndDrain(
    WidgetTester tester,
    Finder finder, {
    int iterations = 20,
  }) async {
    await tester.ensureVisible(finder);
    await tester.runAsync(() async {
      await tester.tap(finder);
      for (var i = 0; i < iterations; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });
  }

  Future<String> writeJpeg(
    WidgetTester tester,
    String name, {
    int totalSize = 20 * 1024,
  }) async {
    final result = await tester.runAsync(() async {
      final path = '${temp.path}/$name';
      await File(path).writeAsBytes(plainJpegBytes(totalSize: totalSize));
      return path;
    });
    return result!;
  }

  Future<int> fileLength(WidgetTester tester, String path) async {
    final result = await tester.runAsync(() => File(path).length());
    return result!;
  }

  Future<String> checksum(WidgetTester tester, String path) async {
    return (await tester.runAsync(() => CoffeeV2Checksum.sha256OfFile(path)))!;
  }

  Widget app({ReadingOperationSender? send, CoffeeAnalysisPort? analysis}) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        coffeeV2SubmissionStoreProvider.overrideWithValue(
          CoffeeV2SubmissionStore(
            storage,
            ownerId: 'coffee-v2-widget-owner',
            requireOwner: true,
          ),
        ),
        readingOperationSenderProvider.overrideWithValue(send ?? backend.send),
        coffeeImageInputProvider.overrideWithValue(images),
        coffeeAnalysisProvider.overrideWithValue(
          analysis ?? const _FakeCompletedAnalysis(),
        ),
      ],
      child: const MaterialApp(home: CoffeeV2FlowScreen()),
    );
  }

  CoffeeV2SubmissionRecord recordOf(WidgetTester tester) {
    return ProviderScope.containerOf(
      tester.element(find.byType(CoffeeV2FlowScreen)),
    ).read(coffeeV2FlowControllerProvider).record;
  }

  Future<void> pumpFresh(WidgetTester tester, {Widget? widget}) async {
    await tester.pumpWidget(widget ?? app());
    await tester.pump();
    // Lets the provider's fire-and-forget `boot()` (which may validate a
    // recovered DRAFT's real files) actually finish before assertions.
    // Recovery validates confirmed files sequentially (existence, size,
    // streaming checksum), so complete three-slot drafts need a wider
    // real-async window than a fresh/one-slot draft.
    await drain(tester, iterations: 30);
  }

  /// Gallery selection itself never touches real files (the scripted
  /// fake just returns a path) — only "Bu fotoğrafı kullan" does, via
  /// `setSlot`'s real normalize/checksum work.
  Future<void> pickAndUse(WidgetTester tester, String path) async {
    images.nextPath = path;
    final gallery = find.text(CoffeeV2Copy.actionPickGallery);
    await tester.ensureVisible(gallery);
    await tester.tap(gallery);
    await tester.pump();
    await tester.pump();
    await tapAndDrain(tester, find.text(CoffeeV2Copy.previewUse));
  }

  Future<void> tapGallery(WidgetTester tester) async {
    final gallery = find.text(CoffeeV2Copy.actionPickGallery);
    await tester.ensureVisible(gallery);
    await tester.tap(gallery);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
  }

  Future<void> reachStep2(WidgetTester tester, {String? primaryPath}) async {
    await pumpFresh(tester);
    await tester.tap(find.text(CoffeeV2Copy.introCta));
    await tester.pump();
    final path =
        primaryPath ?? await writeJpeg(tester, 'primary.jpg', totalSize: 20001);
    await pickAndUse(tester, path);
  }

  Future<void> reachStep3(
    WidgetTester tester, {
    String? primaryPath,
    String? secondaryPath,
  }) async {
    await reachStep2(tester, primaryPath: primaryPath);
    final path =
        secondaryPath ??
        await writeJpeg(tester, 'secondary.jpg', totalSize: 20101);
    await pickAndUse(tester, path);
  }

  Future<void> reachFinalReview(
    WidgetTester tester, {
    String? primaryPath,
    String? secondaryPath,
    String? saucerPath,
  }) async {
    await reachStep3(
      tester,
      primaryPath: primaryPath,
      secondaryPath: secondaryPath,
    );
    final path =
        saucerPath ?? await writeJpeg(tester, 'saucer.jpg', totalSize: 20201);
    await pickAndUse(tester, path);
  }

  group('Flow (A-L)', () {
    testWidgets('A — Intro renders exact locked explanation', (tester) async {
      await pumpFresh(tester);
      expect(find.text(CoffeeV2Copy.introTitle), findsOneWidget);
      expect(find.text(CoffeeV2Copy.introBody), findsOneWidget);
      expect(find.text(CoffeeV2Copy.introCta), findsOneWidget);
    });

    testWidgets('B — Intro -> Step 1', (tester) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      expect(find.text(CoffeeV2Copy.stepTitlePrimary), findsOneWidget);
    });

    testWidgets('C — Step 1 shows 1/3 and exact guidance', (tester) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepInstructionPrimary), findsOneWidget);
    });

    testWidgets('D — Step 2 shows 2/3 and half-turn/unseen-side guidance', (
      tester,
    ) async {
      await reachStep2(tester);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepTitleSecondary), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepInstructionSecondary), findsOneWidget);
    });

    testWidgets('E — Step 3 shows 3/3 and saucer guidance', (tester) async {
      await reachStep3(tester);
      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepTitleSaucer), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepInstructionSaucer), findsOneWidget);
    });

    testWidgets('F — selecting a photo only opens temporary preview', (
      tester,
    ) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      final path = await writeJpeg(tester, 'primary.jpg', totalSize: 20001);
      images.nextPath = path;
      await tapGallery(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text(CoffeeV2Copy.previewUse), findsOneWidget);
      expect(find.text(CoffeeV2Copy.previewRetake), findsOneWidget);
    });

    testWidgets('G — candidate is not committed before confirmation', (
      tester,
    ) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      final path = await writeJpeg(tester, 'primary.jpg', totalSize: 20001);
      images.nextPath = path;
      await tapGallery(tester);
      await tester.pump();
      await tester.pump();
      final record = recordOf(tester);
      expect(record.slots[CoffeeV2PhotoSlot.cupPrimary]?.confirmed, isFalse);
    });

    testWidgets('H — confirming step 1 commits only cup_primary', (
      tester,
    ) async {
      await reachStep2(tester);
      final record = recordOf(tester);
      expect(record.slots[CoffeeV2PhotoSlot.cupPrimary]?.confirmed, isTrue);
      expect(record.slots[CoffeeV2PhotoSlot.cupSecondary]?.confirmed, isFalse);
      expect(record.slots[CoffeeV2PhotoSlot.saucer]?.confirmed, isFalse);
    });

    testWidgets('I — confirming step 2 commits only cup_secondary', (
      tester,
    ) async {
      await reachStep3(tester);
      final record = recordOf(tester);
      expect(record.slots[CoffeeV2PhotoSlot.cupPrimary]?.confirmed, isTrue);
      expect(record.slots[CoffeeV2PhotoSlot.cupSecondary]?.confirmed, isTrue);
      expect(record.slots[CoffeeV2PhotoSlot.saucer]?.confirmed, isFalse);
    });

    testWidgets('J — confirming step 3 commits only saucer', (tester) async {
      await reachFinalReview(tester);
      final record = recordOf(tester);
      expect(record.slots[CoffeeV2PhotoSlot.cupPrimary]?.confirmed, isTrue);
      expect(record.slots[CoffeeV2PhotoSlot.cupSecondary]?.confirmed, isTrue);
      expect(record.slots[CoffeeV2PhotoSlot.saucer]?.confirmed, isTrue);
    });

    testWidgets('K — each confirmation advances correctly', (tester) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      expect(find.text(CoffeeV2Copy.stepTitlePrimary), findsOneWidget);
      await pickAndUse(
        tester,
        await writeJpeg(tester, 'p.jpg', totalSize: 20001),
      );
      expect(find.text(CoffeeV2Copy.stepTitleSecondary), findsOneWidget);
      await pickAndUse(
        tester,
        await writeJpeg(tester, 's.jpg', totalSize: 20101),
      );
      expect(find.text(CoffeeV2Copy.stepTitleSaucer), findsOneWidget);
      await pickAndUse(
        tester,
        await writeJpeg(tester, 't.jpg', totalSize: 20201),
      );
      expect(find.text(CoffeeV2Copy.reviewTitle), findsOneWidget);
    });

    testWidgets(
      'L — final confirmation lands on Final Review, not submission',
      (tester) async {
        await reachFinalReview(tester);
        expect(find.text(CoffeeV2Copy.reviewTitle), findsOneWidget);
        expect(backend.operationCount, 0);
      },
    );
  });

  group('User control (M-T)', () {
    testWidgets('M — cancelling preview preserves existing confirmed asset', (
      tester,
    ) async {
      await reachStep2(tester);
      final before = recordOf(
        tester,
      ).slots[CoffeeV2PhotoSlot.cupPrimary]?.asset;
      images.nextPath = await writeJpeg(tester, 'bad.jpg', totalSize: 20301);
      await tapGallery(tester);
      await tester.pump();
      await tester.pump();
      await tapVisible(tester, find.text(CoffeeV2Copy.previewRetake));
      await tester.pump();
      final after = recordOf(tester).slots[CoffeeV2PhotoSlot.cupPrimary]?.asset;
      expect(after?.sha256, before?.sha256);
    });

    testWidgets('N — cancelling a replacement preserves old confirmed asset', (
      tester,
    ) async {
      await reachFinalReview(tester);
      final before = recordOf(
        tester,
      ).slots[CoffeeV2PhotoSlot.cupPrimary]?.asset;
      await tester.tap(find.text(CoffeeV2Copy.reviewChange).first);
      await tester.pump();
      images.nextPath = await writeJpeg(
        tester,
        'replacement.jpg',
        totalSize: 20401,
      );
      await tapGallery(tester);
      await tester.pump();
      await tester.pump();
      await tapVisible(tester, find.text(CoffeeV2Copy.previewRetake));
      await tester.pump();
      await tapVisible(tester, find.text('Geri dön'));
      await tester.pump();
      expect(find.text(CoffeeV2Copy.reviewTitle), findsOneWidget);
      final after = recordOf(tester).slots[CoffeeV2PhotoSlot.cupPrimary]?.asset;
      expect(after?.sha256, before?.sha256);
    });

    testWidgets('O — replacement confirmation changes only selected slot', (
      tester,
    ) async {
      await reachFinalReview(tester);
      final secondaryBefore = recordOf(
        tester,
      ).slots[CoffeeV2PhotoSlot.cupSecondary]?.asset;
      final saucerBefore = recordOf(
        tester,
      ).slots[CoffeeV2PhotoSlot.saucer]?.asset;
      await tester.tap(find.text(CoffeeV2Copy.reviewChange).first);
      await tester.pump();
      await pickAndUse(
        tester,
        await writeJpeg(tester, 'replacement.jpg', totalSize: 20501),
      );
      expect(find.text(CoffeeV2Copy.reviewTitle), findsOneWidget);
      final record = recordOf(tester);
      expect(
        record.slots[CoffeeV2PhotoSlot.cupSecondary]?.asset,
        secondaryBefore,
      );
      expect(record.slots[CoffeeV2PhotoSlot.saucer]?.asset, saucerBefore);
    });

    testWidgets('P — Final Review shows exactly 3 canonical cards', (
      tester,
    ) async {
      await reachFinalReview(tester);
      expect(find.text(CoffeeV2Copy.stepTitlePrimary), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepTitleSecondary), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepTitleSaucer), findsOneWidget);
      expect(find.byType(CoffeeV2Thumbnail), findsNWidgets(3));
    });

    testWidgets('Q — each card has working Değiştir', (tester) async {
      await reachFinalReview(tester);
      expect(find.text(CoffeeV2Copy.reviewChange), findsNWidgets(3));
      await tester.tap(find.text(CoffeeV2Copy.reviewChange).at(1));
      await tester.pump();
      expect(find.text(CoffeeV2Copy.stepTitleSecondary), findsOneWidget);
    });

    testWidgets('R — Final Review CTA is exactly "3 Fotoğrafı İncele"', (
      tester,
    ) async {
      await reachFinalReview(tester);
      expect(find.text(CoffeeV2Copy.reviewCta), findsOneWidget);
    });

    testWidgets('S — operation count is still ZERO on Final Review', (
      tester,
    ) async {
      await reachFinalReview(tester);
      expect(backend.operationCount, 0);
    });

    testWidgets('T — tapping final CTA creates exactly ONE operation', (
      tester,
    ) async {
      await reachFinalReview(tester);
      await tapAndDrain(tester, find.text(CoffeeV2Copy.reviewCta));
      expect(backend.operationCount, 1);
    });
  });

  group('Errors (U-Y)', () {
    testWidgets('U — primary/secondary duplicate shows locked guidance', (
      tester,
    ) async {
      final shared = await writeJpeg(tester, 'shared.jpg', totalSize: 20601);
      await reachStep2(tester, primaryPath: shared);
      await pickAndUse(tester, shared);
      expect(find.text(CoffeeV2Copy.duplicateSecondaryMessage), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepTitleSecondary), findsOneWidget);
    });

    testWidgets('V — duplicate prevents submission', (tester) async {
      final shared = await writeJpeg(tester, 'shared.jpg', totalSize: 20701);
      await reachStep2(tester, primaryPath: shared);
      await pickAndUse(tester, shared);
      expect(find.text(CoffeeV2Copy.reviewTitle), findsNothing);
      expect(backend.operationCount, 0);
    });

    testWidgets('W — saucer duplicate shows saucer-specific guidance', (
      tester,
    ) async {
      final primary = await writeJpeg(tester, 'primary.jpg', totalSize: 20801);
      await reachStep3(tester, primaryPath: primary);
      await pickAndUse(tester, primary);
      expect(find.text(CoffeeV2Copy.duplicateSaucerMessage), findsOneWidget);
      expect(find.text(CoffeeV2Copy.stepTitleSaucer), findsOneWidget);
    });

    testWidgets(
      'X — invalid/oversize local image remains on draft flow with safe copy',
      (tester) async {
        await pumpFresh(tester);
        await tester.tap(find.text(CoffeeV2Copy.introCta));
        await tester.pump();
        final badPath = '${temp.path}/not_an_image.bin';
        await tester.runAsync(
          () => File(badPath).writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]),
        );
        images.nextPath = badPath;
        await tapGallery(tester);
        await tester.pump();
        await tester.pump();
        await tapAndDrain(tester, find.text(CoffeeV2Copy.previewUse));
        expect(find.text(CoffeeV2Copy.invalidPhotoMessage), findsOneWidget);
        expect(find.text(CoffeeV2Copy.stepTitlePrimary), findsOneWidget);
        expect(backend.operationCount, 0);
      },
    );

    testWidgets('Y — picker cancellation changes nothing', (tester) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      images.nextPath = null; // cancellation
      await tapGallery(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text(CoffeeV2Copy.stepTitlePrimary), findsOneWidget);
      expect(
        recordOf(tester).slots[CoffeeV2PhotoSlot.cupPrimary]?.asset,
        isNull,
      );
    });
  });

  group('Recovery (Z-AH)', () {
    testWidgets('Z — recovered 1-slot draft lands on first incomplete step', (
      tester,
    ) async {
      final path = await writeJpeg(tester, 'primary.jpg', totalSize: 20901);
      final asset = CoffeeV2PhotoAsset(
        slot: CoffeeV2PhotoSlot.cupPrimary,
        path: path,
        mimeType: 'image/jpeg',
        sha256: await checksum(tester, path),
        sizeBytes: await fileLength(tester, path),
      );
      final seeded = CoffeeV2SubmissionRecord.empty().copyWith(
        slots: {
          CoffeeV2PhotoSlot.cupPrimary: CoffeeV2SlotRecord(
            asset: asset,
            confirmed: true,
          ),
          CoffeeV2PhotoSlot.cupSecondary: const CoffeeV2SlotRecord(),
          CoffeeV2PhotoSlot.saucer: const CoffeeV2SlotRecord(),
        },
      );
      await CoffeeV2SubmissionStore(storage).save(seeded);

      await pumpFresh(tester);
      expect(find.text(CoffeeV2Copy.stepTitleSecondary), findsOneWidget);
    });

    testWidgets('AA — recovered 2-slot draft lands on first incomplete step', (
      tester,
    ) async {
      final p1 = await writeJpeg(tester, 'p1.jpg', totalSize: 21001);
      final p2 = await writeJpeg(tester, 'p2.jpg', totalSize: 21101);
      Future<CoffeeV2PhotoAsset> assetFor(
        CoffeeV2PhotoSlot slot,
        String path,
        String sum,
      ) async {
        return CoffeeV2PhotoAsset(
          slot: slot,
          path: path,
          mimeType: 'image/jpeg',
          sha256: await checksum(tester, path),
          sizeBytes: await fileLength(tester, path),
        );
      }

      final seeded = CoffeeV2SubmissionRecord.empty().copyWith(
        slots: {
          CoffeeV2PhotoSlot.cupPrimary: CoffeeV2SlotRecord(
            asset: await assetFor(CoffeeV2PhotoSlot.cupPrimary, p1, 'sum-1'),
            confirmed: true,
          ),
          CoffeeV2PhotoSlot.cupSecondary: CoffeeV2SlotRecord(
            asset: await assetFor(CoffeeV2PhotoSlot.cupSecondary, p2, 'sum-2'),
            confirmed: true,
          ),
          CoffeeV2PhotoSlot.saucer: const CoffeeV2SlotRecord(),
        },
      );
      await CoffeeV2SubmissionStore(storage).save(seeded);

      await pumpFresh(tester);
      expect(find.text(CoffeeV2Copy.stepTitleSaucer), findsOneWidget);
    });

    testWidgets(
      'AB/AC — recovered complete draft lands on Final Review and does not auto-submit',
      (tester) async {
        final p1 = await writeJpeg(tester, 'p1.jpg', totalSize: 21201);
        final p2 = await writeJpeg(tester, 'p2.jpg', totalSize: 21301);
        final p3 = await writeJpeg(tester, 'p3.jpg', totalSize: 21401);
        Future<CoffeeV2PhotoAsset> assetFor(
          CoffeeV2PhotoSlot slot,
          String path,
          String sum,
        ) async {
          return CoffeeV2PhotoAsset(
            slot: slot,
            path: path,
            mimeType: 'image/jpeg',
            sha256: await checksum(tester, path),
            sizeBytes: await fileLength(tester, path),
          );
        }

        final seeded = CoffeeV2SubmissionRecord.empty().copyWith(
          slots: {
            CoffeeV2PhotoSlot.cupPrimary: CoffeeV2SlotRecord(
              asset: await assetFor(CoffeeV2PhotoSlot.cupPrimary, p1, 'sum-1'),
              confirmed: true,
            ),
            CoffeeV2PhotoSlot.cupSecondary: CoffeeV2SlotRecord(
              asset: await assetFor(
                CoffeeV2PhotoSlot.cupSecondary,
                p2,
                'sum-2',
              ),
              confirmed: true,
            ),
            CoffeeV2PhotoSlot.saucer: CoffeeV2SlotRecord(
              asset: await assetFor(CoffeeV2PhotoSlot.saucer, p3, 'sum-3'),
              confirmed: true,
            ),
          },
        );
        await CoffeeV2SubmissionStore(storage).save(seeded);

        await pumpFresh(tester);
        expect(find.text(CoffeeV2Copy.reviewTitle), findsOneWidget);
        expect(backend.operationCount, 0);
      },
    );

    testWidgets(
      'AD/AE — ACTIVE recovery hides edit controls and preserves operationId',
      (tester) async {
        final created = await backend.send('POST', '/v1/reading-operations', {
          'readingType': 'coffee',
          'sourceRequestId': 'seed-active',
        });
        final operationId = created!.json!['data']['operationId'] as String;
        final p1 = await writeJpeg(tester, 'p1.jpg', totalSize: 21501);
        final p2 = await writeJpeg(tester, 'p2.jpg', totalSize: 21601);
        final p3 = await writeJpeg(tester, 'p3.jpg', totalSize: 21701);
        Future<CoffeeV2PhotoAsset> assetFor(
          CoffeeV2PhotoSlot slot,
          String path,
          String sum,
        ) async {
          return CoffeeV2PhotoAsset(
            slot: slot,
            path: path,
            mimeType: 'image/jpeg',
            sha256: sum,
            sizeBytes: await fileLength(tester, path),
          );
        }

        final seeded = CoffeeV2SubmissionRecord(
          operationId: operationId,
          sourceRequestId: 'seed-active',
          slots: {
            CoffeeV2PhotoSlot.cupPrimary: CoffeeV2SlotRecord(
              asset: await assetFor(CoffeeV2PhotoSlot.cupPrimary, p1, 'sum-1'),
              confirmed: true,
              stageState: CoffeeV2StageState.staged,
            ),
            CoffeeV2PhotoSlot.cupSecondary: CoffeeV2SlotRecord(
              asset: await assetFor(
                CoffeeV2PhotoSlot.cupSecondary,
                p2,
                'sum-2',
              ),
              confirmed: true,
              stageState: CoffeeV2StageState.staged,
            ),
            CoffeeV2PhotoSlot.saucer: CoffeeV2SlotRecord(
              asset: await assetFor(CoffeeV2PhotoSlot.saucer, p3, 'sum-3'),
              confirmed: true,
              stageState: CoffeeV2StageState.staged,
            ),
          },
        );
        await CoffeeV2SubmissionStore(storage).save(seeded);

        await pumpFresh(tester);
        await drain(tester);

        expect(find.text(CoffeeV2Copy.reviewChange), findsNothing);
        expect(find.text(CoffeeV2Copy.reviewCta), findsNothing);
        final record = recordOf(tester);
        expect(record.operationId, operationId);
        expect(backend.operationCount, 1);
      },
    );

    testWidgets(
      'AF/AG/AH — retryable staging error, retry keeps operationId, then observes',
      (tester) async {
        final transport = RecordingStagedTransport(backend);
        await pumpFresh(tester, widget: app(send: transport.send));
        await tester.tap(find.text(CoffeeV2Copy.introCta));
        await tester.pump();
        await pickAndUse(
          tester,
          await writeJpeg(tester, 'p1.jpg', totalSize: 21801),
        );
        await pickAndUse(
          tester,
          await writeJpeg(tester, 'p2.jpg', totalSize: 21901),
        );
        await pickAndUse(
          tester,
          await writeJpeg(tester, 'p3.jpg', totalSize: 22001),
        );
        transport.failSlotsOnce.add('cup_primary');

        await tapAndDrain(tester, find.text(CoffeeV2Copy.reviewCta));

        expect(find.text(CoffeeV2Copy.stagingConnectionLost), findsOneWidget);
        expect(find.text(CoffeeV2Copy.stagingRetry), findsOneWidget);
        final operationIdAfterFailure = recordOf(tester).operationId;
        expect(operationIdAfterFailure, isNotNull);
        expect(backend.operationCount, 1);

        await tapAndDrain(tester, find.text(CoffeeV2Copy.stagingRetry));
        await drain(tester);

        expect(recordOf(tester).operationId, operationIdAfterFailure);
        expect(backend.operationCount, 1);
        expect(find.text(ReadingLiveCopy.headline), findsOneWidget);
      },
    );
  });

  group('Memory/UI (AI-AM)', () {
    testWidgets(
      'AI — preview uses a file-backed image provider, not MemoryImage',
      (tester) async {
        await pumpFresh(tester);
        await tester.tap(find.text(CoffeeV2Copy.introCta));
        await tester.pump();
        images.nextPath = await writeJpeg(
          tester,
          'primary.jpg',
          totalSize: 22101,
        );
        await tapGallery(tester);
        await tester.pump();
        await tester.pump();

        final previewImages = tester.widgetList<Image>(find.byType(Image));
        expect(previewImages, isNotEmpty);
        for (final img in previewImages) {
          expect(img.image, isNot(isA<MemoryImage>()));
        }
      },
    );

    testWidgets(
      'AJ/AL — review thumbnails are file-backed and decode-bounded',
      (tester) async {
        await reachFinalReview(tester);
        final thumbs = tester.widgetList<CoffeeV2Thumbnail>(
          find.byType(CoffeeV2Thumbnail),
        );
        expect(thumbs.length, 3);
        for (final element in find.byType(CoffeeV2Thumbnail).evaluate()) {
          final innerImages = find
              .descendant(
                of: find.byWidget(element.widget),
                matching: find.byType(Image),
              )
              .evaluate()
              .map((e) => e.widget as Image);
          for (final img in innerImages) {
            expect(img.image, isNot(isA<MemoryImage>()));
            expect(img.image, isA<ResizeImage>());
            final resize = img.image as ResizeImage;
            expect(resize.width, isNotNull);
            expect(resize.width!, lessThanOrEqualTo(512));
          }
        }
      },
    );

    testWidgets('AK — preview decode is bounded', (tester) async {
      await pumpFresh(tester);
      await tester.tap(find.text(CoffeeV2Copy.introCta));
      await tester.pump();
      images.nextPath = await writeJpeg(
        tester,
        'primary.jpg',
        totalSize: 22201,
      );
      await tapGallery(tester);
      await tester.pump();
      await tester.pump();

      final previewImages = tester.widgetList<Image>(find.byType(Image));
      final resized = previewImages
          .where((i) => i.image is ResizeImage)
          .map((i) => i.image as ResizeImage);
      expect(resized, isNotEmpty);
      for (final resize in resized) {
        expect(resize.width, isNotNull);
        expect(resize.width!, lessThanOrEqualTo(1280));
      }
    });

    testWidgets(
      'AM — all 3 review thumbnails render together without exceptions',
      (tester) async {
        await reachFinalReview(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(CoffeeV2Thumbnail), findsNWidgets(3));
      },
    );
  });
}
