/// Which Dream section is guarded, and where its text came from.
library;

/// Every role stays bound to the Dream; only the emotional theme may instead
/// honour a feeling the dreamer stated (backend role-grounding parity).
enum DreamGuardRole { dream, emotionalTheme }

/// Provider AI prose has already passed the backend Dream acceptance gates;
/// it is judged on safety, certainty, grounding and invented images, never
/// on on-device template style. Local text keeps the generic-style guard.
enum DreamGuardSource { providerAi, local }
