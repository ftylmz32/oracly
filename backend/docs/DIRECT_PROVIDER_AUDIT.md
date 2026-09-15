# Direct-provider audit

Audited the R4 client candidate and R5 backend source on 2026-09-13.

- **A — reachable and required:** backend OpenAI-compatible provider calls. They are the intended server-side trust boundary.
- **B — unreachable in production, harmless compatibility:** client `DirectOpenAiTransport`, `OpenAiTransport`, `OpenAiSpeechHttp`, and the `api.openai.com` constants. Selection requires `environment.isDevelopment && !kReleaseMode`; release-lock regression tests also inject stray keys and prove no direct transport is selected.
- **C — stale/dead and safe to exclude:** no additional abandoned production call site identified. Tests and development fixtures referencing direct transport are not production paths.
- **D — architect decision required:** none.

Production-reachable direct client provider path: **NO**. No client source was modified.
