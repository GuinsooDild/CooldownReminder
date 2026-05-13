# NexusPointReminders Assumptions

## Product
- The addon targets WoW Retail only.
- Native reminders are the only supported reminder source in v1.
- The user prefers a simple timeline/reminder editor over broad feature coverage.

## Data
- Nexus-Point Xenas has 3 boss encounters relevant to this addon:
  - Chief Corewright Kasreth
  - Corewarden Nysarra
  - Lothraxion
- Encounter IDs are assigned from local EXBoss / Exwind encounter mappings:
  - `kasreth` -> `3328`
  - `nysarra` -> `3332`
  - `lothraxion` -> `3333`
- The exact boss-to-ID ordering above is treated as high-confidence local addon data, pending only live client confirmation.
- Boss spell names are aligned to the Method tracker naming, while detection IDs are cross-checked against EXBoss local spell data.
- When a boss spell is confirmed by local addons or public guides but its cadence is not yet defensible, it should remain visible as reference-only coverage rather than being omitted or assigned guessed timings.

## UX
- Double-clicking empty timeline space should create a reminder relative to pull, not relative to an arbitrary hidden event.
- If reminder text is empty at runtime, the event label is used as fallback display text.
- If an icon spell ID is invalid or absent, the addon uses a question mark or event icon fallback rather than blocking save.
- Empty or malformed reminder records in SavedVariables should be normalized or discarded rather than trusted blindly.
- The timeline should stay simple: users see duration and relative danger on each line, but raw damage values stay out of the UI.

## Validation
- Python is available locally and is the primary out-of-game test runner.
- npm cache writes in the default home cache are unreliable in this workspace, so parser validation should use a local cache directory.
- Local parser validation and Python tests are expected to catch syntax and pure-logic regressions, but not frame-template or secure-environment issues that only exist in-game.
- A dedicated static UI audit script is worthwhile because click reliability is a top-level product risk.
