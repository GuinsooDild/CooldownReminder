from pathlib import Path
import re
import sys

from test_npr_logic import (
    ALLOWED_CHALLENGE_MAP_ID_POSTURES,
    ALGETHAR_PROOF_ORDER_TOKENS,
    SEAT_REGISTRY_TOKENS,
    SKYREACH_REGISTRY_TOKENS,
    SEASON_SELECTOR_ORDER,
    load_season_registry,
    parse_mapped_boss_counts,
    parse_season_registry_builds,
)


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")
DATA = (ROOT / "CooldownReminder" / "Data" / "NexusPointXenas.lua").read_text()
PROOF_DATA = (ROOT / "CooldownReminder" / "Data" / "SeasonProof.lua").read_text()
ALL_DATA = DATA + "\n" + PROOF_DATA
REGISTRY = load_season_registry()
REGISTRY_BUILDS = parse_season_registry_builds(REGISTRY)
MAPPED_BOSS_COUNTS = parse_mapped_boss_counts()
UTIL = (ROOT / "CooldownReminder" / "Core" / "Util.lua").read_text()
TOC = (ROOT / "CooldownReminder" / "CooldownReminder.toc").read_text()


EXPECTED_TOKENS = [
    "encounterID = 3328",
    "encounterID = 3332",
    "encounterID = 3333",
    'label = "Reflux Charge"',
    'label = "Arcane Zap"',
    'label = "Corespark Detonation"',
    'label = "Flux Collapse"',
    'label = "Leyline Array"',
    'label = "Eclipsing Step"',
    'label = "Null Vanguard"',
    'label = "Umbral Lash"',
    'label = "Lightscar Flare"',
    'label = "Devour the Unworthy"',
    'label = "Brilliant Dispersion"',
    'label = "Divine Guile"',
    'label = "Searing Rend"',
    'label = "Flicker"',
    "spellID = 1251772",
    "1250553",
    "1251626",
    "spellID = 1257509",
    "spellID = 1264048",
    "spellID = 1251183",
    "spellID = 1249027",
    "spellID = 1252703",
    "spellID = 1247937",
    "spellID = 1264429",
    "spellID = 1252883",
    "spellID = 1253855",
    "spellID = 1257601",
    "spellID = 1253950",
    "spellID = 1269222",
    'label = "Void Slash"',
    'label = "Decimate"',
    'label = "Null Palm"',
    'label = "Oozing Slam"',
    'label = "Crashing Void"',
    'label = "Gale Surge"',
    'label = "Fan of Blades"',
    'label = "Wind Chakram"',
    'label = "Chakram Vortex"',
    'label = "Searing Smash"',
    'label = "Dawn"',
    'label = "Burning Claws"',
    'label = "Searing Feathers"',
    'label = "Blaze of Glory"',
    "spellID = 1263440",
    "spellID = 1263282",
    "spellID = 1268916",
    "spellID = 1263399",
    "spellID = 1263297",
    "spellID = 1252690",
    "spellID = 153757",
    "spellID = 1258152",
    "spellID = 156793",
    "spellID = 154113",
    "spellID = 1253510",
    "spellID = 1253519",
    "spellID = 159382",
    "spellID = 1253416",
]


