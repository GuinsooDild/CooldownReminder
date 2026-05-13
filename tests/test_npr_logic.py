from pathlib import Path
import math
import re
import unittest


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")
ADDON = ROOT / "CooldownReminder"
SEASON_SELECTOR_ORDER = [
    "magisters_terrace",
    "maisara_caverns",
    "nexus_point_xenas",
    "windrunner_spire",
    "algethar_academy",
    "pit_of_saron",
    "seat_of_the_triumvirate",
    "skyreach",
]
ALLOWED_CHALLENGE_MAP_ID_POSTURES = {"confirmed", "provisional", "intentionally_nil"}
SKYREACH_REGISTRY_TOKENS = [
    'ranjit = BuildEncounterSeed("ranjit", "Ranjit", 965, 1698)',
    'araknath = BuildEncounterSeed("araknath", "Araknath", 966, 1699)',
    'rukhran = BuildEncounterSeed("rukhran", "Rukhran", 967, 1700)',
    'high_sage_viryx = BuildEncounterSeed("high_sage_viryx", "High Sage Viryx", 968, 1701)',
]
SEAT_REGISTRY_TOKENS = [
    'zuraal_the_ascended = BuildEncounterSeed("zuraal_the_ascended", "Zuraal the Ascended", 1979, 2065)',
    'saprish = BuildEncounterSeed("saprish", "Saprish", 1980, 2066)',
    'viceroy_nezhar = BuildEncounterSeed("viceroy_nezhar", "Viceroy Nezhar", 1981, 2067)',
    "lura = BuildEncounterSeed(\"lura\", \"L'ura\", 1982, 2068)",
]
ALGETHAR_PROOF_ORDER_TOKENS = [
    'BuildEncounterSeed("overgrown_ancient", "Overgrown Ancient", 2563, 2563)',
    'BuildEncounterSeed("crawth", "Crawth", 2564, 2564)',
    'BuildEncounterSeed("vexamus", "Vexamus", 2562, 2562)',
    'BuildEncounterSeed("echo_of_doragosa", "Echo of Doragosa", 2565, 2565)',
]


def load_season_registry():
    return (ADDON / "Data" / "SeasonRegistry.lua").read_text()


def parse_season_registry_builds(registry_text):
    pattern = re.compile(
        r'(?P<field>\w+)\s*=\s*BuildDungeon\(\s*"(?P<dungeonKey>[^"]+)",\s*"(?P<displayName>[^"]+)",\s*(?P<selectorOrder>\d+),\s*(?P<journalInstanceID>\d+),\s*(?P<mapID>\d+),\s*(?P<challengeMapID>nil|\d+),\s*"(?P<challengeMapIDPosture>confirmed|provisional|intentionally_nil)",\s*(?P<totalBossCount>\d+),',
        re.S,
    )
    builds = {}
    for match in pattern.finditer(registry_text):
        builds[match.group("field")] = {
            "dungeonKey": match.group("dungeonKey"),
            "displayName": match.group("displayName"),
            "selectorOrder": int(match.group("selectorOrder")),
            "journalInstanceID": int(match.group("journalInstanceID")),
            "mapID": int(match.group("mapID")),
            "challengeMapID": None if match.group("challengeMapID") == "nil" else int(match.group("challengeMapID")),
            "challengeMapIDPosture": match.group("challengeMapIDPosture"),
            "totalBossCount": int(match.group("totalBossCount")),
        }
    return builds


def parse_mapped_boss_counts():
    counts = {dungeon_key: 0 for dungeon_key in SEASON_SELECTOR_ORDER}
    pattern = re.compile(
        r'NPR\.Data\.dungeons\.(?P<dungeonKey>\w+).*?dungeon\.encounterOrder\s*=\s*\{(?P<encounters>.*?)\}',
        re.S,
    )

    for path in (ADDON / "Data").glob("*.lua"):
        content = path.read_text()
        for match in pattern.finditer(content):
            encounter_keys = re.findall(r'"([^"]+)"', match.group("encounters"))
            counts[match.group("dungeonKey")] = len(encounter_keys)
        proof_pattern = re.compile(
            r'ApplyProofCoverage\(\s*"(?P<dungeonKey>\w+)",\s*\{(?P<encounters>.*?)\}',
            re.S,
        )
        for match in proof_pattern.finditer(content):
            encounter_keys = re.findall(r'"([^"]+)"', match.group("encounters"))
            counts[match.group("dungeonKey")] = len(encounter_keys)

    return counts


def get_event_entries(event):
    if not isinstance(event, dict):
        return []
    entries = event.get("entries")
    return entries if isinstance(entries, list) else []


def get_event_occurrence(event, occurrence_index):
    entries = get_event_entries(event)
    occurrence_index = max(0, int(occurrence_index or 1) - 1)
    if occurrence_index >= len(entries):
        return None
    occurrence = entries[occurrence_index]
    if not isinstance(occurrence, dict) or not isinstance(occurrence.get("time"), (int, float)):
        return None
    return occurrence


def resolve_reminder_time(events_by_encounter, reminder):
    encounter_events = events_by_encounter.get(reminder["encounterKey"], {})
    event = encounter_events.get(reminder["eventKey"])
    if event is None:
        return None, "UNKNOWN_EVENT"

    occurrence = get_event_occurrence(event, reminder.get("occurrence", 1))
    if occurrence is None:
        return None, "UNKNOWN_OCCURRENCE"

    return occurrence["time"] + reminder.get("offsetSeconds", 0), None


def get_reminder_context_time(events_by_encounter, reminder):
    event = events_by_encounter.get(reminder.get("encounterKey"), {}).get(reminder.get("eventKey"))
    occurrence = get_event_occurrence(event, reminder.get("occurrence", 1))
    return occurrence["time"] if occurrence else 0


def render_occurrence_times(event):
    return [
        entry.get("time")
        for entry in get_event_entries(event)
        if isinstance(entry, dict) and isinstance(entry.get("time"), (int, float))
    ]


def observe_event(bucket, event, elapsed):
    event_key = event.get("key", "event")
    next_count = bucket["eventCounts"].get(event_key, 0) + 1
    bucket["eventCounts"][event_key] = next_count
    expected = get_event_occurrence(event, next_count)
    if expected is not None:
        bucket["driftByEvent"][event_key] = round_half_away_from_zero(elapsed - expected["time"], 2)
    return bucket


