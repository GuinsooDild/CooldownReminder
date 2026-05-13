# Validation UI

## Current Summary
- Current sandbox path: `.codex-ui-validation/`.
- `2026-05-11 RI-25 / Rukhran UI validation`: mirror updated for dropdown combat recovery and Skyreach Rukhran partial coverage. Static source/mirror checks passed, targeted production UI/data audits passed, but rendered screenshots are still blocked in this environment.
- Browser blockers: `npm test` reaches Chromium launch but Chromium exits with `SIGTRAP` after `ThermalStateObserverMac unable to register to power notifications. Result: 9`, and cleanup reports `kill EPERM`; `scripts/file-smoke.js` cannot bind `127.0.0.1` (`listen EPERM`).
- Screenshots produced this run: none.
- Current verdict: `Partial / source-backed`. RI-25 appears to resolve `UI-2026-05-11-01` locally by dismissing already-open dropdowns during combat and releasing the full-screen click catcher; do not mark UI clean-final until browser screenshots or live Retail UI proof cover the planned interaction map.
- Live Retail proof remains separate and still required for actual addon launcher behavior, combat/protected-action behavior, real dropdown feel, minimap behavior, and in-game scale/layout feel.

## Latest RI-25 / Rukhran Sandbox Pass
- Report: `.codex-ui-validation/reports/2026-05-11-ri25-rukhran-ui-validation-0906.md`.
- Sandbox update: `.codex-ui-validation/app.js` now mirrors Skyreach `3/4 mapped`, the Rukhran partial timeline, and the RI-25 dropdown combat-dismiss recovery path; `.codex-ui-validation/tests/ui-smoke.spec.js` now checks first load, Skyreach/Rukhran selectors, Rukhran editor invalid correction, combat warnings, dropdown-open-before-combat dismissal, `/crem` identity, retired `/npr` copy, and a narrow viewport.
- Commands run:
  - `node --check app.js` passed.
  - `node --check tests/ui-smoke.spec.js` passed.
  - `npm test` failed before rendering because Chromium exits with `SIGTRAP` and cleanup reports `kill EPERM`.
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_ui.py` passed, including `dropdowns-dismiss-stale-overlay-in-combat`.
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_data.py` passed.
  - `node tests/audit_npr_lua_parse.js` passed, `14 files 0 failures`.
- Source evidence: `Widgets.lua` menu-item and outside-click combat paths call `DismissMenuDuringCombat()`, which closes the menu, hides the close frame, removes the active dropdown entry, and sets pending recovery; `Addon.lua` runs dropdown recovery on `PLAYER_REGEN_ENABLED`.
- Visual quality verdict: not final because screenshots are unavailable; source/mirror evidence supports that the old stuck-overlay interaction is resolved locally and no new visible identity drift was found in active addon/sandbox surfaces.

## Latest RI-21 Sandbox Rerun
- Report: `.codex-ui-validation/reports/2026-05-11-ri21-ui-validation-rerun-0802.md`.
- Sandbox update: `.codex-ui-validation/app.js` now mirrors production dropdown item-click combat guards, and `.codex-ui-validation/tests/ui-smoke.spec.js` asserts that an already-open dropdown cannot select a new item during combat.
- Interaction map prepared: first load, normal dropdown select, event editor, invalid numeric correction, copy/preview/runtime card, combat launcher/minimap/runtime/editor/reset guards, dropdown-open-before-combat edge, `/crem status`, retired `/npr` messaging, and narrow viewport reachability.
- Commands run:
  - `node --check app.js` passed.
  - `node --check tests/ui-smoke.spec.js` passed.
  - `npm test` failed before rendering because Chromium exits with `SIGTRAP` and cleanup reports `kill EPERM`.
  - `PLAYWRIGHT_BROWSERS_PATH=.ms-playwright node scripts/file-smoke.js` failed before browser launch with `listen EPERM: operation not permitted 127.0.0.1`.
  - Targeted identity grep found production `CooldownReminder`, `/crem`, and `CooldownReminderDB`; sandbox `/npr` appears only as retired-command test copy.
  - Targeted dropdown guard grep confirmed production and sandbox both guard item-click and outside-dismiss paths during combat.

## Latest RI-21 Sandbox Run
- Report: `.codex-ui-validation/reports/2026-05-11-ri21-ui-validation.md`.
- Interaction map prepared: first load, Addon Compartment/minimap launcher, minimap drag, runtime-anchor move, window close, normal dropdown select, dropdown open before combat, timeline filters, track visibility, event reminder editor, invalid numeric correction, preview/copy/save/cancel/delete guards, `/crem reset`, `/crem status`, retired `/npr` messaging, and narrow viewport reachability.
- Commands run:
  - `npm test` failed on local server bind: `listen EPERM: operation not permitted 127.0.0.1:4176`.
  - `npm test` after file-mode fallback failed on Chromium startup: `browserType.launch: Target page, context or browser has been closed`, `signal=SIGTRAP`, `kill EPERM`.
  - In-app Browser attempt blocked local `file://` navigation by URL policy.
  - `node --check app.js && node --check tests/ui-smoke.spec.js` passed.
  - Targeted identity grep found production `CooldownReminder`, `/crem`, and `CooldownReminderDB`; sandbox `/npr` appears only as retired-command test copy.

## Current UI Risks
- Ensure user-facing product identity remains `CooldownReminder`.
- Ensure `/crem` is the only active command surface.
- Ensure no visible old test-identity label remains in minimap/addon launcher/main UI surfaces.
- Ensure UI does not drift back toward the old blue Timeline Reminder clone.

## Rules
- Keep this file short.
- Put only current verdict, current screenshots, commands, and reproducible UI defects here.
- Put detailed historical screenshot reports in `project_control/archive/`.
