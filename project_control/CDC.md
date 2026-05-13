# CDC

## Role
- Stable product brief for `CooldownReminder`.
- Describes target user experience, core scope, constraints, and acceptance goals.
- Must only change when the user makes or confirms a product decision.

## Product Summary
- `CooldownReminder` is a World of Warcraft Retail addon for planning cooldowns and reminders across all Season 1 Midnight dungeons.
- The product direction is a native addon inspired by the useful parts of BigWigs, WeakAuras, Timeline Reminder, and MRT: enemy ability awareness, timeline-based planning, personalized player cooldown reminders, and clean in-game configuration.
- The addon must support boss timelines for the whole season, not just the initial proof dungeon.
- The addon should support optional miniboss timelines and important trash ability timelines when enough data exists, but this remains secondary to boss coverage and reliability.
- The UI should stay visually clean and close in spirit to `EXEMPLE.png`: compact, readable, low-noise, and efficient.
- Users must be able to place player cooldown reminders on dungeon, boss, miniboss, or important enemy ability events directly from the timeline with minimal friction.
- Scope is native-only for v1. Do not add MRT note import, external runtime dependencies, or broad integration surfaces unless the user explicitly changes that decision.

## Primary Product Priorities
- Priority 1: solidity, startup safety, and zero avoidable errors.
- Priority 2: no forbidden-action, taint, combat-lockdown, or protected-action popup during login, opening, configuration, or normal runtime paths.
- Priority 3: reliable interaction model with clean, predictable UI behavior.
- Priority 4: complete Season 1 Midnight dungeon coverage for main boss timelines.
- Priority 5: optional miniboss and important trash support where it can be added safely without destabilizing boss support.
- Priority 6: visual polish and convenience improvements only after the relevant reliability and validation gates are stable.

## Core Features
- Safe addon startup with defensive initialization and resilient SavedVariables normalization.
- Discoverable launcher via minimap button or equivalent entry point.
- Dungeon selection for all supported Season 1 Midnight dungeons, including incomplete dungeons that remain visible but clearly marked.
- Boss selection and timeline display for each supported dungeon.
- Optional miniboss selection per dungeon only after validation, through a secondary or optional selector model.
- Optional important trash entries for high-impact casts, DoTs, kicks, or damage events only when the data is clear enough to avoid clutter and false confidence.
- Reminder creation and editing from timeline interactions.
- Reminder options must include:
  - text
  - icon
  - sound
  - color or visual emphasis
  - display duration
  - timing offset
- Reminders should be copyable or duplicable when that reduces repetitive setup without creating hidden complexity.
- Boss, miniboss, or enemy-event patterns should be duplicable or reusable when the same ability pattern safely applies elsewhere, but duplicated data must retain confidence and source notes.
- Runtime reminder display must be predictable, role-aware, and stable.
- Runtime reminders may be driven by pull-relative timing, enemy spell/cast/combat-log triggers, or a combination of both. The chosen trigger model must be explicit per event and must degrade safely when evidence is incomplete.
- Slash-command recovery uses `/crem`.

## UX Goals
- UI must be as clean as possible.
- Visual hierarchy should remain close to `EXEMPLE.png` without copying noisy or fragile details.
- Important timeline information should be readable at a glance.
- Reminder editing should not require excessive clicks or hidden knowledge.
- The UI should scale to multiple dungeons without becoming cluttered or confusing.
- Custom dropdown behavior should be discoverable through subtle hover guidance, not loud persistent helper text.
- Timeline zoom, boss or miniboss switching, reminder duplication, and common navigation actions should be simple enough for normal in-game use.
- The UI should feel like a polished in-game tool, not a raw data editor.

## Quality Goals
- Minimize startup failures, nil-state issues, broken handlers, and bad SavedVariables states.
- Reduce risk of broken clicks, dropdowns, blocked-action paths, and taint.
- Eliminate the current forbidden-action popup risk. Midnight/Retail restrictions must be treated as a first-class constraint, not as a late validation detail.
- Keep dungeon data, IDs, names, event timing notes, and data confidence traceable and documented.
- Separate validated facts from uncertain assumptions.
- Favor robust, testable, maintainable code over quick feature breadth.
- Keep incomplete or partial dungeon data empty-safe. Never leak boss data from another dungeon and never show fake completeness.
- When live Retail validation is blocked, work may continue only if it reduces architectural, safety, or robustness risk. Do not expand dependent UX or data breadth from local evidence alone.

## Source Of Truth
- `CDC.md` defines stable product intent.
- `DECISIONS.md` contains confirmed user decisions and overrides older assumptions.
- `REGLES.md` defines shared automation and documentation rules.
- `TODO.md` is the only implementation backlog.
- `CONTRATS_ACTIFS.md` contains shared implementation contracts for rename, registry, rollout, and schema work.
- `VALIDATION.md`, `validationUI.md`, `ERREUR.md`, and `erreurUI.md` are evidence sources, not backlog owners.

## Non-Goals
- Do not add feature sprawl that weakens stability.
- Do not introduce speculative complexity if it harms reliability, simplicity, or testability.
- Do not replace stable working flows with large rewrites without strong evidence.
- Do not treat miniboss support as more important than main boss coverage and core stability.
- Do not depend on live APIs or external addon data during startup-critical UI paths.
- Do not let reference data, public guides, or local addon snapshots silently become product truth without explicit confidence and validation posture.
- Do not build a generic WeakAura/MRT replacement or note-import system in v1; use those products only as inspiration for useful workflows.
- Do not add trash or miniboss timelines if they make the main boss flow confusing, noisy, or less reliable.

## Acceptance Criteria
- The addon loads safely and predictably.
- The addon does not trigger "addon tried to perform an action only available to the Blizzard UI" or equivalent forbidden-action popups on login or normal use.
- The launcher is recoverable and discoverable.
- The UI stays clean while supporting all targeted dungeons, including incomplete ones.
- Timeline interactions are understandable, robust, and easy to validate.
- Reminder creation, editing, duplication, sound, color, duration, and timing behavior are understandable and consistent.
- Main Season 1 Midnight dungeons are covered with traceable data quality.
- Boss abilities are the first coverage target; minibosses and important trash abilities are added only with traceable confidence and low UI clutter.
- Incomplete dungeons show a clearly marked empty-safe state with no leaked boss data from another dungeon.
- Validation state, known risks, and remaining uncertainties are clearly documented.
- Rename-facing behavior is deliberate: visible `CooldownReminder` presentation, bounded compatibility handling, and no accidental breakage of saved variables or recovery commands.
- Registry and boss data carry enough confidence metadata that validation can distinguish confirmed, provisional, intentionally nil, and blocked states.
