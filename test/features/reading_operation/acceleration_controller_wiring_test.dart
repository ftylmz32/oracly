library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _Images implements CoffeeImageInputPort {
  const _Images(this.path); final String path;
  @override bool get cameraAvailable => false;
  @override bool get galleryAvailable => true;
  @override Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override Future<CoffeeImagePick?> pickFromGallery() async => CoffeeImagePick(path: path);
}

class _StagedCoffee implements CoffeeAnalysisPort, CoffeeStagedAnalysisPort {
  final gate = Completer<void>();
  int calls = 0;
  @override bool get isAvailable => true;
  @override Future<CoffeeReading> analyze(CoffeeImagePick image) => throw UnimplementedError();
  @override Future<CoffeeReading> analyzeStaged({required String operationId, required String mimeType}) async {
    calls++; await gate.future;
    return CoffeeReading(id: 'accelerated-coffee', createdAt: DateTime.utc(2026), overall: 'real', love: '', career: '', money: '', nearFuture: '', takeaway: 'done');
  }
}

class _StagedPalm implements PalmAnalysisPort, PalmStagedAnalysisPort {
  final gate = Completer<void>();
  int calls = 0;
  PalmHand? seenHand;
  @override bool get isAvailable => true;
  @override Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) => throw UnimplementedError();
  @override Future<PalmReading> analyzeStaged({required String operationId, required String mimeType, required PalmHand hand}) async {
    calls++; seenHand = hand; await gate.future;
    return PalmReading(id: 'accelerated-palm', createdAt: DateTime.utc(2026), hand: hand, overall: 'real', takeaway: 'done');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Coffee acceleration is single-flight, applies only returned balance, and resumes the same operation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-accel-test');
    final analysis = _StagedCoffee();
    final balances = <int>[];
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: _Images(File('unused').path), live: runner,
      acceptAuthoritativeBalance: (value) async => balances.add(value),
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    expect(controller.canAccelerate, isTrue);
    final first = controller.accelerateWaiting();
    final duplicate = controller.accelerateWaiting();
    await Future<void>.delayed(Duration.zero);
    expect(backend.accelerationCalls, 1);
    expect(analysis.calls, 1);
    expect(balances, [40]);
    analysis.gate.complete();
    await Future.wait([first, duplicate]);
    expect(controller.liveState?.kind, ReadingLiveKind.ready);
    expect(controller.reading?.id, 'accelerated-coffee');
  });

  test('insufficient Gems keeps Coffee waiting and uses fetched authoritative balance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false)
      ..accelerationInsufficient = true
      ..authoritativeBalance = 7;
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-insufficient');
    final analysis = _StagedCoffee();
    final balances = <int>[];
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'), live: runner,
      acceptAuthoritativeBalance: (value) async => balances.add(value),
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    await controller.accelerateWaiting();
    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    expect(analysis.calls, 0);
    expect(balances, [7]);
    // The waiting screen's error banner reads this -- without it, a real
    // insufficient-Gems failure would leave the UI stuck showing loading
    // with no way for the user to understand what happened.
    expect(controller.accelerationError, isNotNull);
  });

  test('insufficient Gems keeps Palm waiting, surfaces a retryable error, and never resubmits the image', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false)
      ..accelerationInsufficient = true
      ..authoritativeBalance = 5;
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.palm, sourceRequestId: 'palm-insufficient');
    final analysis = _StagedPalm();
    final balances = <int>[];
    final controller = PalmReadingController(
      experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'), live: runner,
      acceptAuthoritativeBalance: (value) async => balances.add(value),
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    expect(controller.accelerationError, isNull);
    await controller.accelerateWaiting();
    // Operation stays valid and waiting -- not failed, not a fake success.
    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    expect(analysis.calls, 0);
    expect(balances, [5]);
    expect(controller.accelerationError, isNotNull);
    expect(controller.canAccelerate, isTrue);
  });

  test('Palm acceleration is single-flight, applies canonical response, and resumes same right-hand operation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.palm, sourceRequestId: 'palm-accel-test');
    final analysis = _StagedPalm();
    final balances = <int>[];
    final controller = PalmReadingController(
      experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'), live: runner,
      acceptAuthoritativeBalance: (value) async => balances.add(value),
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    final first = controller.accelerateWaiting();
    final duplicate = controller.accelerateWaiting();
    await Future<void>.delayed(Duration.zero);
    expect(backend.accelerationCalls, 1);
    expect(balances, [35]);
    expect(analysis.calls, 1);
    expect(analysis.seenHand, PalmHand.right);
    analysis.gate.complete();
    await Future.wait([first, duplicate]);
    expect(controller.liveState?.kind, ReadingLiveKind.ready);
    expect(controller.reading?.id, 'accelerated-palm');
  });

  test('Coffee CTA cost is fetched from server authority and matches what accelerate() actually charges', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-cost-preview');
    final analysis = _StagedCoffee();
    final balances = <int>[];
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'), live: runner,
      acceptAuthoritativeBalance: (value) async => balances.add(value),
    );
    addTearDown(controller.dispose);
    // Not fetched yet -- never a locally-invented placeholder number.
    expect(controller.accelerationCost, isNull);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);
    expect(controller.accelerationCost, 10);
    analysis.gate.complete();
    await controller.accelerateWaiting();
    // Same cost the quote showed -- proven against the real charge, not a
    // separately-maintained client number that could drift.
    expect(backend.accelerationCalls, 1);
    expect(balances, [backend.authoritativeBalance]);
  });

  test('Palm CTA cost is fetched from server authority', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.palm, sourceRequestId: 'palm-cost-preview');
    final analysis = _StagedPalm();
    final controller = PalmReadingController(
      experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'), live: runner,
    );
    addTearDown(controller.dispose);
    expect(controller.accelerationCost, isNull);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);
    expect(controller.accelerationCost, 15);
  });

  test('a price change after the quote blocks the first tap with zero debit; a second explicit tap then charges once', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-price-race');
    final analysis = _StagedCoffee();
    final balances = <int>[];
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'), live: runner,
      acceptAuthoritativeBalance: (value) async => balances.add(value),
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);
    // quote 10 -> charge 10 would succeed (baseline authority check).
    expect(controller.accelerationCost, 10);

    // Deployed policy changes to 15 after the user saw the quote but
    // before they tap -- simulated the same way the backend test does.
    backend.coffeeAccelerationCost = 15;

    // First explicit tap still carries the stale (10) price token.
    await controller.accelerateWaiting();
    expect(backend.accelerationCalls, 1);
    // Zero debit: still waiting, no analysis pipeline ever ran, and the
    // authoritative balance callback reflects the UNCHANGED balance.
    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    expect(analysis.calls, 0);
    expect(balances, [backend.authoritativeBalance]);
    // UI updates to the fresh price with no extra round trip.
    expect(controller.accelerationCost, 15);
    expect(controller.accelerationError, isNotNull);
    expect(controller.canAccelerate, isTrue);

    // A second, explicit tap (a brand new user action) now carries the
    // fresh token and charges 15 exactly once.
    analysis.gate.complete();
    await controller.accelerateWaiting();
    expect(backend.accelerationCalls, 2);
    expect(controller.liveState?.kind, ReadingLiveKind.ready);
    expect(controller.reading?.id, 'accelerated-coffee');
    expect(balances.last, 50 - 15);
  });

  test('a server-side cost change is reflected in what the client displays', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-cost-change');
    final controllerA = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: _StagedCoffee()),
      images: const _Images('unused'), live: runner,
    );
    addTearDown(controllerA.dispose);
    await controllerA.recoverActive();
    await Future<void>.delayed(Duration.zero);
    expect(controllerA.accelerationCost, 10);

    // The deployed cost policy changes server-side (simulated here by the
    // fake backend's own cost, which is what the client always defers to --
    // it never computes or remembers this number itself).
    backend.coffeeAccelerationCost = 25;
    final prefs2 = await SharedPreferences.getInstance();
    final controllerB = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs2)), analysis: _StagedCoffee()),
      images: const _Images('unused'), live: runner,
    );
    addTearDown(controllerB.dispose);
    await controllerB.recoverActive();
    await Future<void>.delayed(Duration.zero);
    expect(controllerB.accelerationCost, 25);
  });
}
