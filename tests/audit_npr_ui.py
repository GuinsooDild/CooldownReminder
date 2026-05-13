from pathlib import Path
import sys


ROOT = Path("/Users/julienduhamel/Documents/HealerReminder")
ADDON = ROOT / "CooldownReminder"

MAIN = (ADDON / "UI" / "MainWindow.lua").read_text()
WIDGETS = (ADDON / "UI" / "Widgets.lua").read_text()
EDITOR = (ADDON / "UI" / "Editor.lua").read_text()
ADDON_CORE = (ADDON / "Core" / "Addon.lua").read_text()
UTIL = (ADDON / "Core" / "Util.lua").read_text()
SCHEDULER = (ADDON / "Runtime" / "Scheduler.lua").read_text()
SLASH = (ADDON / "Core" / "Slash.lua").read_text()
MINIMAP = (ADDON / "UI" / "MinimapButton.lua").read_text()
THEME = (ADDON / "UI" / "Theme.lua").read_text()


CHECKS = [
    (
        "timeline-view-is-mouse-frame",
        'local timelineView = CreateFrame("Frame", nil, content)' in MAIN and "timelineView:EnableMouse(true)" in MAIN,
        "Timeline root should be a mouse-enabled frame so drag handling stays local without relying on a root Button surface.",
    ),
    (
        "timeline-left-drag-scroll",
        'if button == "LeftButton" or button == "RightButton" then' in MAIN and "dragMoved" in MAIN,
        "Timeline should allow left-drag navigation while preserving double-click placement on empty space.",
    ),
    (
        "timeline-mouseup-signature",
        'timelineView:SetScript("OnMouseUp", function(_, button)' in MAIN,
        "Timeline mouse-up handler must use the explicit button argument instead of arg1.",
    ),
    (
        "timeline-scaled-cursor-helper",
        "local function GetScaledCursorPosition()" in MAIN and "local cursorX, cursorY = GetScaledCursorPosition()" in MAIN,
        "Timeline hover and click math should use an explicit scaled cursor helper so X/Y sampling stays correct on Retail UI scale changes.",
    ),
    (
        "timeline-zoom",
        'timelineView:SetScript("OnMouseWheel"' in MAIN,
        "Timeline must handle mouse wheel zoom.",
    ),
    (
        "event-block-click",
        'block:SetScript("OnClick", function()' in MAIN and 'self:OpenNewReminder(encounterKey, eventKey, currentOccurrenceIndex, 0)' in MAIN,
        "Event blocks must open reminder creation directly.",
    ),
    (
        "marker-click",
        'local reminderID = reminder.id' in MAIN and 'self:OpenExistingReminder(reminderID)' in MAIN,
        "Reminder markers must reopen the saved reminder editor.",
    ),
    (
        "loop-callbacks-freeze-current-values",
        'local currentOccurrenceIndex = occurrenceIndex' in MAIN and 'local reminderID = reminder.id' in MAIN,
        "Timeline and marker callbacks should freeze per-loop values so clicks reopen the intended occurrence or reminder.",
    ),
    (
        "relative-danger-visuals",
        'Relative danger %d%%' in MAIN and "holder.metricFill" in MAIN,
        "Timeline rows should expose a relative-danger visual instead of plain single-line labels.",
    ),
    (
        "block-duration-label",
        'block.text:SetText(format("%.1fs"' in MAIN,
        "Timeline event blocks should show a compact duration label when space allows.",
    ),
    (
        "no-legacy-arg1",
        "arg1" not in MAIN,
        "Legacy global arg1 usage should not remain in timeline code.",
    ),
    (
        "checkbox-expanded-hitbox",
        "check:SetHitRectInsets" in WIDGETS,
        "Checkboxes must expand their hit rect so labels remain clickable.",
    ),
    (
        "dropdown-menu-is-custom",
        'dropdown.menu = CreateFrame("Frame", nil, UIParent)' in WIDGETS and 'dropdown.closeFrame = CreateFrame("Frame", nil, UIParent)' in WIDGETS and "function dropdown:OpenMenu()" in WIDGETS and "function dropdown:CloseMenu(silent)" in WIDGETS,
        "Dropdowns should use a custom menu frame plus an outside-click catcher instead of Blizzard menu templates or blind click-cycling.",
    ),
    (
        "dropdown-is-custom-only",
        "SetDropdownDisplay" in WIDGETS and "NormalizeDropdownValue" in WIDGETS and "CloseAllDropdownMenus" in WIDGETS and "WowStyle1DropdownTemplate" not in WIDGETS and "SetupMenu" not in WIDGETS,
        "Dropdowns should stay on the custom non-template path to avoid Blizzard menu taint and keep their displayed selection text in sync.",
    ),
    (
        "editor-uses-db-dimensions",
        'CreateWindow("editor", self.db.ui.editor.width, self.db.ui.editor.height, "Reminder")' in EDITOR,
        "Editor should use persisted dimensions so reset and saved variables keep a sane, usable size.",
    ),
    (
        "editor-anchors-enabled-below-validation",
        'controls.enabled:SetPoint("TOPLEFT", controls.validation, "BOTTOMLEFT", 0, -12)' in EDITOR,
        "Editor controls should anchor below the validation copy instead of using a fixed top offset that can overlap wrapped text.",
    ),
    (
        "main-helptext-uses-control-panel-gap",
        'controlPanel:SetSize(controlPanelWidth, 108)' in MAIN and 'helpText:SetPoint("TOPRIGHT", controlPanel, "TOPLEFT", -12, 0)' in MAIN,
        "Header copy should terminate against a dedicated right-side options panel instead of rendering underneath inline toggles.",
    ),
    (
        "track-label-is-click-registered",
        'holder.labelButton:RegisterForClicks("LeftButtonUp")' in MAIN,
        "Track label buttons should explicitly register clicks so the whole row remains interactive.",
    ),
    (
        "editor-enter-save",
        'controls.text:SetScript("OnEnterPressed"' in EDITOR and 'controls.offset:SetScript("OnEnterPressed"' in EDITOR,
        "Editor should support Enter-to-save on key fields.",
    ),
    (
        "editor-context-mode",
        'local function GetReminderModeText(reminder)' in EDITOR and 'controls.contextMode = self:CreateLabel(content, "", NPRFontNormal, unpack(self.theme.textAccent))' in EDITOR and 'controls.contextMode:SetText(GetReminderModeText(workingReminder))' in EDITOR,
        "Editor should explicitly distinguish pull-relative and event-relative reminders.",
    ),
    (
        "editor-lead-delay-copy",
        "Lead / delay (s)" in EDITOR,
        "Editor should make it explicit that reminder timing can be configured before or after the ability.",
    ),
    (
        "editor-copy-and-duration-controls",
        'controls.copy = self:CreateButton(content, "Copy"' in EDITOR
        and "self:DuplicateReminder(reminderID)" in EDITOR
        and "Display duration (s)" in EDITOR
        and "controls.durationSeconds:SetScript(\"OnEnterPressed\"" in EDITOR,
        "Editor should let users duplicate an existing reminder and tune display duration without leaving the edit flow.",
    ),
    (
        "editor-soft-numeric-correction",
        'Icon spell ID must be numeric or empty. Invalid value cleared.' in EDITOR and 'Offset must be a valid number. Reset to 0.0s.' in EDITOR and 'controls.offset:SetScript("OnEditFocusLost"' in EDITOR and 'controls.iconSpellID:SetScript("OnEditFocusLost"' in EDITOR,
        "Editor should correct invalid numeric input with a lightweight path instead of forcing a separate recovery flow.",
    ),
    (
        "editor-event-defaults",
        'local function GetSuggestedReminderDefaults(eventKey, event)' in EDITOR and 'reminder.soundKey = soundKey' in EDITOR and 'reminder.importance = importance' in EDITOR and 'controls.prefill:SetText(options.prefillNote or "")' in EDITOR,
        "New reminders should prefill sound and importance from event context while making manual override explicit.",
    ),
    (
        "theme-before-runtime",
        'SafeCall(function() NPR:InitializeTheme() end)' in ADDON_CORE
        and "function NPR:InitializeClientUI()" in ADDON_CORE
        and ADDON_CORE[ADDON_CORE.index("function NPR:InitializeClientUI()"):].index("self:InitializeRuntime()")
        < ADDON_CORE[ADDON_CORE.index("function NPR:InitializeClientUI()"):].index("self:InitializeMainWindow()"),
        "Theme initialization must happen before deferred client UI bootstrap, and runtime frames should still initialize before main-window consumers.",
    ),
    (
        "debug-refresh-relayout",
        'self:LayoutCards()' in SCHEDULER,
        "Debug refresh should relayout runtime cards so the anchor shows immediately when debug mode toggles.",
    ),
    (
        "observation-reset-on-start",
        'self:ResetObservationBucket(encounterKey)' in SCHEDULER,
        "Starting an encounter should reset debug observation counts for that boss.",
    ),
    (
        "diagnostics-show-multiple-drifts",
        'local limit = min(3, #driftParts)' in SCHEDULER and '(+%d more)' in SCHEDULER,
        "Diagnostics should surface more than one drift sample so live timing verification is faster.",
    ),
    (
        "multi-stage-addon-init",
        ADDON_CORE.count('SafeCall(function()') >= 6,
        "Addon initialization should be split into multiple SafeCall stages so one UI failure does not kill the full addon.",
    ),
    (
        "minimap-button-init",
        "InitializeMinimapButton" in ADDON_CORE,
        "Addon should initialize a minimap button so configuration is reachable without slash commands.",
    ),
    (
        "window-title-visible",
        'CreateWindow("window", self.db.ui.window.width, self.db.ui.window.height, "CooldownReminder")' in MAIN,
        "The main window should have a visible title for faster discoverability.",
    ),
    (
        "main-window-has-dungeon-selector",
        "BuildDungeonItems(self)" in MAIN and 'self:SetSelectedDungeonKey(value)' in MAIN and 'self.dungeonDropdown = dungeonDropdown' in MAIN,
        "The main window should expose a compact top-level dungeon selector before the boss selector.",
    ),
    (
        "main-window-uses-selection-helpers",
        "BuildBossItems(self)" in MAIN and 'self:SetSelectedEncounterKey(value)' in MAIN and 'self:GetSelectedEncounterKey()' in MAIN,
        "The main window should read and write the normalized dungeon-scoped selection helpers instead of relying directly on a single flat selectedEncounterKey field.",
    ),
    (
        "incomplete-dungeon-empty-state",
        'self.bossDropdown.text:SetText("No boss data yet")' in MAIN and "GetDungeonEmptyStateMessage(selectedDungeonKey)" in MAIN and 'self.emptyStateText:SetText(format("%s\\n%s"' in MAIN,
        "An incomplete dungeon should render an explicit empty state instead of leaking another dungeon's boss list.",
    ),
    (
        "minimap-toggle-visible",
        '"Hide minimap"' in MAIN and "self.minimapToggle = minimapToggle" in MAIN,
        "The main window should expose a minimap toggle so users can recover the launcher state without editing saved variables.",
    ),
    (
        "coverage-note-visible",
        "self.coverageText = coverageText" in MAIN
        and "GetEncounterReferenceOnlySummary(encounter)" in MAIN
        and "GetDungeonCoverageSummary(selectedDungeon)" in MAIN
        and "GetDungeonCoverageMenuLabel(dungeon)" in MAIN,
        "The main window should surface partial mapped-boss coverage and reference-only spell coverage without implying complete timelines.",
    ),
    (
        "unknown-reminders-wrap-rows",
        '(unknownCount - 1) % unknownColumns' in MAIN and 'floor((unknownCount - 1) / unknownColumns)' in MAIN and 'unknownArea:SetHeight(unknownHeight)' in MAIN,
        "Unknown reminder icons should wrap into additional rows instead of overflowing horizontally out of the panel.",
    ),
    (
        "dynamic-height-uses-active-offset",
        'activeViewTopOffset + timelineView:GetHeight()' in MAIN,
        "Dynamic window height should include the extra top offset when reference-only coverage text is visible.",
    ),
    (
        "window-backdrop-resizes-with-height",
        'window:SetScript("OnSizeChanged", function(selfFrame)' in WIDGETS and 'selfFrame.bgTop:SetHeight(max(48, selfFrame:GetHeight() * 0.34))' in WIDGETS,
        "Window backdrop gradients should track runtime height changes so the visual framing stays consistent.",
    ),
    (
        "window-content-frame",
        'window.content = CreateFrame("Frame", nil, window)' in WIDGETS and 'window.content:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -34)' in WIDGETS,
        "Windows should expose an inset content frame so inner layouts do not collide with title-bar controls.",
    ),
    (
        "close-button-hitbox",
        'window.close:SetSize(24, 24)' in WIDGETS and 'window.close:SetHitRectInsets(-4, -4, -4, -4)' in WIDGETS,
        "Window close buttons should have an enlarged click target instead of a tiny glyph-only hit area.",
    ),
    (
        "refresh-resyncs-toggles",
        'self.relevantCheck:SetChecked(self.db.timeline.showRelevantOnly, true)' in MAIN and 'self.disabledCheck:SetChecked(self.db.timeline.showDisabled, true)' in MAIN and 'self.diagnosticsCheck:SetChecked(self.db.timeline.showDiagnostics, true)' in MAIN,
        "Refreshing the timeline should resync visible toggles with SavedVariables so reset and slash-driven state changes never leave stale checkbox UI behind.",
    ),
    (
        "role-filter-falls-back-to-spec",
        'UnitGroupRolesAssigned("player")' in UTIL and 'GetSpecializationInfo' in UTIL and '"specialization"' in UTIL,
        "Reminder relevance should fall back to specialization role when no group role is assigned.",
    ),
    (
        "config-ui-blocked-in-combat",
        'self:CanUseConfigUI(action or "The configuration window")' in MAIN and 'self:PrintCombatLockdownMessage("Reminder editing")' in EDITOR and 'self:PrintCombatLockdownMessage("Reset")' in SLASH,
        "Configuration windows and reset flows should be blocked during combat instead of trying to mutate UI state in lockdown.",
    ),
    (
        "launcher-clicks-report-combat-lockdown",
        'self:ToggleMainWindow("Addon Compartment")' in ADDON_CORE
        and 'self:ToggleMainWindow("Minimap launcher")' in MINIMAP,
        "Addon Compartment and minimap launcher clicks should degrade to a path-specific chat warning in combat.",
    ),
    (
        "minimap-positioning-deferred-in-combat",
        "self.pendingMinimapRefresh = true" in MINIMAP
        and 'self:PrintCombatLockdownMessage("Minimap launcher movement")' in MINIMAP
        and "or NPR.pendingMinimapRefresh" in ADDON_CORE,
        "Minimap show/hide/reposition and drag movement should defer or warn instead of moving UI during combat.",
    ),
    (
        "window-position-helpers-guard-combat",
        'self:PrintCombatLockdownMessage("Window position saving")' in UTIL
        and 'self:PrintCombatLockdownMessage("Window position restore")' in UTIL
        and 'self:PrintCombatLockdownMessage("Window movement")' in WIDGETS
        and 'self:PrintCombatLockdownMessage("Window closing")' in WIDGETS,
        "Generic window drag, close, save, and restore helpers should not move or hide config frames during combat.",
    ),
    (
        "dropdowns-blocked-in-combat",
        'NPR:PrintCombatLockdownMessage("Dropdown menus")' in WIDGETS
        and "function dropdown:OpenMenu()" in WIDGETS
        and "if NPR:IsConfigLockedDown() then" in WIDGETS,
        "Custom dropdown menus should warn and no-op in combat instead of showing or changing menu frames.",
    ),
    (
        "dropdowns-dismiss-stale-overlay-in-combat",
        "function dropdown:DismissMenuDuringCombat()" in WIDGETS
        and "dropdown:DismissMenuDuringCombat()" in WIDGETS
        and "function NPR:RecoverCombatDropdownMenus()" in WIDGETS
        and "NPR.pendingDropdownRecovery" in ADDON_CORE,
        "Dropdowns opened before combat should release their full-screen close catcher and recover visuals after combat instead of trapping clicks.",
    ),
    (
        "editor-actions-blocked-in-combat",
        'self:PrintCombatLockdownMessage("Reminder save")' in EDITOR
        and 'self:PrintCombatLockdownMessage("Reminder deletion")' in EDITOR
        and 'self:PrintCombatLockdownMessage("Reminder copy")' in EDITOR
        and 'self:PrintCombatLockdownMessage("Reminder preview")' in EDITOR,
        "Editor action buttons should avoid save/copy/delete/preview UI mutations while the client is in combat lockdown.",
    ),
    (
        "timeline-filter-toggles-blocked-in-combat",
        'self:PrintCombatLockdownMessage("Timeline filters")' in MAIN
        and 'self:PrintCombatLockdownMessage("Track visibility")' in MAIN
        and 'self:PrintCombatLockdownMessage("Timeline navigation")' in MAIN,
        "Timeline filter, navigation, and track visibility toggles are configuration changes and should not mutate state in combat.",
    ),
    (
        "runtime-anchor-movement-blocked-in-combat",
        'self:PrintCombatLockdownMessage("Runtime anchor movement")' in SCHEDULER
        and "runtime.anchor.NPRMoving = true" in SCHEDULER,
        "The debug runtime anchor should not be repositioned during combat lockdown.",
    ),
    (
        "config-open-guards-first-run",
        "function NPR:CanUseConfigUI(action)" in UTIL and "not self.clientUIReady or not self.mainWindow" in UTIL and "Try again after the loading screen finishes." in UTIL,
        "Launcher and slash open paths should fail visibly before client UI bootstrap instead of silently dropping the first command.",
    ),
    (
        "slash-minimap-settings-blocked-in-combat",
        'self:PrintCombatLockdownMessage("Minimap launcher settings")' in SLASH,
        "Slash minimap visibility changes are configuration changes and should stay out of combat.",
    ),
    (
        "runtime-defers-combat-refresh",
        'self.pendingTimelineRefresh = true' in SCHEDULER and 'if self:IsConfigLockedDown() then' in SCHEDULER,
        "Runtime diagnostics should defer full timeline rebuilds until combat ends instead of refreshing UI immediately.",
    ),
    (
        "diagnostics-show-next-target",
        'GetNextValidationTarget' in SCHEDULER and '"Next: " .. (targetText or "none")' in SCHEDULER and '"Next validation target: " .. nextTarget' in SLASH,
        "Diagnostics should surface one compact next validation target in the UI and slash output.",
    ),
    (
        "grey-dark-cooldownreminder-theme",
        "backgroundMid" in THEME
        and "sectionBackground" in THEME
        and "15 / 255, 56 / 255, 119 / 255" not in THEME
        and "3 / 255, 24 / 255, 69 / 255" not in THEME
        and "4 / 255, 14 / 255, 37 / 255" not in THEME
        and "CreateColor(unpack(self.theme.backgroundMid))" in WIDGETS,
        "The main shell should use a neutral grey/dark CooldownReminder theme instead of the previous saturated-blue gradient.",
    ),
    (
        "larger-cleaner-panels",
        "local rowHeight = 38" in MAIN
        and "local leftPanelWidth = 296" in MAIN
        and "local baseViewTopOffset = 126" in MAIN
        and "self.theme.sectionBackground" in MAIN,
        "The first screen should use larger rows and neutral panel surfaces for a cleaner CooldownReminder hierarchy.",
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
        print("\nUI static audit failed:", ", ".join(failures))
        return 1

    print("\nUI static audit passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
