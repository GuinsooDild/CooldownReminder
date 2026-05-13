local _, NPR = ...

local rowHeight = 38
local rowSpacing = 6
local markerIconSize = 22
local markerLaneSpacing = 4
local leftPanelWidth = 296
local controlPanelWidth = 218
local dungeonDropdownWidth = 268
local bossDropdownWidth = 268
local baseViewTopOffset = 126
local coverageViewTopOffset = 168
local emptyTimelineHeight = 128
local diagnosticsTextHeight = 54

local function GetScaledCursorPosition()
    local scale = (UIParent and UIParent:GetEffectiveScale()) or 1
    if scale == 0 then
        scale = 1
    end
    local cursorX, cursorY = GetCursorPosition()
    return (cursorX or 0) / scale, (cursorY or 0) / scale
end

local function CreatePool()
    return {
        used = 0,
        items = {},
    }
end

local function Acquire(pool, creator)
    pool.used = pool.used + 1
    if not pool.items[pool.used] then
        pool.items[pool.used] = creator()
    end
    pool.items[pool.used]:Show()
    return pool.items[pool.used]
end

local function ResetPool(pool)
    pool.used = 0
    for _, item in ipairs(pool.items) do
        item:Hide()
    end
end

local function BuildEventMeta(self, event)
    return format(
        "Dur %.1fs   Danger %d%%",
        self:GetEventDuration(event, 1),
        self:GetEventDangerPercent(event)
    )
end

