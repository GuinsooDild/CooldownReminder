# AMELIORATION

## Role
- Catalog of useful improvement ideas.
- Includes UX, data, architecture, validation, and workflow ideas.
- This file is not the implementation backlog; Agent 1 decides what enters `TODO.md`.
- Ideas here are candidates only. Do not implement them directly unless `TODO.md` promotes them into a bounded task.

## Active Candidate Improvements

### Reliability And Recovery
- Strengthen malformed occurrence-row handling so partially wired `entries` tables cannot crash timeline rendering.
- Eliminate the real forbidden-action popup seen when launching/opening the addon: "l'addon veut faire une action que seul Blizzard est autorisé à faire". Treat this as production-blocking until a Retail-safe path is validated. Reference addons in the workspace do not show this error on launch, so CooldownReminder must not normalize this as acceptable.
- Add a compact recovery/status surface for rename and compatibility state, including visible product name, active slash aliases, and SavedVariables bridge status.
- Improve live recovery paths and slash-command troubleshooting only when they reduce real support risk.
- Keep strengthening state normalization where validation finds concrete malformed SavedVariables, selector, reminder, or runtime states.

### Registry And Data Confidence
- Add explicit registry confidence or posture for `challengeMapID` and related map identifiers: confirmed, provisional, intentionally nil, or blocked.
- Keep Encounter Journal IDs, map IDs, runtime encounter IDs, and challenge-mode IDs separate in code, tests, and diagnostics.
- Add an opt-in debug export for roster and map evidence outside startup-critical code.
- Strengthen timing verification for reference-only and live-only events, but do not widen boss coverage from unvalidated timing data.

### Multi-Dungeon UX
- Improve top-level dungeon selection while keeping incomplete dungeons visible, clearly marked, and empty-safe.
- Add visible boss coverage beyond Nexus-Point. Current automation progress is not acceptable if no additional dungeon or boss becomes usable.
- Keep boss switching and future miniboss switching low-clutter, with minibosses secondary and hidden until they have sufficient validated structure.
- Add important trash ability support only after the boss/miniboss model can represent high-impact casts, DoTs, kicks, or damage events without clutter.
- Reuse one coverage vocabulary across selector rows, selected-dungeon messaging, empty states, and validation notes.
- Avoid route-aware or progression-driven navigation until route assumptions are explicitly validated.

### Reminder Editing And Runtime UX
- Improve reminder editor defaults per event when they are helpful but easy to override.
- Clarify pull-relative versus event-relative reminder context without adding modal noise.
- Keep lightweight validation messaging for bad numeric inputs if it reduces user confusion.
- Consider auto-suggesting sound or importance from event danger only after runtime and click behavior are stable.
- Add copy or duplicate actions for reminders when the interaction is obvious and preserves simple editing.
- Add safe pattern reuse between bosses, minibosses, or trash events only when copied data keeps source, confidence, and trigger semantics visible.
- Improve timeline zoom and quick switching controls so users can place reminders quickly during setup.
- Make the trigger model visible enough that users understand whether a reminder is pull-relative, enemy-spell-triggered, combat-log-triggered, or provisional.

### Visual Polish
- Move away from the current overly blue visual direction that feels too close to Timeline Reminder. Target a larger, cleaner grey/dark CooldownReminder identity with stronger hierarchy and less copy/paste feel.
- Tune row spacing, top padding, marker lanes, colors, text density, and left-panel alignment against `EXEMPLE.png`.
- Consider a dedicated untimed or reference-only row style if the current coverage note becomes too subtle or too noisy.
- Keep visual polish secondary to solidity, interaction safety, and traceable data confidence.
- Keep the interface beautiful and efficient enough to feel like a purpose-built in-game tool, not a raw configuration table.

### Validation And Diagnostics
- Improve live diagnostics when they close an active uncertainty: richer drift samples, unknown-reminder summaries, or a tiny debug snapshot command.
- Prefer one focused live artifact over adding more broad local audits to already green paths.
- Add screenshot-based UI validation evidence for high-risk interaction changes through the UI validation sandbox.

### Automation Process Feedback
- The automation must produce visible product progress, not only research, validation logs, or repeated blockers.
- Avoid "one tiny task per run" behavior when a coherent batch is needed to make the addon meaningfully better.
- Do not spend cycles looking for git metadata; this workspace is not expected to be a git repository.
- Reduce token usage by reading targeted sections and files, not by scanning the whole project every run.

## Absorbed Or No Longer Standalone
- Product rename toward `CooldownReminder` is now a confirmed direction in `DECISIONS.md` and should be handled through bounded TODO tasks, not as an open idea.
- Expansion to all Season 1 Midnight dungeons is now confirmed product scope, not an optional improvement.
- Optional miniboss support is allowed but remains secondary and validation-gated.

## Rules For This File
- Keep ideas concise.
- Mark risky ideas clearly.
- Remove duplicates when a better version exists.
- Move confirmed decisions to `DECISIONS.md`, active implementation work to `TODO.md`, and research evidence to `CONTEXTE_SUPPLEMENTAIRE.md`.
