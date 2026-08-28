/// Discovery share — short public card, never private dumps.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_share/copy/discovery_share_copy.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_card_png.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_controller.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_port.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_sanitize.dart';

import 'discovery_share_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('share generated keeps brand, type, and a short theme', () async {
    final port = RecordingDiscoveryShare();
    final card = DiscoveryShareBuilder.coffee(symbolName: ' Değişim ');
    final outcome = await DiscoveryShareController(
      port: port,
      renderer: const SilentDiscoveryShareCard(),
    ).share(card);
    expect(outcome, DiscoveryShareOutcome.completed);
    expect(port.last!.caption, contains(DiscoveryShareCopy.themeLabel));
    expect(port.last!.caption, contains('Değişim'));
    expect(port.last!.caption, contains(DiscoveryShareCopy.brand));
    expect(card.typeLabel, DiscoveryShareCopy.coffeeType);
    final soul = DiscoveryShareBuilder.soulMate(
      portrait: Uint8List.fromList(const [7, 7, 7]),
      interpretation: 'Sembolik mesaj: sade eşlik.',
    );
    await DiscoveryShareController(port: port).share(soul);
    expect(port.last!.imageBytes, isNotEmpty);
    expect(port.last!.caption, isNot(contains('gerçek')));
  });

  test('share canceled stays quiet and keeps the sanitized card', () async {
    final port = RecordingDiscoveryShare()
      ..next = DiscoveryShareOutcome.canceled;
    final outcome = await DiscoveryShareController(port: port).share(
      DiscoveryShareBuilder.tarot(theme: 'Denge', cardName: 'Denizci'),
    );
    expect(outcome, DiscoveryShareOutcome.canceled);
    expect(port.last!.caption, contains('Denge'));
    expect(port.last!.caption, isNot(contains('Denizci')));
  });

  test('no private data leakage in highlight, caption, or soul-mate share', () {
    expect(
      DiscoveryShareSanitize.highlight(
        'Merhaba Ayşe, 1994-03-12 ve ayse@mail.com burada.',
        denylist: const ['Ayşe'],
      ),
      DiscoveryShareCopy.fallbackHighlight,
    );
    expect(DiscoveryShareSanitize.leaksPrivate('sk-abc123 Bearer tok'), isTrue);
    final coffee = DiscoveryShareBuilder.coffee(
      overall: 'uuid 3fa85f64-5717-4562-b3fc-2c963f66afa6 günlük notu uzun.',
    );
    expect(DiscoveryShareSanitize.leaksPrivate(coffee.caption), isFalse);
    expect(coffee.caption, isNot(contains('3fa85f64')));
    expect(coffee.visual, isNull);
    final soul = DiscoveryShareBuilder.soulMate(
      portrait: Uint8List.fromList(const [1, 2, 3]),
      interpretation:
          'Ayşe, gerçek ruh eşi. Sembolik mesaj: sade durabilen yakınlık.',
      name: 'Ayşe',
    );
    expect(soul.highlight, isNot(contains('Ayşe')));
    expect(soul.highlight.toLowerCase(), isNot(contains('gerçek ruh eşi')));
    expect(soul.caption, isNot(contains('1994')));
    expect(
      DiscoveryShareSanitize.leaksPrivate('doğum tarihi 12.03.1994'),
      isTrue,
    );
    expect(DiscoveryShareSanitize.leaksPrivate('user_id 4491'), isTrue);
    expect(DiscoveryShareSanitize.leaksPrivate('keşif günlüğü sayfa'), isTrue);
    expect(DiscoveryShareSanitize.leaksPrivate('or sohbet kaydı'), isTrue);
    expect(DiscoveryShareSanitize.leaksPrivate('private dream text'), isTrue);
    expect(DiscoveryShareSanitize.leaksPrivate('api_key secret'), isTrue);
    expect(
      DiscoveryShareSanitize.leaksPrivate('41.0082, 28.9784 exact location'),
      isTrue,
    );
    expect(
      DiscoveryShareSanitize.leaksPrivate('konum: Kadıköy, İstanbul'),
      isTrue,
    );
    final banned = DiscoveryShareBuilder.soulMate(
      portrait: Uint8List.fromList(const [1]),
      interpretation: 'Gerçek ruh eşim. Kesin karşına çıkacak.',
    );
    expect(banned.highlight, DiscoveryShareCopy.soulMateHighlight);
    expect(banned.caption.toLowerCase(), isNot(contains('gerçek ruh eşi')));
    expect(banned.caption.toLowerCase(), isNot(contains('kesin karşına')));
  });

  test('daily, palm, astrology, and yıldızname stay short and public', () {
    final daily = DiscoveryShareBuilder.dailyInsight(highlight: 'değişim');
    expect(daily.typeLabel, DiscoveryShareCopy.dailyType);
    expect(daily.caption, contains(DiscoveryShareCopy.themeLabel));
    expect(daily.caption, contains('değişim'));
    expect(daily.caption, contains(DiscoveryShareCopy.brand));
    expect(daily.visual, isNull);
    expect(
      DiscoveryShareBuilder.dailyInsight(
        highlight: 'bugün kapsamlı bir rüya kaydı: ...',
      ).highlight,
      DiscoveryShareCopy.fallbackHighlight,
    );
    expect(
      DiscoveryShareBuilder.palm(theme: 'Karar').typeLabel,
      DiscoveryShareCopy.palmType,
    );
    expect(
      DiscoveryShareBuilder.astrology(innerTheme: 'İletişim').typeLabel,
      DiscoveryShareCopy.astrologyType,
    );
    expect(
      DiscoveryShareBuilder.starMap(highlight: 'Umut').typeLabel,
      DiscoveryShareCopy.starMapType,
    );
    final long = DiscoveryShareBuilder.coffee(
      overall: 'Denge.\n\n${'uzun özel çözümleme satırı ' * 20}',
    );
    expect(long.highlight, 'Denge');
    expect(long.caption, isNot(contains('uzun özel çözümleme')));
  });

  test('excluded private fields fall back instead of leaking into cards', () {
    expect(
      DiscoveryShareBuilder.astrology(
        innerTheme: 'birth date 1994-03-12',
        signName: 'Aslan',
      ).highlight,
      DiscoveryShareCopy.fallbackHighlight,
    );
    expect(
      DiscoveryShareBuilder.starMap(
        highlight: 'user_id 4491 ve keşif günlüğü notu',
      ).highlight,
      DiscoveryShareCopy.fallbackHighlight,
    );
    expect(
      DiscoveryShareBuilder.dailyInsight(
        highlight: 'private dream text ve Bearer abc',
      ).highlight,
      DiscoveryShareCopy.fallbackHighlight,
    );
    expect(
      DiscoveryShareBuilder.astrology(
        innerTheme: 'konum: Kadıköy ve doğum yeri: Ankara',
      ).highlight,
      DiscoveryShareCopy.fallbackHighlight,
    );
  });

  test('share card png is story 9:16 campaign art', () async {
    final bytes = await const DiscoveryShareCardPng().render(
      DiscoveryShareBuilder.coffee(symbolName: 'Değişim'),
    );
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(800));
    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width / frame.image.height, closeTo(9 / 16, 0.02));
  });

  test('all requested share cards render and soulmate stays visual', () async {
    final renderer = const DiscoveryShareCardPng();
    // Minimal valid 1×1 PNG — invalid bytes must never crash the card.
    final png1x1 = Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final cards = [
      DiscoveryShareBuilder.coffee(symbolName: 'Denge'),
      DiscoveryShareBuilder.palm(theme: 'Sakinlik'),
      DiscoveryShareBuilder.astrology(innerTheme: 'İletişim'),
      DiscoveryShareBuilder.starMap(highlight: 'Umut'),
      DiscoveryShareBuilder.dailyInsight(highlight: 'Değişim'),
      DiscoveryShareBuilder.soulMate(
        portrait: png1x1,
        interpretation: 'Sembolik mesaj: nazik eşlik.',
      ),
    ];
    for (final card in cards) {
      final bytes = await renderer.render(card);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(800));
    }
    expect(cards.last.visual, isNotNull);
  });

  test('no crash if share unavailable', () async {
    final outcome = await DiscoveryShareController(
      port: ThrowingDiscoveryShare(),
    ).share(DiscoveryShareBuilder.palm(theme: 'Sakinlik'));
    expect(outcome, DiscoveryShareOutcome.unavailable);
  });
}