local function BuildEventTooltip(self, event, occurrenceIndex, entry)
    local tooltipParts = {
        format("At %s", self:SecondsToClock(entry.time)),
        format("Estimated duration %.1fs", entry.duration or event.defaultDuration or 0),
        format("Relative danger %d%%", self:GetEventDangerPercent(event)),
        format("Spell IDs: %s", self:FormatSpellIDList(event)),
    }

    if event.summary and event.summary ~= "" then
        tooltipParts[#tooltipParts + 1] = event.summary
    end
    if event.source and event.source ~= "" then
        tooltipParts[#tooltipParts + 1] = "Source: " .. event.source
    end
    if event.confidence and event.confidence ~= "" then
        tooltipParts[#tooltipParts + 1] = "Confidence: " .. event.confidence
    end

    return format("%s #%d", event.label, occurrenceIndex), table.concat(tooltipParts, "\n")
end

local function BuildBossItems(self)
    local bossItems = {}
    for _, encounterKey in ipairs(self:GetDungeonEncounterKeys(self:GetSelectedDungeonKey())) do
        local encounter = self:GetEncounter(encounterKey)
        if encounter then
            local label = encounter.name
            if encounter.coverageState == "partial" then
                label = format("%s (partial)", label)
            end
            bossItems[#bossItems + 1] = {
                text = label,
                value = encounterKey,
            }
        end
    end
    return bossItems
end

local function BuildDungeonItems(self)
    local dungeonItems = {}
    for _, dungeon in ipairs(self:GetDungeons()) do
        local label = dungeon.name
        local coverageLabel = self:GetDungeonCoverageMenuLabel(dungeon)
        if coverageLabel then
            label = format("%s (%s)", label, coverageLabel)
        end
        dungeonItems[#dungeonItems + 1] = {
            text = label,
            value = dungeon.key,
        }
    end
    return dungeonItems
end

function NPR:ToggleMainWindow(action)
    if not self:CanUseConfigUI(action or "The configuration window") then
        return
    end

    self.mainWindow:SetShown(not self.mainWindow:IsShown())
    if self.mainWindow:IsShown() then
        self.mainWindow:Raise()
        self:RefreshTimeline()
    end
end

function NPR:InitializeMainWindow()
    local window = self:CreateWindow("window", self.db.ui.window.width, self.db.ui.window.height, "CooldownReminder")
    window:Hide()

    self.mainWindow = window
    local content = window.content or window

    local dungeonDropdown = self:CreateSimpleDropdown(content, dungeonDropdownWidth, BuildDungeonItems(self), function(value)
        self:SetSelectedDungeonKey(value)
        self.db.timeline.scroll = 0
        self:RefreshTimeline()
    end)
    dungeonDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    dungeonDropdown:SetSelected(self:GetSelectedDungeonKey(), true)
    self:SetTooltip(dungeonDropdown, "Dungeon", "Select which Season 1 dungeon to inspect.")
    self.dungeonDropdown = dungeonDropdown

    local bossDropdown = self:CreateSimpleDropdown(content, bossDropdownWidth, BuildBossItems(self), function(value)
        self:SetSelectedEncounterKey(value)
        self.db.timeline.scroll = 0
        self:RefreshTimeline()
    end)
    bossDropdown:SetPoint("TOPLEFT", dungeonDropdown, "TOPRIGHT", 12, 0)
    bossDropdown:SetSelected(self:GetSelectedEncounterKey(), true)
    self:SetTooltip(bossDropdown, "Boss", "Select which boss timeline to inspect for the current dungeon.")
    self.bossDropdown = bossDropdown

    local controlPanel = CreateFrame("Frame", nil, content)
    controlPanel:SetSize(controlPanelWidth, 108)
    controlPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    controlPanel.bg = controlPanel:CreateTexture(nil, "BACKGROUND")
    controlPanel.bg:SetAllPoints()
    controlPanel.bg:SetColorTexture(unpack(self.theme.sectionBackground))
    self:AddBorder(controlPanel)
    self.controlPanel = controlPanel

    controlPanel.label = self:CreateLabel(controlPanel, "View Options", NPRFontSmall, unpack(self.theme.textAccent))
    controlPanel.label:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 10, -8)

    local relevantCheck = self:CreateCheckButton(controlPanel, "Relevant only", self.db.timeline.showRelevantOnly, function(value)
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Timeline filters")
            self.relevantCheck:SetChecked(self.db.timeline.showRelevantOnly, true)
            return
        end
        self.db.timeline.showRelevantOnly = value
        self:RefreshTimeline()
    end)
    relevantCheck:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 10, -28)
    relevantCheck.label:SetFontObject(NPRFontSmall)
    self.relevantCheck = relevantCheck

    local disabledCheck = self:CreateCheckButton(controlPanel, "Show disabled", self.db.timeline.showDisabled, function(value)
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Timeline filters")
            self.disabledCheck:SetChecked(self.db.timeline.showDisabled, true)
            return
        end
        self.db.timeline.showDisabled = value
        self:RefreshTimeline()
    end)
    disabledCheck:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 10, -48)
    disabledCheck.label:SetFontObject(NPRFontSmall)
    self.disabledCheck = disabledCheck

    local diagnosticsCheck = self:CreateCheckButton(controlPanel, "Show diagnostics", self.db.timeline.showDiagnostics, function(value)
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Timeline filters")
            self.diagnosticsCheck:SetChecked(self.db.timeline.showDiagnostics, true)
            return
        end
        self.db.timeline.showDiagnostics = value
        self:RefreshTimeline()
        if self.runtime then
            self.runtime:RefreshDebugText()
        end
    end)
    diagnosticsCheck:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 10, -68)
    diagnosticsCheck.label:SetFontObject(NPRFontSmall)
    self.diagnosticsCheck = diagnosticsCheck

    local minimapToggle = self:CreateCheckButton(controlPanel, "Hide minimap", self:IsMinimapButtonHidden(), function(value)
        self:SetMinimapButtonHidden(value)
    end)
    minimapToggle:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 10, -88)
    minimapToggle.label:SetFontObject(NPRFontSmall)
    self.minimapToggle = minimapToggle

    local helpText = self:CreateLabel(content, "Left click an ability to add a reminder. Click a marker to edit it. Double click empty space to place a pull-relative reminder.", NPRFontSmall, unpack(self.theme.textMuted))
    helpText:SetPoint("TOPLEFT", dungeonDropdown, "BOTTOMLEFT", 0, -8)
    helpText:SetPoint("TOPRIGHT", controlPanel, "TOPLEFT", -12, 0)
    helpText:SetJustifyH("LEFT")
    helpText:SetJustifyV("TOP")
    self.helpText = helpText

    local coverageText = self:CreateLabel(content, "", NPRFontSmall, unpack(self.theme.textAccent))
    coverageText:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -4)
    coverageText:SetPoint("TOPRIGHT", controlPanel, "TOPLEFT", -12, -4)
    coverageText:SetJustifyH("LEFT")
    coverageText:SetJustifyV("TOP")
    coverageText:Hide()
    self.coverageText = coverageText

    local tracksPanel = CreateFrame("Frame", nil, content)
    tracksPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -baseViewTopOffset)
    tracksPanel:SetWidth(leftPanelWidth)
    tracksPanel.bg = tracksPanel:CreateTexture(nil, "BACKGROUND")
    tracksPanel.bg:SetAllPoints()
    tracksPanel.bg:SetColorTexture(unpack(self.theme.sectionBackground))
    self:AddBorder(tracksPanel)
    self.tracksPanel = tracksPanel

    local timelineView = CreateFrame("Frame", nil, content)
    timelineView:SetPoint("TOPLEFT", tracksPanel, "TOPRIGHT", 8, 0)
    timelineView:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -baseViewTopOffset)
    timelineView:EnableMouse(true)
    timelineView:EnableMouseWheel(true)
    timelineView:SetClipsChildren(true)
    timelineView.bg = timelineView:CreateTexture(nil, "BACKGROUND")
    timelineView.bg:SetAllPoints()
    timelineView.bg:SetColorTexture(unpack(self.theme.timelineBackground))
    self:AddBorder(timelineView)
    self.timelineView = timelineView

    local emptyStateText = self:CreateLabel(timelineView, "", NPRFontNormal, unpack(self.theme.textMuted))
    emptyStateText:SetPoint("CENTER", timelineView, "CENTER", 0, 0)
    emptyStateText:SetWidth(420)
    emptyStateText:SetJustifyH("CENTER")
    emptyStateText:SetJustifyV("MIDDLE")
    emptyStateText:Hide()
    self.emptyStateText = emptyStateText

    local timelineContent = CreateFrame("Frame", nil, timelineView)
    timelineContent:SetPoint("TOPLEFT", timelineView, "TOPLEFT")
    timelineContent:SetPoint("BOTTOMLEFT", timelineView, "BOTTOMLEFT")
    self.timelineContent = timelineContent

    local markerArea = CreateFrame("Frame", nil, content)
    markerArea:SetPoint("TOPLEFT", timelineView, "BOTTOMLEFT", 0, -6)
    markerArea:SetPoint("TOPRIGHT", timelineView, "BOTTOMRIGHT", 0, -6)
    markerArea:SetHeight(56)
    markerArea.bg = markerArea:CreateTexture(nil, "BACKGROUND")
    markerArea.bg:SetAllPoints()
    markerArea.bg:SetColorTexture(unpack(self.theme.panelBackground))
    self:AddBorder(markerArea)
    self.markerArea = markerArea

    local unknownArea = CreateFrame("Frame", nil, content)
    unknownArea:SetPoint("TOPLEFT", markerArea, "BOTTOMLEFT", 0, -8)
    unknownArea:SetPoint("TOPRIGHT", markerArea, "BOTTOMRIGHT", 0, -8)
    unknownArea:SetHeight(28)
    unknownArea.bg = unknownArea:CreateTexture(nil, "BACKGROUND")
    unknownArea.bg:SetAllPoints()
    unknownArea.bg:SetColorTexture(unpack(self.theme.panelBackground))
    self:AddBorder(unknownArea)
    self.unknownArea = unknownArea

    local debugText = self:CreateLabel(content, "", NPRFontSmall, unpack(self.theme.textMuted))
    debugText:SetPoint("TOPLEFT", controlPanel, "BOTTOMLEFT", 0, -8)
    debugText:SetPoint("TOPRIGHT", controlPanel, "BOTTOMRIGHT", 0, -8)
    debugText:SetJustifyH("LEFT")
    debugText:SetJustifyV("TOP")
    debugText:SetHeight(diagnosticsTextHeight)
    self.debugText = debugText

    local leftBadge = CreateFrame("Frame", nil, window)
    leftBadge:SetSize(52, 20)
    leftBadge:SetPoint("BOTTOMLEFT", timelineView, "TOPLEFT", 0, 4)
    leftBadge.bg = leftBadge:CreateTexture(nil, "BACKGROUND")
    leftBadge.bg:SetAllPoints()
    leftBadge.bg:SetColorTexture(unpack(self.theme.sectionBackground))
    self:AddBorder(leftBadge)
    leftBadge.text = self:CreateLabel(leftBadge, "00:00", NPRFontSmall)
    leftBadge.text:SetPoint("CENTER")
    self.leftBadge = leftBadge

    local rightBadge = CreateFrame("Frame", nil, window)
    rightBadge:SetSize(52, 20)
    rightBadge:SetPoint("BOTTOMRIGHT", timelineView, "TOPRIGHT", 0, 4)
    rightBadge.bg = rightBadge:CreateTexture(nil, "BACKGROUND")
    rightBadge.bg:SetAllPoints()
    rightBadge.bg:SetColorTexture(unpack(self.theme.sectionBackground))
    self:AddBorder(rightBadge)
    rightBadge.text = self:CreateLabel(rightBadge, "00:00", NPRFontSmall)
    rightBadge.text:SetPoint("CENTER")
    self.rightBadge = rightBadge

    local cursorLine = CreateFrame("Frame", nil, timelineView)
    cursorLine:SetWidth(1)
    cursorLine:SetFrameStrata("HIGH")
    cursorLine.tex = cursorLine:CreateTexture(nil, "OVERLAY")
    cursorLine.tex:SetAllPoints()
    cursorLine.tex:SetColorTexture(unpack(self.theme.cursor))
    cursorLine:Hide()
    self.cursorLine = cursorLine

    local cursorBadge = CreateFrame("Frame", nil, window)
    cursorBadge:SetSize(58, 20)
    cursorBadge.bg = cursorBadge:CreateTexture(nil, "BACKGROUND")
    cursorBadge.bg:SetAllPoints()
    cursorBadge.bg:SetColorTexture(unpack(self.theme.sectionBackground))
    self:AddBorder(cursorBadge)
    cursorBadge.text = self:CreateLabel(cursorBadge, "00:00", NPRFontSmall)
    cursorBadge.text:SetPoint("CENTER")
    cursorBadge:Hide()
    self.cursorBadge = cursorBadge

    self.uiPools = {
        trackRows = CreatePool(),
        trackBands = CreatePool(),
        eventBlocks = CreatePool(),
        intervalLines = CreatePool(),
        markerLines = CreatePool(),
        markerButtons = CreatePool(),
        unknownButtons = CreatePool(),
    }

    local dragging
    local dragButton
    local dragMoved
    local dragStartX
    local dragStartScroll
    local lastLeftClickTime = 0

    local function RefreshCursor(selfFrame)
        local encounter = self:GetSelectedEncounter()
        if not encounter then
            return
        end

        local left = selfFrame:GetLeft()
        local right = selfFrame:GetRight()
        local top = selfFrame:GetTop()
        local bottom = selfFrame:GetBottom()
        if not left or not right or not top or not bottom then
            return
        end

        local cursorX, cursorY = GetScaledCursorPosition()
        if cursorX < left or cursorX > right then
            self.cursorLine:Hide()
            self.cursorBadge:Hide()
            return
        end

        if cursorY < bottom or cursorY > top then
            self.cursorLine:Hide()
            self.cursorBadge:Hide()
            return
        end

        local relativeX = cursorX - left
        local hoverTime = self.db.timeline.scroll + relativeX * self.db.timeline.zoom
        self.hoverTime = self:Clamp(hoverTime, 0, encounter.maxTime)

        self.cursorLine:ClearAllPoints()
        self.cursorLine:SetPoint("TOPLEFT", selfFrame, "TOPLEFT", relativeX, 0)
        self.cursorLine:SetPoint("BOTTOMLEFT", selfFrame, "BOTTOMLEFT", relativeX, 0)
        self.cursorLine:Show()

        self.cursorBadge.text:SetText(self:SecondsToClock(self.hoverTime))
        self.cursorBadge:ClearAllPoints()
        self.cursorBadge:SetPoint("TOP", selfFrame, "BOTTOMLEFT", relativeX, -2)
        self.cursorBadge:Show()
    end

    timelineView:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" or button == "RightButton" then
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Timeline navigation")
                return
            end
            dragging = true
            dragButton = button
            dragMoved = false
            dragStartX = GetScaledCursorPosition()
            dragStartScroll = self.db.timeline.scroll
        end
    end)

    timelineView:SetScript("OnMouseUp", function(_, button)
        local usedForDrag = dragging and dragMoved and button == dragButton
        dragging = false
        dragButton = nil
        dragMoved = nil
        if usedForDrag then
            return
        end
        if button == "LeftButton" then
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Reminder editing")
                return
            end
            local now = GetTime()
            if now - lastLeftClickTime < 0.30 then
                local encounter = self:GetSelectedEncounter()
                local timeAtCursor = encounter and self.hoverTime or nil
                if encounter then
                    local left = timelineView:GetLeft()
                    local right = timelineView:GetRight()
                    local top = timelineView:GetTop()
                    local bottom = timelineView:GetBottom()
                    if left and right and top and bottom then
                        local cursorX, cursorY = GetScaledCursorPosition()
                        if cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top then
                            local relativeX = cursorX - left
                            timeAtCursor = self:Clamp(self.db.timeline.scroll + relativeX * self.db.timeline.zoom, 0, encounter.maxTime)
                        end
                    end
                    timeAtCursor = self:Round(timeAtCursor or 0, 1)
                    self:OpenNewReminder(self:GetSelectedEncounterKey(), "pull_anchor", 1, timeAtCursor)
                end
                lastLeftClickTime = 0
            else
                lastLeftClickTime = now
            end
        end
    end)

    timelineView:SetScript("OnUpdate", function(selfFrame)
        RefreshCursor(selfFrame)
        if dragging then
            local encounter = self:GetSelectedEncounter()
            if not encounter then
                return
            end
            local cursorX = GetScaledCursorPosition()
            local deltaPixels = dragStartX - cursorX
            dragMoved = dragMoved or math.abs(deltaPixels) >= 4
            local maxScroll = max(0, encounter.maxTime - (timelineView:GetWidth() * self.db.timeline.zoom))
            self.db.timeline.scroll = self:Clamp(dragStartScroll + deltaPixels * self.db.timeline.zoom, 0, maxScroll)
            self:RefreshTimeline()
        end
    end)

    timelineView:SetScript("OnMouseWheel", function(_, delta)
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Timeline navigation")
            return
        end
        local encounter = self:GetSelectedEncounter()
        if not encounter then
            return
        end

        local previousZoom = self.db.timeline.zoom
        self.db.timeline.zoom = self:Clamp(previousZoom - delta * 0.015, 0.05, 0.55)

        local relativePixel = 0
        local left = timelineView:GetLeft()
        if left then
            local cursorX = GetScaledCursorPosition()
            relativePixel = cursorX - left
        end
        local anchorTime = (self.hoverTime or self.db.timeline.scroll) - relativePixel * previousZoom
        local maxScroll = max(0, encounter.maxTime - timelineView:GetWidth() * self.db.timeline.zoom)
        self.db.timeline.scroll = self:Clamp(anchorTime, 0, maxScroll)
        self:RefreshTimeline()
    end)

    timelineView:SetScript("OnLeave", function()
        self.cursorLine:Hide()
        self.cursorBadge:Hide()
    end)

    self:RefreshTimeline()