def rebuild_indexes(reminders, events_by_encounter=None):
    index = {}
    for reminder_id, reminder in reminders.items():
        reminder = dict(reminder)
        if not reminder.get("encounterKey") or not reminder.get("eventKey"):
            continue
        reminder["id"] = reminder_id
        reminder["occurrence"] = max(1, int(reminder.get("occurrence", 1)))
        reminder["offsetSeconds"] = round(float(reminder.get("offsetSeconds", 0)), 1)
        reminder["enabled"] = reminder.get("enabled", True) is not False
        reminder["text"] = reminder.get("text", "") or ""
        reminder["importance"] = reminder.get("importance", "MEDIUM")
        reminder["durationSeconds"] = min(20, max(2, round(float(reminder.get("durationSeconds", 6)), 1)))
        reminder["roleScope"] = reminder.get("roleScope", "ALL")
        index.setdefault(reminder["encounterKey"], []).append(reminder)

    for encounter_key in index:
        encounter_events = (events_by_encounter or {}).get(encounter_key, {})

        def resolved_sort_key(reminder):
            resolved, _ = resolve_reminder_time({encounter_key: encounter_events}, reminder)
            if resolved is None:
                return (1, float("inf"), reminder["id"])
            return (0, resolved, reminder["id"])

        index[encounter_key].sort(
            key=lambda reminder: (
                0 if reminder.get("enabled", True) else 1,
                *resolved_sort_key(reminder),
            ),
        )
    return index


def duplicate_reminder(store, reminder_id, new_id):
    source = store[reminder_id]
    copied = dict(source)
    copied["id"] = new_id
    copied["copiedFromReminderID"] = reminder_id
    store[new_id] = copied
    return rebuild_indexes(store).get(copied["encounterKey"], [])


def build_runtime_queue(events_by_encounter, reminders, encounter_key):
    queue = []
    for reminder in rebuild_indexes(reminders, events_by_encounter).get(encounter_key, []):
        if not reminder.get("enabled", True):
            continue
        resolved_time, reason = resolve_reminder_time(events_by_encounter, reminder)
        if reason is not None:
            continue
        queue.append((reminder["id"], max(0, resolved_time)))
    return queue


def count_unknown_reminders(events_by_encounter, reminders, encounter_key):
    count = 0
    for reminder in rebuild_indexes(reminders, events_by_encounter).get(encounter_key, []):
        resolved, reason = resolve_reminder_time(events_by_encounter, reminder)
        if resolved is None and reason is not None:
            count += 1
    return count


def get_reminder_display_label(events_by_encounter, reminder):
    text = reminder.get("text")
    if isinstance(text, str) and text:
        return text
    if reminder.get("eventKey") == "pull_anchor":
        return "Pull reminder"
    event = events_by_encounter.get(reminder.get("encounterKey"), {}).get(reminder.get("eventKey"))
    if event and event.get("label"):
        return event["label"]
    return "Reminder"


def get_reminder_issue_label(reason):
    if reason == "UNKNOWN_EVENT":
        return "missing event"
    if reason == "UNKNOWN_OCCURRENCE":
        return "missing occurrence"
    return "unresolved timing"


def get_next_validation_target(events_by_encounter, reminders, encounter_key, observations=None, encounter_data=None):
    indexed = rebuild_indexes(reminders, events_by_encounter).get(encounter_key, [])
    unknown_count = 0
    first_unknown = None
    for reminder in indexed:
        _, reason = resolve_reminder_time(events_by_encounter, reminder)
        if reason is not None:
            unknown_count += 1
            if first_unknown is None:
                first_unknown = f'{get_reminder_display_label(events_by_encounter, reminder)} ({get_reminder_issue_label(reason)})'

    if first_unknown is not None:
        suffix = f" (+{unknown_count - 1} more)" if unknown_count > 1 else ""
        return "Fix " + first_unknown + suffix

    bucket = (observations or {}).get(encounter_key, {})
    best_drift = None
    best_abs = None
    for event_key, drift in (bucket.get("driftByEvent") or {}).items():
        drift = float(drift)
        drift_abs = abs(drift)
        if best_abs is None or drift_abs > best_abs:
            label = events_by_encounter.get(encounter_key, {}).get(event_key, {}).get("label", event_key)
            best_drift = f"{label} {drift:+.1f}s"
            best_abs = drift_abs

    if best_drift is not None:
        return "Validate " + best_drift

    reference_only = ((encounter_data or {}).get(encounter_key, {}) or {}).get("referenceOnlySpells") or []
    for info in reference_only:
        label = info.get("label")
        if label:
            return "Time " + label

    return None


def normalize_minimap_settings(settings, fallback):
    angle = settings.get("angle", fallback["angle"])
    try:
        angle = float(angle) % 360
    except (TypeError, ValueError):
        angle = fallback["angle"]

    return {
        "hide": settings.get("hide", False) is True,
        "angle": angle,
    }


def resolve_player_role(group_role, spec_role):
    if group_role and group_role != "NONE":
        return group_role, "group"
    if spec_role and spec_role not in ("NONE", 0):
        return spec_role, "specialization"
    return "DAMAGER", "fallback"


def matches_combat_log_event(event, sub_event, spell_id):
    if not event or not sub_event:
        return False

    if event.get("combatLogEvent") and event["combatLogEvent"] != sub_event:
        return False

    preferred_ids = event.get("combatLogSpellIDs")
    if preferred_ids:
        return int(spell_id) in {int(candidate) for candidate in preferred_ids}

    if event.get("eventSpellID"):
        return int(event["eventSpellID"]) == int(spell_id)

    spell_ids = event.get("spellIDs") or []
    return int(spell_id) in {int(candidate) for candidate in spell_ids}


def round_half_away_from_zero(value, decimals=0):
    factor = 10 ** decimals
    scaled = value * factor
    if scaled < 0:
        return math.ceil(scaled - 0.5) / factor
    return math.floor(scaled + 0.5) / factor


def normalize_text(value):
    if not isinstance(value, str):
        return ""
    return value.strip()


def apply_editor_numeric_corrections(icon_text, offset_text, duration_text="6.0"):
    notes = []

    icon_text = normalize_text(icon_text)
    try:
        icon_value = float(icon_text) if icon_text != "" else None
    except ValueError:
        icon_value = None

    if icon_text != "" and (icon_value is None or icon_value <= 0):
        icon_text = ""
        notes.append("Icon spell ID must be numeric or empty. Invalid value cleared.")
    elif icon_value is not None and icon_value > 0:
        icon_text = str(math.floor(icon_value))

    offset_text = normalize_text(offset_text)
    try:
        offset_value = float(offset_text) if offset_text != "" else None
    except ValueError:
        offset_value = None

    if offset_text == "":
        offset_text = "0.0"
    elif offset_value is None:
        offset_text = "0.0"
        notes.append("Offset must be a valid number. Reset to 0.0s.")
    else:
        offset_text = f"{round_half_away_from_zero(offset_value, 1):.1f}"

    duration_text = normalize_text(duration_text)
    try:
        duration_value = float(duration_text) if duration_text != "" else None
    except ValueError:
        duration_value = None

    if duration_text == "":
        duration_text = "6.0"
    elif duration_value is None or duration_value <= 0:
        duration_text = "6.0"
        notes.append("Display duration must be a positive number. Reset to 6.0s.")
    else:
        duration_text = f"{min(20, max(2, round_half_away_from_zero(duration_value, 1))):.1f}"

    return {
        "iconText": icon_text,
        "offsetText": offset_text,
        "durationText": duration_text,
        "notes": notes,
    }


