# Disaster recovery runbook

| Incident | Source of truth / backup | Restore order | Recommended RPO/RTO | Currently unrecoverable |
|---|---|---|---|---|
| Firestore deletion/corruption | Scheduled managed exports to separate protected bucket | Stop writers; restore identity/billing/Gem, operations, results, transient records; reconcile | RPO 24h, RTO 4h | Changes after latest export |
| GCS staged-image loss | Staging is temporary and not a durable source | Do not reconstruct; fail/compensate affected operations; ask for a new operation | RPO 0 expected, RTO 1h | Lost private input image |
| Bad Cloud Run revision | Immutable freeze + image digest | Route traffic to last verified R4/R5-compatible revision | RPO 0, RTO 30m | In-flight ambiguous provider requests become unknown |
| Queue misconfiguration | Versioned queue/runbook settings | Stop enqueue, correct target/OIDC, reconcile waiting operations | RPO 0, RTO 1h | Tasks past configured retention |
| Development PC loss | Immutable freezes in protected replicated storage/repository | Restore tools, clone source, verify manifest | RPO 24h, RTO 1 business day | Uncommitted local-only work |
| Signing/upload key loss | Play App Signing plus offline access-control records | Recover console access; rotate upload key through Play process | RPO 0, RTO depends on store | App-signing key if Play protection was never enabled |
| Production defines loss | Secret/config inventory in protected secret manager, never source | Restore non-secret config, secret references, validate readiness without traffic | RPO 24h, RTO 2h | Values never recorded in approved secret inventory |
| Immutable freeze loss | At least two checksum-verified offline/remote copies | Restore archive, verify manifest/tree before use | RPO per release, RTO 2h | Freeze if it existed only on this PC |

No backups or cloud settings are created by R5. These are required future operational actions.
