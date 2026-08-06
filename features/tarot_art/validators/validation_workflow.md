# Validation Workflow — OR-1310

## When to Validate

| Stage | Validator | Output |
|-------|-----------|--------|
| After brief | Schema check | `card_brief_schema.json` valid |
| After composite | Full checklist | `qa_report.yaml` |
| After export | Export spec | `manifest.json` valid |
| Before integration | Registry update | `card_registry.yaml` status |

## Step 1 — Brief Schema Validation

```bash
# Example using any JSON schema CLI (ajv, etc.)
ajv validate -s validators/card_brief_schema.json -d briefs/oracly_tarot_major_17.json
```

Required fields must be present. `approved_by` and `approved_at` must be set before `in_progress`.

## Step 2 — Checklist Execution

1. Open `validators/acceptance_checklist.yaml`
2. For each **blocking** check under all sections, record PASS / FAIL
3. Any FAIL → return to illustrator with specific check ID (e.g. `OR-01`)
4. All PASS → proceed to export

### QA Report Format (`qa_report.yaml`)

```yaml
card_id: oracly_tarot_major_17
validated_at: "2026-08-05T12:00:00Z"
validator_version: "1.0"
reviewer: "QA Name"
art_director_signoff: "AD Name"
blocking_result: pass  # pass | fail
failed_checks: []      # list of check IDs if fail
advisory_notes: []
```

## Step 3 — Automated Checks (Future)

Recommended tooling (not shipped — optional integration):

| Check | Tool |
|-------|------|
| Resolution / aspect | ImageMagick `identify` |
| Pure black % | Python PIL sample script |
| Frame overlay align | Photoshop/GIMP template diff |
| OCR text in illustration | Tesseract on safe zone crop |
| WebP quality | `cwebp` metadata |

## Step 4 — Identity Blind Test

Before batch approval:
- Show card without title to 3 reviewers
- Ask: "Is this ORACLY?"
- Pass: ≥2/3 yes + 0/3 "looks like Rider-Waite"

## Rejection Loop

```
FAIL → annotate check IDs → return to Stage 4 (Illustration) or Stage 5 (Composite)
PASS → Stage 7 Export → registry approved
```

## Card Back

Single validation run. If back passes, locked forever — no per-suit variants.
