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

  Map<String, String> get _source => _env ?? dotenv.env;

  @override
  String? get openAiKey => _source['OPENAI_API_KEY'];

  @override
  String? get firebaseApiKey => _source['FIREBASE_API_KEY'];

  @override
  String? get revenueCatKey => _source['REVENUECAT_API_KEY'];
}
