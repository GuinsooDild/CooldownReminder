# VALIDATION

## Current Summary
- Full historical validation was archived to `project_control/archive/2026-05-06-context-reduction/VALIDATION.full.md`.
- Current local validation state before archiving: startup staging, `/crem` command recovery, custom UI paths, reminder copy/duration behavior, partial coverage copy, and local data/registry audits were locally validated.
- `2026-05-06`: context-reduction and identity cleanup passed the local audit suite after renaming active addon paths to `CooldownReminder/`, TOC to `CooldownReminder.toc`, SavedVariables to `CooldownReminderDB`, and reference addons to `addon_examples/`.
- `2026-05-11`: `RI-21` protected-action closure batch is locally validated for guard presence, guard ordering, parser safety, data regressions, and partial-entry safety. Live Retail proof remains required for the original protected-action popup and real interaction behavior.
- `2026-05-11`: `RI-25` dropdown combat recovery and the `RI-23` Skyreach Rukhran proof slice are locally validated by source inspection, targeted negative probing, unit tests, static audits, data audits, registry contract checks, partial-entry guards, and Lua parsing. Live Retail proof remains required for dropdown feel/protected-action behavior and Rukhran spell/cadence confirmation.

## Latest Validation
- Scope: validated latest `RI-25 [P1]` and `RI-23 [P1]` implementation batch from `WORKLOG.md`: `Widgets.lua`, `Addon.lua`, `SeasonProof.lua`, `NexusPointXenas.lua`, `tests/test_npr_logic.py`, `tests/audit_npr_ui.py`, and `tests/audit_npr_data.py`.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.test_npr_logic` passed, `64 tests`.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_ui.py` passed, including `dropdowns-dismiss-stale-overlay-in-combat`, existing dropdown combat no-op guards, launcher/minimap/window/editor/timeline combat guards, and deferred runtime refresh.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_data.py` passed, including Rukhran labels, trigger/effect spell metadata, local `addon_examples` source paths, partial proof timelines, separated non-Nexus ID fields, and Skyreach `mappedBossCount = 3`.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_boot.py` passed, including combat-reload deferral, Addon Compartment metadata path, `/crem` identity, minimap recovery, and reset coverage.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_validation_edges.py` passed, including malformed editor numeric input and incomplete-dungeon selection edge cases.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_entry_guards.py` passed.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_partial_entry_shapes.py` passed, including missing, false, empty, malformed, non-table, missing-time, and string-time occurrence rows.
- `Validated`: `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_registry_contract.py` passed.
- `Validated`: `node tests/audit_npr_lua_parse.js` passed, `14 files 0 failures`.
- `Validated`: deliberate dropdown recovery negative probe passed: combat-time menu-item click and outside-click both call `DismissMenuDuringCombat()` before returning; the dismiss path silently closes the menu, hides the full-screen click catcher, removes the active dropdown entry, queues `pendingDropdownRecovery`, and `PLAYER_REGEN_ENABLED` refreshes dismissed dropdown visuals before global refresh.
- `Likely`: local source evidence supports that `UI-2026-05-11-01` no longer leaves a stale custom-dropdown overlay trapping clicks after combat begins.
- `Likely`: Rukhran is safely exposed as partial Skyreach coverage with explicit provisional confidence, trigger fields, occurrence rows, reference-only variants, and no fake full-dungeon completion.
- `Blocked`: live Retail proof is still required for the original protected-action popup, Addon Compartment/minimap/open/config interaction paths, actual dropdown behavior under combat lockdown, and Rukhran combat-log spell/cadence confirmation.

## Rules
- Keep this file short.
- Append only current validation conclusions, exact commands, and unresolved proof gaps.
- Move detailed historical evidence into `project_control/archive/`.
