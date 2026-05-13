# erreurUI

## Current UI Defects
- None currently open from the latest source-backed UI validation pass.
- UI validation still must screenshot-verify that current visible labels use `CooldownReminder`, the command surface is `/crem`, and no old test-identity label appears in launcher/minimap/main UI surfaces.
- UI validation must keep watching for the old too-blue Timeline Reminder clone direction.

## Resolved / Locally Superseded
- `UI-2026-05-11-01 [P2]`: Dropdown could remain visually stuck if combat started while a custom dropdown was already open. `Latest status:` locally superseded by `RI-25` source evidence on `2026-05-11`; menu-item and outside-click combat paths now call `DismissMenuDuringCombat()`, which closes the menu, hides the full-screen close frame, clears the active dropdown, and queues dropdown recovery on `PLAYER_REGEN_ENABLED`. `Evidence:` `CooldownReminder/UI/Widgets.lua` lines 420-455 and 482-552; `CooldownReminder/Core/Addon.lua` lines 158-164; `.codex-ui-validation/reports/2026-05-11-ri25-rukhran-ui-validation-0906.md`. `Remaining proof gap:` Playwright screenshots and live Retail feel/protected-action proof are still blocked/unavailable.

## Current UI Proof Gaps
- Live Retail visual/interaction proof is still needed for Addon Compartment, minimap, dropdown feel, combat-state UI blocking, and actual game scale.
- Sandbox screenshots are useful evidence, but they do not replace live Retail proof.

## Archive
- Full historical UI error log was archived to `project_control/archive/2026-05-06-context-reduction/erreurUI.full.md`.

## Rules
- Keep this file short and current.
- Add only reproducible UI defects with steps, expected result, observed result, screenshot path if available, severity, and owner.