end

function NPR:RefreshTimeline()
    if not self.mainWindow then
        return
    end

    if self:IsConfigLockedDown() then
        self.pendingTimelineRefresh = true
        return
    end

    local selectedDungeonKey = self:GetSelectedDungeonKey()
    local selectedDungeon = self:GetDungeon(selectedDungeonKey)
    local encounter = self:GetSelectedEncounter()

    self.dungeonDropdown:SetItems(BuildDungeonItems(self))
    self.dungeonDropdown:SetSelected(selectedDungeonKey, true)
    self.bossDropdown:SetItems(BuildBossItems(self))
    if #self.bossDropdown.items > 0 then
        self.bossDropdown:Enable()
        self.bossDropdown:SetAlpha(1)
        self.bossDropdown:SetSelected(self:GetSelectedEncounterKey(), true)
    else
        self.bossDropdown:CloseMenu(true)
        self.bossDropdown:Disable()
        self.bossDropdown:SetAlpha(0.65)
        self.bossDropdown:SetSelected(nil, true)
        self.bossDropdown.text:SetText("No boss data yet")
    end
    self.relevantCheck:SetChecked(self.db.timeline.showRelevantOnly, true)
    self.disabledCheck:SetChecked(self.db.timeline.showDisabled, true)
    self.diagnosticsCheck:SetChecked(self.db.timeline.showDiagnostics, true)
    if self.minimapToggle then
        self.minimapToggle:SetChecked(self:IsMinimapButtonHidden(), true)
    end

    local pools = self.uiPools
    ResetPool(pools.trackRows)
    ResetPool(pools.trackBands)
    ResetPool(pools.eventBlocks)
    ResetPool(pools.intervalLines)
    ResetPool(pools.markerLines)
    ResetPool(pools.markerButtons)
    ResetPool(pools.unknownButtons)
    self.cursorLine:Hide()
    self.cursorBadge:Hide()

    local tracksPanel = self.tracksPanel
    local timelineView = self.timelineView
    local timelineContent = self.timelineContent
    local markerArea = self.markerArea
    local unknownArea = self.unknownArea
    local content = self.mainWindow.content or self.mainWindow
    local coverageParts = {}
    local dungeonCoverageSummary = selectedDungeon and self:GetDungeonCoverageSummary(selectedDungeon) or nil
    local encounterCoverageSummary = encounter and self:GetEncounterReferenceOnlySummary(encounter) or nil
    if dungeonCoverageSummary then
        coverageParts[#coverageParts + 1] = dungeonCoverageSummary
    end
    if encounterCoverageSummary then
        coverageParts[#coverageParts + 1] = encounterCoverageSummary
    end
    local coverageSummary = #coverageParts > 0 and table.concat(coverageParts, "\n") or nil
    local activeViewTopOffset = coverageSummary and coverageViewTopOffset or baseViewTopOffset
    if self.db.timeline.showDiagnostics then
        activeViewTopOffset = activeViewTopOffset + diagnosticsTextHeight + 4
    end
    if coverageSummary then
        self.coverageText:SetText(coverageSummary)
        self.coverageText:Show()
    else
        self.coverageText:SetText("")
        self.coverageText:Hide()
    end

    tracksPanel:ClearAllPoints()
    tracksPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -activeViewTopOffset)

    timelineView:ClearAllPoints()
    timelineView:SetPoint("TOPLEFT", tracksPanel, "TOPRIGHT", 8, 0)
    timelineView:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -activeViewTopOffset)

    self.debugText:ClearAllPoints()
    self.debugText:SetPoint("TOPLEFT", self.controlPanel, "BOTTOMLEFT", 0, -8)
    self.debugText:SetPoint("TOPRIGHT", self.controlPanel, "BOTTOMRIGHT", 0, -8)
    self.debugText:SetShown(self.db.timeline.showDiagnostics)

    if self.db.timeline.showDiagnostics and self.runtime then
        self.debugText:SetText(self.runtime:GetDiagnosticsSummary())
    else
        self.debugText:SetText("")
    end

    if not encounter then
        tracksPanel:SetHeight(emptyTimelineHeight)
        timelineView:SetHeight(emptyTimelineHeight)
        timelineContent:SetWidth(max(1, timelineView:GetWidth()))
        timelineContent:ClearAllPoints()
        timelineContent:SetPoint("TOPLEFT", timelineView, "TOPLEFT", 0, 0)
        timelineContent:SetPoint("BOTTOMLEFT", timelineView, "BOTTOMLEFT", 0, 0)
        markerArea:SetHeight(0)
        markerArea:Hide()
        unknownArea:SetHeight(0)
        unknownArea:Hide()
        self.leftBadge.text:SetText("00:00")
        self.rightBadge.text:SetText("00:00")
        self.emptyStateText:SetText(format("%s\n%s", selectedDungeon and selectedDungeon.name or "No dungeon selected", self:GetDungeonEmptyStateMessage(selectedDungeonKey)))
        self.emptyStateText:Show()

        local dynamicHeight = activeViewTopOffset + timelineView:GetHeight() + 78
        self.mainWindow:SetHeight(max(282, dynamicHeight))
        self.db.ui.window.height = self.mainWindow:GetHeight()
        return
    end

    self.emptyStateText:Hide()
    markerArea:Show()
    unknownArea:Show()

    local events = encounter.events
    local zoom = self.db.timeline.zoom
    local contentWidth = encounter.maxTime / zoom
    local viewWidth = timelineView:GetWidth() > 0 and timelineView:GetWidth() or (self.mainWindow:GetWidth() - leftPanelWidth - 36)
    local viewSpan = viewWidth * zoom
    local maxScroll = max(0, encounter.maxTime - viewSpan)
    self.db.timeline.scroll = self:Clamp(self.db.timeline.scroll, 0, maxScroll)

    timelineContent:SetWidth(contentWidth)
    timelineContent:ClearAllPoints()
    timelineContent:SetPoint("TOPLEFT", timelineView, "TOPLEFT", -(self.db.timeline.scroll / zoom), 0)
    timelineContent:SetPoint("BOTTOMLEFT", timelineView, "BOTTOMLEFT", -(self.db.timeline.scroll / zoom), 0)

    tracksPanel:SetHeight(#events * (rowHeight + rowSpacing))
    timelineView:SetHeight(#events * (rowHeight + rowSpacing) - rowSpacing)
    markerArea:SetHeight(56)
    unknownArea:SetHeight(28)

    local unknownLabel = unknownArea.label
    if not unknownLabel then
        unknownLabel = self:CreateLabel(unknownArea, "", NPRFontSmall, unpack(self.theme.textAccent))
        unknownLabel:SetPoint("TOPLEFT", unknownArea, "TOPLEFT", 0, -2)
        unknownArea.label = unknownLabel
    end
    unknownLabel:SetText("Unknown event bindings")

    self.leftBadge.text:SetText(self:SecondsToClock(self.db.timeline.scroll))
    self.rightBadge.text:SetText(self:SecondsToClock(self.db.timeline.scroll + viewSpan))

    local contentHeight = #events * (rowHeight + rowSpacing) - rowSpacing

    for markerTime = 10, encounter.maxTime, 10 do
        local line = Acquire(pools.intervalLines, function()
            local frame = CreateFrame("Frame", nil, timelineContent)
            frame.tex = frame:CreateTexture(nil, "BACKGROUND")
            frame.tex:SetAllPoints()
            frame.tex:SetColorTexture(0.9, 0.9, 1, 0.18)
            return frame
        end)
        local x = markerTime / zoom
        line:SetWidth(1)
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", timelineContent, "TOPLEFT", x, 0)
        line:SetPoint("BOTTOMLEFT", timelineContent, "TOPLEFT", x, -contentHeight)
    end

    for index, event in ipairs(events) do
        local y = -((index - 1) * (rowHeight + rowSpacing))
        local band = Acquire(pools.trackBands, function()
            local frame = CreateFrame("Frame", nil, timelineContent)
            frame.tex = frame:CreateTexture(nil, "BACKGROUND")
            frame.tex:SetAllPoints()
            return frame
        end)
        band:ClearAllPoints()
        band:SetPoint("TOPLEFT", timelineContent, "TOPLEFT", 0, y)
        band:SetPoint("TOPRIGHT", timelineContent, "TOPRIGHT", 0, y)
        band:SetHeight(rowHeight)
        if index % 2 == 0 then
            band.tex:SetColorTexture(1, 1, 1, 0.025)
        else
            band.tex:SetColorTexture(1, 1, 1, 0.045)
        end

        local row = Acquire(pools.trackRows, function()
            local holder = CreateFrame("Frame", nil, tracksPanel)
            holder:SetSize(leftPanelWidth, rowHeight)
            holder.bg = holder:CreateTexture(nil, "BACKGROUND")
            holder.bg:SetAllPoints()
            holder.bg:SetColorTexture(unpack(self.theme.panelBackground))

            holder.check = self:CreateCheckButton(holder, "", true, nil)
            holder.check:SetPoint("LEFT", holder, "LEFT", 0, 0)

            holder.iconFrame = CreateFrame("Frame", nil, holder)
            holder.iconFrame:SetSize(18, 18)
            holder.iconFrame:SetPoint("LEFT", holder.check.label, "RIGHT", 4, 0)
            holder.iconFrame.tex = holder.iconFrame:CreateTexture(nil, "BACKGROUND")
            holder.iconFrame.tex:SetAllPoints()
            self:AddBorder(holder.iconFrame)

            holder.labelButton = CreateFrame("Button", nil, holder)
            holder.labelButton:SetPoint("LEFT", holder.iconFrame, "RIGHT", 6, 0)
            holder.labelButton:SetPoint("RIGHT", holder, "RIGHT", -4, 0)
            holder.labelButton:SetHeight(rowHeight)
            holder.labelButton:RegisterForClicks("LeftButtonUp")
            holder.labelBG = holder.labelButton:CreateTexture(nil, "BACKGROUND")
            holder.labelBG:SetAllPoints()
            holder.labelBG:SetColorTexture(unpack(self.theme.sectionBackground))
            holder.metricBG = holder.labelButton:CreateTexture(nil, "BORDER")
            holder.metricBG:SetPoint("BOTTOMLEFT", holder.labelButton, "BOTTOMLEFT", 0, 2)
            holder.metricBG:SetHeight(4)
            holder.metricBG:SetWidth(leftPanelWidth - 54)
            holder.metricBG:SetColorTexture(1, 1, 1, 0.06)
            holder.metricFill = holder.labelButton:CreateTexture(nil, "ARTWORK")
            holder.metricFill:SetPoint("LEFT", holder.metricBG, "LEFT")
            holder.metricFill:SetHeight(4)
            holder.metricFill:SetWidth(0)
            holder.titleText = self:CreateLabel(holder.labelButton, "", NPRFontNormal)
            holder.titleText:SetPoint("TOPLEFT", holder.labelButton, "TOPLEFT", 0, -2)
            holder.metaText = self:CreateLabel(holder.labelButton, "", NPRFontSmall, unpack(self.theme.textMuted))
            holder.metaText:SetPoint("TOPLEFT", holder.titleText, "BOTTOMLEFT", 0, -1)
            holder.highlight = holder.labelButton:CreateTexture(nil, "HIGHLIGHT")
            holder.highlight:SetAllPoints()
            holder.highlight:SetColorTexture(unpack(self.theme.hover))

            return holder
        end)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", tracksPanel, "TOPLEFT", 0, y)
        row.check:SetChecked(self:GetTrackVisibility(encounter.key, event.key), true)
        row.check.label:SetText("")
        row.iconFrame.tex:SetTexture(self:GetIconPath(event))
        row.titleText:SetText(event.label)
        row.metaText:SetText(BuildEventMeta(self, event))
        row.metricBG:SetWidth(max(16, row.labelButton:GetWidth() - 10))
        local dangerColor = self:GetEventDangerColor(event)
        row.metricFill:SetWidth(max(12, row.metricBG:GetWidth() * (self:GetEventDangerPercent(event) / 100)))
        row.metricFill:SetColorTexture(dangerColor.r, dangerColor.g, dangerColor.b, 0.9)

        local function ApplyTrackVisuals()
            local enabled = row.check:GetChecked()
            local color = enabled and self.theme.text or self.theme.disabled
            row.titleText:SetTextColor(color[1], color[2], color[3], color[4])
            row.metaText:SetTextColor(self.theme.textMuted[1], self.theme.textMuted[2], self.theme.textMuted[3], enabled and 1 or 0.65)
            row.iconFrame.tex:SetDesaturated(not enabled)
            row.bg:SetAlpha(enabled and 1 or 0.65)
            row.metricFill:SetAlpha(enabled and 1 or 0.4)
        end

        local encounterKey = encounter.key
        local eventKey = event.key
        local eventLabel = event.label
        row.check:SetScript("OnClick", function(selfButton)
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Track visibility")
                selfButton:SetChecked(self:GetTrackVisibility(encounterKey, eventKey), true)
                return
            end
            selfButton:SetChecked(not selfButton.checked, true)
            self:SetTrackVisibility(encounterKey, eventKey, selfButton:GetChecked())
            self:RefreshTimeline()
        end)
        row.labelButton:SetScript("OnClick", function()
            row.check:Click()
        end)
        self:SetTooltip(
            row.labelButton,
            eventLabel,
            format(
                "Relative danger %d%%\nDuration %.1fs\nSpell IDs: %s\nSource: %s\nConfidence: %s",
                self:GetEventDangerPercent(event),
                self:GetEventDuration(event, 1),
                self:FormatSpellIDList(event),
                event.source or "n/a",
                event.confidence or "n/a"
            )
        )
        ApplyTrackVisuals()

        local visible = self:GetTrackVisibility(encounter.key, event.key)
        local entries = self:GetEventEntries(event)
        if visible and entries then
            for occurrenceIndex, entry in ipairs(entries) do
                local currentOccurrenceIndex = occurrenceIndex
                local currentEntry = entry
                if type(currentEntry) == "table" and type(currentEntry.time) == "number" then
                    local block = Acquire(pools.eventBlocks, function()
                        local button = CreateFrame("Button", nil, timelineContent)
                        button:RegisterForClicks("LeftButtonUp")
                        button.tex = button:CreateTexture(nil, "BACKGROUND")
                        button.tex:SetAllPoints()
                        button.danger = button:CreateTexture(nil, "ARTWORK")
                        button.danger:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
                        button.danger:SetHeight(3)
                        button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
                        button.highlight:SetAllPoints()
                        button.highlight:SetColorTexture(unpack(self.theme.hover))
                        button.text = self:CreateLabel(button, "", NPRFontSmall)
                        button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
                        self:AddBorder(button)
                        return button
                    end)
                    local width = max(10, (currentEntry.duration or event.defaultDuration or 0) / zoom)
                    local x = currentEntry.time / zoom
                    block:SetSize(width, rowHeight - 2)
                    block:ClearAllPoints()
                    block:SetPoint("TOPLEFT", timelineContent, "TOPLEFT", x, y)
                    block.tex:SetColorTexture(event.color.r, event.color.g, event.color.b, event.color.a or 1)
                    local blockDangerColor = self:GetEventDangerColor(event)
                    block.danger:SetWidth(max(8, width * (self:GetEventDangerPercent(event) / 100)))
                    block.danger:SetColorTexture(blockDangerColor.r, blockDangerColor.g, blockDangerColor.b, 0.95)
                    if width >= 44 then
                        block.text:SetText(format("%.1fs", self:GetEventDuration(event, currentOccurrenceIndex)))
                    else
                        block.text:SetText("")
                    end
                    block:SetScript("OnClick", function()
                        self:OpenNewReminder(encounterKey, eventKey, currentOccurrenceIndex, 0)
                    end)
                    self:SetTooltip(block, BuildEventTooltip(self, event, currentOccurrenceIndex, currentEntry))
                end
            end
        end
    end

    local reminders = {}
    for _, reminder in ipairs(self:GetEncounterReminders(encounter.key)) do
        if self.db.timeline.showDisabled or reminder.enabled then
            if not self.db.timeline.showRelevantOnly or self:IsReminderRelevant(reminder) then
                table.insert(reminders, reminder)
            end
        end
    end

    self:SortReminders(reminders)

    local markerLanes = {}
    local maxLaneUsed = 0
    local unknownCount = 0
    local unknownAreaWidth = unknownArea:GetWidth() > 0 and unknownArea:GetWidth() or viewWidth
    local unknownColumns = max(1, floor((unknownAreaWidth + 4) / (markerIconSize + 4)))
    local unknownRows = 0

    for _, reminder in ipairs(reminders) do
        local reminderID = reminder.id
        local resolvedTime, reason = self:ResolveReminderTime(reminder)
        if not resolvedTime then
            unknownCount = unknownCount + 1
            local button = Acquire(pools.unknownButtons, function()
                local icon = CreateFrame("Button", nil, unknownArea)
                icon:SetSize(markerIconSize, markerIconSize)
                icon:RegisterForClicks("LeftButtonUp")
                icon.tex = icon:CreateTexture(nil, "BACKGROUND")
                icon.tex:SetAllPoints()
                self:AddBorder(icon)
                    return icon
                end)
            local column = (unknownCount - 1) % unknownColumns
            local rowIndex = floor((unknownCount - 1) / unknownColumns)
            local x = column * (markerIconSize + 4)
            local y = -18 - rowIndex * (markerIconSize + 4)
            unknownRows = max(unknownRows, rowIndex + 1)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", unknownArea, "TOPLEFT", x, y)
            button.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            button:SetScript("OnClick", function()
                self:OpenExistingReminder(reminderID)
            end)
            self:SetTooltip(button, "Unknown reminder", reason or "Could not resolve event for this reminder.")
        else
            local xVisible = (resolvedTime - self.db.timeline.scroll) / zoom
            if xVisible >= -markerIconSize and xVisible <= viewWidth + markerIconSize then
                local lane = 1
                for laneIndex, laneMax in ipairs(markerLanes) do
                    if laneMax < xVisible - markerIconSize then
                        lane = laneIndex
                        break
                    else
                        lane = laneIndex + 1
                    end
                end
                markerLanes[lane] = xVisible + markerIconSize
                maxLaneUsed = max(maxLaneUsed, lane)

                local line = Acquire(pools.markerLines, function()
                    local frame = CreateFrame("Frame", nil, timelineContent)
                    frame.tex = frame:CreateTexture(nil, "BACKGROUND")
                    frame.tex:SetAllPoints()
                    return frame
                end)
                line:SetWidth(2)
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", timelineContent, "TOPLEFT", resolvedTime / zoom, 0)
                line:SetPoint("BOTTOMLEFT", timelineContent, "TOPLEFT", resolvedTime / zoom, -(contentHeight + 4))
                local importanceColor = self:GetImportanceColor(reminder.importance)
                line.tex:SetColorTexture(importanceColor.r, importanceColor.g, importanceColor.b, reminder.enabled and 1 or 0.4)

                local button = Acquire(pools.markerButtons, function()
                    local icon = CreateFrame("Button", nil, markerArea)
                    icon:SetSize(markerIconSize, markerIconSize)
                    icon:RegisterForClicks("LeftButtonUp")
                    icon.tex = icon:CreateTexture(nil, "BACKGROUND")
                    icon.tex:SetAllPoints()
                    self:AddBorder(icon)
                    return icon
                end)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", markerArea, "TOPLEFT", xVisible - markerIconSize / 2, (lane - 1) * -(markerIconSize + markerLaneSpacing))
                button:SetAlpha(reminder.enabled and 1 or 0.5)
                button.tex:SetTexture(self:GetIconPath({
                    spellID = reminder.iconSpellID,
                    icon = self:GetIconPath(self:GetEvent(reminder.encounterKey, reminder.eventKey) or {}),
                }))
                button:SetScript("OnClick", function()
                    self:OpenExistingReminder(reminderID)
                end)

                local text = self:GetReminderDisplayLabel(reminder)
                self:SetTooltip(
                    button,
                    text,
                    format(
                        "Trigger: %s\nLead / delay: %s\nDisplay: %.1fs\nRole: %s\nSound: %s\nEnabled: %s",
                        self:SecondsToClock(resolvedTime),
                        self:DescribeOffsetSeconds(reminder.offsetSeconds),
                        self:GetReminderDisplaySeconds(reminder),
                        reminder.roleScope or "ALL",
                        self:GetSoundOption(reminder.soundKey or "NONE").label,
                        reminder.enabled and "Yes" or "No"
                    )
                )
            end
        end
    end

    markerArea:SetHeight(max(56, maxLaneUsed * (markerIconSize + markerLaneSpacing)))
    local unknownHeight = unknownCount > 0 and max(28, 22 + unknownRows * (markerIconSize + 4)) or 28
    unknownArea:SetHeight(unknownHeight)

    if unknownCount > 0 then
        unknownLabel:SetText(format("Unknown event reminders: %d", unknownCount))
    end

    unknownArea:SetShown(unknownCount > 0)
    unknownLabel:SetShown(unknownCount > 0)

    local visibleUnknownHeight = unknownCount > 0 and unknownHeight or 0
    local dynamicHeight = activeViewTopOffset + timelineView:GetHeight() + markerArea:GetHeight() + visibleUnknownHeight + 78
    self.mainWindow:SetHeight(max(282, dynamicHeight))
    self.db.ui.window.height = self.mainWindow:GetHeight()

end
