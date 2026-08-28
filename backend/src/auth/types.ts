export type AuthenticatedIdentity = {
  /** JWT `sub` (or opaque-dev marker). Never a client-supplied userId. */
  subject: string;
  /** Rate-limit / concurrency key. Never the raw token. */
  identityKey: string;
};

export type AuthResult =
  | { ok: true; identity: AuthenticatedIdentity }
  | { ok: false };

export type AuthenticationService = {
  authenticate(
    authorizationHeader: unknown,
    requestIp?: string,
  ): Promise<AuthResult>;
};
