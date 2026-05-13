local _, NPR = ...

local validImportance = {
    LOW = true,
    MEDIUM = true,
    HIGH = true,
}

local validRoleScope = {
    ALL = true,
    HEALER = true,
    TANK = true,
    DAMAGER = true,
}

local validFramePoints = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local validSoundChannels = {
    Master = true,
    SFX = true,
    Music = true,
    Ambience = true,
    Dialog = true,
}

local function NormalizeString(value, fallback)
    if type(value) == "string" then
        return value
    end
    return fallback
end

local function NormalizeTrimmedString(value, fallback)
    value = NormalizeString(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function NormalizeRequiredString(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return fallback
end

local function NormalizeNumber(value, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback
    end
    return value
end

local function NormalizeClampedNumber(value, fallback, minValue, maxValue)
    value = NormalizeNumber(value, fallback)
    if value == nil then
        return fallback
    end
    if minValue ~= nil and value < minValue then
        value = minValue
    end
    if maxValue ~= nil and value > maxValue then
        value = maxValue
    end
    return value
end

local function NormalizeFramePoint(value, fallback)
    if type(value) == "string" and validFramePoints[value] then
        return value
    end
    return fallback
end

local function NormalizeFrameSettings(settings, defaults, minWidth, minHeight)
    settings = type(settings) == "table" and settings or {}
    settings.point = NormalizeFramePoint(settings.point, defaults.point)
    settings.relativePoint = NormalizeFramePoint(settings.relativePoint, defaults.relativePoint)
    settings.x = floor(NormalizeClampedNumber(settings.x, defaults.x, -10000, 10000))
    settings.y = floor(NormalizeClampedNumber(settings.y, defaults.y, -10000, 10000))

    if defaults.width then
        settings.width = floor(NormalizeClampedNumber(settings.width, defaults.width, minWidth or 120, 2400))
    end
    if defaults.height then
        settings.height = floor(NormalizeClampedNumber(settings.height, defaults.height, minHeight or 80, 1600))
    end

    return settings
end

local function IsValidSoundKey(soundKey)
    if type(soundKey) ~= "string" then
        return false
    end

    for _, option in ipairs(NPR.soundOptions or {}) do
        if option.key == soundKey then
            return true
        end
    end

    return false
end

function NPR:NormalizeReminder(reminderID, reminder)
    if type(reminder) ~= "table" then
        return nil
    end

    local normalized = self:DeepCopy(reminder)
    normalized.id = reminderID
    normalized.encounterKey = NormalizeRequiredString(normalized.encounterKey, nil)
    normalized.eventKey = NormalizeRequiredString(normalized.eventKey, nil)
    normalized.occurrence = max(1, floor(NormalizeNumber(normalized.occurrence, 1)))
    normalized.offsetSeconds = self:Round(NormalizeNumber(normalized.offsetSeconds, 0), 1)
    normalized.enabled = normalized.enabled ~= false
    normalized.text = NormalizeTrimmedString(normalized.text, "")

    local iconSpellID = NormalizeNumber(normalized.iconSpellID, nil)
    normalized.iconSpellID = iconSpellID and iconSpellID > 0 and floor(iconSpellID) or nil

    normalized.soundKey = IsValidSoundKey(normalized.soundKey) and normalized.soundKey or "NONE"
    normalized.importance = validImportance[normalized.importance] and normalized.importance or "MEDIUM"
    normalized.durationSeconds = self:Clamp(self:Round(NormalizeNumber(normalized.durationSeconds, 6), 1), 2, 20)
    normalized.roleScope = validRoleScope[normalized.roleScope] and normalized.roleScope or "ALL"
    normalized.updatedAt = NormalizeNumber(normalized.updatedAt, time())

    if not normalized.encounterKey or not normalized.eventKey then
        return nil
    end

    return normalized
end

function NPR:InitializeDatabase()
    if not CooldownReminderDB then
        CooldownReminderDB = self:DeepCopy(self.defaults)
    end

    self.db = self:MergeDefaults(CooldownReminderDB, self.defaults)
    self.db.version = self.version

    if type(self.db.reminders) ~= "table" then
        self.db.reminders = {}
    end
    if type(self.db.debug.logs) ~= "table" then
        self.db.debug.logs = {}
    end
    if type(self.db.debug.observations) ~= "table" then
        self.db.debug.observations = {}
    end
    if type(self.db.timeline.trackVisibility) ~= "table" then
        self.db.timeline.trackVisibility = {}
    end

    self.db.ui.window = NormalizeFrameSettings(self.db.ui.window, self.defaults.ui.window, 1040, 300)
    self.db.ui.editor = NormalizeFrameSettings(self.db.ui.editor, self.defaults.ui.editor, 520, 420)
    self.db.ui.runtimeAnchor = NormalizeFrameSettings(self.db.ui.runtimeAnchor, self.defaults.ui.runtimeAnchor, 180, 24)

    if type(self.db.timeline.selectedEncounterByDungeon) ~= "table" then
        self.db.timeline.selectedEncounterByDungeon = {}
    end

    local selectedDungeonKey = self:NormalizeDungeonSelection(self.db.timeline.selectedDungeonKey)
    local legacyEncounterKey = NormalizeRequiredString(self.db.timeline.selectedEncounterKey, nil)
    if legacyEncounterKey and self.db.timeline.selectedEncounterByDungeon[selectedDungeonKey] == nil then
        self.db.timeline.selectedEncounterByDungeon[selectedDungeonKey] = legacyEncounterKey
    end

    local normalizedEncounterByDungeon = {}
    for dungeonKey, encounterKey in pairs(self.db.timeline.selectedEncounterByDungeon) do
        if self:GetDungeon(dungeonKey) then
            normalizedEncounterByDungeon[dungeonKey] = self:NormalizeEncounterSelection(dungeonKey, encounterKey)
        end
    end
    self.db.timeline.selectedEncounterByDungeon = normalizedEncounterByDungeon
    self:SetSelectedDungeonKey(selectedDungeonKey)
    self.db.timeline.zoom = self:Clamp(NormalizeNumber(self.db.timeline.zoom, self.defaults.timeline.zoom), 0.05, 0.55)
    self.db.timeline.scroll = max(0, NormalizeNumber(self.db.timeline.scroll, 0))
    self.db.timeline.showRelevantOnly = self.db.timeline.showRelevantOnly == true
    self.db.timeline.showDisabled = self.db.timeline.showDisabled ~= false
    self.db.timeline.showDiagnostics = self.db.timeline.showDiagnostics == true
    self.db.ui.minimap.hide = self.db.ui.minimap.hide == true
    self.db.ui.minimap.angle = NormalizeNumber(self.db.ui.minimap.angle, self.defaults.ui.minimap.angle) % 360
    self.db.runtime.soundChannel = validSoundChannels[self.db.runtime.soundChannel] and self.db.runtime.soundChannel or self.defaults.runtime.soundChannel
    self.db.runtime.selectedRole = validRoleScope[self.db.runtime.selectedRole] and self.db.runtime.selectedRole or self.defaults.runtime.selectedRole
    self.db.debug.enabled = self.db.debug.enabled == true
    if self.db.debug.armedBossKey and not self:GetEncounter(self.db.debug.armedBossKey) then
        self.db.debug.armedBossKey = nil
    end

    local removals = {}
    for reminderID, reminder in pairs(self.db.reminders) do
        local normalized = self:NormalizeReminder(reminderID, reminder)
        self.db.reminders[reminderID] = normalized
        if not normalized then
            removals[#removals + 1] = reminderID
        end
    end
    for _, reminderID in ipairs(removals) do
        self.db.reminders[reminderID] = nil
    end
end

function NPR:RebuildReminderIndexes()
    wipe(self.state.remindersByEncounter)

    local removals = {}
    for reminderID, reminder in pairs(self.db.reminders) do
        local normalized = self:NormalizeReminder(reminderID, reminder)
        self.db.reminders[reminderID] = normalized
        if not normalized then
            removals[#removals + 1] = reminderID
        end
        if normalized and normalized.encounterKey then
            if not self.state.remindersByEncounter[normalized.encounterKey] then
                self.state.remindersByEncounter[normalized.encounterKey] = {}
            end
            table.insert(self.state.remindersByEncounter[normalized.encounterKey], normalized)
        end
    end

    for _, reminderID in ipairs(removals) do
        self.db.reminders[reminderID] = nil
    end

    for _, reminders in pairs(self.state.remindersByEncounter) do
        self:SortReminders(reminders)
    end
end

function NPR:UpsertReminder(reminder)
    reminder.updatedAt = time()
    self.db.reminders[reminder.id] = self:NormalizeReminder(reminder.id, reminder)
    self:RebuildReminderIndexes()
end

function NPR:DuplicateReminder(reminderID)
    local source = self.db and self.db.reminders and self.db.reminders[reminderID]
    if not source then
        return nil
    end

    local copy = self:DeepCopy(source)
    copy.id = self:GenerateID()
    copy.copiedFromReminderID = reminderID
    copy.updatedAt = time()
    self.db.reminders[copy.id] = self:NormalizeReminder(copy.id, copy)
    self:RebuildReminderIndexes()
    return self.db.reminders[copy.id]
end

function NPR:DeleteReminder(reminderID)
    self.db.reminders[reminderID] = nil
    self:RebuildReminderIndexes()
end

function NPR:GetEncounterReminders(encounterKey)
    return self.state.remindersByEncounter[encounterKey] or {}
end

function NPR:LogWork(message)
    self.pendingWorkLog = self.pendingWorkLog or {}
    table.insert(self.pendingWorkLog, date("%Y-%m-%d %H:%M:%S") .. " " .. tostring(message))
end