def suggest_reminder_defaults(event_key, danger_percent):
    if event_key == "pull_anchor":
        return {
            "soundKey": "NONE",
            "importance": "MEDIUM",
            "prefillNote": None,
        }

    if danger_percent >= 75:
        return {
            "soundKey": "RAID_WARNING",
            "importance": "HIGH",
            "prefillNote": "Sound and importance were prefilled from the event danger. Change them if needed.",
        }

    if danger_percent >= 45:
        return {
            "soundKey": "READY_CHECK",
            "importance": "MEDIUM",
            "prefillNote": "Sound and importance were prefilled from the event danger. Change them if needed.",
        }

    return {
        "soundKey": "NONE",
        "importance": "MEDIUM",
        "prefillNote": None,
    }


def normalize_selection_state(state, known_dungeons, encounter_order, defaults):
    selected_dungeon_key = state.get("selectedDungeonKey")
    if selected_dungeon_key not in known_dungeons:
        selected_dungeon_key = defaults["selectedDungeonKey"]
    if selected_dungeon_key not in known_dungeons:
        selected_dungeon_key = next(iter(known_dungeons), None)

    selected_by_dungeon = dict(state.get("selectedEncounterByDungeon") or {})
    legacy_encounter_key = state.get("selectedEncounterKey")
    if selected_dungeon_key and selected_by_dungeon.get(selected_dungeon_key) is None and legacy_encounter_key:
        selected_by_dungeon[selected_dungeon_key] = legacy_encounter_key

    normalized_by_dungeon = {}
    for dungeon_key, encounter_key in selected_by_dungeon.items():
        if dungeon_key not in known_dungeons:
            continue
        valid_encounters = encounter_order.get(dungeon_key, [])
        fallback_encounter = defaults["selectedEncounterByDungeon"].get(dungeon_key) or defaults["selectedEncounterKey"]
        if encounter_key not in valid_encounters:
            encounter_key = fallback_encounter if fallback_encounter in valid_encounters else (valid_encounters[0] if valid_encounters else None)
        normalized_by_dungeon[dungeon_key] = encounter_key

    if selected_dungeon_key:
        valid_encounters = encounter_order.get(selected_dungeon_key, [])
        selected_encounter_key = normalized_by_dungeon.get(selected_dungeon_key)
        if selected_encounter_key not in valid_encounters:
            fallback_encounter = defaults["selectedEncounterByDungeon"].get(selected_dungeon_key) or defaults["selectedEncounterKey"]
            if fallback_encounter in valid_encounters:
                selected_encounter_key = fallback_encounter
            else:
                selected_encounter_key = valid_encounters[0] if valid_encounters else None
        normalized_by_dungeon[selected_dungeon_key] = selected_encounter_key
    else:
        selected_encounter_key = None

    return {
        "selectedDungeonKey": selected_dungeon_key,
        "selectedEncounterKey": selected_encounter_key,
        "selectedEncounterByDungeon": normalized_by_dungeon,
    }


def grid_position(index, columns):
    column = (index - 1) % columns
    row = math.floor((index - 1) / columns)
    return column, row


