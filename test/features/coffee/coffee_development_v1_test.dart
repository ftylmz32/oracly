/// Coffee V1 — parser, persistence, honest analysis port, OR context.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_kind.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_followup_copy.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_parser.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_pick_exception.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_validator.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parser keeps structured Turkish sections without inventing symbols', () {
    const raw = '''
{
  "genelYorum": "Fincanda sakin bir açıklık var.",
  "ask": "Yakınlık için net bir cümle iyi gelir.",
  "kariyer": "Tek bir işi bitirmek kazandırır.",
  "maddiDurum": "Küçük bir birikim adımı yeter.",
  "yakinGelecek": "Acele kararları bir gece beklet.",
  "semboller": [
    {"ad": "Kuş", "anlam": "Haber", "yorum": "Bir haber kapısı açık olabilir."}
  ],
  "sonuc": "Bugün sakin ve net dur."
}
''';
    final reading = CoffeeReadingParser.parse(
      raw,
      id: 'c1',
      createdAt: DateTime(2026, 8, 9),
    );
    expect(reading, isNotNull);
    expect(reading!.overall, contains('açıklık'));
    expect(reading.love, contains('Yakınlık'));
    expect(reading.symbols, hasLength(1));
    expect(reading.symbols.first.name, 'Kuş');
    expect(reading.takeaway, contains('sakin'));
  });

  test('saved coffee reading reopens the same text', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CoffeeReadingStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final reading = CoffeeReading(
      id: 'c2',
      createdAt: DateTime(2026, 8, 9, 10),
      overall: 'Genel sakinlik.',
      love: 'Aşkta netlik.',
      career: 'İşde sabır.',
      money: 'Küçük adım.',
      nearFuture: 'Acele etme.',
      takeaway: 'Nefes al.',
    );
    await store.save(reading);
    final loaded = store.byId('c2');
    expect(loaded?.overall, 'Genel sakinlik.');
    expect(loaded?.love, 'Aşkta netlik.');
    expect(store.all(), hasLength(1));
  });

  test('unavailable analysis does not fake a cup reading', () async {
    SharedPreferences.setMockInitialValues({});
    final service = CoffeeExperienceService(
      store: CoffeeReadingStore(
        LocalStorage(await SharedPreferences.getInstance()),
      ),
      analysis: const UnavailableCoffeeAnalysis(),
    );
    expect(service.analysisAvailable, isFalse);
    await expectLater(
      service.analyze(const CoffeeImagePick(path: 'missing.jpg')),
      throwsA(isA<CoffeeAnalysisException>()),
    );
    expect(service.history(), isEmpty);
  });

  test('OR a Sor coffee context preserves the reading', () {
    final reading = CoffeeReading(
      id: 'c3',
      createdAt: DateTime(2026, 8, 9),
      overall: 'Fincanda duruluk var.',
      love: 'Yakınlık.',
      career: 'Sabır.',
      money: 'Denge.',
      nearFuture: 'Yavaşla.',
      takeaway: 'Sakin kal.',
    );
    final context = OracleReadingContextSources.coffee(reading);
    expect(context.kind, OracleReadingKind.coffee);
    expect(context.interpretationSummary, contains('duruluk'));
    final answer = OracleFollowupCopy.respond(
      context: context,
      question: 'Bu aşk yorumu ne zaman gerçekleşebilir?',
    );
    expect(answer.toLowerCase(), contains('aşk'));
    expect(answer, contains('Yakınlık'));
    expect(answer, isNot(contains('kesin tarih')));
  });

  test('copy distinguishes analyze CTA from landing', () {
    expect(CoffeeCopy.landingLine, 'Masa hazır. Fincan hâlâ sıcak.');
    expect(CoffeeCopy.cameraLabel, 'Fincanı çek');
    expect(CoffeeCopy.galleryLabel, 'GALERİDEN SEÇ');
    expect(CoffeeCopy.analyzeCta, 'FALIMI YORUMLA');
    expect(
      CoffeeCopy.analysisUnavailable,
      'Kahve falı şu an hazırlanamadı. Biraz sonra tekrar deneyebilirsin.',
    );
    expect(CoffeeCopy.landingSteps, contains('Fotoğrafı yükle'));
    expect(CoffeeCopy.guidanceSteps, contains('Fincanı çek'));
    expect(CoffeeCopy.capabilityNote.toLowerCase(), contains('or'));
    expect(CoffeeCopy.capabilityNote.toLowerCase(), isNot(contains('önizleme')));
    expect(CoffeeCopy.landingStepsUnavailable, contains('Kayıtlı'));
  });

  test('validator rejects tiny images with Turkish copy', () async {
    final file = File(
      '${Directory.systemTemp.path}/oracly_tiny_cup_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(List<int>.filled(120, 0));
    addTearDown(() => file.deleteSync());
    final result = await CoffeeImageValidator.validate(file.path);
    expect(result.ok, isFalse);
    expect(result.message, CoffeeCopy.imageTooDarkOrSmall);
  });

  test('camera pick failure is honest, not silent cancel', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
        analysis: const UnavailableCoffeeAnalysis(),
      ),
      images: const _ThrowingCameraImages(),
    );
    controller.startCapture();
    await controller.pickCamera();
    expect(controller.image, isNull);
    expect(controller.errorMessage, CoffeeCopy.cameraUnavailable);
  });

  test('analyze without a photo stays on capture', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
        analysis: _FakeCoffeeAnalysis(),
      ),
      images: const UnavailableCoffeeImageInput(),
    );
    controller.startCapture();
    await controller.analyze();
    expect(controller.phase, CoffeePhase.capture);
    expect(controller.errorMessage, CoffeeCopy.imageRequired);
  });

  test('unavailable vision still allows capture for photo preview', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
        analysis: const UnavailableCoffeeAnalysis(),
      ),
      images: const UnavailableCoffeeImageInput(),
    );
    controller.startCapture();
    expect(controller.phase, CoffeePhase.capture);
    expect(controller.analysisAvailable, isFalse);
  });

  test('real analysis port persists the same reading for reopen', () async {
    SharedPreferences.setMockInitialValues({});
    final png = await _writeCupPng();
    addTearDown(() => png.deleteSync());
    final store = CoffeeReadingStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final service = CoffeeExperienceService(
      store: store,
      analysis: _FakeCoffeeAnalysis(),
    );
    final reading = await service.analyze(CoffeeImagePick(path: png.path));
    expect(reading.overall, 'Canlı fincan yorumu.');
    expect(store.byId(reading.id)?.overall, 'Canlı fincan yorumu.');
    expect(store.byId(reading.id)?.love, 'Aşkta sakinlik.');
  });
}

class _ThrowingCameraImages implements CoffeeImageInputPort {
  const _ThrowingCameraImages();

  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async {
    throw CoffeeImagePickException(CoffeeCopy.cameraUnavailable);
  }

  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

class _FakeCoffeeAnalysis implements CoffeeAnalysisPort {
  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    return CoffeeReading(
      id: 'live-1',
      createdAt: DateTime(2026, 8, 9),
      imagePath: image.path,
      overall: 'Canlı fincan yorumu.',
      love: 'Aşkta sakinlik.',
      career: 'İşde netlik.',
      money: 'Denge.',
      nearFuture: 'Yavaşla.',
      takeaway: 'Nefes.',
    );
  }
}

Future<File> _writeCupPng() async {
  const size = 240;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();
  var seed = 17;
  for (var y = 0; y < size; y += 2) {
    for (var x = 0; x < size; x += 2) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      paint.color = Color.fromARGB(
        255,
        seed & 255,
        (seed >> 8) & 255,
        (seed >> 16) & 255,
      );
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 2, 2),
        paint,
      );
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(
    '${Directory.systemTemp.path}/oracly_cup_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file;
}
