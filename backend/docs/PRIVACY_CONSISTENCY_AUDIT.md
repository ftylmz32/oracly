# Privacy/runtime consistency audit

Re-fetched and compared R5 behavior with the canonical public documents on 2026-09-13:

- Privacy Policy: `https://github.com/ftylmz32/oracly/blob/main/docs/privacy-policy.md`, alignment commit `de93a6e04dfb40dd6d2037b8873ae858b723a892`.
- Data Deletion: `https://github.com/ftylmz32/oracly/blob/main/docs/data-deletion.md`, alignment commit `c1c0e9719413d01a388c059be0333f705e17dc30`.

Consistent:

- Policy discloses backend and AI-provider processing of uploaded text/images.
- Temporary and durable operation records, recovery state, billing/fraud records, and diagnostic events are disclosed.
- R5 uses 10-minute response replay, up-to-24-hour staged inputs, short operational result/checkpoint retention, and non-content structured logs.
- Purchase ownership integrity records survive account deletion only in pseudonymized form; raw purchase tokens are not stored in those bindings.
- Account deletion removes user-bound backend records, staged objects, notification tokens, Gem state, personalization/memory, and anonymizes purchase ownership.
- Both documents describe authenticated server deletion before Firebase identity deletion and the subsequent local wipe.
- Both documents limit retained purchase/fraud/accounting/security/audit records and describe detachment from active ownership and pseudonymization where feasible.
- The Data Deletion document retains an email-assisted path for users who cannot access the app and explicitly warns against sending secrets or purchase/authentication tokens.

Proven mismatch count: **0**.

No contradiction was found for account deletion ordering, response replay, image cleanup, billing/fraud retention, or safe logs. The public legal documents were not modified by this R5 workspace.