class TestReminderLogic(unittest.TestCase):
    def setUp(self):
        self.events = {
            "kasreth": {
                "pull_anchor": {"entries": [{"time": 0}]},
                "reflux_charge": {
                    "entries": [
                        {"time": 14},
                        {"time": 43},
                    ]
                },
                "corespark_detonation": {
                    "entries": [
                        {"time": 28},
                    ]
                },
            }
        }

    def test_resolve_occurrence_time(self):
        reminder = {
            "encounterKey": "kasreth",
            "eventKey": "reflux_charge",
            "occurrence": 2,
            "offsetSeconds": -3.5,
        }
        resolved, reason = resolve_reminder_time(self.events, reminder)
        self.assertEqual(reason, None)
        self.assertAlmostEqual(resolved, 39.5)

    def test_unknown_event(self):
        resolved, reason = resolve_reminder_time(
            self.events,
            {
                "encounterKey": "kasreth",
                "eventKey": "missing",
                "occurrence": 1,
                "offsetSeconds": 0,
            },
        )
        self.assertIsNone(resolved)
        self.assertEqual(reason, "UNKNOWN_EVENT")

    def test_unknown_occurrence(self):
        resolved, reason = resolve_reminder_time(
            self.events,
            {
                "encounterKey": "kasreth",
                "eventKey": "corespark_detonation",
                "occurrence": 5,
                "offsetSeconds": 0,
            },
        )
        self.assertIsNone(resolved)
        self.assertEqual(reason, "UNKNOWN_OCCURRENCE")

    def test_missing_entries_resolve_as_unknown_occurrence(self):
        resolved, reason = resolve_reminder_time(
            {"kasreth": {"reflux_charge": {}}},
            {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "offsetSeconds": 0,
            },
        )
        self.assertIsNone(resolved)
        self.assertEqual(reason, "UNKNOWN_OCCURRENCE")

    def test_false_entries_resolve_as_unknown_occurrence(self):
        resolved, reason = resolve_reminder_time(
            {"kasreth": {"reflux_charge": {"entries": False}}},
            {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "offsetSeconds": 0,
            },
        )
        self.assertIsNone(resolved)
        self.assertEqual(reason, "UNKNOWN_OCCURRENCE")

    def test_malformed_entry_rows_resolve_as_unknown_occurrence(self):
        malformed_events = [
            {"entries": [False]},
            {"entries": ["not-a-row"]},
            {"entries": [{"duration": 4.0}]},
            {"entries": [{"time": "soon", "duration": 4.0}]},
        ]
        reminder = {
            "encounterKey": "kasreth",
            "eventKey": "reflux_charge",
            "occurrence": 1,
            "offsetSeconds": 0,
        }

        for event in malformed_events:
            with self.subTest(event=event):
                resolved, reason = resolve_reminder_time({"kasreth": {"reflux_charge": event}}, reminder)
                self.assertIsNone(resolved)
                self.assertEqual(reason, "UNKNOWN_OCCURRENCE")

    def test_context_time_defaults_to_zero_without_entries(self):
        context_time = get_reminder_context_time(
            {"kasreth": {"reflux_charge": {}}},
            {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
            },
        )
        self.assertEqual(context_time, 0)

    def test_render_occurrences_skips_missing_entries(self):
        self.assertEqual(render_occurrence_times({"label": "Partial event"}), [])
        self.assertEqual(render_occurrence_times({"entries": False}), [])
        self.assertEqual(
            render_occurrence_times({"entries": [False, {"duration": 3.0}, {"time": "soon"}, {"time": 12.5}]}),
            [12.5],
        )

    def test_observe_event_skips_drift_without_entries(self):
        bucket = {"eventCounts": {}, "driftByEvent": {}}
        updated = observe_event(bucket, {"key": "partial_event", "entries": False}, 19.4)
        self.assertEqual(updated["eventCounts"]["partial_event"], 1)
        self.assertNotIn("partial_event", updated["driftByEvent"])

    def test_observe_event_skips_drift_for_malformed_entry_row(self):
        bucket = {"eventCounts": {}, "driftByEvent": {}}
        updated = observe_event(bucket, {"key": "partial_event", "entries": [{"duration": 4.0}]}, 19.4)
        self.assertEqual(updated["eventCounts"]["partial_event"], 1)
        self.assertNotIn("partial_event", updated["driftByEvent"])

    def test_editor_corrections_clear_invalid_numeric_fields(self):
        corrected = apply_editor_numeric_corrections("not-a-spell", "soon", "forever")
        self.assertEqual(corrected["iconText"], "")
        self.assertEqual(corrected["offsetText"], "0.0")
        self.assertEqual(corrected["durationText"], "6.0")
        self.assertEqual(
            corrected["notes"],
            [
                "Icon spell ID must be numeric or empty. Invalid value cleared.",
                "Offset must be a valid number. Reset to 0.0s.",
                "Display duration must be a positive number. Reset to 6.0s.",
            ],
        )

    def test_editor_corrections_normalize_valid_numeric_fields(self):
        corrected = apply_editor_numeric_corrections("12345.9", " -3.26 ", " 21.4 ")
        self.assertEqual(corrected["iconText"], "12345")
        self.assertEqual(corrected["offsetText"], "-3.3")
        self.assertEqual(corrected["durationText"], "20.0")
        self.assertEqual(corrected["notes"], [])

    def test_editor_defaults_high_danger_event(self):
        defaults = suggest_reminder_defaults("reflux_charge", 82)
        self.assertEqual(defaults["soundKey"], "RAID_WARNING")
        self.assertEqual(defaults["importance"], "HIGH")
        self.assertIn("prefilled", defaults["prefillNote"])

    def test_editor_defaults_pull_anchor_stay_quiet(self):
        defaults = suggest_reminder_defaults("pull_anchor", 100)
        self.assertEqual(defaults["soundKey"], "NONE")
        self.assertEqual(defaults["importance"], "MEDIUM")
        self.assertIsNone(defaults["prefillNote"])

    def test_rebuild_indexes_groups_by_encounter(self):
        reminders = {
            "a": {"encounterKey": "kasreth", "eventKey": "reflux_charge", "enabled": True, "offsetSeconds": 4},
            "b": {"encounterKey": "kasreth", "eventKey": "reflux_charge", "enabled": False, "offsetSeconds": -2},
            "c": {"encounterKey": "nysarra", "eventKey": "eclipsing_step", "enabled": True, "offsetSeconds": 0},
        }
        index = rebuild_indexes(reminders, self.events)
        self.assertEqual([item["id"] for item in index["kasreth"]], ["a", "b"])
        self.assertEqual([item["id"] for item in index["nysarra"]], ["c"])

    def test_rebuild_indexes_skips_invalid_reminder(self):
        reminders = {
            "bad": {"encounterKey": "kasreth"},
            "good": {"encounterKey": "kasreth", "eventKey": "reflux_charge"},
        }
        index = rebuild_indexes(reminders, self.events)
        self.assertEqual([item["id"] for item in index["kasreth"]], ["good"])

    def test_end_to_end_create_edit_reload_flow(self):
        store = {}
        reminder_id = "abc123"
        store[reminder_id] = {
            "encounterKey": "kasreth",
            "eventKey": "reflux_charge",
            "occurrence": 1,
            "offsetSeconds": -2.0,
            "enabled": True,
            "text": "Pre-move left",
            "iconSpellID": None,
            "soundKey": "RAID_WARNING",
            "importance": "HIGH",
            "durationSeconds": 8.5,
            "roleScope": "HEALER",
        }

        first_index = rebuild_indexes(store, self.events)
        self.assertEqual(first_index["kasreth"][0]["id"], reminder_id)

        resolved, reason = resolve_reminder_time(self.events, first_index["kasreth"][0])
        self.assertEqual(reason, None)
        self.assertAlmostEqual(resolved, 12.0)

        store[reminder_id]["text"] = "Pre-move and ramp"
        store[reminder_id]["offsetSeconds"] = -3.0

        reloaded_index = rebuild_indexes(dict(store), self.events)
        reloaded = reloaded_index["kasreth"][0]
        self.assertEqual(reloaded["text"], "Pre-move and ramp")
        self.assertAlmostEqual(resolve_reminder_time(self.events, reloaded)[0], 11.0)
        self.assertAlmostEqual(reloaded["durationSeconds"], 8.5)

    def test_duplicate_reminder_preserves_editable_setup(self):
        store = {
            "source": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 2,
                "offsetSeconds": -4.0,
                "enabled": True,
                "text": "Ramp now",
                "iconSpellID": 12345,
                "soundKey": "RAID_WARNING",
                "importance": "HIGH",
                "durationSeconds": 9.5,
                "roleScope": "HEALER",
            }
        }

        indexed = duplicate_reminder(store, "source", "copy")
        copied = next(item for item in indexed if item["id"] == "copy")

        self.assertEqual(copied["encounterKey"], "kasreth")
        self.assertEqual(copied["eventKey"], "reflux_charge")
        self.assertEqual(copied["occurrence"], 2)
        self.assertEqual(copied["offsetSeconds"], -4.0)
        self.assertEqual(copied["text"], "Ramp now")
        self.assertEqual(copied["soundKey"], "RAID_WARNING")
        self.assertEqual(copied["importance"], "HIGH")
        self.assertEqual(copied["roleScope"], "HEALER")
        self.assertEqual(copied["durationSeconds"], 9.5)
        self.assertEqual(store["copy"]["copiedFromReminderID"], "source")

    def test_rebuild_indexes_uses_resolved_time_order(self):
        reminders = {
            "later": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 2,
                "offsetSeconds": 0,
                "enabled": True,
            },
            "earlier": {
                "encounterKey": "kasreth",
                "eventKey": "corespark_detonation",
                "occurrence": 1,
                "offsetSeconds": -10,
                "enabled": True,
            },
        }
        index = rebuild_indexes(reminders, self.events)
        self.assertEqual([item["id"] for item in index["kasreth"]], ["earlier", "later"])

    def test_runtime_queue_clamps_negative_offsets(self):
        reminders = {
            "early": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "offsetSeconds": -40,
                "enabled": True,
            },
            "normal": {
                "encounterKey": "kasreth",
                "eventKey": "corespark_detonation",
                "occurrence": 1,
                "offsetSeconds": -3,
                "enabled": True,
            },
            "disabled": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 2,
                "offsetSeconds": 0,
                "enabled": False,
            },
        }
        queue = build_runtime_queue(self.events, reminders, "kasreth")
        self.assertEqual(queue, [("early", 0), ("normal", 25)])

    def test_unknown_reminder_count(self):
        reminders = {
            "ok": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "enabled": True,
            },
            "missing-event": {
                "encounterKey": "kasreth",
                "eventKey": "missing",
                "occurrence": 1,
                "enabled": True,
            },
            "missing-occurrence": {
                "encounterKey": "kasreth",
                "eventKey": "corespark_detonation",
                "occurrence": 9,
                "enabled": True,
            },
        }
        self.assertEqual(count_unknown_reminders(self.events, reminders, "kasreth"), 2)

    def test_next_validation_target_prefers_unknown_binding(self):
        reminders = {
            "good": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "enabled": True,
            },
            "bad": {
                "encounterKey": "kasreth",
                "eventKey": "missing",
                "occurrence": 1,
                "enabled": True,
                "text": "Custom note",
            },
        }
        target = get_next_validation_target(
            self.events,
            reminders,
            "kasreth",
            observations={"kasreth": {"driftByEvent": {"reflux_charge": 1.3}}},
        )
        self.assertEqual(target, "Fix Custom note (missing event)")

    def test_next_validation_target_uses_largest_drift_when_bindings_are_clean(self):
        reminders = {
            "good": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "enabled": True,
            },
        }
        target = get_next_validation_target(
            self.events,
            reminders,
            "kasreth",
            observations={"kasreth": {"driftByEvent": {"reflux_charge": 1.3, "corespark_detonation": -2.6}}},
        )
        self.assertEqual(target, "Validate corespark_detonation -2.6s")

    def test_next_validation_target_falls_back_to_reference_only_spell(self):
        reminders = {
            "good": {
                "encounterKey": "kasreth",
                "eventKey": "reflux_charge",
                "occurrence": 1,
                "enabled": True,
            },
        }
        target = get_next_validation_target(
            self.events,
            reminders,
            "kasreth",
            encounter_data={
                "kasreth": {
                    "referenceOnlySpells": [
                        {"label": "Arcane Zap"},
                    ]
                }
            },
        )
        self.assertEqual(target, "Time Arcane Zap")

    def test_player_role_prefers_group_assignment(self):
        role, source = resolve_player_role("HEALER", "DAMAGER")
        self.assertEqual(role, "HEALER")
        self.assertEqual(source, "group")

    def test_player_role_falls_back_to_specialization(self):
        role, source = resolve_player_role("NONE", "TANK")
        self.assertEqual(role, "TANK")
        self.assertEqual(source, "specialization")

    def test_player_role_falls_back_to_damager_last(self):
        role, source = resolve_player_role("NONE", None)
        self.assertEqual(role, "DAMAGER")
        self.assertEqual(source, "fallback")

    def test_combat_log_match_uses_trigger_spell_id(self):
        event = {
            "combatLogEvent": "SPELL_CAST_START",
            "combatLogSpellIDs": [1251767],
            "eventSpellID": 1251767,
            "spellIDs": [1251767, 1251772],
        }
        self.assertTrue(matches_combat_log_event(event, "SPELL_CAST_START", 1251767))
        self.assertFalse(matches_combat_log_event(event, "SPELL_AURA_APPLIED", 1251767))
        self.assertFalse(matches_combat_log_event(event, "SPELL_CAST_START", 1251772))

    def test_combat_log_match_falls_back_to_event_spell_id(self):
        event = {
            "eventSpellID": 1247937,
            "spellIDs": [1247937, 1248007],
        }
        self.assertTrue(matches_combat_log_event(event, "SPELL_CAST_START", 1247937))
        self.assertFalse(matches_combat_log_event(event, "SPELL_CAST_START", 1248007))

    def test_round_half_away_from_zero_positive(self):
        self.assertEqual(round_half_away_from_zero(3.25, 1), 3.3)

    def test_round_half_away_from_zero_negative(self):
        self.assertEqual(round_half_away_from_zero(-3.25, 1), -3.3)
        self.assertEqual(round_half_away_from_zero(-3.75, 1), -3.8)

    def test_normalize_text_trims_whitespace_only_to_empty(self):
        self.assertEqual(normalize_text("   "), "")
        self.assertEqual(normalize_text("  ramp now  "), "ramp now")

    def test_grid_position_wraps_to_next_row(self):
        self.assertEqual(grid_position(1, 3), (0, 0))
        self.assertEqual(grid_position(3, 3), (2, 0))
        self.assertEqual(grid_position(4, 3), (0, 1))


