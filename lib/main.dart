import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/oracly_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // LIVE product paths do not require secrets at startup. Missing .env must
  // not block launch; optional keys are read later only by unwired AI helpers.
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } on EmptyEnvFileError {
    dotenv.testLoad(fileInput: '');
  }

  final container = await bootstrapProviders();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OraclyApp(),
    ),
  );
}
