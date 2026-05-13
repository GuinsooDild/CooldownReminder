# REGLES

## Ownership
- `TODO.md` is owned by Agent 1 only.
- Production code is owned by Agent 4 only.
- Validation evidence is owned by Agent 5.
- System-level coordination notes are owned by Agent 6.
- `project_control/CONTRATS_ACTIFS.md` is the shared handoff for rename and registry contracts until those items are absorbed into implementation or explicit decisions.
- `REGLES.md` is a stable shared charter. Agents may read it, but no automation may modify it unless the user explicitly asks for a rules update.
- `SUIVI_GLOBAL_AGENTS.md` is a user-facing oversight report. It must not drive the main automation loop directly.

## Product Rules
- Respect `CDC.md` and `DECISIONS.md`.
- Read `AGENT_BRIEF.md` before larger control files.
- Treat `FEEDBACK.md` as the authoritative queue for unresolved user-policy questions.
- Treat addon solidity and error prevention as the top priority.
- Prefer one robust feature over several fragile ones.
- Expand scope to all Season 1 Midnight dungeons, but only in a way that preserves clarity and reliability.
- Miniboss support is secondary and must never destabilize boss support or the main UI.
- Keep the UI as clean as possible even as dungeon coverage grows.
- Prefer monotonic improvements over rewrites.
- Keep the UI simple and efficient.
- Do not let assumptions silently become facts.
- Mark uncertainty explicitly.

## Code Rules
- Active addon code lives in `CooldownReminder/`.
- Reference addons live in `addon_examples/` and are read-only.
- Rename-facing changes should use `CooldownReminder`, `/crem`, and `CooldownReminderDB`.
- Avoid speculative rewrites.
- Reduce regression risk before adding complexity.
- Keep implementation bounded and testable.
- Protect sensitive or fragile areas before expanding them.
- Do not add new data or selectors unless they degrade gracefully when data is incomplete.
- This workspace is not expected to be a git repository. Agents must not require git, search for git metadata, or treat missing `.git` as a blocker.
- Automation runs must produce visible product progress when ready work exists. Safety rules should prevent damage, not justify repeated no-op runs.

## Validation Rules
- Prioritize checks that prove absence of obvious runtime errors, broken interactions, and invalid data transitions.
- Never declare a feature validated without evidence.
- Use multiple validation methods where possible.
- Distinguish validated, likely, unverified, and blocked.
- Prefer closing the highest external blocker over adding another local proof layer to an already well-covered path.
- Do not add broad new local audits when the next meaningful uncertainty is live-client or artifact capture.

## Documentation Rules
- Keep logs concise and useful.
- Keep frequently read control files short; archive detailed historical logs under `project_control/archive/`.
- Update shared control files only when state changes.
- Prefer append-style history with a short current-state summary.
- Keep a short current-state summary at the top of large living documents before appending more historical evidence.
- Avoid duplicate sections, repeated conclusions, and stale blockers that contradict newer active state.
- Archive or supersede old entries explicitly when they are no longer active.
- Keep active summaries phrased in `CooldownReminder` terms.
- Root-level `TODO.md`, `WORKLOG.md`, and `VALIDATION.md` have been archived and must not be recreated as active control files.
- Reduce token usage by reading targeted sections and relevant files instead of re-reading the whole project when the task scope is already clear.
