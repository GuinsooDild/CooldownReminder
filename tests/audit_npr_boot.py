from pathlib import Path
import sys


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")
ADDON = ROOT / "CooldownReminder"
TOC = ADDON / "CooldownReminder.toc"
ADDON_CORE = (ADDON / "Core" / "Addon.lua").read_text()
MINIMAP = (ADDON / "UI" / "MinimapButton.lua").read_text()
SLASH = (ADDON / "Core" / "Slash.lua").read_text()


def toc_files():
    files = []
    for raw_line in TOC.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("##") or line.startswith("#"):
            continue
        files.append(line)
    return files


CHECKS = [
    (
        "toc-compartment-uses-safe-metadata",
        "## AddonCompartmentFunc: CooldownReminder_OnAddonCompartmentClick" in TOC.read_text()
        and "## AddonCompartmentFuncOnEnter: CooldownReminder_OnAddonCompartmentEnter" in TOC.read_text()
        and "## AddonCompartmentFuncOnLeave: CooldownReminder_OnAddonCompartmentLeave" in TOC.read_text()
        and "RegisterAddon" not in ADDON_CORE,
        "Addon Compartment access should use Retail TOC metadata and avoid a manual registration path.",
    ),
    (
        "toc-includes-minimap",
        "UI/MinimapButton.lua" in toc_files(),
        "The addon TOC must load the minimap button implementation.",
    ),
    (
        "toc-includes-season-registry",
        "Data/SeasonRegistry.lua" in toc_files(),
        "The addon TOC must load the season registry before per-dungeon data files so multi-dungeon startup stays deterministic.",
    ),
    (
        "toc-files-exist",
        all((ADDON / relpath).exists() for relpath in toc_files()),
        "Every file referenced in the TOC must exist on disk.",
    ),
    (
        "addon-safe-staged-init",
        ADDON_CORE.count('SafeCall(function()') >= 7,
        "Startup should remain split across multiple SafeCall phases.",
    ),
    (
        "minimap-has-click-handler",
        'button:SetScript("OnClick"' in MINIMAP and 'self:ToggleMainWindow("Minimap launcher")' in MINIMAP,
        "The minimap button must open the addon from a real click handler that reports its launcher path.",
    ),
    (
        "minimap-has-drag-handler",
        'button:RegisterForDrag("LeftButton")' in MINIMAP and 'button:SetScript("OnDragStart"' in MINIMAP,
        "The minimap button should support drag repositioning.",
    ),
    (
        "minimap-shape-aware-positioning",
        '["TRICORNER-BOTTOMRIGHT"]' in MINIMAP and "diagonalWidth" in MINIMAP and "quadTable[quadrant]" in MINIMAP,
        "Minimap positioning should account for non-round minimap shapes instead of using a naive circular clamp.",
    ),
    (
        "player-login-defers-client-ui-init",
        'event == "PLAYER_LOGIN"' in ADDON_CORE and "InitializeClientUI" in ADDON_CORE and 'self:InitializeMinimapButton()' in ADDON_CORE,
        "Startup should defer client UI initialization until PLAYER_LOGIN so custom top-level frames are not created during ADDON_LOADED.",
    ),
    (
        "combat-reload-defers-client-ui-init",
        "self.pendingClientUIInit = true" in ADDON_CORE
        and 'self:PrintCombatLockdownMessage("Client UI initialization")' in ADDON_CORE
        and "if NPR.pendingClientUIInit then" in ADDON_CORE
        and 'event == "PLAYER_REGEN_ENABLED"' in ADDON_CORE,
        "Combat reload should defer client UI frame creation until combat ends instead of creating config frames in lockdown.",
    ),
    (
        "slash-supports-minimap-toggle",
        'command == "minimap" or command == "icon"' in SLASH and 'Usage: /crem minimap show|hide|toggle' in SLASH,
        "Slash commands should expose minimap show/hide/toggle recovery.",
    ),
    (
        "slash-uses-crem-with-retired-npr-alias",
        'SLASH_COOLDOWNREMINDER1 = "/crem"' in SLASH
        and 'SLASH_COOLDOWNREMINDER2' not in SLASH
        and '"/npr"' not in SLASH
        and "SlashCmdList.COOLDOWNREMINDER" in SLASH,
        "The product rename should make /crem the recovery command and leave no active /npr alias.",
    ),
    (
        "status-exposes-cooldown-savedvariables",
        'NPR.savedVariablesName = "CooldownReminderDB"' in ADDON_CORE
        and "SavedVariables: %s" in SLASH
        and "NexusPointRemindersDB" not in ADDON_CORE
        and "NexusPointRemindersDB" not in TOC.read_text(),
        "Status output and TOC should use the CooldownReminder SavedVariables contract.",
    ),
    (
        "slash-supports-opt-in-registry-evidence",
        'command == "evidence" or command == "registry"' in SLASH
        and "GetMapScoreInfo" in SLASH
        and "GetMapUIInfo" in SLASH
        and "GetChallengeCompletionInfo" in SLASH
        and "matchesRegistryChallengeMapID" in SLASH
        and "Evidence export no-op: no season registry is loaded." in SLASH
        and "GetMapScoreInfo" not in ADDON_CORE
        and "GetMapUIInfo" not in ADDON_CORE
        and "GetChallengeCompletionInfo" not in ADDON_CORE,
        "Registry evidence capture should be an explicit slash diagnostic and must not call live challenge APIs from startup code.",
    ),
    (
        "reset-restores-minimap-state",
        'self.db.ui.minimap = self:DeepCopy(self.defaults.ui.minimap)' in SLASH and 'self:UpdateMinimapButtonPosition()' in SLASH,
        "Slash reset should restore the minimap launcher to a visible default state.",
    ),
    (
        "reset-restores-timeline-filters",
        'self.db.timeline.trackVisibility = {}' in SLASH and 'self.db.timeline.showRelevantOnly = self.defaults.timeline.showRelevantOnly' in SLASH and 'self.db.timeline.selectedDungeonKey = self.defaults.timeline.selectedDungeonKey' in SLASH and 'self.db.timeline.selectedEncounterByDungeon = self:DeepCopy(self.defaults.timeline.selectedEncounterByDungeon)' in SLASH,
        "Slash reset should also restore normalized dungeon and boss selection plus timeline filters so stale state does not strand the user.",
    ),
    (
        "reset-clears-runtime-state",
        'self.db.runtime.activeEncounterKey = nil' in SLASH and 'self.db.debug.armedBossKey = nil' in SLASH and 'self.db.debug.observations = {}' in SLASH and 'self.runtime:StopEncounter("slash-reset")' in SLASH,
        "Slash reset should clear manual arming, queued runtime state and debug observations so recovery is complete instead of purely visual.",
    ),
    (
        "compartment-handlers-kept-local",
        "HandleCompartmentClick" in ADDON_CORE
        and "HandleCompartmentEnter" in ADDON_CORE
        and "HandleCompartmentLeave" in ADDON_CORE
        and 'addonName .. "_OnAddonCompartmentClick"' in ADDON_CORE,
        "Addon compartment handlers should stay available in code so the launcher can be restored later without rebuilding the shared callbacks.",
    ),
    (
        "compartment-click-uses-config-guard",
        'self:ToggleMainWindow("Addon Compartment")' in ADDON_CORE,
        "Addon Compartment clicks should pass through the same combat-safe config UI guard as slash and minimap launchers.",
    ),
    (
        "compartment-tooltips-guard-missing-frame",
        "if not button then" in ADDON_CORE and "if not GameTooltip then" in ADDON_CORE,
        "Addon Compartment hover callbacks should no-op cleanly if Retail passes an unexpected frame during startup.",
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
        print("\nBootstrap audit failed:", ", ".join(failures))
        return 1

    print("\nBootstrap audit passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
