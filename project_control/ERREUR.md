# ERREUR

## Current Functional Defects
- `P0 Live`: user reported a launch popup similar to "the addon wants to do an action only Blizzard is allowed to do". This must remain open until a Retail run confirms it is gone.
- `P0 Live`: protected-action safety still needs a real client pass for login, Addon Compartment, minimap, `/crem`, reset, editor open/save, dropdowns, and combat lockdown.
- `P1 Live`: challenge-map, Encounter Journal, and combat-log trigger evidence still need live or exported artifacts for final confidence.

## Current Non-Defects / Superseded
- `/npr` is intentionally retired. Do not reopen it as a compatibility defect.
- The active command surface is `/crem`.
- Active SavedVariables are `CooldownReminderDB`.

## Archive
- Full historical error log was archived to `project_control/archive/2026-05-06-context-reduction/ERREUR.full.md`.

## Rules
- Keep this file short and current.
- Add only reproducible active defects, exact steps, expected result, observed result, severity, and current owner.
- Move superseded detail into archive instead of repeating it.
