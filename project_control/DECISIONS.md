# DECISIONS

## Confirmed Decisions
- Product identity is `CooldownReminder`.
- Product name for v1 is explicitly `CooldownReminder`.
- Visible product copy should now use `CooldownReminder` rather than `Nexus Point Reminders`.
- Remaining visible `Nexus Point`, `NexusPoint`, or `Nexus Point Reminders` surfaces are unwanted and should be removed or renamed to `CooldownReminder`, including minimap/addon launcher labels if they still show the old name.
- Slash-command surface is `/crem`; `/npr` should not remain active as a v1 compatibility command.
- Scope stays native-only for v1. No MRT note import or runtime dependency.
- Target is WoW Retail only.
- Scope now targets all Season 1 Midnight dungeons rather than a single dungeon.
- Product direction is a native Cooldown Reminder workflow inspired by BigWigs, WeakAuras, Timeline Reminder, and MRT, without becoming dependent on those addons or importing their runtimes for v1.
- Timeline data uses explicit occurrence tables with verified spell IDs and confidence notes.
- Runtime reminders may use pull-relative timing, enemy spell/cast/combat-log triggers, or both, but each event must make its trigger model explicit and safe.
- Free-form double-click reminders are anchored to a synthetic `pull_anchor` event.
- The editor supports Enter-to-save and Escape-to-close on main fields for fast reminder editing.
- Negative offsets are presented as pre-warning lead time in the editor and runtime cards.
- Reminder customization should stay simple but include timing, sound, color or visual emphasis, display duration, and easy manual override.
- Reminder copy/duplicate and safe pattern reuse are desired quality-of-life features when they reduce repetitive setup without hiding complexity.
- Addon Compartment access should follow TOC metadata first on Retail, with runtime setup kept compatibility-safe.
- For v1 reliability, custom widgets are preferred over Blizzard dropdown or menu templates.
- For v1 reliability, configuration is out-of-combat only; combat-time behavior is limited to runtime reminders and passive observation.
- Midnight/Retail protected-action restrictions are a first-class constraint. The addon must not trigger forbidden-action popups on login or normal use.
- Primary success metric is solidity: avoid errors, protect interactions, and keep state recovery strong before pushing breadth.
- Miniboss selection is allowed as a lower-priority feature if it remains clean, safe, and secondary to the main boss flow.
- All Season 1 dungeons should stay visible in the selector even when incomplete, but incomplete dungeons must be clearly marked and render an explicit empty-safe state with no fake or leaked boss data.
- Coverage wording may use `Ready`, `Partial`, and `Not mapped yet`; exact wording is less important than keeping incomplete coverage obvious and safe.
- Minibosses should be visible when they have a defined name and usable reminder relevance.
- Visible miniboss support must include important abilities and when those abilities happen, because reminders must be able to trigger from miniboss ability timing or casts.
- Important trash abilities may be shown after boss coverage when they are high-impact, traceable, and do not make the UI noisy.
- When live validation is blocked, work may continue only if it reduces architectural or robustness risk; dependent UX or data breadth should not expand.
- Custom dropdown discoverability should use subtle hover guidance.
- Reminder defaults should auto-fill when helpful but remain easy to override manually.

## Rules For This File
- Only confirmed user decisions belong here.
- Do not store guesses or temporary assumptions here.
- When a decision supersedes an older one, keep the latest state clear.
