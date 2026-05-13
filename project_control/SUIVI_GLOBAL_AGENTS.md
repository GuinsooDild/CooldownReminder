# SUIVI GLOBAL AGENTS

## Current Oversight Summary
- Context-reduction work has materially improved the automation setup: active control docs are now compact, large historical logs are archived, and reference addons are isolated under `addon_examples/`.
- `AGENTS.md` and `project_control/AGENT_BRIEF.md` now provide the intended first-read context path for agents.
- The active addon identity has moved to `CooldownReminder/`, `CooldownReminder.toc`, `/crem`, and `CooldownReminderDB`.
- Root-level legacy tracking files were archived and should not be treated as active sources.
- `2026-05-11`: the first-read brief/backlog drift was resolved by refreshing `AGENT_BRIEF.md` to mirror the ready work in `TODO.md`: `RI-21`, `RI-23`, and `RI-24`.

## Remaining Workflow Risks
- Automation prompts still name some agent roles with the old `NPR` prefix. That is agent naming, not product UI, but it may be worth renaming later for clarity.
- Some historical archive files still contain old command/name references. Agents must not treat archive text as current truth unless a targeted search is explicitly needed.
- Live Retail validation remains the main external proof gap for protected-action safety.

## Recommendations
- Keep current control files short.
- Search archive only with exact task IDs, file paths, commands, or defect text.
- Keep `addon_examples/` read-only and search it only for narrow reference questions.
- After each implementation batch, update only the compact current summaries and move detailed evidence to archive.

## Locked Practices
- `project_control/TODO.md` remains the active backlog.
- `project_control/DECISIONS.md` remains confirmed user decisions only.
- `project_control/AGENT_BRIEF.md` is the first context file for automations.
