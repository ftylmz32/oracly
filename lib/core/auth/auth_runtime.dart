/// Resolves whether the running app must use real auth (not MockAuth).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_environment.dart';

abstract final class AuthRuntime {
  AuthRuntime._();

  static bool get isProductionLike {
    if (kReleaseMode) return true;
    const envDefine = String.fromEnvironment('APP_ENV');
    String? env;
    try {
      env = dotenv.env['APP_ENV'];
    } catch (_) {}
    final resolved = AppEnvironment.fromString(
      envDefine.trim().isNotEmpty ? envDefine : env,
    );
    return !resolved.isDevelopment;
  }
}
