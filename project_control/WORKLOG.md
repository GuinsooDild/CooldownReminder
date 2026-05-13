# WORKLOG

## Current Summary
- Full historical worklog was archived to `project_control/archive/2026-05-06-context-reduction/WORKLOG.full.md`.
- Current product identity cleanup is in progress: active addon folder is `CooldownReminder/`, TOC file is `CooldownReminder.toc`, SavedVariables are `CooldownReminderDB`, and reference addons have moved to `addon_examples/`.
- Root-level legacy tracking files were archived into the same context-reduction archive.
- `RI-21` protected-action closure batch shipped locally on `2026-05-11`: config UI creation/open/move/hide/reset/dropdown/editor/minimap launcher paths now warn or defer during combat lockdown; local unit/static/Lua-parse suite passed; live Retail proof remains required.

## Latest Implementation Note
- `2026-05-11T08:26:19Z`: implemented `RI-25 [P1]` plus the `RI-23 [P1]` Skyreach Rukhran proof slice.
- Intent: fix the combat-start dropdown recovery regression while continuing bounded non-Nexus boss coverage without implying full dungeon completion.
- Files changed: `CooldownReminder/UI/Widgets.lua`, `CooldownReminder/Core/Addon.lua`, `CooldownReminder/Data/SeasonProof.lua`, `CooldownReminder/Data/NexusPointXenas.lua`, `tests/test_npr_logic.py`, `tests/audit_npr_ui.py`, and `tests/audit_npr_data.py`.
- Implementation: dropdown item/outside-click handlers now dismiss already-open custom menus during combat, release the full-screen click catcher, and refresh visuals on `PLAYER_REGEN_ENABLED`; Skyreach proof coverage now includes `Rukhran` with four provisional EXBoss-timed rows (`Dawn`, `Burning Claws`, `Searing Feathers`, `Blaze of Glory`), explicit trigger/combat-log fields, reference-only variants, and Skyreach mapped count `3/4`; active local source URLs now point at `addon_examples/`.
- Validation passed: `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.test_npr_logic`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_boot.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_ui.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_data.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_validation_edges.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_entry_guards.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_partial_entry_shapes.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_registry_contract.py`; `node tests/audit_npr_lua_parse.js`.
- Risk level: medium-low locally; dropdown recovery is statically guarded but needs live Retail interaction proof, and Rukhran spell labels/timings remain provisional pending Retail/log confirmation.
- Next validation needed: live Retail pass for the `UI-2026-05-11-01` sequence, Addon Compartment/minimap/open paths after the RI-21 guard batch, and a Skyreach Rukhran pull/log check for trigger IDs and cadence.

- `2026-05-11T06:28:27Z`: implemented `RI-21 [P0]` Retail protected-action closure batch.
- Intent: reduce forbidden/protected Blizzard action popup risk for login/reload, Addon Compartment, minimap, `/crem`, reset, editor actions, dropdowns, and movable config surfaces.
- Files changed: `CooldownReminder/Core/Addon.lua`, `CooldownReminder/Core/Util.lua`, `CooldownReminder/UI/MinimapButton.lua`, `CooldownReminder/UI/Widgets.lua`, `CooldownReminder/UI/MainWindow.lua`, `CooldownReminder/UI/Editor.lua`, `CooldownReminder/Runtime/Scheduler.lua`, `tests/test_npr_logic.py`, `tests/audit_npr_boot.py`, and `tests/audit_npr_ui.py`.
- Implementation: combat reload now defers client UI creation until `PLAYER_REGEN_ENABLED`; Addon Compartment/minimap clicks pass path-specific combat-safe launcher labels; minimap repositioning and drag movement defer or warn in lockdown; frame position save/restore, window drag/close, dropdown open/select/outside-close, timeline navigation/filter/track changes, editor preview/save/copy/delete/cancel, and debug runtime-anchor movement are guarded.
- Validation passed: `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.test_npr_logic`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_boot.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_ui.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_data.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_validation_edges.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_entry_guards.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_partial_entry_shapes.py`; `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_registry_contract.py`; `node tests/audit_npr_lua_parse.js`.
- Risk level: medium-low locally; broad shared UI guard changes are statically covered, but only a real Retail client can prove the original popup is gone.
- Next validation needed: live Retail pass for login/reload in combat if possible, Addon Compartment, minimap click/drag/toggle, `/crem`, `/crem reset`, dropdown open/select/close, editor save/copy/delete/cancel, runtime anchor movement, and combat-lockdown warning copy.

## Previous Implementation Note
- `2026-05-06`: context-reduction pass started.
- Intent: reduce token usage by adding `AGENTS.md`, adding `project_control/AGENT_BRIEF.md`, archiving large historical control files, and moving large reference addons away from root.
- Files changed structurally: active addon folder renamed to `CooldownReminder/`, TOC renamed to `CooldownReminder.toc`, reference addons moved to `addon_examples/`, root legacy `TODO.md`/`WORKLOG.md`/`VALIDATION.md` archived, and large control logs compacted with full copies in `project_control/archive/2026-05-06-context-reduction/`.
- Product identity cleanup: active SavedVariables are now `CooldownReminderDB`; `/crem` remains the active slash command; active tests expect no active `/npr` alias.
- Validation: local unit/audit/Lua-parse suite passed after the changes.

## Rules
- Keep this file short.
- Append only the latest implementation batch summary, files changed, validation commands/results, and current follow-up.
- Do not paste long historical logs here.
