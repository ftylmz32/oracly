/// Coffee V2 client transport ceiling — 8 MiB per photo. This is a
/// Coffee-V2-only rule: it does NOT reduce the shared legacy
/// `CoffeeImageLimits.maxBytes` (12 MiB), which still governs single-image
/// Coffee and Palm exactly as before. Rationale: JSON/Base64 staging
/// expands bytes by roughly 33%; 8 MiB keeps a 3-photo submission's
/// per-request body comfortably under the global Fastify body limit.
library;

abstract final class CoffeeV2ImageLimits {
  CoffeeV2ImageLimits._();

  static const maxBytes = 8 * 1024 * 1024;
}
