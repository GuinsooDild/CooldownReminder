local _, NPR = ...

local function NormalizeBossKey(text)
    text = (text or ""):lower():gsub("%s+", "")
    if text == "kasreth" or text == "chiefcorewrightkasreth" then
        return "kasreth"
    elseif text == "nysarra" or text == "corewardennysarra" then
        return "nysarra"
    elseif text == "lothraxion" then
        return "lothraxion"
    end
end

local function SafeCallAPI(owner, methodName, ...)
    if type(owner) ~= "table" or type(owner[methodName]) ~= "function" then
        return false, methodName .. " unavailable"
    end

    local ok, first, second, third, fourth, fifth = pcall(owner[methodName], ...)
    if not ok then
        return false, tostring(first)
    end

    return true, first, second, third, fourth, fifth
end

local function FormatValue(value)
    if value == nil then
        return "nil"
    end
    return tostring(value)
end

local function AppendField(fields, label, value)
    fields[#fields + 1] = label .. "=" .. FormatValue(value)
end

local function FormatMapScoreInfo(challengeMapID)
    if not challengeMapID then
        return "GetMapScoreInfo skipped: no registry challengeMapID"
    end

    local ok, scoreInfo = SafeCallAPI(C_MythicPlus, "GetMapScoreInfo", challengeMapID)
    if not ok then
        return "GetMapScoreInfo unavailable: " .. tostring(scoreInfo)
    end

    if type(scoreInfo) ~= "table" then
        return "GetMapScoreInfo(" .. challengeMapID .. ")=" .. FormatValue(scoreInfo)
    end

    local fields = {}
    AppendField(fields, "mapScore", scoreInfo.mapScore)
    AppendField(fields, "bestRunLevel", scoreInfo.bestRunLevel)
    AppendField(fields, "bestRunDurationMS", scoreInfo.bestRunDurationMS)
    AppendField(fields, "finishedSuccess", scoreInfo.finishedSuccess)
    return "GetMapScoreInfo(" .. challengeMapID .. ") {" .. table.concat(fields, ", ") .. "}"
end

local function FormatMapUIInfo(challengeMapID)
    if not challengeMapID then
        return "GetMapUIInfo skipped: no registry challengeMapID"
    end

    local ok, mapName, _, timeLimit, texture = SafeCallAPI(C_ChallengeMode, "GetMapUIInfo", challengeMapID)
    if not ok then
        return "GetMapUIInfo unavailable: " .. tostring(mapName)
    end

    return "GetMapUIInfo(" .. challengeMapID .. ") {name=" .. FormatValue(mapName) .. ", timeLimit=" .. FormatValue(timeLimit) .. ", texture=" .. FormatValue(texture) .. "}"
end

local function FormatCompletionInfo(challengeMapID)
    local ok, completionChallengeMapID, level, completionTime, onTime, upgrades = SafeCallAPI(C_ChallengeMode, "GetChallengeCompletionInfo")
    if not ok then
        return "GetChallengeCompletionInfo unavailable: " .. tostring(completionChallengeMapID)
    end

    local matchesRegistry = challengeMapID and completionChallengeMapID and tonumber(completionChallengeMapID) == tonumber(challengeMapID)
    local fields = {}
    AppendField(fields, "mapChallengeModeID", completionChallengeMapID)
    AppendField(fields, "level", level)
    AppendField(fields, "time", completionTime)
    AppendField(fields, "onTime", onTime)
    AppendField(fields, "upgrades", upgrades)
    AppendField(fields, "matchesRegistryChallengeMapID", matchesRegistry)
    return "GetChallengeCompletionInfo {" .. table.concat(fields, ", ") .. "}"
end

local function GetSeedSortValue(seed)
    return tonumber(seed and (seed.journalEncounterID or seed.encounterID)) or 999999
end

local function FormatBossSeed(seed, index)
    local label = seed.encounterKey or seed.key or ("boss" .. tostring(index))
    return label .. "[journalEncounterID=" .. FormatValue(seed.journalEncounterID) .. ", encounterID=" .. FormatValue(seed.encounterID) .. "]"
end

local function FormatOrderedBossIDs(addon, dungeon)
    local chunks = {}

    if type(dungeon.encounterOrder) == "table" and #dungeon.encounterOrder > 0 then
        for index, encounterKey in ipairs(dungeon.encounterOrder) do
            local encounter = addon:GetEncounter(encounterKey)
            chunks[#chunks + 1] = FormatBossSeed({
                encounterKey = encounterKey,
                encounterID = encounter and encounter.encounterID or nil,
            }, index)
        end
        return table.concat(chunks, ", ")
    end

    if type(dungeon.proofEncounterOrder) == "table" and #dungeon.proofEncounterOrder > 0 then
        for index, seed in ipairs(dungeon.proofEncounterOrder) do
            chunks[#chunks + 1] = FormatBossSeed(seed, index)
        end
        return table.concat(chunks, ", ")
    end

    if type(dungeon.encounterRegistry) == "table" then
        local seeds = {}
        for _, seed in pairs(dungeon.encounterRegistry) do
            if type(seed) == "table" then
                seeds[#seeds + 1] = seed
            end
        end
        table.sort(seeds, function(left, right)
            return GetSeedSortValue(left) < GetSeedSortValue(right)
        end)
        for index, seed in ipairs(seeds) do
            chunks[#chunks + 1] = FormatBossSeed(seed, index)
        end
        if #chunks > 0 then
            return table.concat(chunks, ", ")
        end
    end

    return "unavailable (no ordered boss IDs loaded yet)"
end

local function PrintRegistryEvidence(addon, dungeon)
    addon:Print(format(
        "Evidence %s: journalInstanceID=%s | mapID=%s | challengeMapID=%s | challengeMapIDPosture=%s | totalBossCount=%s | mappedBossCount=%s",
        dungeon.displayName or dungeon.name or dungeon.key,
        FormatValue(dungeon.journalInstanceID),
        FormatValue(dungeon.mapID),
        FormatValue(dungeon.challengeMapID),
        FormatValue(dungeon.challengeMapIDPosture),
        FormatValue(dungeon.totalBossCount),
        FormatValue(dungeon.mappedBossCount)
    ))
    addon:Print("Evidence boss IDs: " .. FormatOrderedBossIDs(addon, dungeon))
    addon:Print("Evidence live: " .. FormatMapScoreInfo(dungeon.challengeMapID) .. " | " .. FormatMapUIInfo(dungeon.challengeMapID) .. " | " .. FormatCompletionInfo(dungeon.challengeMapID))
end

local function PrintRegistryEvidenceExport(addon, scope)
    local dungeons = {}
    scope = (scope or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if scope == "season" or scope == "all" or scope == "roster" then
        dungeons = addon:GetDungeons()
    elseif scope ~= "" and scope ~= "current" and scope ~= "selected" then
        local dungeon = addon:GetDungeon(scope)
        if not dungeon then
            addon:Print("Usage: /crem evidence [season|all|current|<dungeon_key>]")
            return
        end
        dungeons[1] = dungeon
    else
        local selectedDungeon = addon:GetDungeon(addon:GetSelectedDungeonKey())
        if selectedDungeon then
            dungeons[1] = selectedDungeon
        end
    end

    if #dungeons == 0 then
        addon:Print("Evidence export no-op: no season registry is loaded.")
        return
    end

    addon:Print("Registry evidence export (" .. (scope ~= "" and scope or "current") .. "). Live API fields may be unavailable outside the Retail client or before a completed challenge run.")
    for _, dungeon in ipairs(dungeons) do
        PrintRegistryEvidence(addon, dungeon)
    end
end

function NPR:RegisterSlashCommands()
    SLASH_COOLDOWNREMINDER1 = "/crem"

    SlashCmdList.COOLDOWNREMINDER = function(message)
        local command, rest = message:match("^(%S*)%s*(.-)$")
        command = command and command:lower() or ""

        if command == "" then
            self:ToggleMainWindow()
            return
        end

        if command == "debug" then
            self.db.debug.enabled = not self.db.debug.enabled
            if self.runtime then
                self.runtime:RefreshDebugText()
            end
            self:Print("Debug " .. (self.db.debug.enabled and "enabled" or "disabled"))
            return
        end

        if command == "reset" then
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Reset")
                return
            end
            self.db.ui.window = self:DeepCopy(self.defaults.ui.window)
            self.db.ui.editor = self:DeepCopy(self.defaults.ui.editor)
            self.db.ui.runtimeAnchor = self:DeepCopy(self.defaults.ui.runtimeAnchor)
            self.db.ui.minimap = self:DeepCopy(self.defaults.ui.minimap)
            self.db.runtime.activeEncounterKey = nil
            self.db.timeline.selectedDungeonKey = self.defaults.timeline.selectedDungeonKey
            self.db.timeline.selectedEncounterKey = self.defaults.timeline.selectedEncounterKey
            self.db.timeline.selectedEncounterByDungeon = self:DeepCopy(self.defaults.timeline.selectedEncounterByDungeon)
            self.db.timeline.zoom = self.defaults.timeline.zoom
            self.db.timeline.scroll = self.defaults.timeline.scroll
            self.db.timeline.showRelevantOnly = self.defaults.timeline.showRelevantOnly
            self.db.timeline.showDisabled = self.defaults.timeline.showDisabled
            self.db.timeline.showDiagnostics = self.defaults.timeline.showDiagnostics
            self.db.timeline.trackVisibility = {}
            self:SetSelectedDungeonKey(self.db.timeline.selectedDungeonKey)
            self.db.debug.armedBossKey = nil
            self.db.debug.observations = {}
            if self.runtime then
                self.runtime:StopEncounter("slash-reset")
            end
            self:RestoreFramePosition(self.mainWindow, "window")
            self:RestoreFramePosition(self.editorWindow, "editor")
            self:RestoreFramePosition(self.runtime and self.runtime.anchor, "runtimeAnchor")
            self:UpdateMinimapButtonPosition()
            if self.minimapToggle then
                self.minimapToggle:SetChecked(self:IsMinimapButtonHidden(), true)
            end
            if self.mainWindow then
                self:RefreshTimeline()
            end
            self:Print("Window, editor, runtime, minimap button and timeline filters reset.")
            return
        end

        if command == "status" then
            local selected = self:GetSelectedEncounter()
            local selectedDungeon = self:GetDungeon(self:GetSelectedDungeonKey())
            local activeKey = self.db.runtime.activeEncounterKey
            local active = activeKey and self:GetEncounter(activeKey)
            local activeName = active and active.name or "none"
            local selectedName = selected and selected.name or "none"
            local selectedDungeonName = selectedDungeon and selectedDungeon.name or "none"
            local armedKey = self.db.debug.armedBossKey
            local armed = armedKey and self:GetEncounter(armedKey)
            local armedName = armed and armed.name or "none"
            local reminderCount = selected and #self:GetEncounterReminders(selected.key) or 0
            local unknownCount = selected and self:GetUnknownReminderCount(selected.key) or 0
            local role, roleSource = self:GetPlayerRole()
            local nextTarget = self:GetNextValidationTarget(activeKey or (selected and selected.key))
            self:Print(format("Dungeon: %s | Selected: %s | Active: %s | Armed: %s | Reminders: %d | Unknown: %d | Role: %s (%s) | Debug: %s | Minimap: %s", selectedDungeonName, selectedName, activeName, armedName, reminderCount, unknownCount, tostring(role), tostring(roleSource), self.db.debug.enabled and "on" or "off", self:IsMinimapButtonHidden() and "hidden" or "shown"))
            self:Print(format("Command surface: /crem | SavedVariables: %s", self.savedVariablesName or "CooldownReminderDB"))
            if nextTarget then
                self:Print("Next validation target: " .. nextTarget)
            end
            return
        end

        if command == "evidence" or command == "registry" then
            PrintRegistryEvidenceExport(self, rest)
            return
        end

        if command == "minimap" or command == "icon" then
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Minimap launcher settings")
                return
            end

            local mode = (rest or ""):lower()
            if mode == "hide" or mode == "off" then
                self:SetMinimapButtonHidden(true)
                self:Print("Minimap button hidden.")
                return
            elseif mode == "show" or mode == "on" then
                self:SetMinimapButtonHidden(false)
                self:Print("Minimap button shown.")
                return
            elseif mode == "toggle" or mode == "" then
                local hidden = not self:IsMinimapButtonHidden()
                self:SetMinimapButtonHidden(hidden)
                self:Print("Minimap button " .. (hidden and "hidden." or "shown."))
                return
            end

            self:Print("Usage: /crem minimap show|hide|toggle")
            return
        end

        if command == "arm" then
            if rest == "off" or rest == "clear" then
                self.db.debug.armedBossKey = nil
                if self.runtime then
                    self.runtime:StopEncounter("manual-clear")
                end
                self:Print("Manual arming cleared.")
                return
            end

            local encounterKey = NormalizeBossKey(rest)
            if not encounterKey then
                self:Print("Usage: /crem arm kasreth|nysarra|lothraxion|off")
                return
            end

            self.db.debug.armedBossKey = encounterKey
            if self.runtime then
                self.runtime:StartEncounter(encounterKey, "manual-arm")
            end
            self:Print("Manually armed " .. self:GetEncounter(encounterKey).name)
            return
        end

        self:Print("Commands: /crem, /crem debug, /crem status, /crem evidence [season|current|<dungeon_key>], /crem reset, /crem minimap show|hide|toggle, /crem arm <boss>, /crem arm off.")
    end
end
