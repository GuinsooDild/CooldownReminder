# AGENTS

## Active Project
- Product: `CooldownReminder`, a WoW Retail addon for Season 1 Midnight cooldown reminders.
- Active addon code: `CooldownReminder/`.
- Active tests and audits: `tests/`.
- Active control files: `project_control/`.
- Read `project_control/AGENT_BRIEF.md` first for the current state before opening larger documents.

## Context Budget Rules
- Do not scan the whole workspace.
- Do not open large history files unless a targeted search shows they are needed.
- Prefer `rg` with exact task IDs, filenames, function names, spell IDs, or error text.
- Treat `project_control/archive/` as historical. Search it only for a specific task, defect, or validation entry.
- Treat `addon_examples/` as read-only reference material. Search it only with a narrow query and only when the active task explicitly needs reference-addon behavior.
- The workspace is not expected to use git. Do not run `git status`, do not search for `.git`, and do not block on missing git metadata.

## Directory Map
- `CooldownReminder/`: production addon source. Implementation agents may edit this when the selected task requires code changes.
- `tests/`: local Python/Node audits and regression checks.
- `project_control/AGENT_BRIEF.md`: compact current-state brief. Read first.
- `project_control/TODO.md`: authoritative current backlog.
- `project_control/DECISIONS.md`: confirmed user decisions only.
- `project_control/REGLES.md`: stable shared rules.
- `project_control/ERREUR.md` and `project_control/erreurUI.md`: current reproducible functional/UI defects.
- `project_control/VALIDATION.md` and `project_control/validationUI.md`: current validation summaries only.
- `project_control/WORKLOG.md`: compact latest implementation history only.
- `project_control/CONTEXTE_SUPPLEMENTAIRE.md`: compact current research findings only.
- `project_control/archive/`: historical logs and full old documents.
- `addon_examples/`: large reference addons, read-only.
- `.codex-ui-validation/`: disposable UI validation sandbox. Only UI validation may modify it.

## Reference Addon Rules
- `addon_examples/MRT/`, `addon_examples/TimelineReminders/`, `addon_examples/EXBoss-v26.4.7.1900/`, `addon_examples/ExwindTools-v26.4.11.0540/`, and `addon_examples/DandersFrames/` are examples, not active product code.
- Never copy large files or whole subsystems from reference addons into the prompt context.
- Use reference addons for targeted patterns only: one function, one API usage, one data shape, or one UI behavior.

## Product Identity Rules
- User-facing product identity is `CooldownReminder`.
- Active slash command is `/crem`.
- Do not restore `/npr`.
- Do not introduce user-facing labels from the old test identity.
- SavedVariables use `CooldownReminderDB`.

## Testing
- Prefer narrow tests first, then broader audits when touching shared code.
- Common commands:
  - `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.test_npr_logic`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_boot.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_ui.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_data.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_validation_edges.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_entry_guards.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_partial_entry_shapes.py`
  - `PYTHONDONTWRITEBYTECODE=1 python3 tests/audit_npr_registry_contract.py`
  - `node tests/audit_npr_lua_parse.js`
