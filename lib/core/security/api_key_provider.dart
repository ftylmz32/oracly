/// OR-1130 — API key resolution — never hardcode secrets.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class ApiKeyProvider {
  String? get openAiKey;
  String? get firebaseApiKey;
  String? get revenueCatKey;
}

class EnvApiKeyProvider implements ApiKeyProvider {
  const EnvApiKeyProvider([this._env]);

  final Map<String, String>? _env;

  Map<String, String> get _source {
    final local = _env;
    if (local != null) return local;
    try {
      return dotenv.env;
    } catch (_) {
      return const {};
    }
  }

  @override
  String? get openAiKey {
    // DEV only via dotenv. Never String.fromEnvironment — that would embed
    // the secret in a production binary if passed as --dart-define.
    final env = _source['OPENAI_API_KEY']?.trim();
    if (env != null && env.isNotEmpty) return env;
    return null;
  }

  @override
  String? get firebaseApiKey => _source['FIREBASE_API_KEY'];

  @override
  String? get revenueCatKey => _source['REVENUECAT_API_KEY'];
}
