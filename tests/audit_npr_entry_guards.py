from pathlib import Path
import sys


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")


CHECKS = [
    (
        "editor-context-guards-event-entries",
        ROOT / "CooldownReminder" / "UI" / "Editor.lua",
        'local eventTime = event and event.entries[reminder.occurrence or 1] and event.entries[reminder.occurrence or 1].time or 0',
        "Editor context text should not index event.entries directly without a guard, or partial event data can throw while opening the editor.",
    ),
    (
        "resolve-reminder-time-guards-event-entries",
        ROOT / "CooldownReminder" / "Core" / "Util.lua",
        "local occurrence = event.entries[reminder.occurrence or 1]",
        "ResolveReminderTime should treat missing entries as UNKNOWN_OCCURRENCE instead of indexing a nil entries table.",
    ),
    (
        "combat-observation-guards-event-entries",
        ROOT / "CooldownReminder" / "Runtime" / "Scheduler.lua",
        "local expected = event.entries[nextCount]",
        "Combat-log observation should not assume every matched event has entries, or partial boss data can break diagnostics during pulls.",
    ),
    (
        "timeline-render-guards-event-entries",
        ROOT / "CooldownReminder" / "UI" / "MainWindow.lua",
        "for occurrenceIndex, entry in ipairs(event.entries) do",
        "Timeline rendering should skip events without entries instead of erroring when partial encounter data is present.",
    ),
    (
        "occurrence-helper-rejects-missing-time",
        ROOT / "CooldownReminder" / "Core" / "Util.lua",
        'type(occurrence) ~= "table" or type(occurrence.time) ~= "number"',
        "Shared occurrence access should reject malformed rows without numeric time before reminder, context, or drift math.",
    ),
    (
        "timeline-render-rejects-missing-time",
        ROOT / "CooldownReminder" / "UI" / "MainWindow.lua",
        'type(currentEntry) == "table" and type(currentEntry.time) == "number"',
        "Timeline rendering should skip non-table rows and rows without numeric time.",
    ),
]


def main():
    failures = []
    for key, path, needle, reason in CHECKS:
        source = path.read_text()
        if key in {"occurrence-helper-rejects-missing-time", "timeline-render-rejects-missing-time"}:
            ok = needle in source
        else:
            ok = needle not in source
        status = "PASS" if ok else "FAIL"
        print(f"{status}: {key} - {reason}")
        if not ok:
            failures.append((key, path))

    if failures:
        print("\nEntry guard audit failed:")
        for key, path in failures:
            print(f"- {key}: {path}")
        return 1

    print("\nEntry guard audit passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
