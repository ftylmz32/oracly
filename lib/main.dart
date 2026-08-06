import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/oracly_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final container = await bootstrapProviders();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OraclyApp(),
    ),
  );
}
