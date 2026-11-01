/// Real glyph metrics for layout tests: the default test font draws every
/// glyph one em wide, so "is this line cut?" needs the app's actual font.
/// Loads Roboto (and maps the platform display families onto it) plus the
/// Material icon font, from the Flutter SDK and test/fonts.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oracly_new/core/theme/app_theme.dart';

Future<void> loadLayoutFonts() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final material = '${sdk.path}/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.view(File(path).readAsBytesSync().buffer);
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular', 'roboto-medium', 'roboto-bold']) {
    final path = '$material/$f.ttf';
    if (File(path).existsSync()) roboto.addFont(read(path));
  }
  roboto.addFont(read('test/fonts/Roboto-Regular.ttf'));
  await roboto.load();
  for (final family in ['Segoe UI', '.SF UI Text', '.SF UI Display']) {
    await (FontLoader(family)..addFont(read('test/fonts/Roboto-Regular.ttf')))
        .load();
  }
  final iconsPath = '$material/materialicons-regular.otf';
  if (File(iconsPath).existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(read(iconsPath))).load();
  }
}

ThemeData robotoDarkTheme() {
  final base = AppTheme.dark;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    dialogTheme: base.dialogTheme.copyWith(
      titleTextStyle: (base.dialogTheme.titleTextStyle ?? const TextStyle())
          .copyWith(fontFamily: 'Roboto'),
      contentTextStyle: (base.dialogTheme.contentTextStyle ?? const TextStyle())
          .copyWith(fontFamily: 'Roboto'),
    ),
  );
}
