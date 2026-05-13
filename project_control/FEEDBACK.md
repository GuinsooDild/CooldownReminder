# FEEDBACK

## Role
- Bridge between the user and the other agents.
- Keep only genuinely unresolved user decisions here.
- Do not keep answered decision queues after the answer has been promoted to `project_control/DECISIONS.md`.
- Internal execution issues belong in `TODO.md`, `ERREUR.md`, `erreurUI.md`, `VALIDATION.md`, or `validationUI.md`, not as repeated user questions.

## Coordination Status
- Reviewed on `2026-05-06`.
- The previous rename, coverage, and miniboss questions are now answered and must not be re-asked unless the user explicitly reopens them.
- Current state: no active user arbitration is blocking the next implementation run.
- The main remaining risk is implementation/document drift: agents must keep `FEEDBACK.md`, `DECISIONS.md`, `TODO.md`, and validation/error files synchronized after a user reply or a completed implementation batch.

## Confirmed User Replies
- `2026-05-06`: `CooldownReminder` is the product identity. Remaining visible `Nexus Point` or `NexusPoint` surfaces are unwanted, including minimap/addon launcher labels if they still show the old name.
- `2026-05-06`: the active slash command is `/crem`; `/npr` should not remain active as a v1 compatibility command.
- `2026-05-06`: all Season 1 Midnight dungeons should stay visible even when incomplete.
- `2026-05-06`: coverage wording may use `Ready`, `Partial`, and `Not mapped yet`; exact wording is less important than making incomplete coverage obvious and safe.
- `2026-05-06`: minibosses should be visible when they have a defined name and usable reminder relevance.
- `2026-05-06`: visible miniboss support must include their important abilities and when those abilities happen, because reminders must be able to trigger from miniboss ability timing or casts.

## Active Questions
- None.

## Notes For Agents
- Do not ask again whether `/npr` should stay active. The answer is no.
- Do not ask again whether the visible product name is `CooldownReminder`. The answer is yes.
- Do not ask again whether incomplete dungeons should stay visible. The answer is yes, with an explicit incomplete/empty-safe state.
- Do not ask again whether minibosses belong in the product. The answer is yes when named and structured enough to support ability-based reminders.
- If a future implementation discovers a concrete tradeoff that changes one of these decisions, write the specific tradeoff here as a new question instead of reopening the old generic queue.

## Improvements Worth Considering
- Add a quiet diagnostic surface such as `/crem status` that confirms visible identity, active slash command, SavedVariables source, coverage posture, and whether legacy `Nexus Point` surfaces remain.
- Keep selector coverage labels consistent across dungeon selector, selected-dungeon header, and empty states.
- Keep evidence provenance such as `live`, `local`, or `reference` out of primary selector badges unless it is presented as diagnostics, because users mainly need to know what is usable.
- Keep minibosses secondary to the boss flow, but still first-class enough that their name, abilities, timings, and reminder hooks are visible when relevant.
