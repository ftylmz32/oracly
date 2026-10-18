import type { AppConfig } from '../config.js';

/** True only for an App ID extracted from a verified App Check token. */
export function isConfiguredWebApp(appId: string, config: AppConfig): boolean {
  return appId.length > 0 && config.firebaseWebAppCheckAppIds.includes(appId);
}

/**
 * Classifies only the verified Firebase App ID. Unknown web apps are denied
 * from legacy Coffee paths, while the paid endpoint additionally requires the
 * explicit allowlist above. Firebase Web App IDs have the documented
 * `1:<project-number>:web:<hash>` shape.
 */
export function isWebAppIdentity(appId: string, config: AppConfig): boolean {
  return isConfiguredWebApp(appId, config) || /^1:\d+:web:[A-Za-z0-9]+$/u.test(appId);
}