class TestWorkspaceArtifacts(unittest.TestCase):
    def test_required_files_exist(self):
        required = [
            ADDON / "CooldownReminder.toc",
            ADDON / "README.md",
            ADDON / "Core" / "Addon.lua",
            ADDON / "Data" / "SeasonRegistry.lua",
            ADDON / "Data" / "NexusPointXenas.lua",
            ADDON / "UI" / "MainWindow.lua",
            ADDON / "UI" / "Editor.lua",
            ADDON / "Runtime" / "Scheduler.lua",
            ROOT / "ASSUMPTIONS.md",
            ROOT / "AGENTS.md",
            ROOT / "project_control" / "AGENT_BRIEF.md",
            ROOT / "project_control" / "WORKLOG.md",
            ROOT / "project_control" / "TODO.md",
            ROOT / "project_control" / "VALIDATION.md",
        ]
        for path in required:
            self.assertTrue(path.exists(), f"Missing required artifact: {path}")

        self.assertFalse((ROOT / "WORKLOG.md").exists())
        self.assertFalse((ROOT / "TODO.md").exists())
        self.assertFalse((ROOT / "VALIDATION.md").exists())

    def test_click_handlers_are_present(self):
        main_window = (ADDON / "UI" / "MainWindow.lua").read_text()
        editor = (ADDON / "UI" / "Editor.lua").read_text()
        widgets = (ADDON / "UI" / "Widgets.lua").read_text()
        slash = (ADDON / "Core" / "Slash.lua").read_text()

        self.assertIn('local timelineView = CreateFrame("Frame", nil, content)', main_window)
        self.assertIn('timelineView:EnableMouse(true)', main_window)
        self.assertIn('timelineView:SetScript("OnMouseUp", function(_, button)', main_window)
        self.assertIn('if button == "LeftButton" or button == "RightButton" then', main_window)
        self.assertIn('if now - lastLeftClickTime < 0.30 then', main_window)
        self.assertIn('button:RegisterForClicks("LeftButtonUp")', main_window)
        self.assertIn('button:SetScript("OnClick"', main_window)
        self.assertIn('local reminderID = reminder.id', main_window)
        self.assertIn('"Hide minimap"', main_window)
        self.assertIn('controls.save = self:CreateButton', editor)
        self.assertIn('controls.text:SetScript("OnEnterPressed"', editor)
        self.assertIn('controls.copy = self:CreateButton', editor)
        self.assertIn('self:DuplicateReminder(reminderID)', editor)
        self.assertIn('Display duration (s)', editor)
        self.assertIn('function NPR:CreateCheckButton', widgets)
        self.assertIn('check:SetHitRectInsets', widgets)
        self.assertIn('command == "minimap" or command == "icon"', slash)

    def test_reminder_duplication_and_duration_source_paths_exist(self):
        defaults = (ADDON / "Core" / "Defaults.lua").read_text()
        storage = (ADDON / "Core" / "Storage.lua").read_text()
        util = (ADDON / "Core" / "Util.lua").read_text()
        scheduler = (ADDON / "Runtime" / "Scheduler.lua").read_text()
        main_window = (ADDON / "UI" / "MainWindow.lua").read_text()

        self.assertIn("durationSeconds = 6", defaults)
        self.assertIn("function NPR:DuplicateReminder(reminderID)", storage)
        self.assertIn("copy.copiedFromReminderID = reminderID", storage)
        self.assertIn("normalized.durationSeconds", storage)
        self.assertIn("function NPR:GetReminderDisplaySeconds(reminder)", util)
        self.assertIn("local duration = self:GetReminderDisplaySeconds(reminder)", scheduler)
        self.assertIn("Display: %.1fs", main_window)

    def test_addon_initializes_theme_before_runtime(self):
        addon = (ADDON / "Core" / "Addon.lua").read_text()
        self.assertIn('SafeCall(function() NPR:InitializeTheme() end)', addon)
        self.assertIn("function NPR:InitializeClientUI()", addon)
        client_ui = addon[addon.index("function NPR:InitializeClientUI()"):]
        self.assertLess(client_ui.index("self:InitializeRuntime()"), client_ui.index("self:InitializeMainWindow()"))

    def test_addon_uses_multiple_safe_init_stages(self):
        addon = (ADDON / "Core" / "Addon.lua").read_text()
        self.assertGreaterEqual(addon.count('SafeCall(function()'), 6)

    def test_encounter_and_event_names_present(self):
        data = (ADDON / "Data" / "NexusPointXenas.lua").read_text()
        expected = [
            "Chief Corewright Kasreth",
            "Corewarden Nysarra",
            "Lothraxion",
            "reflux_charge",
            "lightscar_flare",
            "divine_guile",
            "leyline_array",
            "devour_the_unworthy",
            "flicker",
            "encounterID = 3328",
            "encounterID = 3332",
            "encounterID = 3333",
            "spellID = 1251772",
            "spellID = 1257601",
            "spellID = 1269222",
        ]
        for token in expected:
            self.assertIn(token, data)

    def test_storage_normalizes_frame_points_and_required_keys(self):
        storage = (ADDON / "Core" / "Storage.lua").read_text()
        self.assertIn("validFramePoints", storage)
        self.assertIn("NormalizeFrameSettings", storage)
        self.assertIn('value ~= ""', storage)
        self.assertIn("validSoundChannels", storage)
        self.assertIn("IsValidSoundKey", storage)
        self.assertIn("selectedEncounterByDungeon", storage)
        self.assertIn("NormalizeDungeonSelection", storage)
        self.assertIn("NormalizeEncounterSelection", storage)

    def test_season_registry_declares_full_roster(self):
        registry = load_season_registry()
        self.assertEqual(registry.count(" = BuildDungeon("), 8)
        for token in SEASON_SELECTOR_ORDER:
            self.assertIn(token, registry)

    def test_season_registry_freezes_selector_order_contract(self):
        builds = parse_season_registry_builds(load_season_registry())
        self.assertEqual(
            [dungeon_key for dungeon_key, _ in sorted(builds.items(), key=lambda item: item[1]["selectorOrder"])],
            SEASON_SELECTOR_ORDER,
        )
        self.assertEqual(builds["nexus_point_xenas"]["selectorOrder"], 3)
        self.assertEqual(builds["skyreach"]["selectorOrder"], 8)

    def test_non_nexus_registry_seed_freezes_skyreach_boss_labels(self):
        registry = load_season_registry()
        for token in SKYREACH_REGISTRY_TOKENS:
            self.assertIn(token, registry)

    def test_non_nexus_registry_seed_freezes_seat_boss_labels(self):
        registry = load_season_registry()
        for token in SEAT_REGISTRY_TOKENS:
            self.assertIn(token, registry)

    def test_non_nexus_proof_roster_freezes_known_order_drift(self):
        registry = load_season_registry()
        positions = [registry.index(token) for token in ALGETHAR_PROOF_ORDER_TOKENS]
        self.assertEqual(sorted(positions), positions)
        self.assertIn("proofEncounterOrder = proofEncounterOrder or {}", registry)

    def test_non_nexus_registry_seed_keeps_id_fields_separate(self):
        registry = load_season_registry()
        builds = parse_season_registry_builds(registry)
        skyreach = builds["skyreach"]
        self.assertEqual(skyreach["journalInstanceID"], 1209)
        self.assertEqual(skyreach["mapID"], 1209)
        self.assertIsInstance(skyreach["challengeMapID"], int)
        self.assertEqual(skyreach["challengeMapIDPosture"], "provisional")
        self.assertIn('BuildEncounterSeed("ranjit", "Ranjit", 965, 1698)', registry)
        self.assertIn('BuildEncounterSeed("high_sage_viryx", "High Sage Viryx", 968, 1701)', registry)
        seat = builds["seat_of_the_triumvirate"]
        self.assertEqual(seat["journalInstanceID"], 1753)
        self.assertEqual(seat["mapID"], 1753)
        self.assertEqual(seat["challengeMapIDPosture"], "provisional")
        self.assertIn('BuildEncounterSeed("zuraal_the_ascended", "Zuraal the Ascended", 1979, 2065)', registry)
        self.assertIn("BuildEncounterSeed(\"lura\", \"L'ura\", 1982, 2068)", registry)

    def test_non_nexus_proof_timelines_are_partial_and_traceable(self):
        proof = (ADDON / "Data" / "SeasonProof.lua").read_text()
        toc = (ADDON / "CooldownReminder.toc").read_text()
        util = (ADDON / "Core" / "Util.lua").read_text()

        self.assertIn("Data/SeasonProof.lua", toc)
        self.assertIn('ApplyProofCoverage(', proof)
        self.assertIn('coverageState = "partial"', proof)
        self.assertIn('timingConfidence = "provisional"', proof)
        self.assertIn('timelineTrigger = "TIME"', proof)
        self.assertIn('journalEncounterID = 1979', proof)
        self.assertIn('journalEncounterID = 965', proof)
        self.assertIn('journalEncounterID = 966', proof)
        self.assertIn('journalEncounterID = 967', proof)
        self.assertIn('triggerSpellID = 1263304', proof)
        self.assertIn('triggerSpellID = 1252733', proof)
        self.assertIn('triggerSpellID = 154115', proof)
        self.assertIn('triggerSpellID = 1253527', proof)
        self.assertIn('triggerSpellID = 1283787', proof)
        self.assertIn('combatLogEvent = "SPELL_CAST_START"', proof)
        self.assertIn('combatLogEvent = "SPELL_CAST_SUCCESS"', proof)
        self.assertIn('label = "Crashing Void"', proof)
        self.assertIn('label = "Gale Surge"', proof)
        self.assertIn('label = "Searing Smash"', proof)
        self.assertIn('label = "Dawn"', proof)
        self.assertIn('label = "Burning Claws"', proof)
        self.assertIn('label = "Searing Feathers"', proof)
        self.assertIn('label = "Blaze of Glory"', proof)
        self.assertIn('timelineTrigger = "AI"', proof)
        self.assertIn('Remaining Seat bosses', proof)
        self.assertIn('Remaining Skyreach bosses', proof)
        self.assertIn('Araknath remaining abilities', proof)
        self.assertIn('Rukhran trigger variants', proof)
        self.assertIn('/HealerReminder/addon_examples/EXBoss-v26.4.7.1900/', proof)
        self.assertNotIn('/HealerReminder/EXBoss-v26.4.7.1900/', proof)
        self.assertIn("entry.triggerSpellID", util)

    def test_season_registry_classifies_challenge_map_id_posture(self):
        builds = parse_season_registry_builds(load_season_registry())
        self.assertEqual(set(builds), set(SEASON_SELECTOR_ORDER))
        for dungeon_key, build in builds.items():
            posture = build["challengeMapIDPosture"]
            self.assertIn(posture, ALLOWED_CHALLENGE_MAP_ID_POSTURES, dungeon_key)
            if build["challengeMapID"] is None:
                self.assertEqual(posture, "intentionally_nil", dungeon_key)
            else:
                self.assertIn(posture, {"confirmed", "provisional"}, dungeon_key)

    def test_slash_registry_evidence_export_is_opt_in_and_id_based(self):
        slash = (ADDON / "Core" / "Slash.lua").read_text()
        addon = (ADDON / "Core" / "Addon.lua").read_text()

        self.assertIn('command == "evidence" or command == "registry"', slash)
        self.assertIn("PrintRegistryEvidenceExport(self, rest)", slash)
        self.assertIn("GetMapScoreInfo", slash)
        self.assertIn("GetMapUIInfo", slash)
        self.assertIn("GetChallengeCompletionInfo", slash)
        self.assertIn("matchesRegistryChallengeMapID", slash)
        self.assertIn("challengeMapIDPosture", slash)
        self.assertIn("journalInstanceID", slash)
        self.assertIn("mapID", slash)
        self.assertIn("FormatOrderedBossIDs", slash)
        self.assertIn('Evidence export no-op: no season registry is loaded.', slash)
        self.assertIn('Live API fields may be unavailable outside the Retail client', slash)

        self.assertNotIn("GetMapScoreInfo", addon)
        self.assertNotIn("GetMapUIInfo", addon)
        self.assertNotIn("GetChallengeCompletionInfo", addon)

    def test_crem_rename_retires_npr_alias_but_keeps_storage_observable(self):
        slash = (ADDON / "Core" / "Slash.lua").read_text()
        addon = (ADDON / "Core" / "Addon.lua").read_text()
        toc = (ADDON / "CooldownReminder.toc").read_text()
        readme = (ADDON / "README.md").read_text()

        self.assertIn('SLASH_COOLDOWNREMINDER1 = "/crem"', slash)
        self.assertNotIn("SLASH_COOLDOWNREMINDER2", slash)
        self.assertNotIn('"/npr"', slash)
        self.assertEqual(slash.count("SlashCmdList.COOLDOWNREMINDER = function(message)"), 1)
        self.assertIn("self:ToggleMainWindow()", slash)
        self.assertIn('command == "status"', slash)
        self.assertIn('command == "reset"', slash)
        self.assertIn('command == "evidence" or command == "registry"', slash)
        self.assertIn('NPR.savedVariablesName = "CooldownReminderDB"', addon)
        self.assertIn("SavedVariables: %s", slash)
        self.assertIn("## SavedVariables: CooldownReminderDB", toc)
        self.assertIn("SavedVariables now use `CooldownReminderDB`", readme)
        self.assertNotIn("NexusPointRemindersDB", addon + toc + readme)

    def test_total_and_mapped_boss_counts_use_distinct_semantics(self):
        builds = parse_season_registry_builds(load_season_registry())
        mapped_counts = parse_mapped_boss_counts()
        registry = load_season_registry()
        self.assertEqual(builds["nexus_point_xenas"]["totalBossCount"], 3)
        self.assertEqual(mapped_counts["nexus_point_xenas"], 3)
        self.assertEqual(builds["seat_of_the_triumvirate"]["totalBossCount"], 4)
        self.assertEqual(mapped_counts["seat_of_the_triumvirate"], 1)
        self.assertEqual(builds["skyreach"]["totalBossCount"], 4)
        self.assertEqual(mapped_counts["skyreach"], 3)
        self.assertIn("mappedBossCount = 0", registry)
        self.assertIn("dungeon.mappedBossCount = #dungeon.encounterOrder", (ADDON / "Data" / "NexusPointXenas.lua").read_text())

    def test_dungeon_lookup_does_not_fall_back_to_global_encounter_pool(self):
        util = (ADDON / "Core" / "Util.lua").read_text()
        self.assertIn("return {}", util)
        self.assertNotIn("for encounterKey in pairs(self.Data and self.Data.encounters or {}) do", util)

    def test_partial_coverage_ui_copy_uses_mapped_count(self):
        util = (ADDON / "Core" / "Util.lua").read_text()
        main_window = (ADDON / "UI" / "MainWindow.lua").read_text()

        self.assertIn("function NPR:GetDungeonCoverageMenuLabel(dungeon)", util)
        self.assertIn('return format("%d/%d mapped"', util)
        self.assertIn("Partial dungeon coverage: %d/%d main bosses mapped", util)
        self.assertIn("self:GetDungeonCoverageMenuLabel(dungeon)", main_window)
        self.assertIn("self:GetDungeonCoverageSummary(selectedDungeon)", main_window)
        self.assertIn('label = format("%s (partial)", label)', main_window)

    def test_flat_selected_encounter_key_references_are_confined_to_helpers(self):
        allowed = {
            ADDON / "Core" / "Defaults.lua",
            ADDON / "Core" / "Storage.lua",
            ADDON / "Core" / "Slash.lua",
            ADDON / "Core" / "Util.lua",
        }
        matches = []
        for path in ADDON.rglob("*.lua"):
            for lineno, line in enumerate(path.read_text().splitlines(), 1):
                if "selectedEncounterKey" not in line:
                    continue
                if "GetSelectedEncounterKey" in line or "SetSelectedEncounterKey" in line:
                    continue
                if "selectedEncounterByDungeon" in line:
                    continue
                matches.append((path, lineno, line.strip()))

        unexpected = [(path, lineno, line) for path, lineno, line in matches if path not in allowed]
        self.assertEqual(unexpected, [], f"Unexpected flat selectedEncounterKey reference(s): {unexpected}")


