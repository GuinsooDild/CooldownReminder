local _, NPR = ...

local randomPool = {}
local base64 = {
    [0] = "a", "b", "c", "d", "e", "f", "g", "h",
    "i", "j", "k", "l", "m", "n", "o", "p",
    "q", "r", "s", "t", "u", "v", "w", "x",
    "y", "z", "A", "B", "C", "D", "E", "F",
    "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V",
    "W", "X", "Y", "Z", "0", "1", "2", "3",
    "4", "5", "6", "7", "8", "9", "(", ")",
}

function NPR:DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, innerValue in pairs(value) do
        copy[key] = self:DeepCopy(innerValue)
    end
    return copy
end

function NPR:MergeDefaults(target, defaults)
    if type(target) ~= "table" then
        target = {}
    end

    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = self:MergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end

    return target
end

function NPR:GenerateID()
    wipe(randomPool)
    for index = 1, 11 do
        randomPool[index] = base64[random(0, 63)]
    end
    return table.concat(randomPool)
end

function NPR:Round(value, decimals)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    local scaled = value * factor
    if scaled < 0 then
        return ceil(scaled - 0.5) / factor
    end
    return floor(scaled + 0.5) / factor
end

function NPR:Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    elseif value > maxValue then
        return maxValue
    end
    return value
end

function NPR:SecondsToClock(seconds)
    seconds = max(0, seconds or 0)
    local minutes = floor(seconds / 60)
    local wholeSeconds = floor(seconds % 60)
    return format("%02d:%02d", minutes, wholeSeconds)
end

