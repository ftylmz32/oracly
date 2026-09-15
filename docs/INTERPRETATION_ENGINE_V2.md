# ORACLY Interpretation Engine V2 and Connected Memory

## Production audit (before V2)

- Tarot builds interpretations through `TarotInterpretationService` / the AI
  executor. It receives the current session, cards, intention, first name and a
  history-derived journey hint. Results are saved as `ReadingModel` records in
  `or_reading_history`.
- Coffee and Palm call their vision adapters, then their feature composers.
  They received first name but no real cross-reading memory. Results lived in
  independent `coffee_readings` and `palm_readings` stores.
- Soulmate used its own generation and interpretation gates and retained one
  latest `SoulMateSavedResult`; it was invisible to other features.
- Dream used `DreamExperienceService` and `LocalDreamRepository`; its history
  was available to Dream pattern matching but not as canonical OR context.
- Daily Astrology and the calendar-driven Star Map hub are local catalogue
  surfaces, not durable personalized completions. The Birth Chart journey
  branded as Yildizname does persist a stable chart id, completion date and
  generated insight set; that completed journey is the authoritative memory
  seam.
- OR/Luna persisted conversations and had bounded recent-turn, discovery and
  compact profile summaries. It could not retrieve the Coffee/Palm/Soulmate
  stores by source and date, so cross-feature recall was not reliable.
- `MemoryService`, Personal Memory Core, Discovery Journal, feature histories,
  and companion thread memory were isolated systems with different schemas.

## Architecture after V2

Every completed supported reading writes a compact `OraclyMemory` alongside
its existing feature record. Existing runtime and result stores remain the
source of truth; V2 is a bounded retrieval index, not a replacement.

`feature result -> OraclyMemoryFactory -> OraclyMemoryStore -> OraclyMemoryRetriever -> OraclyContextPacket -> OR/interpretation prompt`

Write-through is enabled for Tarot, Coffee, Palm, Dream, Soulmate, completed
Birth Chart/Yildizname journeys, and explicit user-saved OR facts. OR reads the
canonical store on every turn. Deleting a source reading removes its canonical
item. User-local-data wipe removes the entire V2 store. The store is
SharedPreferences-backed and therefore survives process restart on the same
installation.

Birth Chart/Yildizname writes only after the interpreted chart passes the
journey-ready validator and the authoritative chart record has been saved.
Existing completed records are backfilled when loaded after upgrade. Repeating
the same chart id upserts, while replacing the latest chart removes only the
superseded source memory. Memory writes and removals are fail-soft: an index
failure cannot suppress a successfully persisted result or block clearing it.

Tarot injects a relevant packet selected from its explicit current intention.
Coffee and Palm accept the same packet through their existing personalization
payload when a caller has established relevant current themes; an empty current
context sends no history. Both adapters catch lookup failures and continue with
the unchanged vision request. The backend caps Tarot memory at 220 characters
and tells the writer to ignore it unless current evidence supports it.

Dream read-side retrieval derives its query only from the current dream
narrative plus emotions and tags explicitly supplied for that dream. It
excludes prior Dream memories, runs locally before the existing interpretation
call, and appends one bounded, source-attributed context string after the
current dream evidence. Empty/unusable or unrelated input exports no history.
Retrieval failure leaves the same single interpretation call intact.

Soulmate read-side retrieval is stricter. No memory is read for portrait
generation and the portrait request schema has no memory field. Only after a
portrait exists may a sufficiently specific explicit intention select bounded
cross-feature context for the existing text-interpretation call. Generic or
missing intentions keep read-side memory off, and prior Soulmate records are
excluded to prevent narrative feedback loops. Retrieval failure continues the
interpretation without history.

For both features, current evidence and interpretation instructions precede
historical context, which is explicitly optional and uncertain. Retrieval is
deterministic and introduces no classification, summarization, image, or text
provider call: Dream remains one interpretation call; Soulmate retains its
existing portrait call(s) plus one interpretation request (including its
existing bounded server repair when required).

## Canonical schema

An item contains schema version, canonical id, kind (`stableFact`, `reading`,
or `conversation`), source id/type/date/result reference, short summary,
dominant themes, concrete evidence, emotional themes, explicitly grounded
people, intentions, unresolved threads, prior advice, confidence, and update
date. Fields and list sizes are clipped on decode; full generated prose and raw
conversation archives are not copied into the index.

The store upserts by canonical id (duplicate-safe), retains at most 160 items,
and supports list, edit-by-upsert, remove-by-item, remove-by-source, and clear.
These operations are the API foundation for the existing/future “What ORACLY
knows about me” view.

## Retrieval and prompt budget

Retrieval tokenizes the current intention/question plus direct evidence, then
scores overlap, recency decay, and source confidence. Unrelated records receive
no context slot. Explicit recall/comparison questions may retrieve recent
history even without a theme token. Results are capped at four memories and
approximately 1,200 characters. Recurring themes require the same theme in at
least two different reading types. Each prompt row preserves type, date, and
source id internally.

Prompt order is current intention, current direct evidence, relevant sourced
history, verified cross-feature themes, then uncertainty instructions. This
keeps Coffee/Palm visual findings authoritative. The prompt explicitly permits
silence about history when it adds no value and requires uncertainty for
conflicting records.

## Human quality corpus

The fixed corpus used for regression review is in
`test/fixtures/interpretation_engine_v2_corpus.json`. Its baseline examples
represent the previous no-memory behavior; V2 expectations require sourced
specificity without forced continuity. Evaluation dimensions are specificity,
evidence grounding, naturalness, continuity, usefulness, repetition,
hallucinated memory, and generic mystical filler. Hallucinated-memory and
unattributed-continuity scores are hard failures, not compensable averages.

## Astrology and Yildizname boundaries

The persisted Birth Chart journey presented as Yildizname now emits canonical
`birthChart` memory. Its bounded summary is derived from completed generated
insights and conservative supported themes; raw birth date/time/place,
placements, prompts and profile facts are not copied into reading memory.

Generic daily Astrology and the date-varying Star Map catalogue remain
excluded. Opening their result screens is not an authoritative persisted
completion, and indexing them would create generic long-term noise. Their OR
handoff context remains current-session context only. No separate AI-generated
Astrology completion exists in the current runtime.

Conversation compaction remains deliberately limited to facts the user
explicitly asks OR to save; automatic extraction of arbitrary chat is excluded
to avoid false or overly sensitive memory.
