local _, NPR = ...

local function ParseNumber(text, fallback)
    local value = tonumber(text)
    if value == nil then
        return fallback
    end
    return value
end

local function TrimText(text)
    text = text or ""
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function GetReminderModeText(reminder)
    if reminder.eventKey == "pull_anchor" then
        return "Pull-relative reminder"
    end
    return "Event-relative reminder"
end

local function GetReminderContextText(reminder)
    local event = NPR:GetEvent(reminder.encounterKey, reminder.eventKey)
    local eventLabel = event and event.label or "Unknown event"
    local occurrence = NPR:GetEventOccurrence(event, reminder.occurrence)
    local eventTime = occurrence and occurrence.time or 0
    local offset = reminder.offsetSeconds or 0
    local trigger = NPR:ResolveReminderTime(reminder)
    local offsetText = NPR:DescribeOffsetSeconds(offset)
    local triggerText = NPR:SecondsToClock(trigger or 0)

    if reminder.eventKey == "pull_anchor" then
        return format("Anchored to pull. Reminder fires %s at %s.", offsetText, triggerText)
    end

    return format(
        "%s #%d happens at %s. Reminder fires %s at %s.",
        eventLabel,
        reminder.occurrence or 1,
        NPR:SecondsToClock(eventTime),
        offsetText,
        triggerText
    )
end

local function GetSuggestedReminderDefaults(eventKey, event)
    if eventKey == "pull_anchor" or not event then
        return "NONE", "MEDIUM", nil
    end

    local dangerPercent = NPR:GetEventDangerPercent(event)
    if dangerPercent >= 75 then
        return "RAID_WARNING", "HIGH", "Sound and importance were prefilled from the event danger. Change them if needed."
    end
    if dangerPercent >= 45 then
        return "READY_CHECK", "MEDIUM", "Sound and importance were prefilled from the event danger. Change them if needed."
    end

    return "NONE", "MEDIUM", nil
end

