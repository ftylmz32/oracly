# Rollback compatibility matrix

| Client / backend | Pre-V2 production | R4 successor | R5 successor |
|---|---|---|---|
| Existing Internal pre-Coffee-V2 client | SAFE for legacy Coffee/Palm/Gem; no deletion/rebind guarantees | SAFE; missing locale falls back to `tr` | SAFE; same compatibility contract |
| Upcoming Coffee-V2 client | UNSAFE: three-slot staging and R4 deletion/rebind absent | SAFE | SAFE |

Feature detail: Coffee V2 requires R4+; Palm and existing Gem operations remain compatible; account deletion, purchase rebind, durable locale, provider checkpoints and unknown-outcome compensation require R4+ semantics. R5 adds TTL/cleanup/trace metadata without removing R4-readable fields. Old results without trace metadata remain readable.

Minimum backend floor: once any R4/R5-capable client is distributed, **R4 tree `29c42bf2ea19b27eb04907f433d9065618408c82cfa3de5e48e50218b7d53d41`**. Rolling back below R4 is unsafe for account deletion honesty, restored purchases, Coffee V2 locale, and provider ambiguity handling.
