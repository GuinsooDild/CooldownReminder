# CooldownReminder

## Scope
- Retail-only addon for `CooldownReminder`
- Boss timeline shell for Season 1 Midnight dungeons
- Minimap button opens the configuration directly
- Click an event or marker to create/edit a reminder
- Reminder fields:
  - text
  - icon spell ID
  - sound
  - offset
  - enabled
  - importance
  - role scope

## Commands
- `/crem`
- `/crem debug`
- `/crem status`
- `/crem evidence [season|current|<dungeon_key>]`
- `/crem reset`
- `/crem minimap show|hide|toggle`
- `/crem arm kasreth`
- `/crem arm nysarra`
- `/crem arm lothraxion`
- `/crem arm off`

## Notes
- Runtime scheduling is predictive from the local timeline, not combat-log reactive.
- Boss encounter IDs are cross-checked locally against `EXBoss-v26.4.7.1900` and `ExwindTools-v26.4.11.0540`.
- Boss ability names are aligned with the Method ability tracker and wow.gg guide.
- The UI shows per-ability duration and a relative danger percentage, not raw damage numbers.
- Reminder display supports sound, custom icon spell IDs and negative offsets for pre-warning timing.
- Command surface: use `/crem` for open, status, reset, minimap recovery and evidence export.
- SavedVariables now use `CooldownReminderDB` so the active addon identity matches the product name.

## Local Validation References
- `/Users/julienduhamel/Documents/HealerReminder/VALIDATION.md`
- `/Users/julienduhamel/Documents/HealerReminder/WORKLOG.md`
