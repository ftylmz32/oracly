/// OR-1130 — Deployment environment identifiers.
library;

enum AppEnvironment {
  development,
  staging,
  production;

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;

  static AppEnvironment fromString(String? value) {
    return switch (value?.toLowerCase().trim()) {
      'internal' || 'staging' || 'stage' => AppEnvironment.staging,
      'production' || 'prod' => AppEnvironment.production,
      _ => AppEnvironment.development,
    };
  }
}
