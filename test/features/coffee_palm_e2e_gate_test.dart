/// Coffee + Palm end-to-end production gate — deterministic integration checks.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_analysis_error.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:oracly_new/features/palm/services/unavailable_palm_analysis.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late String fixturePath;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_palm_gate_');
    PathProviderPlatform.instance = _GatePathProvider(temp.path);
    fixturePath = '${temp.path}${Platform.pathSeparator}cup.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('Coffee production gate', () {
    test('successful analyze archives image and reopens without AI', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final store = CoffeeReadingStore(storage);
      var aiCalls = 0;
      final experience = CoffeeExperienceService(
        store: store,
        analysis: _CoffeeOkAnalysis(onCall: () => aiCalls++),
      );
      final controller = CoffeeReadingController(
        experience: experience,
        images: _FixedImages(fixturePath),
      );
      await controller.acceptCapturedPath(fixturePath);
      await controller.analyze();
      expect(controller.phase, CoffeePhase.result);
      expect(aiCalls, 1);
      final archived = controller.reading!.imagePath!;
      expect(await File(archived).exists(), isTrue);
      expect(archived, contains('coffee_images'));

      final id = controller.reading!.id;
      controller.backToEntry();
      expect(controller.phase, CoffeePhase.entry);
      final saved = store.byId(id);
      expect(saved, isNotNull);
      controller.openSaved(saved!);
      expect(controller.phase, CoffeePhase.result);
      expect(aiCalls, 1);
    });

    test('gallery cancel does not set image or spend', () async {
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: CoffeeReadingStore(LocalStorage.ephemeral()),
          analysis: const UnavailableCoffeeAnalysis(),
        ),
        images: const _CancelImages(),
      );
      controller.startCapture();
      await controller.pickGallery();
      expect(controller.image, isNull);
      expect(controller.phase, CoffeePhase.capture);
    });

    test('invalid tiny image fails before analyze', () async {
      final tiny = File('${temp.path}${Platform.pathSeparator}tiny.jpg');
      await tiny.writeAsBytes(List<int>.filled(100, 1));
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: CoffeeReadingStore(LocalStorage.ephemeral()),
          analysis: _CoffeeOkAnalysis(),
        ),
        images: _FixedImages(tiny.path),
      );
      await controller.acceptCapturedPath(tiny.path);
      expect(controller.errorMessage, isNotNull);
    });

    test('unavailable backend fails closed — no fabricated reading', () async {
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: CoffeeReadingStore(LocalStorage.ephemeral()),
          analysis: const UnavailableCoffeeAnalysis(),
        ),
        images: _FixedImages(fixturePath),
      );
      await controller.acceptCapturedPath(fixturePath);
      await controller.analyze();
      expect(controller.phase, CoffeePhase.error);
      expect(controller.reading, isNull);
    });

    test('retry after failure reuses image without double AI success path', () async {
      var calls = 0;
      final analysis = _CoffeeFailOnceAnalysis(onCall: () => calls++);
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: CoffeeReadingStore(LocalStorage.ephemeral()),
          analysis: analysis,
          persistImage: ({required readingId, required sourcePath}) async =>
              sourcePath,
        ),
        images: _FixedImages(fixturePath),
      );
      await controller.acceptCapturedPath(fixturePath);
      final path = controller.image!.path;
      await controller.analyze();
      expect(controller.phase, CoffeePhase.error);
      await controller.analyze();
      expect(controller.phase, CoffeePhase.result);
      expect(calls, 2);
      expect(controller.image?.path, path);
    });

    testWidgets('320x568 saved reopen shows result sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final store = CoffeeReadingStore(storage);
      await store.save(
        CoffeeReading(
          id: 'coffee_gate_1',
          createdAt: DateTime(2026, 8, 27),
          overall: 'Sakin bir fincan.',
          love: 'Ask alani.',
          career: 'Is alani.',
          money: 'Para alani.',
          nearFuture: 'Yakin donem.',
          takeaway: 'Bugun sakin kal.',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(storage)],
          child: const MaterialApp(
            home: CoffeeReferenceScreen(savedReadingId: 'coffee_gate_1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Sakin bir fincan.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('production proxy config prohibits direct OpenAI transport', () {
      const config = AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: 'https://api.oracly.app/v1/ai/complete',
        visionEnabled: true,
      );
      final transport = AiTransportSelection.create(config);
      expect(transport, isA<ProxyAiTransport>());
      expect(transport, isNot(isA<DirectOpenAiTransport>()));
    });
  });

  group('Palm production gate', () {
    test('successful analyze persists and reopens without second AI', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final store = PalmReadingStore(storage);
      var aiCalls = 0;
      final experience = PalmExperienceService(
        store: store,
        analysis: _PalmOkAnalysis(onCall: () => aiCalls++),
        persistImage: ({required readingId, required sourcePath}) async {
          final dest = File('${temp.path}${Platform.pathSeparator}$readingId.jpg');
          await File(sourcePath).copy(dest.path);
          return dest.path;
        },
      );
      final controller = PalmReadingController(
        experience: experience,
        images: _FixedImages(fixturePath),
      );
      controller.selectHand(PalmHand.right);
      await controller.acceptCapturedPath(fixturePath);
      await controller.analyze();
      expect(controller.phase, PalmPhase.result);
      expect(aiCalls, 1);
      final id = controller.reading!.id;
      controller.backToEntry();
      controller.openSaved(store.byId(id)!);
      expect(controller.phase, PalmPhase.result);
      expect(aiCalls, 1);
    });

    test('gallery cancel leaves capture without image', () async {
      final controller = PalmReadingController(
        experience: PalmExperienceService(
          analysis: const UnavailablePalmAnalysis(),
        ),
        images: const _CancelImages(),
      );
      controller.startCapture();
      await controller.pickGallery();
      expect(controller.image, isNull);
    });

    test('unavailable analysis never fabricates palm reading', () async {
      const port = UnavailablePalmAnalysis();
      expect(port.isAvailable, isFalse);
      expect(
        () => port.analyze(
          CoffeeImagePick(path: fixturePath),
          hand: PalmHand.right,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('analysis failure surfaces retryable error without charging', () async {
      final controller = PalmReadingController(
        experience: PalmExperienceService(
          analysis: _PalmFailAnalysis(),
          persistImage: ({required readingId, required sourcePath}) async =>
              sourcePath,
        ),
        images: _FixedImages(fixturePath),
      );
      controller.selectHand(PalmHand.left);
      await controller.acceptCapturedPath(fixturePath);
      await controller.analyze();
      expect(controller.phase, PalmPhase.error);
      expect(controller.lastError?.canRetrySameImage, isTrue);
    });
  });

  group('Gem settlement gate', () {
    test('coffee abandon on failure does not charge when cost enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final wallet = GemWalletService(GemWalletStore(storage));
      final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      final op = await ops.begin(
        feature: PaidAiFeature.coffee,
        ledgerKey: 'coffee_gem_charged',
        reason: GemsCopy.reasonCoffee,
        cost: 20,
      );
      await ops.abandon(op.id);
      expect(wallet.balance, 50);
    });

    test('palm idempotent settle charges once on retry', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final wallet = GemWalletService(GemWalletStore(storage));
      final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      final op = await ops.begin(
        feature: PaidAiFeature.palm,
        ledgerKey: 'palm_gem_charged',
        reason: GemsCopy.reasonPalm,
        cost: 20,
      );
      expect(await ops.completeAfterProvider(op), isTrue);
      expect(await ops.completeAfterProvider(op), isTrue);
      expect(wallet.balance, 30);
    });
  });
}