class TestSavedVariableNormalization(unittest.TestCase):
    def test_normalize_minimap_settings(self):
        settings = normalize_minimap_settings({"hide": "yes", "angle": "725"}, {"hide": False, "angle": 210})
        self.assertEqual(settings["hide"], False)
        self.assertAlmostEqual(settings["angle"], 5.0)

    def test_normalize_minimap_settings_fallback(self):
        settings = normalize_minimap_settings({"hide": True, "angle": "bad"}, {"hide": False, "angle": 210})
        self.assertEqual(settings["hide"], True)
        self.assertEqual(settings["angle"], 210)

    def test_selection_state_migrates_legacy_encounter_key(self):
        defaults = {
            "selectedDungeonKey": "nexus_point_xenas",
            "selectedEncounterKey": "kasreth",
            "selectedEncounterByDungeon": {"nexus_point_xenas": "kasreth"},
        }
        state = normalize_selection_state(
            {
                "selectedDungeonKey": "nexus_point_xenas",
                "selectedEncounterKey": "nysarra",
            },
            {"nexus_point_xenas"},
            {"nexus_point_xenas": ["kasreth", "nysarra", "lothraxion"]},
            defaults,
        )
        self.assertEqual(state["selectedDungeonKey"], "nexus_point_xenas")
        self.assertEqual(state["selectedEncounterKey"], "nysarra")
        self.assertEqual(state["selectedEncounterByDungeon"]["nexus_point_xenas"], "nysarra")

    def test_selection_state_rejects_stale_dungeon_and_encounter(self):
        defaults = {
            "selectedDungeonKey": "nexus_point_xenas",
            "selectedEncounterKey": "kasreth",
            "selectedEncounterByDungeon": {"nexus_point_xenas": "kasreth"},
        }
        state = normalize_selection_state(
            {
                "selectedDungeonKey": "bad_dungeon",
                "selectedEncounterKey": "missing_boss",
                "selectedEncounterByDungeon": {
                    "bad_dungeon": "whatever",
                    "nexus_point_xenas": "missing_boss",
                },
            },
            {"nexus_point_xenas"},
            {"nexus_point_xenas": ["kasreth", "nysarra", "lothraxion"]},
            defaults,
        )
        self.assertEqual(state["selectedDungeonKey"], "nexus_point_xenas")
        self.assertEqual(state["selectedEncounterKey"], "kasreth")
        self.assertEqual(state["selectedEncounterByDungeon"], {"nexus_point_xenas": "kasreth"})

    def test_selection_state_keeps_valid_legacy_encounter_without_map(self):
        defaults = {
            "selectedDungeonKey": "nexus_point_xenas",
            "selectedEncounterKey": "kasreth",
            "selectedEncounterByDungeon": {"nexus_point_xenas": "kasreth"},
        }
        state = normalize_selection_state(
            {
                "selectedDungeonKey": "nexus_point_xenas",
                "selectedEncounterKey": "lothraxion",
            },
            {"nexus_point_xenas"},
            {"nexus_point_xenas": ["kasreth", "nysarra", "lothraxion"]},
            defaults,
        )
        self.assertEqual(state["selectedDungeonKey"], "nexus_point_xenas")
        self.assertEqual(state["selectedEncounterKey"], "lothraxion")
        self.assertEqual(state["selectedEncounterByDungeon"], {"nexus_point_xenas": "lothraxion"})

    def test_selection_state_handles_known_dungeon_without_encounters(self):
        defaults = {
            "selectedDungeonKey": "nexus_point_xenas",
            "selectedEncounterKey": "kasreth",
            "selectedEncounterByDungeon": {"nexus_point_xenas": "kasreth"},
        }
        state = normalize_selection_state(
            {
                "selectedDungeonKey": "nexus_point_xenas",
                "selectedEncounterKey": "kasreth",
                "selectedEncounterByDungeon": {"nexus_point_xenas": "kasreth"},
            },
            {"nexus_point_xenas"},
            {"nexus_point_xenas": []},
            defaults,
        )
        self.assertEqual(state["selectedDungeonKey"], "nexus_point_xenas")
        self.assertIsNone(state["selectedEncounterKey"])
        self.assertEqual(state["selectedEncounterByDungeon"], {"nexus_point_xenas": None})


