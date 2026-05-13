# AGENT BRIEF

## Current Product State
- Product identity: `CooldownReminder`.
- Active slash command: `/crem`.
- Active SavedVariables: `CooldownReminderDB`.
- Active code folder: `CooldownReminder/`.
- Reference addons have been moved under `addon_examples/` and must be searched only with targeted queries.
- Historical control logs have been moved under `project_control/archive/2026-05-06-context-reduction/`.

## User Decisions
- No active user arbitration is blocking implementation.
- All Season 1 Midnight dungeons should be visible even when incomplete.
- Incomplete coverage should be explicit and safe, using wording such as `Ready`, `Partial`, and `Not mapped yet`.
- Minibosses should be visible when they have a defined name and useful reminder relevance.
- Visible miniboss support must include important abilities plus timing or trigger information.
- The addon must not show forbidden/protected Blizzard action popups on login or normal use.
- UI direction should be larger, cleaner, grey/dark, and not a too-blue Timeline Reminder clone.

## Current Implementation Priorities
- `RI-21 [P0]`: close Retail protected-action risk across launcher/open/config paths with explicit combat guards and local safety audits.
- `RI-23 [P1]`: add one more playable non-Nexus boss slice with explicit partial-data behavior, trigger fields, occurrence rows, and source/confidence notes.
- `RI-24 [P1]`: polish reminder customization by making trigger/manual override state visible while preserving copy/duplicate, sound, color, duration, and lead-time behavior.

## Current Validation State
- Local audits previously validated staged startup, `/crem`, custom UI paths, reminder copy/duration behavior, partial coverage copy, and sandbox UI validation.
- Live Retail proof remains required for startup/open paths, Addon Compartment behavior, minimap behavior, `/crem` recovery commands, combat/protected-action safety, and real runtime interaction feel.
- If live proof is unavailable, record the exact remaining Retail-only check instead of claiming final validation.

## Current Known Risks
- Token usage can explode if agents read historical logs or reference addons broadly.
- Use `TODO.md`, `ERREUR.md`, `erreurUI.md`, `VALIDATION.md`, `validationUI.md`, `WORKLOG.md`, and `CONTEXTE_SUPPLEMENTAIRE.md` as current summaries only.
- Search archived full logs only by exact task ID, defect ID, command, or file name.
- Do not use root-level legacy tracking files; they are archived.

## Context Reading Order
- Planner: read this brief, then `TODO.md`, then only changed decision/error/validation summaries.
- Implement: read this brief, selected `TODO.md` batch, target source files, and relevant current errors/validation summaries.
- Research: read this brief, selected research task, then targeted reference docs or `addon_examples/` queries.
- Functional validation: read this brief, latest `WORKLOG.md`, target code, and relevant current error summaries.
- UI validation: read this brief, latest `WORKLOG.md`, UI source, `validationUI.md`, `erreurUI.md`, and sandbox files.
- User feedback: read this brief, `FEEDBACK.md`, `DECISIONS.md`, and only the docs needed to identify a real unresolved user decision.
- Meta oversight: read this brief and current summaries; use archive only to prove a repeated workflow problem.