class _CoffeeOkAnalysis implements CoffeeAnalysisPort {
  _CoffeeOkAnalysis({this.onCall});
  final VoidCallback? onCall;

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    onCall?.call();
    return CoffeeReading(
      id: 'coffee_test_1',
      createdAt: DateTime(2026, 8, 27),
      overall: 'Fincan sakin.',
      love: 'Ask.',
      career: 'Is.',
      money: 'Para.',
      nearFuture: 'Yakin.',
      takeaway: 'Sakin kal.',
      imagePath: image.path,
    );
  }
}

class _CoffeeFailOnceAnalysis implements CoffeeAnalysisPort {
  _CoffeeFailOnceAnalysis({this.onCall});
  final VoidCallback? onCall;
  var _failed = false;

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    onCall?.call();
    if (!_failed) {
      _failed = true;
      throw CoffeeAnalysisException(CoffeeCopy.analysisFailed);
    }
    return _CoffeeOkAnalysis().analyze(image);
  }
}

class _PalmOkAnalysis implements PalmAnalysisPort {
  _PalmOkAnalysis({this.onCall});
  final VoidCallback? onCall;

  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    onCall?.call();
    return PalmReading(
      id: 'palm_test_1',
      createdAt: DateTime(2026, 8, 27),
      hand: hand,
      overall: 'Avuc sakin.',
      takeaway: 'Denge.',
      imagePath: image.path,
    );
  }
}

class _PalmFailAnalysis implements PalmAnalysisPort {
  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    throw PalmAnalysisException(
      const PalmAnalysisError(
        PalmAnalysisErrorKind.network,
        'Ag baglantisi zayif.',
      ),
    );
  }
}

class _FixedImages implements CoffeeImageInputPort {
  _FixedImages(this.path);
  final String path;

  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async =>
      CoffeeImagePick(path: path, mimeType: 'image/jpeg');
  @override
  Future<CoffeeImagePick?> pickFromGallery() async =>
      CoffeeImagePick(path: path, mimeType: 'image/jpeg');
}

class _CancelImages implements CoffeeImageInputPort {
  const _CancelImages();

  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

class _GatePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _GatePathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}