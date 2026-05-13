# CONTRATS ACTIFS

## Role
- Shared handoff for contract-level implementation guidance.
- Exists to stop repeated re-research on rename and season-registry shape.
- These contracts are implementation guidance, not confirmed product decisions, unless the same point is also present in `project_control/DECISIONS.md`.
- This file is read by planning, research, implementation, and validation agents when a task touches rename, registry, boss-event schema, rollout sequencing, or shared contracts.
- Keep this file small and stable. It is not a worklog, not a research dump, and not the product backlog.
- Prefer updating one existing contract section over adding a parallel contract.
- If a contract is absorbed into code, `TODO.md`, or `DECISIONS.md`, mark it as absorbed instead of leaving it as a second active source of truth.

## RF-02 Rename Contract Handoff

### Goal
- Keep the active product presentation and technical package aligned on `CooldownReminder`.

### Guardrails
- Do not run a broad rename pass until the migration surface is inventoried first.
- Visible copy must converge to `CooldownReminder`; remaining `Nexus Point`, `NexusPoint`, or `Nexus Point Reminders` labels are defects unless explicitly documented as legacy internal storage.
- `/crem` is the active slash command.
- `/npr` must not remain active as a v1 compatibility command.
- Legacy persistence paths must not be reintroduced unless the user explicitly asks for migration from an old saved state.

### Required Checklist Before A Broad Rename Pass
- Inventory every user-facing and persistence-facing identity surface:
  - addon folder
  - `.toc` title and metadata
  - SavedVariables names
  - slash commands and help text
  - minimap and Addon Compartment labels
  - debug or status output
  - docs, tests, and validation references
- Decide which surfaces are:
  - visible-name-only
  - retired compatibility aliases
  - migration-required
  - deferred legacy internals
- If legacy state import is ever reintroduced, make the bridge observable in diagnostics such as `/crem status`.
- Re-run the local audit suite after any rename-touching change and record whether `/crem` works and retired aliases such as `/npr` remain inactive.
- Do remove `/npr` from active slash registration unless the user explicitly reopens compatibility.

### Confirmed Working Policy
- Use `CooldownReminder` for active product wording and user-facing labels.
- Use `/crem` as the active command surface.
- Use `CooldownReminderDB` as the active SavedVariables table.
- Treat `/npr` as retired, not as an active alias.
- Keep legacy technical identifiers only in historical archive text or actual gameplay data names, not in active product identity.

## RF-03 Canonical Season Registry Contract

### Goal
- Freeze one reusable, multi-dungeon schema before wider boss-data rollout.

### Dungeon-Level Fields
- `dungeonKey`: stable internal slug.
- `displayName`: user-facing name.
- `selectorOrder`: stable season selector order.
- `journalInstanceID`: Encounter Journal instance identifier.
- `mapID`: dungeon map identifier used for display and lookups.
- `challengeMapID`: optional Mythic+ challenge map identifier.
- `incompleteNote`: optional empty-safe copy for incomplete coverage.
- `encounterOrder`: ordered list of main-boss `encounterKey` values.
- `minibosses`: optional secondary list only; never mixed into primary boss order.
- Each visible miniboss entry needs a defined display name, important abilities, timing or trigger notes, confidence notes, and enough reminder relevance to justify display.
- `routeNotes`: optional metadata only; not core navigation logic.

### Boss-Level Fields
- `encounterKey`: stable internal boss slug.
- `displayName`: user-facing boss name.
- `journalEncounterID`: Encounter Journal boss identifier.
- `encounterID`: runtime or addon-facing encounter identifier kept separate from journal IDs.
- `events`: ordered list of event records.
- `coverageState`: explicit boss-level coverage summary such as `validated`, `partial`, or `reference_only`.
- `coverageNotes`: optional concise note for remaining gaps.

### Event-Level Fields
- `eventKey`: stable internal event slug.
- `label`: user-facing event name.
- `spellID`: primary tracked spell or effect identifier when known.
- `triggerSpellID`: optional separate trigger identifier when the cast and effect differ.
- `triggerType`: optional combat-log event type when matching must stay narrow.
- `occurrences`: explicit timing table.
- `duration`: optional duration when meaningful to the timeline.
- `relativeDanger`: display-oriented danger level.
- `timingConfidence`: explicit confidence field such as `validated`, `local`, `reference_only`, or `unverified`.
- `referenceSpellIDs`: optional list of known but not yet fully timed spell IDs.
- `notes`: concise fact-only note, never a hidden assumption.

### Contract Rules
- Keep journal IDs, runtime encounter IDs, map IDs, and challenge IDs in separate fields.
- Do not overload one numeric field for multiple lookup systems.
- Keep miniboss or route-gate content in optional secondary structures, but visible miniboss support is allowed once the entry has a name, relevant abilities, timing or cast triggers, and safe partial-data behavior.
- Empty or incomplete dungeons must remain visible and must degrade to an explicit empty-safe state.
- Selector order is stable season ordering, not inferred route progression.

### Definition Of Done For The Contract
- One non-Nexus validation artifact confirms the registry shape against live or EJ data.
- At least one implementation task can use this schema without adding dungeon-specific exceptions.
- Agents can extend coverage by filling the agreed fields instead of inventing new ones per dungeon.

## Workflow Use
- Read this file before starting rename planning or wider dungeon-data expansion.
- Update this file only when a contract meaningfully changes or a repeated ambiguity has been resolved.
- Do not update this file for routine implementation logs, validation logs, or one-off research notes.
- Do not use this file to override `CDC.md` or confirmed user decisions in `DECISIONS.md`.
