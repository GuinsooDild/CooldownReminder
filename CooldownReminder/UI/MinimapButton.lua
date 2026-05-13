local addonName, NPR = ...

local iconTexture = "Interface\\Icons\\INV_Misc_EngGizmos_17"
local atan2 = math.atan2 or function(y, x)
    if x == 0 then
        if y > 0 then
            return math.pi / 2
        elseif y < 0 then
            return -math.pi / 2
        end
        return 0
    end

    local angle = math.atan(y / x)
    if x < 0 then
        angle = angle + math.pi
    end
    return angle
end

local minimapShapes = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, true, true, true },
    ["CORNER-TOPRIGHT"] = { true, false, true, true },
    ["CORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["CORNER-BOTTOMRIGHT"] = { true, true, true, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function GetShape()
    if type(GetMinimapShape) == "function" then
        return GetMinimapShape() or "ROUND"
    end
    return "ROUND"
end

function NPR:UpdateMinimapButtonPosition()
    if not self.minimapButton or not Minimap then
        return false
    end

    if self:IsConfigLockedDown() then
        self.pendingMinimapRefresh = true
        return false
    end

    local settings = self.db and self.db.ui and self.db.ui.minimap
    if not settings or self:IsMinimapButtonHidden() then
        self.minimapButton:Hide()
        return true
    end

    local angle = math.rad(settings.angle or 210)
    local x = math.cos(angle)
    local y = math.sin(angle)
    local quadrant = 1
    if x < 0 then
        quadrant = quadrant + 1
    end
    if y > 0 then
        quadrant = quadrant + 2
    end

    local shape = GetShape()
    local quadTable = minimapShapes[shape] or minimapShapes.ROUND
    local widthRadius = (Minimap:GetWidth() / 2) + 5
    local heightRadius = (Minimap:GetHeight() / 2) + 5

    if quadTable[quadrant] then
        x = x * widthRadius
        y = y * heightRadius
    else
        local diagonalWidth = math.sqrt(2 * (widthRadius ^ 2)) - 10
        local diagonalHeight = math.sqrt(2 * (heightRadius ^ 2)) - 10
        x = math.max(-widthRadius, math.min(x * diagonalWidth, widthRadius))
        y = math.max(-heightRadius, math.min(y * diagonalHeight, heightRadius))
    end

    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    self.minimapButton:Show()
    self.pendingMinimapRefresh = nil
    return true
end

function NPR:InitializeMinimapButton()
    if self.minimapButton or not Minimap then
        self:UpdateMinimapButtonPosition()
        return
    end

    local button = CreateFrame("Button", addonName .. "MinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    button.background:SetSize(20, 20)
    button.background:SetPoint("CENTER", 0, 1)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture(iconTexture)
    button.icon:SetSize(18, 18)
    button.icon:SetPoint("CENTER", 0, 1)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border:SetTexCoord(0, 0.6, 0, 0.6)
    button.border:SetAllPoints()

    button:SetScript("OnClick", function(_, buttonName)
        if buttonName == "LeftButton" or buttonName == "RightButton" then
            self:ToggleMainWindow("Minimap launcher")
        end
    end)

    button:SetScript("OnDragStart", function(selfButton)
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Minimap launcher movement")
            return
        end
        selfButton:SetScript("OnUpdate", function()
            if self:IsConfigLockedDown() then
                selfButton:SetScript("OnUpdate", nil)
                self:PrintCombatLockdownMessage("Minimap launcher movement")
                return
            end
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px = px / scale
            py = py / scale
            self.db.ui.minimap.angle = math.deg(atan2(py - my, px - mx))
            self:UpdateMinimapButtonPosition()
        end)
    end)

    button:SetScript("OnDragStop", function(selfButton)
        selfButton:SetScript("OnUpdate", nil)
        if self.pendingMinimapRefresh and not self:IsConfigLockedDown() then
            self:UpdateMinimapButtonPosition()
        end
    end)

    self:SetTooltip(
        button,
        "CooldownReminder",
        "Left click: open the reminder timeline\nRight click: open the reminder timeline\nDrag: move the minimap button"
    )

    self.minimapButton = button
    self:UpdateMinimapButtonPosition()
end