function NPR:InitializeEditor()
    local editor = self:CreateWindow("editor", self.db.ui.editor.width, self.db.ui.editor.height, "Reminder")
    editor:Hide()
    local content = editor.content or editor
    local rightColumnX = 284
    local dropdownWidth = 248
    local buttonWidth = 104
    local copyButtonWidth = 76

    self.editorWindow = editor
    self.editorState = {
        reminderID = nil,
    }

    local controls = {}
    self.editorControls = controls

    controls.contextMode = self:CreateLabel(content, "", NPRFontNormal, unpack(self.theme.textAccent))
    controls.contextMode:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    controls.contextMode:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    controls.contextMode:SetJustifyH("LEFT")
    controls.contextMode:SetJustifyV("TOP")

    controls.context = self:CreateLabel(content, "", NPRFontSmall, unpack(self.theme.textMuted))
    controls.context:SetPoint("TOPLEFT", controls.contextMode, "BOTTOMLEFT", 0, -4)
    controls.context:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -4)
    controls.context:SetJustifyH("LEFT")
    controls.context:SetJustifyV("TOP")

    controls.prefill = self:CreateLabel(content, "", NPRFontSmall, unpack(self.theme.textAccent))
    controls.prefill:SetPoint("TOPLEFT", controls.context, "BOTTOMLEFT", 0, -4)
    controls.prefill:SetPoint("TOPRIGHT", controls.context, "BOTTOMRIGHT", 0, -4)
    controls.prefill:SetJustifyH("LEFT")
    controls.prefill:SetJustifyV("TOP")
    controls.prefill:Hide()

    controls.validation = self:CreateLabel(content, "", NPRFontSmall, 1, 0.45, 0.45)
    controls.validation:SetPoint("TOPLEFT", controls.prefill, "BOTTOMLEFT", 0, -4)
    controls.validation:SetPoint("TOPRIGHT", controls.prefill, "BOTTOMRIGHT", 0, -4)
    controls.validation:SetJustifyH("LEFT")
    controls.validation:SetJustifyV("TOP")

    controls.enabled = self:CreateCheckButton(content, "Enabled", true, nil)
    controls.enabled:SetPoint("TOPLEFT", controls.validation, "BOTTOMLEFT", 0, -12)

    controls.textLabel = self:CreateLabel(content, "Text", NPRFontNormal, unpack(self.theme.textAccent))
    controls.textLabel:SetPoint("TOPLEFT", controls.enabled, "BOTTOMLEFT", 0, -18)

    controls.textRow = CreateFrame("Frame", nil, content)
    controls.textRow:SetPoint("TOPLEFT", controls.textLabel, "BOTTOMLEFT", 0, -6)
    controls.textRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -6)
    controls.textRow:SetHeight(26)

    controls.text = self:CreateEditBox(content, 200, 26)
    controls.text:SetAllPoints(controls.textRow)
    controls.text:SetMaxLetters(120)

    controls.iconLabel = self:CreateLabel(content, "Icon spellID", NPRFontNormal, unpack(self.theme.textAccent))
    controls.iconLabel:SetPoint("TOPLEFT", controls.text, "BOTTOMLEFT", 0, -16)

    controls.iconSpellID = self:CreateEditBox(content, 158, 26)
    controls.iconSpellID:SetNumeric(false)
    controls.iconSpellID:SetMaxLetters(10)
    controls.iconSpellID:SetPoint("TOPLEFT", controls.iconLabel, "BOTTOMLEFT", 0, -6)

    controls.iconPreview = CreateFrame("Frame", nil, content)
    controls.iconPreview:SetSize(26, 26)
    controls.iconPreview:SetPoint("LEFT", controls.iconSpellID, "RIGHT", 8, 0)
    controls.iconPreview.tex = controls.iconPreview:CreateTexture(nil, "BACKGROUND")
    controls.iconPreview.tex:SetAllPoints()
    self:AddBorder(controls.iconPreview)

    controls.soundLabel = self:CreateLabel(content, "Sound", NPRFontNormal, unpack(self.theme.textAccent))
    controls.soundLabel:SetPoint("TOPLEFT", controls.iconSpellID, "BOTTOMLEFT", 0, -16)

    controls.sound = self:CreateSimpleDropdown(content, dropdownWidth, {
        { text = "None", value = "NONE" },
    }, nil)
    controls.sound:SetPoint("TOPLEFT", controls.soundLabel, "BOTTOMLEFT", 0, -6)

    controls.offsetLabel = self:CreateLabel(content, "Lead / delay (s)", NPRFontNormal, unpack(self.theme.textAccent))
    controls.offsetLabel:SetPoint("TOPLEFT", controls.sound, "BOTTOMLEFT", 0, -16)

    controls.offset = self:CreateEditBox(content, 158, 26)
    controls.offset:SetMaxLetters(8)
    controls.offset:SetPoint("TOPLEFT", controls.offsetLabel, "BOTTOMLEFT", 0, -6)

    controls.importanceLabel = self:CreateLabel(content, "Importance", NPRFontNormal, unpack(self.theme.textAccent))
    controls.importanceLabel:SetPoint("TOPLEFT", controls.iconLabel, "TOPLEFT", rightColumnX, 0)

    controls.importance = self:CreateSimpleDropdown(content, dropdownWidth, {
        { text = "Low", value = "LOW" },
        { text = "Medium", value = "MEDIUM" },
        { text = "High", value = "HIGH" },
    }, nil)
    controls.importance:SetPoint("TOPLEFT", controls.importanceLabel, "BOTTOMLEFT", 0, -6)

    controls.roleLabel = self:CreateLabel(content, "Role scope", NPRFontNormal, unpack(self.theme.textAccent))
    controls.roleLabel:SetPoint("TOPLEFT", controls.soundLabel, "TOPLEFT", rightColumnX, 0)

    controls.role = self:CreateSimpleDropdown(content, dropdownWidth, {
        { text = "All", value = "ALL" },
        { text = "Healer", value = "HEALER" },
        { text = "Tank", value = "TANK" },
        { text = "DPS", value = "DAMAGER" },
    }, nil)
    controls.role:SetPoint("TOPLEFT", controls.roleLabel, "BOTTOMLEFT", 0, -6)

    controls.durationLabel = self:CreateLabel(content, "Display duration (s)", NPRFontNormal, unpack(self.theme.textAccent))
    controls.durationLabel:SetPoint("TOPLEFT", controls.role, "BOTTOMLEFT", 0, -16)

    controls.durationSeconds = self:CreateEditBox(content, 158, 26)
    controls.durationSeconds:SetMaxLetters(8)
    controls.durationSeconds:SetPoint("TOPLEFT", controls.durationLabel, "BOTTOMLEFT", 0, -6)

    controls.preview = self:CreateButton(content, "Preview", buttonWidth, 30, function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder preview")
            return
        end
        local reminder = self:CollectEditorReminder()
        if reminder and self.runtime then
            self.runtime:PreviewReminder(reminder)
        elseif reminder then
            self:Print("Runtime preview is unavailable because the runtime module did not initialize.")
        end
    end)
    controls.preview:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)

    controls.delete = self:CreateButton(content, "Delete", buttonWidth, 30, function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder deletion")
            return
        end
        local reminderID = self.editorState.reminderID
        if reminderID then
            self:DeleteReminder(reminderID)
            self:LogWork("Deleted reminder " .. reminderID)
            self:RefreshAll()
            editor:Hide()
        end
    end)
    controls.delete:SetPoint("LEFT", controls.preview, "RIGHT", 8, 0)

    controls.copy = self:CreateButton(content, "Copy", copyButtonWidth, 30, function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder copy")
            return
        end
        local reminderID = self.editorState.reminderID
        if not reminderID then
            return
        end

        local copy = self:DuplicateReminder(reminderID)
        if copy then
            self:LogWork("Copied reminder " .. reminderID .. " to " .. copy.id)
            self:RefreshAll()
            self:OpenEditor(copy, {
                prefillNote = "Copied reminder. Adjust the fields, then save or delete it.",
            })
        end
    end)
    controls.copy:SetPoint("LEFT", controls.delete, "RIGHT", 8, 0)

    controls.save = self:CreateButton(content, "Save", buttonWidth, 30, function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder save")
            return
        end
        local reminder = self:CollectEditorReminder()
        if reminder then
            self:UpsertReminder(reminder)
            self:LogWork("Saved reminder " .. reminder.id .. " for " .. reminder.encounterKey .. "." .. reminder.eventKey)
            self:RefreshAll()
            editor:Hide()
        end
    end)
    controls.save:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    controls.cancel = self:CreateButton(content, "Cancel", buttonWidth, 30, function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder editing")
            return
        end
        editor:Hide()
    end)
    controls.cancel:SetPoint("RIGHT", controls.save, "LEFT", -8, 0)

    local soundItems = {}
    for _, option in ipairs(self.soundOptions) do
        table.insert(soundItems, {
            text = option.label,
            value = option.key,
        })
    end
    controls.sound:SetItems(soundItems)
    controls.sound:SetSelected("NONE", true)

    local function UpdateIconPreview()
        local reminder = self.editorState.reminder
        local fallbackIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
        if reminder then
            local event = self:GetEvent(reminder.encounterKey, reminder.eventKey)
            fallbackIcon = event and self:GetIconPath(event) or fallbackIcon
        end

        local spellID = ParseNumber(controls.iconSpellID:GetText(), nil)
        local icon = fallbackIcon
        if spellID and spellID > 0 then
            local info = self:SafeSpellInfo(spellID)
            if info and info.icon then
                icon = info.icon
            end
        end

        controls.iconPreview.tex:SetTexture(icon)
    end

    local function ApplyNumericFieldCorrections(showMessage)
        local correctionParts = {}
        local iconText = TrimText(controls.iconSpellID:GetText())
        local iconSpellID = ParseNumber(iconText, nil)
        if iconText ~= controls.iconSpellID:GetText() then
            controls.iconSpellID:SetText(iconText)
        end
        if iconText ~= "" and (iconSpellID == nil or iconSpellID <= 0) then
            controls.iconSpellID:SetText("")
            correctionParts[#correctionParts + 1] = "Icon spell ID must be numeric or empty. Invalid value cleared."
        elseif iconSpellID and iconSpellID > 0 then
            local normalizedIcon = tostring(floor(iconSpellID))
            if normalizedIcon ~= iconText then
                controls.iconSpellID:SetText(normalizedIcon)
            end
        end

        local offsetText = TrimText(controls.offset:GetText())
        local parsedOffset = ParseNumber(offsetText, nil)
        if offsetText ~= controls.offset:GetText() then
            controls.offset:SetText(offsetText)
        end
        if offsetText == "" then
            controls.offset:SetText("0.0")
        elseif parsedOffset == nil then
            controls.offset:SetText("0.0")
            correctionParts[#correctionParts + 1] = "Offset must be a valid number. Reset to 0.0s."
        else
            local normalizedOffset = format("%.1f", self:Round(parsedOffset, 1))
            if normalizedOffset ~= offsetText then
                controls.offset:SetText(normalizedOffset)
            end
        end

        local durationText = TrimText(controls.durationSeconds:GetText())
        local parsedDuration = ParseNumber(durationText, nil)
        if durationText ~= controls.durationSeconds:GetText() then
            controls.durationSeconds:SetText(durationText)
        end
        if durationText == "" then
            controls.durationSeconds:SetText("6.0")
        elseif parsedDuration == nil or parsedDuration <= 0 then
            controls.durationSeconds:SetText("6.0")
            correctionParts[#correctionParts + 1] = "Display duration must be a positive number. Reset to 6.0s."
        else
            local normalizedDuration = format("%.1f", self:Clamp(self:Round(parsedDuration, 1), 2, 20))
            if normalizedDuration ~= durationText then
                controls.durationSeconds:SetText(normalizedDuration)
            end
        end

        if showMessage then
            controls.validation:SetText(table.concat(correctionParts, " "))
        end
    end

    controls.iconSpellID:SetScript("OnTextChanged", UpdateIconPreview)
    controls.offset:SetScript("OnTextChanged", function()
        controls.validation:SetText("")
    end)
    controls.durationSeconds:SetScript("OnTextChanged", function()
        controls.validation:SetText("")
    end)
    controls.text:SetScript("OnTextChanged", function()
        controls.validation:SetText("")
    end)
    controls.iconSpellID:SetScript("OnTextChanged", function()
        controls.validation:SetText("")
        UpdateIconPreview()
    end)
    controls.offset:SetScript("OnEditFocusLost", function()
        ApplyNumericFieldCorrections(true)
    end)
    controls.iconSpellID:SetScript("OnEditFocusLost", function()
        ApplyNumericFieldCorrections(true)
    end)
    controls.durationSeconds:SetScript("OnEditFocusLost", function()
        ApplyNumericFieldCorrections(true)
    end)
    controls.offset:SetScript("OnEscapePressed", function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder editing")
            return
        end
        editor:Hide()
    end)
    controls.durationSeconds:SetScript("OnEscapePressed", function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder editing")
            return
        end
        editor:Hide()
    end)
    controls.text:SetScript("OnEscapePressed", function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder editing")
            return
        end
        editor:Hide()
    end)
    controls.iconSpellID:SetScript("OnEscapePressed", function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Reminder editing")
            return
        end
        editor:Hide()
    end)
    controls.text:SetScript("OnEnterPressed", function()
        controls.save:Click()
    end)
    controls.offset:SetScript("OnEnterPressed", function()
        controls.save:Click()
    end)
    controls.durationSeconds:SetScript("OnEnterPressed", function()
        controls.save:Click()
    end)
    controls.iconSpellID:SetScript("OnEnterPressed", function()
        controls.save:Click()
    end)

    editor:SetScript("OnHide", function()
        controls.validation:SetText("")
        controls.text:ClearFocus()
        controls.offset:ClearFocus()
        controls.durationSeconds:ClearFocus()
        controls.iconSpellID:ClearFocus()
        self.editorState.reminder = nil
        self.editorState.reminderID = nil
    end)
end

function NPR:CollectEditorReminder()
    local draft = self.editorState.reminder
    if not draft then
        return nil
    end

    self.editorControls.validation:SetText("")
    self.editorControls.offset:GetScript("OnEditFocusLost")()
    self.editorControls.iconSpellID:GetScript("OnEditFocusLost")()
    self.editorControls.durationSeconds:GetScript("OnEditFocusLost")()

    local reminder = self:DeepCopy(draft)
    reminder.enabled = self.editorControls.enabled:GetChecked()
    reminder.text = TrimText(self.editorControls.text:GetText())

    local iconText = self.editorControls.iconSpellID:GetText()
    local iconSpellID = ParseNumber(iconText, nil)
    reminder.iconSpellID = iconSpellID and iconSpellID > 0 and floor(iconSpellID) or nil
    reminder.soundKey = self.editorControls.sound:GetSelected() or "NONE"

    local offsetText = self.editorControls.offset:GetText()
    local parsedOffset = ParseNumber(offsetText, nil)
    reminder.offsetSeconds = self:Round(parsedOffset or 0, 1)
    reminder.importance = self.editorControls.importance:GetSelected() or "MEDIUM"
    local durationText = self.editorControls.durationSeconds:GetText()
    local parsedDuration = ParseNumber(durationText, nil)
    reminder.durationSeconds = self:Clamp(self:Round(parsedDuration or 6, 1), 2, 20)
    reminder.roleScope = self.editorControls.role:GetSelected() or "ALL"

    return reminder
end

function NPR:OpenEditor(reminder, options)
    if not reminder then
        return
    end

    if self:IsConfigLockedDown() then
        self:PrintCombatLockdownMessage("Reminder editing")
        return
    end

    local editor = self.editorWindow
    local controls = self.editorControls
    local workingReminder = self:DeepCopy(reminder)
    options = options or {}

    self.editorState.reminder = workingReminder
    self.editorState.reminderID = workingReminder.id

    controls.contextMode:SetText(GetReminderModeText(workingReminder))
    controls.context:SetText(GetReminderContextText(workingReminder))
    controls.prefill:SetText(options.prefillNote or "")
    controls.prefill:SetShown((options.prefillNote or "") ~= "")
    controls.enabled:SetChecked(workingReminder.enabled, true)
    controls.text:SetText(workingReminder.text or "")
    controls.iconSpellID:SetText(workingReminder.iconSpellID or "")
    controls.sound:SetSelected(workingReminder.soundKey or "NONE", true)
    controls.offset:SetText(format("%.1f", workingReminder.offsetSeconds or 0))
    controls.importance:SetSelected(workingReminder.importance or "MEDIUM", true)
    controls.role:SetSelected(workingReminder.roleScope or "ALL", true)
    controls.durationSeconds:SetText(format("%.1f", self:GetReminderDisplaySeconds(workingReminder)))
    controls.delete:SetShown(self.db.reminders[workingReminder.id] ~= nil)
    controls.copy:SetShown(self.db.reminders[workingReminder.id] ~= nil)
    controls.validation:SetText("")
    controls.iconSpellID:GetScript("OnTextChanged")()

    editor:Show()
    editor:Raise()
    controls.text:SetFocus()
    controls.text:HighlightText()
end

function NPR:OpenExistingReminder(reminderID)
    local reminder = self.db.reminders[reminderID]
    if reminder then
        self:OpenEditor(reminder)
    end
end

function NPR:CreateReminderDraft(encounterKey, eventKey, occurrence, offsetSeconds)
    local reminder = self:CreateDefaultReminder(encounterKey, eventKey, occurrence, offsetSeconds)
    local event = self:GetEvent(encounterKey, eventKey)
    if event and event.spellID then
        reminder.iconSpellID = event.spellID
    end
    local soundKey, importance, prefillNote = GetSuggestedReminderDefaults(eventKey, event)
    reminder.soundKey = soundKey
    reminder.importance = importance
    return reminder, prefillNote
end

function NPR:OpenNewReminder(encounterKey, eventKey, occurrence, offsetSeconds)
    local reminder, prefillNote = self:CreateReminderDraft(encounterKey, eventKey, occurrence, offsetSeconds)
    self:OpenEditor(reminder, {
        prefillNote = prefillNote,
    })
end
