local _, NPR = ...

local combatEventMap = {
    SPELL_CAST_START = true,
    SPELL_CAST_SUCCESS = true,
    SPELL_AURA_APPLIED = true,
}

local function GetEncounterKeyByEncounterID(encounterID)
    for encounterKey, encounter in pairs(NPR.Data.encounters) do
        if encounter.encounterID == encounterID then
            return encounterKey
        end
    end
end

function NPR:InitializeRuntime()
    local runtime = {
        queued = {},
        cards = {},
        observations = {},
    }
    setmetatable(runtime, { __index = self })
    self.runtime = runtime

    runtime.frame = CreateFrame("Frame")
    runtime.frame:RegisterEvent("ENCOUNTER_START")
    runtime.frame:RegisterEvent("ENCOUNTER_END")
    runtime.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    runtime.anchor = CreateFrame("Frame", nil, UIParent)
    runtime.anchor:SetSize(360, 26)
    runtime.anchor:SetMovable(true)
    runtime.anchor:EnableMouse(true)
    runtime.anchor:SetFrameStrata("DIALOG")
    runtime.anchor:SetClampedToScreen(true)
    runtime.anchor.bg = runtime.anchor:CreateTexture(nil, "BACKGROUND")
    runtime.anchor.bg:SetAllPoints()
    runtime.anchor.bg:SetColorTexture(0, 0, 0, 0.3)
    self:AddBorder(runtime.anchor)
    runtime.anchor.label = self:CreateLabel(runtime.anchor, "CooldownReminder runtime anchor", NPRFontSmall, unpack(self.theme.textMuted))
    runtime.anchor.label:SetPoint("CENTER")
    runtime.anchor:Hide()
    self:RestoreFramePosition(runtime.anchor, "runtimeAnchor")

    runtime.anchor:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and self.db.debug.enabled then
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Runtime anchor movement")
                return
            end
            runtime.anchor.NPRMoving = true
            runtime.anchor:StartMoving()
        end
    end)
    runtime.anchor:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and runtime.anchor.NPRMoving then
            runtime.anchor.NPRMoving = nil
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Runtime anchor movement")
                return
            end
            runtime.anchor:StopMovingOrSizing()
            self:SaveFramePosition(runtime.anchor, "runtimeAnchor")
        end
    end)

    runtime.frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ENCOUNTER_START" then
            local encounterID = ...
            local encounterKey = GetEncounterKeyByEncounterID(encounterID)
            if encounterKey then
                runtime:StartEncounter(encounterKey, "blizzard")
            elseif self.db.debug.enabled and self.db.debug.armedBossKey then
                runtime:StartEncounter(self.db.debug.armedBossKey, "debug-fallback")
            end
        elseif event == "ENCOUNTER_END" then
            runtime:StopEncounter("encounter_end")
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            runtime:ObserveCombatLog(CombatLogGetCurrentEventInfo())
        end
    end)

    function runtime:ClearQueued()
        for reminderID, timer in pairs(self.queued) do
            timer:Cancel()
            self.queued[reminderID] = nil
        end
    end

    function runtime:AcquireCard()
        for _, card in ipairs(self.cards) do
            if not card.active then
                return card
            end
        end

        local card = CreateFrame("Frame", nil, self.anchor)
        card:SetSize(360, 42)
        card.bg = card:CreateTexture(nil, "BACKGROUND")
        card.bg:SetAllPoints()
        card.bg:SetColorTexture(0.02, 0.06, 0.15, 0.93)
        NPR:AddBorder(card)

        card.accent = card:CreateTexture(nil, "ARTWORK")
        card.accent:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
        card.accent:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
        card.accent:SetWidth(4)

        card.icon = CreateFrame("Frame", nil, card)
        card.icon:SetSize(28, 28)
        card.icon:SetPoint("LEFT", card, "LEFT", 10, 0)
        card.icon.tex = card.icon:CreateTexture(nil, "BACKGROUND")
        card.icon.tex:SetAllPoints()
        NPR:AddBorder(card.icon)

        card.text = NPR:CreateLabel(card, "", NPRFontNormal)
        card.text:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -2)
        card.text:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -2)
        card.text:SetJustifyH("LEFT")

        card.timer = NPR:CreateLabel(card, "", NPRFontSmall, unpack(NPR.theme.textMuted))
        card.timer:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 10, 4)
        card.timer:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 4)
        card.timer:SetJustifyH("LEFT")

        table.insert(self.cards, card)
        return card
    end

    function runtime:LayoutCards()
        local index = 0
        for _, card in ipairs(self.cards) do
            if card.active then
                index = index + 1
                card:ClearAllPoints()
                card:SetPoint("TOP", self.anchor, "TOP", 0, -(index - 1) * 46)
            end
        end

        local shouldShowAnchor = self.db.debug.enabled or index > 0
        self.anchor:SetShown(shouldShowAnchor)
        self.anchor.label:SetShown(self.db.debug.enabled and index == 0)
        self.anchor:SetHeight(max(26, index * 46))
    end

    function runtime:HideCard(card)
        card.active = nil
        card:Hide()
        self:LayoutCards()
    end

    function runtime:GetReminderDisplay(reminder)
        local event = self:GetEvent(reminder.encounterKey, reminder.eventKey)
        local text = reminder.text ~= "" and reminder.text or (event and event.label or "Reminder")
        if reminder.eventKey == "pull_anchor" and reminder.text == "" then
            text = "Pull reminder"
        end
        local icon = self:GetIconPath({
            spellID = reminder.iconSpellID,
            icon = event and self:GetIconPath(event) or "Interface\\Icons\\INV_Misc_QuestionMark",
        })
        return text, icon
    end

    function runtime:ShowReminder(reminder, preview)
        if not reminder.enabled and not preview then
            return
        end

        local card = self:AcquireCard()
        local text, icon = self:GetReminderDisplay(reminder)
        local color = self:GetImportanceColor(reminder.importance)
        local duration = self:GetReminderDisplaySeconds(reminder)
        local leadText = self:DescribeOffsetSeconds(reminder.offsetSeconds)
        local soundLabel = self:GetSoundOption(reminder.soundKey or "NONE").label

        card.active = true
        card.reminderID = reminder.id
        card.expiresAt = GetTime() + duration
        card.text:SetText(text)
        card.icon.tex:SetTexture(icon)
        card.accent:SetColorTexture(color.r, color.g, color.b, 1)
        card:Show()
        self:LayoutCards()

        if reminder.soundKey and reminder.soundKey ~= "NONE" then
            self:PlaySoundKey(reminder.soundKey)
        end

        card:SetScript("OnUpdate", function(selfCard)
            local remaining = selfCard.expiresAt - GetTime()
            if remaining <= 0 then
                selfCard:SetScript("OnUpdate", nil)
                runtime:HideCard(selfCard)
            else
                selfCard.timer:SetText(format("%s remaining | %s | %s", runtime:SecondsToClock(remaining), leadText, soundLabel))
            end
        end)
    end

    function runtime:PreviewReminder(reminder)
        self:ShowReminder(reminder, true)
    end

    function runtime:BuildObservationBucket(encounterKey)
        if not self.db.debug.observations[encounterKey] then
            self.db.debug.observations[encounterKey] = {
                eventCounts = {},
                driftByEvent = {},
            }
        end
        return self.db.debug.observations[encounterKey]
    end

    function runtime:ResetObservationBucket(encounterKey)
        self.db.debug.observations[encounterKey] = {
            eventCounts = {},
            driftByEvent = {},
        }
        return self.db.debug.observations[encounterKey]
    end

    function runtime:ObserveCombatLog(...)
        if not self.activeEncounterKey then
            return
        end

        local _, subEvent, _, _, _, _, _, _, _, _, _, spellID = ...
        if not combatEventMap[subEvent] or not spellID then
            return
        end

        local encounter = self:GetEncounter(self.activeEncounterKey)
        if not encounter then
            return
        end

        local bucket = self:BuildObservationBucket(self.activeEncounterKey)
        local elapsed = GetTime() - (self.encounterStartTime or GetTime())

        for _, event in ipairs(encounter.events) do
            if self:MatchesCombatLogEvent(event, subEvent, spellID) then
                local nextCount = (bucket.eventCounts[event.key] or 0) + 1
                bucket.eventCounts[event.key] = nextCount
                local expected = self:GetEventOccurrence(event, nextCount)
                if expected then
                    bucket.driftByEvent[event.key] = self:Round(elapsed - expected.time, 2)
                end
                if self.mainWindow and self.db.timeline.showDiagnostics then
                    if self:IsConfigLockedDown() then
                        self.pendingTimelineRefresh = true
                    else
                        self:RefreshTimeline()
                    end
                end
                break
            end
        end
    end

    function runtime:StartEncounter(encounterKey, source)
        self:StopEncounter("restart")

        local encounter = self:GetEncounter(encounterKey)
        if not encounter then
            return
        end

        self.activeEncounterKey = encounterKey
        self.encounterStartTime = GetTime()
        self.activeSource = source
        self.db.runtime.activeEncounterKey = encounterKey
        self:ResetObservationBucket(encounterKey)
        self:LogDebug("Armed encounter " .. encounter.name .. " (" .. tostring(source) .. ")")

        for _, reminder in ipairs(self:GetEncounterReminders(encounterKey)) do
            if reminder.enabled and self:IsReminderRelevant(reminder) then
                local triggerTime = self:ResolveReminderTime(reminder)
                if triggerTime then
                    self.queued[reminder.id] = C_Timer.NewTimer(max(0, triggerTime), function()
                        self.queued[reminder.id] = nil
                        runtime:ShowReminder(reminder, false)
                    end)
                end
            end
        end

        self:RefreshDebugText()
    end

    function runtime:StopEncounter(reason)
        self:ClearQueued()
        for _, card in ipairs(self.cards) do
            card:SetScript("OnUpdate", nil)
            if card.active then
                self:HideCard(card)
            end
        end

        if self.activeEncounterKey then
            self:LogDebug("Stopped encounter " .. self.activeEncounterKey .. " (" .. tostring(reason) .. ")")
        end

        self.activeEncounterKey = nil
        self.activeSource = nil
        self.encounterStartTime = nil
        self.db.runtime.activeEncounterKey = nil
        self:RefreshDebugText()
    end

    function runtime:GetDiagnosticsSummary()
        local focusEncounterKey = self.activeEncounterKey or self:GetSelectedEncounterKey()
        local active = self.activeEncounterKey and (self:GetEncounter(self.activeEncounterKey) or {}).name or "idle"
        local source = self.activeSource or "idle"
        local count = 0
        local observedCount = 0
        local observationText = "Obs 0"
        local unknownCount = focusEncounterKey and self:GetUnknownReminderCount(focusEncounterKey) or 0
        for _, timer in pairs(self.queued) do
            if timer then
                count = count + 1
            end
        end

        local bucket = self.activeEncounterKey and self.db.debug.observations[self.activeEncounterKey]
        if bucket and bucket.eventCounts then
            local driftParts = {}
            for eventKey, eventCount in pairs(bucket.eventCounts) do
                observedCount = observedCount + eventCount
                local drift = bucket.driftByEvent and bucket.driftByEvent[eventKey]
                if drift then
                    local event = self:GetEvent(self.activeEncounterKey, eventKey)
                    driftParts[#driftParts + 1] = format("%s %+.1fs", event and event.label or eventKey, drift)
                end
            end
            if observedCount > 0 then
                observationText = "Obs " .. observedCount
                table.sort(driftParts)
                if driftParts[1] then
                    local visibleParts = {}
                    local limit = min(3, #driftParts)
                    for index = 1, limit do
                        visibleParts[#visibleParts + 1] = driftParts[index]
                    end
                    observationText = observationText .. "  Drift: " .. table.concat(visibleParts, ", ")
                    if #driftParts > limit then
                        observationText = observationText .. format(" (+%d more)", #driftParts - limit)
                    end
                end
            end
        end

        local targetText = self:GetNextValidationTarget(focusEncounterKey)
        return table.concat({
            format("Active: %s", tostring(active)),
            format("Src %s | Q%d | U%d | %s", tostring(source), count, unknownCount, observationText),
            "Next: " .. (targetText or "none"),
        }, "\n")
    end

    function runtime:RefreshDebugText()
        if self.mainWindow and self.db.timeline.showDiagnostics then
            self.debugText:SetText(self:GetDiagnosticsSummary())
        elseif self.mainWindow and self.debugText then
            self.debugText:SetText("")
        end
        self.anchor.label:SetShown(self.db.debug.enabled)
        self:LayoutCards()
    end
end