function NPR:Print(message)
    local line = "|cff4db3ff[CooldownReminder]|r " .. tostring(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(line)
    else
        print(line)
    end
end

function NPR:IsConfigLockedDown()
    return InCombatLockdown and InCombatLockdown() or false
end

function NPR:PrintCombatLockdownMessage(action)
    self:Print((action or "This action") .. " is unavailable during combat.")
end

function NPR:CanUseConfigUI(action)
    if self:IsConfigLockedDown() then
        self:PrintCombatLockdownMessage(action)
        return false
    end

    if not self.clientUIReady or not self.mainWindow then
        self:Print((action or "Configuration") .. " is not ready yet. Try again after the loading screen finishes.")
        return false
    end

    return true
end

function NPR:LogDebug(message)
    if not self.db or not self.db.debug.enabled then
        return
    end

    local line = date("%H:%M:%S") .. " " .. tostring(message)
    table.insert(self.db.debug.logs, 1, line)
    while #self.db.debug.logs > 60 do
        table.remove(self.db.debug.logs)
    end

    self:Print(message)
end

function NPR:SafeSpellInfo(spellID)
    if not spellID or spellID == 0 then
        return nil
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return {
                name = info.name,
                icon = info.iconID,
            }
        end
    end

    local name, _, icon = GetSpellInfo(spellID)
    if name then
        return {
            name = name,
            icon = icon,
        }
    end
end

local function InsertSpellID(target, seen, spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then
        return
    end

    spellID = floor(spellID)
    if seen[spellID] then
        return
    end

    seen[spellID] = true
    target[#target + 1] = spellID
end

function NPR:GetSpellIDList(entry)
    local spellIDs = {}
    local seen = {}
    if type(entry) ~= "table" then
        return spellIDs
    end

    InsertSpellID(spellIDs, seen, entry.iconSpellID)
    InsertSpellID(spellIDs, seen, entry.spellID)
    InsertSpellID(spellIDs, seen, entry.eventSpellID)
    InsertSpellID(spellIDs, seen, entry.triggerSpellID)

    for _, field in ipairs({ "spellIDs", "combatLogSpellIDs" }) do
        local values = entry[field]
        if type(values) == "table" then
            for _, spellID in ipairs(values) do
                InsertSpellID(spellIDs, seen, spellID)
            end
        end
    end

    return spellIDs
end

function NPR:GetPrimarySpellID(entry)
    local spellIDs = self:GetSpellIDList(entry)
    return spellIDs[1]
end

function NPR:GetIconPath(entry)
    local primarySpellID = self:GetPrimarySpellID(entry)
    if primarySpellID then
        local info = self:SafeSpellInfo(primarySpellID)
        if info and info.icon then
            return info.icon
        end
    end
    return entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function NPR:GetPlayerRole()
    local role = UnitGroupRolesAssigned("player")
    if role and role ~= "NONE" then
        return role, "group"
    end

    local specIndex
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        specIndex = C_SpecializationInfo.GetSpecialization()
    elseif GetSpecialization then
        specIndex = GetSpecialization()
    end

    if specIndex and specIndex > 0 then
        local specRole
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
            local _, _, _, _, resolvedRole = C_SpecializationInfo.GetSpecializationInfo(specIndex)
            specRole = resolvedRole
        elseif GetSpecializationInfo then
            local _, _, _, _, resolvedRole = GetSpecializationInfo(specIndex)
            specRole = resolvedRole
        end

        if specRole and specRole ~= "NONE" and specRole ~= 0 then
            return specRole, "specialization"
        end
    end

    return "DAMAGER", "fallback"
end

function NPR:IsReminderRelevant(reminder)
    if not reminder or reminder.roleScope == "ALL" then
        return true
    end
    return reminder.roleScope == self:GetPlayerRole()
end

function NPR:GetSoundOption(soundKey)
    for _, option in ipairs(self.soundOptions) do
        if option.key == soundKey then
            return option
        end
    end
    return self.soundOptions[1]
end

function NPR:PlaySoundKey(soundKey)
    local option = self:GetSoundOption(soundKey)
    if option and option.soundKit then
        PlaySound(option.soundKit, self.db.runtime.soundChannel or "Master")
    end
end

function NPR:GetImportanceColor(importance)
    local info = self.importanceOptions[importance or "MEDIUM"] or self.importanceOptions.MEDIUM
    return info.color
end

function NPR:GetReminderDisplaySeconds(reminder)
    if not reminder then
        return 6
    end

    return self:Clamp(self:Round(tonumber(reminder.durationSeconds) or 6, 1), 2, 20)
end

function NPR:GetEventEntries(event)
    if type(event) ~= "table" or type(event.entries) ~= "table" then
        return nil
    end
    return event.entries
end

function NPR:GetEventOccurrence(event, occurrenceIndex)
    local entries = self:GetEventEntries(event)
    if not entries then
        return nil
    end

    occurrenceIndex = max(1, floor(tonumber(occurrenceIndex) or 1))
    local occurrence = entries[occurrenceIndex]
    if type(occurrence) ~= "table" or type(occurrence.time) ~= "number" then
        return nil
    end

    return occurrence, occurrenceIndex
end

function NPR:GetEventDuration(event, occurrence)
    if not event then
        return 0
    end

    local entry = self:GetEventOccurrence(event, occurrence)
    return (entry and entry.duration) or event.defaultDuration or 0
end

function NPR:GetEventDangerPercent(event)
    if not event then
        return 0
    end
    return self:Clamp(self:Round(tonumber(event.dangerPercent) or 0), 0, 100)
end

function NPR:GetEventDangerColor(event)
    local percent = self:GetEventDangerPercent(event) / 100
    local low = { 91 / 255, 168 / 255, 255 / 255 }
    local mid = { 255 / 255, 215 / 255, 87 / 255 }
    local high = { 255 / 255, 88 / 255, 106 / 255 }

    local fromColor = low
    local toColor = mid
    local progress = percent * 2
    if percent > 0.5 then
        fromColor = mid
        toColor = high
        progress = (percent - 0.5) * 2
    end

    return {
        r = fromColor[1] + (toColor[1] - fromColor[1]) * progress,
        g = fromColor[2] + (toColor[2] - fromColor[2]) * progress,
        b = fromColor[3] + (toColor[3] - fromColor[3]) * progress,
        a = 1,
    }
end

function NPR:FormatSpellIDList(entry)
    local spellIDs = self:GetSpellIDList(entry)
    if #spellIDs == 0 then
        return "unresolved"
    end

    for index, spellID in ipairs(spellIDs) do
        spellIDs[index] = tostring(spellID)
    end

    return table.concat(spellIDs, ", ")
end

function NPR:GetEncounterReferenceOnlySummary(encounter)
    if not encounter or type(encounter.referenceOnlySpells) ~= "table" or #encounter.referenceOnlySpells == 0 then
        return nil
    end

    local parts = {}
    for _, info in ipairs(encounter.referenceOnlySpells) do
        if type(info) == "table" and info.label then
            parts[#parts + 1] = format("%s (%s)", info.label, self:FormatSpellIDList(info))
        end
    end

    if #parts == 0 then
        return nil
    end

    return "Reference-only spell IDs pending live timing: " .. table.concat(parts, " | ")
end

function NPR:MatchesSpellID(entry, spellID)
    spellID = tonumber(spellID)
    if not spellID or not entry then
        return false
    end

    for _, candidate in ipairs(self:GetSpellIDList(entry)) do
        if candidate == spellID then
            return true
        end
    end

    return false
end

function NPR:MatchesCombatLogEvent(entry, subEvent, spellID)
    if not entry or not subEvent then
        return false
    end

    if entry.combatLogEvent and entry.combatLogEvent ~= subEvent then
        return false
    end

    local preferredSpellIDs = entry.combatLogSpellIDs
    if type(preferredSpellIDs) == "table" and #preferredSpellIDs > 0 then
        for _, candidate in ipairs(preferredSpellIDs) do
            if tonumber(candidate) == tonumber(spellID) then
                return true
            end
        end
        return false
    end

    if entry.eventSpellID then
        return tonumber(entry.eventSpellID) == tonumber(spellID)
    end

    return self:MatchesSpellID(entry, spellID)
end

function NPR:DescribeOffsetSeconds(offsetSeconds)
    offsetSeconds = tonumber(offsetSeconds) or 0
    if offsetSeconds < 0 then
        return format("%.1fs before", math.abs(offsetSeconds))
    elseif offsetSeconds > 0 then
        return format("%.1fs after", offsetSeconds)
    end
    return "on time"
end

function NPR:IsMinimapButtonHidden()
    return self.db and self.db.ui and self.db.ui.minimap and self.db.ui.minimap.hide == true
end

function NPR:SetMinimapButtonHidden(hidden)
    if not self.db or not self.db.ui or not self.db.ui.minimap then
        return false
    end

    if self:IsConfigLockedDown() then
        self:PrintCombatLockdownMessage("Minimap launcher settings")
        if self.minimapToggle then
            self.minimapToggle:SetChecked(self:IsMinimapButtonHidden(), true)
        end
        return false
    end

    self.db.ui.minimap.hide = hidden and true or false
    self:UpdateMinimapButtonPosition()

    if self.minimapToggle then
        self.minimapToggle:SetChecked(self:IsMinimapButtonHidden(), true)
    end
    return true
end

function NPR:GetDungeons()
    local dungeons = {}
    local seen = {}
    local data = self.Data or {}
    local registry = data.dungeons or {}
    local orderedKeys = data.season and data.season.dungeonOrder or {}

    for _, dungeonKey in ipairs(orderedKeys) do
        local dungeon = registry[dungeonKey]
        if dungeon then
            dungeons[#dungeons + 1] = dungeon
            seen[dungeonKey] = true
        end
    end

    for dungeonKey, dungeon in pairs(registry) do
        if not seen[dungeonKey] then
            dungeons[#dungeons + 1] = dungeon
        end
    end

    return dungeons
end

function NPR:GetDungeon(dungeonKey)
    local dungeons = self.Data and self.Data.dungeons
    if type(dungeons) == "table" then
        return dungeons[dungeonKey]
    end
end

function NPR:GetDefaultDungeonKey()
    local defaultKey = self.defaults and self.defaults.timeline and self.defaults.timeline.selectedDungeonKey
    if self:GetDungeon(defaultKey) then
        return defaultKey
    end

    local firstDungeon = self:GetDungeons()[1]
    return firstDungeon and firstDungeon.key or defaultKey
end

function NPR:GetDungeonEncounterKeys(dungeonKey)
    local dungeon = self:GetDungeon(dungeonKey)
    if not dungeon then
        return {}
    end

    if type(dungeon.encounterOrder) == "table" and #dungeon.encounterOrder > 0 then
        return dungeon.encounterOrder
    end

    return {}
end

function NPR:IsDungeonIncomplete(dungeonKey)
    return #self:GetDungeonEncounterKeys(dungeonKey) == 0
end

function NPR:GetDungeonEmptyStateMessage(dungeonKey)
    local dungeon = self:GetDungeon(dungeonKey)
    if not dungeon then
        return "No dungeon selected."
    end

    if type(dungeon.incompleteNote) == "string" and dungeon.incompleteNote ~= "" then
        return dungeon.incompleteNote
    end

    return "Boss timelines are not available for this dungeon yet."
end

function NPR:GetDungeonCoverageMenuLabel(dungeon)
    if not dungeon then
        return nil
    end

    local mappedBossCount = tonumber(dungeon.mappedBossCount) or 0
    local totalBossCount = tonumber(dungeon.totalBossCount) or 0
    if totalBossCount <= 0 then
        return nil
    end

    if mappedBossCount <= 0 then
        return "no timelines"
    end
    if mappedBossCount < totalBossCount then
        return format("%d/%d mapped", mappedBossCount, totalBossCount)
    end

    return "mapped"
end

function NPR:GetDungeonCoverageSummary(dungeon)
    if not dungeon then
        return nil
    end

    local mappedBossCount = tonumber(dungeon.mappedBossCount) or 0
    local totalBossCount = tonumber(dungeon.totalBossCount) or 0
    if totalBossCount <= 0 or mappedBossCount <= 0 or mappedBossCount >= totalBossCount then
        return nil
    end

    return format(
        "Partial dungeon coverage: %d/%d main bosses mapped. Unmapped bosses remain registry-only.",
        mappedBossCount,
        totalBossCount
    )
end

function NPR:GetDefaultEncounterKey(dungeonKey)
    local defaults = self.defaults and self.defaults.timeline or {}
    local selectedByDungeon = defaults.selectedEncounterByDungeon
    local defaultKey = type(selectedByDungeon) == "table" and selectedByDungeon[dungeonKey] or nil
    if self:IsEncounterInDungeon(dungeonKey, defaultKey) then
        return defaultKey
    end

    defaultKey = defaults.selectedEncounterKey
    if self:IsEncounterInDungeon(dungeonKey, defaultKey) then
        return defaultKey
    end

    local encounterKeys = self:GetDungeonEncounterKeys(dungeonKey)
    return encounterKeys[1]
end

function NPR:NormalizeDungeonSelection(dungeonKey)
    if self:GetDungeon(dungeonKey) then
        return dungeonKey
    end
    return self:GetDefaultDungeonKey()
end

function NPR:IsEncounterInDungeon(dungeonKey, encounterKey)
    if not dungeonKey or not encounterKey then
        return false
    end

    for _, candidateKey in ipairs(self:GetDungeonEncounterKeys(dungeonKey)) do
        if candidateKey == encounterKey then
            return true
        end
    end

    return false
end

function NPR:NormalizeEncounterSelection(dungeonKey, encounterKey)
    dungeonKey = self:NormalizeDungeonSelection(dungeonKey)
    if self:IsEncounterInDungeon(dungeonKey, encounterKey) then
        return encounterKey
    end
    return self:GetDefaultEncounterKey(dungeonKey)
end

function NPR:GetSelectedDungeonKey()
    if not self.db or not self.db.timeline then
        return self:GetDefaultDungeonKey()
    end
    return self:NormalizeDungeonSelection(self.db.timeline.selectedDungeonKey)
end

function NPR:GetSelectedEncounterKey(dungeonKey)
    dungeonKey = self:NormalizeDungeonSelection(dungeonKey or self:GetSelectedDungeonKey())

    local timeline = self.db and self.db.timeline or nil
    local selectedByDungeon = timeline and timeline.selectedEncounterByDungeon or nil
    local encounterKey = type(selectedByDungeon) == "table" and selectedByDungeon[dungeonKey] or nil
    if encounterKey == nil and timeline and dungeonKey == self:GetSelectedDungeonKey() then
        encounterKey = timeline.selectedEncounterKey
    end

    return self:NormalizeEncounterSelection(dungeonKey, encounterKey)
end

function NPR:SetSelectedDungeonKey(dungeonKey)
    if not self.db or not self.db.timeline then
        return nil
    end

    dungeonKey = self:NormalizeDungeonSelection(dungeonKey)
    self.db.timeline.selectedDungeonKey = dungeonKey
    if type(self.db.timeline.selectedEncounterByDungeon) ~= "table" then
        self.db.timeline.selectedEncounterByDungeon = {}
    end

    local encounterKey = self:GetSelectedEncounterKey(dungeonKey)
    self.db.timeline.selectedEncounterByDungeon[dungeonKey] = encounterKey
    self.db.timeline.selectedEncounterKey = encounterKey

    return dungeonKey, encounterKey
end

function NPR:SetSelectedEncounterKey(encounterKey, dungeonKey)
    if not self.db or not self.db.timeline then
        return nil
    end

    dungeonKey = self:NormalizeDungeonSelection(dungeonKey or self:GetSelectedDungeonKey())
    encounterKey = self:NormalizeEncounterSelection(dungeonKey, encounterKey)
    if type(self.db.timeline.selectedEncounterByDungeon) ~= "table" then
        self.db.timeline.selectedEncounterByDungeon = {}
    end

    self.db.timeline.selectedEncounterByDungeon[dungeonKey] = encounterKey
    if dungeonKey == self:GetSelectedDungeonKey() then
        self.db.timeline.selectedDungeonKey = dungeonKey
        self.db.timeline.selectedEncounterKey = encounterKey
    end

    return encounterKey
end

function NPR:GetEncounter(encounterKey)
    return self.Data and self.Data.encounters and self.Data.encounters[encounterKey]
end

function NPR:GetSelectedEncounter()
    return self:GetEncounter(self:GetSelectedEncounterKey())
end

function NPR:GetEvent(encounterKey, eventKey)
    local events = self.state.eventsByEncounter[encounterKey]
    return events and events[eventKey]
end

function NPR:GetTrackVisibility(encounterKey, eventKey)
    local encounterVisibility = self.db.timeline.trackVisibility[encounterKey]
    if encounterVisibility == nil then
        self.db.timeline.trackVisibility[encounterKey] = {}
        encounterVisibility = self.db.timeline.trackVisibility[encounterKey]
    end
    if encounterVisibility[eventKey] == nil then
        encounterVisibility[eventKey] = true
    end
    return encounterVisibility[eventKey]
end

function NPR:SetTrackVisibility(encounterKey, eventKey, value)
    if not self.db.timeline.trackVisibility[encounterKey] then
        self.db.timeline.trackVisibility[encounterKey] = {}
    end
    self.db.timeline.trackVisibility[encounterKey][eventKey] = value and true or false
end

function NPR:SaveFramePosition(frame, path)
    if not frame then
        return false
    end
    if self:IsConfigLockedDown() then
        self:PrintCombatLockdownMessage("Window position saving")
        return false
    end
    local settings = self.db.ui[path]
    if not settings then
        return false
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    settings.point = point
    settings.relativePoint = relativePoint
    settings.x = self:Round(x)
    settings.y = self:Round(y)
    if frame:GetWidth() then
        settings.width = self:Round(frame:GetWidth())
    end
    if frame:GetHeight() then
        settings.height = self:Round(frame:GetHeight())
    end
    return true
end

function NPR:RestoreFramePosition(frame, path)
    if not frame then
        return false
    end
    if self:IsConfigLockedDown() then
        self.pendingFullRefresh = true
        self:PrintCombatLockdownMessage("Window position restore")
        return false
    end
    local settings = self.db.ui[path]
    if not settings then
        return false
    end

    frame:ClearAllPoints()
    frame:SetPoint(settings.point or "CENTER", UIParent, settings.relativePoint or "CENTER", settings.x or 0, settings.y or 0)
    if settings.width then
        frame:SetWidth(settings.width)
    end
    if settings.height then
        frame:SetHeight(settings.height)
    end
    return true
end

function NPR:ResolveReminderTime(reminder)
    if not reminder then
        return nil
    end

    local event = self:GetEvent(reminder.encounterKey, reminder.eventKey)
    if not event then
        return nil, "UNKNOWN_EVENT"
    end

    local occurrence = self:GetEventOccurrence(event, reminder.occurrence)
    if not occurrence then
        return nil, "UNKNOWN_OCCURRENCE"
    end

    return occurrence.time + (reminder.offsetSeconds or 0)
end

function NPR:SortReminders(reminders)
    table.sort(reminders, function(left, right)
        local leftTime = self:ResolveReminderTime(left)
        local rightTime = self:ResolveReminderTime(right)

        if left.enabled ~= right.enabled then
            return left.enabled and not right.enabled
        end
        if leftTime and rightTime and leftTime ~= rightTime then
            return leftTime < rightTime
        elseif leftTime and not rightTime then
            return true
        elseif rightTime and not leftTime then
            return false
        end
        return tostring(left.id) < tostring(right.id)
    end)
end

function NPR:GetUnknownReminderCount(encounterKey)
    local count = 0
    for _, reminder in ipairs(self:GetEncounterReminders(encounterKey)) do
        local resolvedTime = self:ResolveReminderTime(reminder)
        if not resolvedTime then
            count = count + 1
        end
    end
    return count
end

function NPR:GetReminderDisplayLabel(reminder)
    if not reminder then
        return "Reminder"
    end

    if type(reminder.text) == "string" and reminder.text ~= "" then
        return reminder.text
    end

    if reminder.eventKey == "pull_anchor" then
        return "Pull reminder"
    end

    local event = self:GetEvent(reminder.encounterKey, reminder.eventKey)
    if event and event.label then
        return event.label
    end

    return "Reminder"
end

function NPR:GetReminderIssueLabel(reason)
    if reason == "UNKNOWN_EVENT" then
        return "missing event"
    elseif reason == "UNKNOWN_OCCURRENCE" then
        return "missing occurrence"
    end

    return "unresolved timing"
end

function NPR:GetUnknownReminderDiagnostics(encounterKey, limit)
    local count = 0
    local samples = {}

    if not encounterKey then
        return count, samples
    end

    limit = max(1, floor(tonumber(limit) or 1))
    for _, reminder in ipairs(self:GetEncounterReminders(encounterKey)) do
        local resolvedTime, reason = self:ResolveReminderTime(reminder)
        if not resolvedTime then
            count = count + 1
            if #samples < limit then
                samples[#samples + 1] = format("%s (%s)", self:GetReminderDisplayLabel(reminder), self:GetReminderIssueLabel(reason))
            end
        end
    end

    return count, samples
end

function NPR:GetNextValidationTarget(encounterKey)
    encounterKey = encounterKey or (self.db and self.db.runtime and self.db.runtime.activeEncounterKey) or self:GetSelectedEncounterKey()
    if not encounterKey then
        return nil
    end

    local unknownCount, unknownSamples = self:GetUnknownReminderDiagnostics(encounterKey, 1)
    if unknownSamples[1] then
        local suffix = unknownCount > 1 and format(" (+%d more)", unknownCount - 1) or ""
        return "Fix " .. unknownSamples[1] .. suffix
    end

    local bucket = self.db and self.db.debug and self.db.debug.observations and self.db.debug.observations[encounterKey]
    local bestDriftText
    local bestDriftAbs
    if bucket and bucket.driftByEvent then
        for eventKey, drift in pairs(bucket.driftByEvent) do
            drift = tonumber(drift)
            if drift then
                local driftAbs = abs(drift)
                if not bestDriftAbs or driftAbs > bestDriftAbs then
                    local event = self:GetEvent(encounterKey, eventKey)
                    bestDriftText = format("%s %+.1fs", event and event.label or eventKey, drift)
                    bestDriftAbs = driftAbs
                end
            end
        end
    end
    if bestDriftText then
        return "Validate " .. bestDriftText
    end

    local encounter = self:GetEncounter(encounterKey)
    if encounter and type(encounter.referenceOnlySpells) == "table" then
        for _, info in ipairs(encounter.referenceOnlySpells) do
            if type(info) == "table" and type(info.label) == "string" and info.label ~= "" then
                return "Time " .. info.label
            end
        end
    end

    return nil
end
