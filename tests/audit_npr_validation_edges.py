import json

from test_npr_logic import (
    apply_editor_numeric_corrections,
    normalize_selection_state,
    resolve_reminder_time,
    suggest_reminder_defaults,
)


def emit(label, payload):
    print(f"{label} {json.dumps(payload, sort_keys=True)}")


def main():
    invalid_editor = apply_editor_numeric_corrections("oops", "later")
    assert invalid_editor == {
        "iconText": "",
        "offsetText": "0.0",
        "durationText": "6.0",
        "notes": [
            "Icon spell ID must be numeric or empty. Invalid value cleared.",
            "Offset must be a valid number. Reset to 0.0s.",
        ],
    }
    emit("editor-invalid", invalid_editor)

    normalized_editor = apply_editor_numeric_corrections(" 42001.9 ", " -3.26 ")
    assert normalized_editor == {
        "iconText": "42001",
        "offsetText": "-3.3",
        "durationText": "6.0",
        "notes": [],
    }
    emit("editor-normalized", normalized_editor)

    defaults_high = suggest_reminder_defaults("reflux_charge", 75)
    assert defaults_high == {
        "soundKey": "RAID_WARNING",
        "importance": "HIGH",
        "prefillNote": "Sound and importance were prefilled from the event danger. Change them if needed.",
    }
    emit("defaults-high", defaults_high)

    defaults_medium = suggest_reminder_defaults("reflux_charge", 45)
    assert defaults_medium == {
        "soundKey": "READY_CHECK",
        "importance": "MEDIUM",
        "prefillNote": "Sound and importance were prefilled from the event danger. Change them if needed.",
    }
    emit("defaults-medium", defaults_medium)

    defaults_low = suggest_reminder_defaults("reflux_charge", 44)
    assert defaults_low == {
        "soundKey": "NONE",
        "importance": "MEDIUM",
        "prefillNote": None,
    }
    emit("defaults-low", defaults_low)

    defaults_pull = suggest_reminder_defaults("pull_anchor", 100)
    assert defaults_pull == {
        "soundKey": "NONE",
        "importance": "MEDIUM",
        "prefillNote": None,
    }
    emit("defaults-pull", defaults_pull)

    defaults = {
        "selectedDungeonKey": "nexus_point_xenas",
        "selectedEncounterKey": "kasreth",
        "selectedEncounterByDungeon": {"nexus_point_xenas": "kasreth"},
    }
    encounter_order = {
        "nexus_point_xenas": ["kasreth", "nysarra", "lothraxion"],
        "magisters_terrace": [],
    }

    switch_to_incomplete = normalize_selection_state(
        {
            "selectedDungeonKey": "magisters_terrace",
            "selectedEncounterByDungeon": {
                "nexus_point_xenas": "lothraxion",
                "magisters_terrace": "stale_boss",
            },
            "selectedEncounterKey": "stale_boss",
        },
        set(encounter_order.keys()),
        encounter_order,
        defaults,
    )
    assert switch_to_incomplete == {
        "selectedDungeonKey": "magisters_terrace",
        "selectedEncounterKey": None,
        "selectedEncounterByDungeon": {
            "magisters_terrace": None,
            "nexus_point_xenas": "lothraxion",
        },
    }
    emit("switch-to-incomplete", switch_to_incomplete)

    return_to_wired = normalize_selection_state(
        {
            "selectedDungeonKey": "nexus_point_xenas",
            "selectedEncounterByDungeon": {
                "nexus_point_xenas": "nysarra",
                "magisters_terrace": None,
            },
            "selectedEncounterKey": "nysarra",
        },
        set(encounter_order.keys()),
        encounter_order,
        defaults,
    )
    assert return_to_wired == {
        "selectedDungeonKey": "nexus_point_xenas",
        "selectedEncounterKey": "nysarra",
        "selectedEncounterByDungeon": {
            "magisters_terrace": None,
            "nexus_point_xenas": "nysarra",
        },
    }
    emit("return-to-wired", return_to_wired)

    unknown_occurrence = resolve_reminder_time(
        {"kasreth": {"reflux_charge": {"entries": [{"time": 12.1}]}}},
        {
            "encounterKey": "kasreth",
            "eventKey": "reflux_charge",
            "occurrence": 2,
            "offsetSeconds": 0,
        },
    )
    assert unknown_occurrence == (None, "UNKNOWN_OCCURRENCE")
    emit(
        "unknown-occurrence",
        {"resolved": unknown_occurrence[0], "reason": unknown_occurrence[1]},
    )

    print("Validation edge audit passed.")


if __name__ == "__main__":
    main()
