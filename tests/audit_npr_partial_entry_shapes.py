from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import sys


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")


def load_logic_module():
    spec = spec_from_file_location("test_npr_logic", ROOT / "tests" / "test_npr_logic.py")
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def simulate_timeline_render(logic, event, zoom):
    blocks = []
    for entry in logic.get_event_entries(event):
        if not isinstance(entry, dict) or not isinstance(entry.get("time"), (int, float)):
            continue
        blocks.append(
            {
                "x": entry.get("time") / zoom,
                "width": max(10, (entry.get("duration") or event.get("defaultDuration") or 0) / zoom),
            }
        )
    return blocks


def main():
    logic = load_logic_module()
    reminder = {"encounterKey": "kasreth", "eventKey": "broken", "occurrence": 1, "offsetSeconds": -2.0}

    safe_cases = {
        "missing_entries": {"label": "Broken Event"},
        "entries_false": {"label": "Broken Event", "entries": False},
        "entries_empty": {"label": "Broken Event", "entries": []},
    }
    malformed_cases = {
        "malformed_entry_row": {"label": "Broken Event", "entries": [False]},
        "non_table_entry_row": {"label": "Broken Event", "entries": ["not-a-row"]},
        "missing_time_entry_row": {"label": "Broken Event", "entries": [{"duration": 4.0}]},
        "string_time_entry_row": {"label": "Broken Event", "entries": [{"time": "soon", "duration": 4.0}]},
    }

    failures = []

    for key, event in safe_cases.items():
        events = {"kasreth": {"broken": event}}
        resolved, reason = logic.resolve_reminder_time(events, reminder)
        context_time = logic.get_reminder_context_time(events, reminder)
        rendered = simulate_timeline_render(logic, event, 2.0)
        observed = logic.observe_event({"eventCounts": {}, "driftByEvent": {}}, dict(event, key="broken"), 12.3)
        ok = resolved is None and reason == "UNKNOWN_OCCURRENCE" and context_time == 0 and rendered == [] and observed["driftByEvent"] == {}
        status = "PASS" if ok else "FAIL"
        print(f"{status}: {key} - Missing or falsy entries should degrade without a render or drift crash.")
        print(f"{key} detail: resolved={resolved} reason={reason} context_time={context_time} rendered={rendered} observed={observed}")
        if not ok:
            failures.append(key)

    for key, event in malformed_cases.items():
        events = {"kasreth": {"broken": event}}
        try:
            resolved, reason = logic.resolve_reminder_time(events, reminder)
            context_time = logic.get_reminder_context_time(events, reminder)
            rendered = simulate_timeline_render(logic, event, 2.0)
            observed = logic.observe_event({"eventCounts": {}, "driftByEvent": {}}, dict(event, key="broken"), 12.3)
        except Exception as exc:
            print(f"FAIL: {key} - Malformed occurrence rows should not crash reminder, render, or drift paths.")
            print(f"{key} detail: {type(exc).__name__}: {exc}")
            failures.append(key)
            continue

        ok = resolved is None and reason == "UNKNOWN_OCCURRENCE" and context_time == 0 and rendered == [] and observed["driftByEvent"] == {}
        status = "PASS" if ok else "FAIL"
        print(f"{status}: {key} - Malformed occurrence rows should degrade without a render or drift crash.")
        print(f"{key} detail: resolved={resolved} reason={reason} context_time={context_time} rendered={rendered} observed={observed}")
        if not ok:
            failures.append(key)

    if failures:
        print("\nPartial entry shape audit failed:", ", ".join(failures))
        return 1

    print("\nPartial entry shape audit passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