class TestCombatSafetyTokens(unittest.TestCase):
    def test_config_lockdown_helpers_present(self):
        util = (ADDON / "Core" / "Util.lua").read_text()
        self.assertIn("function NPR:IsConfigLockedDown()", util)
        self.assertIn("function NPR:PrintCombatLockdownMessage(action)", util)
        self.assertIn("function NPR:CanUseConfigUI(action)", util)
        self.assertIn("Try again after the loading screen finishes.", util)
        self.assertIn('self:PrintCombatLockdownMessage("Window position saving")', util)
        self.assertIn('self:PrintCombatLockdownMessage("Window position restore")', util)

    def test_main_window_and_editor_respect_combat_lockdown(self):
        main = (ADDON / "UI" / "MainWindow.lua").read_text()
        editor = (ADDON / "UI" / "Editor.lua").read_text()
        widgets = (ADDON / "UI" / "Widgets.lua").read_text()
        self.assertIn('self:CanUseConfigUI(action or "The configuration window")', main)
        self.assertIn('self.pendingTimelineRefresh = true', main)
        self.assertIn('self:PrintCombatLockdownMessage("Timeline filters")', main)
        self.assertIn('self:PrintCombatLockdownMessage("Track visibility")', main)
        self.assertIn('self:PrintCombatLockdownMessage("Timeline navigation")', main)
        self.assertIn('self:PrintCombatLockdownMessage("Reminder editing")', editor)
        self.assertIn('self:PrintCombatLockdownMessage("Reminder save")', editor)
        self.assertIn('self:PrintCombatLockdownMessage("Reminder copy")', editor)
        self.assertIn('NPR:PrintCombatLockdownMessage("Dropdown menus")', widgets)
        self.assertIn("function dropdown:DismissMenuDuringCombat()", widgets)
        self.assertIn("function NPR:RecoverCombatDropdownMenus()", widgets)
        self.assertIn("NPR.pendingDropdownRecovery", (ADDON / "Core" / "Addon.lua").read_text())
        self.assertIn('self:PrintCombatLockdownMessage("Window movement")', widgets)

    def test_runtime_defers_diagnostic_refresh_in_combat(self):
        scheduler = (ADDON / "Runtime" / "Scheduler.lua").read_text()
        self.assertIn("if self:IsConfigLockedDown() then", scheduler)
        self.assertIn("self.pendingTimelineRefresh = true", scheduler)
        self.assertIn('self:PrintCombatLockdownMessage("Runtime anchor movement")', scheduler)

    def test_slash_minimap_settings_are_out_of_combat_only(self):
        slash = (ADDON / "Core" / "Slash.lua").read_text()
        addon = (ADDON / "Core" / "Addon.lua").read_text()
        minimap = (ADDON / "UI" / "MinimapButton.lua").read_text()
        self.assertIn('self:PrintCombatLockdownMessage("Minimap launcher settings")', slash)
        self.assertIn('self:ToggleMainWindow("Addon Compartment")', addon)
        self.assertIn('self.pendingClientUIInit = true', addon)
        self.assertIn('self:ToggleMainWindow("Minimap launcher")', minimap)
        self.assertIn('self:PrintCombatLockdownMessage("Minimap launcher movement")', minimap)
        self.assertIn("self.pendingMinimapRefresh = true", minimap)


if __name__ == "__main__":
    unittest.main()
