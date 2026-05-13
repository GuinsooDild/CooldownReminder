# TODO

## Backlog Rules
- This is the single authoritative backlog.
- Read `project_control/AGENT_BRIEF.md` first.
- Full historical backlog was archived to `project_control/archive/2026-05-06-context-reduction/TODO.full.md`.
- Product target: `CooldownReminder` for all Season 1 Midnight dungeons.
- Do not ask for user arbitration unless `FEEDBACK.md` has an active question.
- Do not scan `addon_examples/` broadly.

## Current Priorities
- `P0`: remove any forbidden/protected Blizzard action popup on login or normal use.
- `P0`: keep visible product identity as `CooldownReminder`, with `/crem` and `CooldownReminderDB`.
- `P0`: keep the UI larger, cleaner, grey/dark, readable, and not a blue Timeline Reminder clone.
- `P1`: deepen bounded boss coverage safely before broad season import.
- `P1`: add reminder QOL: duplicate/copy, timing, sound, visual emphasis/color, duration, and easy manual override.
- `P1`: model visible minibosses only with name, important abilities, timing/cast triggers, confidence, and safe partial-data behavior.

## Ready For Implementation
- Next implementation batch: fix the dropdown combat-lockdown regression first, then continue visible product progress with one more boss slice and reminder customization polish.
- `RI-25 [P1]` Combat-open dropdown recovery fix. `Source:` `erreurUI.md` `UI-2026-05-11-01`. `Target:` `CooldownReminder/UI/Widgets.lua`, focused UI/source audits, and sandbox mirror only if UI validation owns it later. `Acceptance:` a custom dropdown opened out of combat cannot remain visually stuck if combat starts before outside-click dismissal; combat-time dismissal either safely closes the menu without protected mutation or leaves an obvious queued/recoverable state that auto-cleans on `PLAYER_REGEN_ENABLED`; the close-frame overlay must not keep trapping clicks indefinitely; existing combat guards for opening/selecting dropdown options remain intact; local UI/static checks cover the regression path.
- `RI-23 [P1]` One more playable non-Nexus boss slice. `Target:` `CooldownReminder/Data/SeasonProof.lua`, `CooldownReminder/Data/SeasonRegistry.lua`, data audits, and selector/timeline copy. `Acceptance:` add one additional main boss from an already registry-seeded non-Nexus dungeon, preferably another Skyreach or Seat of the Triumvirate boss, with explicit `coverageState`, trigger fields, occurrence rows, source/confidence notes, reference-only leftovers, and no fake completeness; selector/header/empty-state copy still shows `Ready`, `Partial`, or `Not mapped yet` consistently; update stale local source paths that still point to pre-archive reference-addon locations.
- `RI-24 [P1]` Reminder customization polish batch. `Target:` editor, reminder storage, runtime card display, and focused UI audits. `Acceptance:` make the trigger model and manual override state visible in the editor/runtime without modal noise; preserve existing copy/duplicate, sound, importance/color, duration, and lead-time behavior; add or update tests for malformed values and duplicated reminders so QOL stays stable while coverage grows.

## Needs Research
- Research only if a Ready task has a concrete unresolved evidence gap.
- Current priority research topics: Retail protected-action behavior, Encounter Journal/challenge-map proof artifacts, and miniboss ability/timing sources.
- `RR-06 [P1]` Next boss timing evidence, only if `RI-23` cannot be completed from existing local proof data. `Question:` which one remaining Skyreach, Seat of the Triumvirate, or Algeth'ar Academy boss has enough spell IDs, trigger types, and occurrence/timing evidence for a safe partial timeline? `Output:` concise source list, candidate boss, event rows to implement, and explicit gaps; do not broaden into a full season scrape.
- If no specific implementation-blocking question exists, Research should write nothing.

## Needs User Decision
- None.

## Validation Follow-Up
- `RI-21` is locally validated but still needs live Retail proof for the original protected-action popup and launcher/open/config interaction paths.
- `RI-25` should be rechecked against `UI-2026-05-11-01`; screenshot proof remains blocked in the current sandbox, so local static/mirror evidence is useful but not final UI proof.
- Run the local audit suite after context/path/name changes:
  - `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.test_npr_logic`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_boot.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_ui.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_data.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_validation_edges.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_entry_guards.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_partial_entry_shapes.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_registry_contract.py`
  - `node tests/audit_npr_lua_parse.js`

## Blocked Or External
- Live Retail proof remains external here, including confirmation that the original protected-action popup is gone after the `RI-21` guard batch.
- Full season boss-data rollout should wait for one stronger live or artifact-backed registry proof.
- Broad miniboss/trash rollout should wait until the boss-first flow remains stable with partial data.

## Done / Archived
- `RI-20 [P0]` Context and identity cleanup validation. `Result:` local validation on `2026-05-06` says the active addon folder/TOC/SavedVariables moved to `CooldownReminder`, `/crem` remains active, `/npr` is retired, and the local unit/audit/Lua-parse suite passed. Remaining identity concern is live UI proof, tracked under validation follow-up rather than Ready implementation.
- `RI-21 [P0]` Retail protected-action closure batch. `Result:` shipped locally on `2026-05-11`; launcher/open/config/editor/dropdown/reset/minimap/runtime-anchor mutation paths now warn, defer, or no-op during combat lockdown; local unit/static/data/UI/Lua-parse audits passed. Remaining protected-action risk is live Retail proof, and the follow-up dropdown stuck case is split to `RI-25`.
- `RI-22 [P1]` First visible product slice. `Result:` current code and validation summaries show reminder copy/duplicate, sound, duration, partial coverage copy, and non-Nexus partial boss proof slices are already present. Further work continues as `RI-23` and `RI-24`.
- Historical implementation and validation details are archived under `project_control/archive/2026-05-06-context-reduction/`.
