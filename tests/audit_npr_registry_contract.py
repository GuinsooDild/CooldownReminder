from pathlib import Path
import re
import sys


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")
TEST_LOGIC = (ROOT / "tests" / "test_npr_logic.py").read_text()
DATA_AUDIT = (ROOT / "tests" / "audit_npr_data.py").read_text()
REGISTRY = (ROOT / "CooldownReminder" / "Data" / "SeasonRegistry.lua").read_text()


CHECKS = [
    (
        "test-suite-does-not-hardpin-skyreach-challenge-id",
        'self.assertEqual(skyreach["challengeMapID"], 846)' not in TEST_LOGIC,
        "The unit mirror should not freeze Skyreach challengeMapID to 846 while project control still treats current non-nil seeds as untrusted research input.",
    ),
    (
        "data-audit-does-not-hardpin-skyreach-challenge-id",
        'REGISTRY_BUILDS.get("skyreach", {}).get("challengeMapID") == 846' not in DATA_AUDIT,
        "The standalone data audit should not report green by asserting the same stale Skyreach challengeMapID literal.",
    ),
    (
        "registry-explicitly-classifies-challenge-id-posture",
        re.search(r"challengeMapID(Posture|Status)\s*=", REGISTRY) is not None,
        "The season registry should classify each challengeMapID as confirmed, provisional, or intentionally nil instead of exposing raw literals alone.",
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
        print("\nRegistry contract audit failed:", ", ".join(failures))
        return 1

    print("\nRegistry contract audit passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