CHECKS = [
    (
        "no-boss-spellid-nil",
        ALL_DATA.count("spellID = nil") <= 1 and 'label = "Pull"' in DATA,
        "Boss timeline entries should no longer rely on nil spell IDs; only the synthetic pull anchor may remain nil.",
    ),
    (
        "danger-percent-for-each-event",
        len(re.findall(r"dangerPercent = \d+", ALL_DATA)) >= 25,
        "Each timeline event should define a relative-danger percentage.",
    ),
    (
        "local-source-paths-use-addon-examples",
        "/HealerReminder/EXBoss-v26.4.7.1900/" not in ALL_DATA
        and "/HealerReminder/addon_examples/EXBoss-v26.4.7.1900/" in ALL_DATA,
        "Active source metadata should point at the post-archive addon_examples reference location.",
    ),
    (
        "expected-tokens-present",
        all(token in ALL_DATA for token in EXPECTED_TOKENS),
        "Verified encounter names and spell IDs should be embedded in the dataset.",
    ),
    (
        "reference-only-coverage-present",
        "referenceOnlySpells" in ALL_DATA and "Reference-only spell IDs pending live timing" in UTIL,
        "Known local-reference spell IDs that are not yet safely timed should stay visible as explicit reference-only coverage instead of being silently dropped.",
    ),
    (
        "combat-log-trigger-metadata-present",
        'combatLogEvent = "SPELL_CAST_START"' in ALL_DATA and 'combatLogEvent = "SPELL_CAST_SUCCESS"' in ALL_DATA and "combatLogSpellIDs" in ALL_DATA and "triggerSpellID" in ALL_DATA,
        "Boss events with separate trigger/effect spell IDs should keep explicit combat-log trigger metadata so diagnostics do not double-count follow-up auras.",
    ),
    (
        "arcane-zap-note-no-longer-calls-it-tank-buster",
        'label = "Arcane Zap"' in DATA and "interruptible Kasreth cast" in DATA and "Arcane Zap" in DATA and "Kasreth's tank buster" not in DATA,
        "Arcane Zap reference notes should match current public guides and avoid calling the cast a confirmed tank buster.",
    ),
    (
        "season-registry-selector-order-frozen",
        [dungeon_key for dungeon_key, _ in sorted(REGISTRY_BUILDS.items(), key=lambda item: item[1]["selectorOrder"])] == SEASON_SELECTOR_ORDER,
        "Season registry should freeze an explicit selector order instead of relying on incidental table iteration or import order.",
    ),
    (
        "non-nexus-skyreach-seed-present",
        all(token in REGISTRY for token in SKYREACH_REGISTRY_TOKENS),
        "At least one non-Nexus dungeon should carry a normalized boss seed so future rollout audits are not Nexus-only.",
    ),
    (
        "non-nexus-seat-seed-present",
        all(token in REGISTRY for token in SEAT_REGISTRY_TOKENS),
        "The first non-Nexus rollout should seed Seat boss labels and separate journal/runtime IDs before exposing partial timelines.",
    ),
    (
        "non-nexus-proof-timelines-are-partial",
        "Data/SeasonProof.lua" in TOC
        and 'ApplyProofCoverage(' in PROOF_DATA
        and PROOF_DATA.count('coverageState = "partial"') >= 3
        and 'timelineTrigger = "TIME"' in PROOF_DATA
        and 'timelineTrigger = "AI"' in PROOF_DATA
        and 'timingConfidence = "provisional"' in PROOF_DATA
        and "Remaining Seat bosses" in PROOF_DATA
        and "Remaining Skyreach bosses" in PROOF_DATA,
        "Seat and Skyreach should expose bounded proof timelines without implying complete boss coverage.",
    ),
    (
        "non-nexus-proof-order-frozen",
        [REGISTRY.index(token) for token in ALGETHAR_PROOF_ORDER_TOKENS] == sorted(REGISTRY.index(token) for token in ALGETHAR_PROOF_ORDER_TOKENS)
        and "proofEncounterOrder = proofEncounterOrder or {}" in REGISTRY,
        "One proof dungeon should freeze a normalized ordered boss roster so known imported order drift cannot silently re-enter the shared contract.",
    ),
    (
        "non-nexus-id-fields-stay-separated",
        REGISTRY_BUILDS.get("skyreach", {}).get("journalInstanceID") == 1209
        and REGISTRY_BUILDS.get("skyreach", {}).get("mapID") == 1209
        and isinstance(REGISTRY_BUILDS.get("skyreach", {}).get("challengeMapID"), int)
        and REGISTRY_BUILDS.get("skyreach", {}).get("challengeMapIDPosture") == "provisional"
        and REGISTRY_BUILDS.get("seat_of_the_triumvirate", {}).get("journalInstanceID") == 1753
        and REGISTRY_BUILDS.get("seat_of_the_triumvirate", {}).get("mapID") == 1753
        and REGISTRY_BUILDS.get("seat_of_the_triumvirate", {}).get("challengeMapIDPosture") == "provisional"
        and 'BuildEncounterSeed("ranjit", "Ranjit", 965, 1698)' in REGISTRY
        and 'BuildEncounterSeed("high_sage_viryx", "High Sage Viryx", 968, 1701)' in REGISTRY,
        "Non-Nexus registry seeds should keep journal, runtime encounter, map, and challenge IDs in separate fields.",
    ),
    (
        "challenge-map-id-posture-classified",
        set(REGISTRY_BUILDS) == set(SEASON_SELECTOR_ORDER)
        and all(build.get("challengeMapIDPosture") in ALLOWED_CHALLENGE_MAP_ID_POSTURES for build in REGISTRY_BUILDS.values())
        and all(
            build.get("challengeMapIDPosture") == "intentionally_nil"
            if build.get("challengeMapID") is None
            else build.get("challengeMapIDPosture") in {"confirmed", "provisional"}
            for build in REGISTRY_BUILDS.values()
        ),
        "Every season registry row should classify challengeMapID posture without treating provisional research seeds as confirmed product truth.",
    ),
    (
        "mapped-boss-count-semantics-frozen",
        REGISTRY_BUILDS.get("nexus_point_xenas", {}).get("totalBossCount") == 3
        and MAPPED_BOSS_COUNTS.get("nexus_point_xenas") == 3
        and REGISTRY_BUILDS.get("seat_of_the_triumvirate", {}).get("totalBossCount") == 4
        and MAPPED_BOSS_COUNTS.get("seat_of_the_triumvirate") == 1
        and REGISTRY_BUILDS.get("skyreach", {}).get("totalBossCount") == 4
        and MAPPED_BOSS_COUNTS.get("skyreach") == 3
        and "mappedBossCount = 0" in REGISTRY
        and "dungeon.mappedBossCount = #dungeon.encounterOrder" in DATA
        and "dungeon.mappedBossCount = #dungeon.encounterOrder" in PROOF_DATA,
        "Mapped boss counts should track wired encounterOrder entries, not the eventual total boss roster for incomplete dungeons.",
    ),
]


def main():
    failures = []
    for key, ok, reason in CHECKS:
        status = "PASS" if ok else "FAIL"
        print(f"{status}: {key} - {reason}")
        if not ok:
            failures.append(key)

    if failures:
        print("\nData audit failed:", ", ".join(failures))
        return 1

    print("\nData audit passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
