local _, NPR = ...

local widgetScriptsReady

local function CreateLineTexture(frame, layer)
    local texture = frame:CreateTexture(nil, layer or "BORDER")
    texture:SetColorTexture(1, 1, 1, 1)
    return texture
end

function NPR:InitializeWidgets()
    if widgetScriptsReady then
        return
    end
    widgetScriptsReady = true
    self.activeDropdowns = self.activeDropdowns or {}
    self.combatDismissedDropdowns = self.combatDismissedDropdowns or {}
end

function NPR:CloseAllDropdownMenus(exceptDropdown)
    if not self.activeDropdowns then
        return
    end

    for dropdown in pairs(self.activeDropdowns) do
        if dropdown ~= exceptDropdown and dropdown.CloseMenu then
            dropdown:CloseMenu(true)
        end
    end
end

function NPR:RecoverCombatDropdownMenus()
    if self.activeDropdowns then
        for dropdown in pairs(self.activeDropdowns) do
            if dropdown and dropdown.CloseMenu then
                dropdown:CloseMenu(true)
            end
        end
    end

    if self.combatDismissedDropdowns then
        for dropdown in pairs(self.combatDismissedDropdowns) do
            if dropdown and dropdown.RefreshMenuVisuals then
                dropdown:RefreshMenuVisuals()
            end
        end
        wipe(self.combatDismissedDropdowns)
    end

    self.pendingDropdownRecovery = nil
end

function NPR:AddBorder(frame, inset)
    if frame.NPRBorder then
        return
    end

    inset = inset or 0
    frame.NPRBorder = {
        top = CreateLineTexture(frame),
        bottom = CreateLineTexture(frame),
        left = CreateLineTexture(frame),
        right = CreateLineTexture(frame),
    }

    frame.NPRBorder.top:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    frame.NPRBorder.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -inset, -inset)
    frame.NPRBorder.top:SetHeight(1)

    frame.NPRBorder.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", inset, inset)
    frame.NPRBorder.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    frame.NPRBorder.bottom:SetHeight(1)

    frame.NPRBorder.left:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    frame.NPRBorder.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", inset, inset)
    frame.NPRBorder.left:SetWidth(1)

    frame.NPRBorder.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -inset, -inset)
    frame.NPRBorder.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    frame.NPRBorder.right:SetWidth(1)

    function frame:SetBorderColor(r, g, b, a)
        for _, texture in pairs(frame.NPRBorder) do
            texture:SetColorTexture(r, g, b, a or 1)
        end
    end

    local color = self.theme.border
    frame:SetBorderColor(color[1], color[2], color[3], color[4])
end

function NPR:CreateWindow(name, width, height, title)
    local window = CreateFrame("Frame", nil, UIParent)
    window:SetSize(width, height)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:SetClampedToScreen(true)
    window:SetToplevel(true)
    window:SetFrameStrata("HIGH")

    window.bgTop = window:CreateTexture(nil, "BACKGROUND")
    window.bgTop:SetPoint("TOPLEFT", window)
    window.bgTop:SetPoint("TOPRIGHT", window)
    window.bgTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    window.bgTop:SetGradient("VERTICAL", CreateColor(unpack(self.theme.backgroundTop)), CreateColor(unpack(self.theme.backgroundMid)))

    window.bgBottom = window:CreateTexture(nil, "BACKGROUND")
    window.bgBottom:SetPoint("TOPLEFT", window.bgTop, "BOTTOMLEFT")
    window.bgBottom:SetPoint("BOTTOMRIGHT", window)
    window.bgBottom:SetColorTexture(unpack(self.theme.backgroundBottom))

    window.titleBar = CreateFrame("Frame", nil, window)
    window.titleBar:SetPoint("TOPLEFT", window)
    window.titleBar:SetPoint("TOPRIGHT", window)
    window.titleBar:SetHeight(28)
    window.titleBar:EnableMouse(true)
    window.titleBar.bg = window.titleBar:CreateTexture(nil, "ARTWORK")
    window.titleBar.bg:SetAllPoints()
    window.titleBar.bg:SetColorTexture(0, 0, 0, 0.34)

    window.titleBar.hover = window.titleBar:CreateTexture(nil, "HIGHLIGHT")
    window.titleBar.hover:SetAllPoints()
    window.titleBar.hover:SetColorTexture(unpack(self.theme.hover))

    window.titleBar.line = window.titleBar:CreateTexture(nil, "BORDER")
    window.titleBar.line:SetPoint("BOTTOMLEFT", window.titleBar, "BOTTOMLEFT", 0, 0)
    window.titleBar.line:SetPoint("BOTTOMRIGHT", window.titleBar, "BOTTOMRIGHT", 0, 0)
    window.titleBar.line:SetHeight(1)
    window.titleBar.line:SetColorTexture(unpack(self.theme.borderStrong))

    window.titleText = window:CreateFontString(nil, "OVERLAY")
    window.titleText:SetFontObject(NPRFontBold)
    window.titleText:SetPoint("LEFT", window.titleBar, "LEFT", 10, -1)
    window.titleText:SetText(title or name)

    window.close = CreateFrame("Button", nil, window)
    window.close:SetSize(24, 24)
    window.close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -2)
    window.close:SetFrameStrata(window:GetFrameStrata())
    window.close:SetFrameLevel(window:GetFrameLevel() + 20)
    window.close:RegisterForClicks("LeftButtonUp")
    window.close:SetHitRectInsets(-4, -4, -4, -4)
    window.close.bg = window.close:CreateTexture(nil, "BACKGROUND")
    window.close.bg:SetAllPoints()
    window.close.bg:SetColorTexture(unpack(self.theme.sectionBackground))
    self:AddBorder(window.close)
    window.close.icon = window.close:CreateFontString(nil, "OVERLAY")
    window.close.icon:SetFontObject(NPRFontBold)
    window.close.icon:SetPoint("CENTER")
    window.close.icon:SetText("X")
    window.close.icon:SetTextColor(unpack(self.theme.textMuted))
    window.close:SetScript("OnClick", function()
        if self:IsConfigLockedDown() then
            self:PrintCombatLockdownMessage("Window closing")
            return
        end
        self:CloseAllDropdownMenus()
        window:Hide()
    end)
    window.close:SetScript("OnEnter", function()
        window.close.bg:SetColorTexture(unpack(self.theme.hover))
        window.close.icon:SetTextColor(unpack(self.theme.textAccent))
    end)
    window.close:SetScript("OnLeave", function()
        window.close.bg:SetColorTexture(unpack(self.theme.sectionBackground))
        window.close.icon:SetTextColor(unpack(self.theme.text))
    end)

    window.content = CreateFrame("Frame", nil, window)
    window.content:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -34)
    window.content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 14)

    self:AddBorder(window)
    window:SetBorderColor(unpack(self.theme.borderStrong))

    window.titleBar:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Window movement")
                return
            end
            window:Raise()
            window.NPRMoving = true
            window:StartMoving()
        end
    end)
    window.titleBar:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and window.NPRMoving then
            window.NPRMoving = nil
            if self:IsConfigLockedDown() then
                self:PrintCombatLockdownMessage("Window movement")
                return
            end
            window:StopMovingOrSizing()
            self:SaveFramePosition(window, name)
        end
    end)

    window:SetScript("OnSizeChanged", function(selfFrame)
        selfFrame.bgTop:SetHeight(max(48, selfFrame:GetHeight() * 0.34))
    end)
    window:HookScript("OnHide", function()
        self:CloseAllDropdownMenus()
    end)

    self:RestoreFramePosition(window, name)
    window.bgTop:SetHeight(max(48, window:GetHeight() * 0.34))

    return window
end

function NPR:CreateLabel(parent, text, fontObject, r, g, b)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(fontObject or NPRFontNormal)
    label:SetText(text or "")
    label:SetTextColor(r or self.theme.text[1], g or self.theme.text[2], b or self.theme.text[3], 1)
    return label
end

function NPR:CreateButton(parent, text, width, height, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:RegisterForClicks("LeftButtonUp")
    button:SetHitRectInsets(-2, -2, -2, -2)

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(unpack(self.theme.panelBackground))

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(unpack(self.theme.hover))

    self:AddBorder(button)

    button.text = self:CreateLabel(button, text, NPRFontNormal)
    button.text:SetPoint("CENTER", 0, -1)

    button:SetScript("OnClick", function(selfButton)
        if onClick then
            onClick(selfButton)
        end
    end)

    function button:SetText(newText)
        self.text:SetText(newText or "")
    end

    return button
end

function NPR:CreateCheckButton(parent, text, initialValue, onChanged)
    local check = CreateFrame("Button", nil, parent)
    check:SetSize(18, 18)
    check:RegisterForClicks("LeftButtonUp")
    check.checked = initialValue and true or false

    check.box = check:CreateTexture(nil, "BACKGROUND")
    check.box:SetAllPoints()
    check.box:SetColorTexture(0, 0, 0, 0.45)

    self:AddBorder(check)

    check.mark = check:CreateFontString(nil, "OVERLAY")
    check.mark:SetFontObject(NPRFontBold)
    check.mark:SetPoint("CENTER")

    check.label = self:CreateLabel(parent, text, NPRFontNormal)
    check.label:SetPoint("LEFT", check, "RIGHT", 6, 0)

    local function UpdateHitRect()
        local labelWidth = max(1, check.label:GetStringWidth() or 0)
        check:SetHitRectInsets(0, -(labelWidth + 10), 0, 0)
    end

    check.UpdateHitRect = UpdateHitRect
    check.label.SetTextOriginal = check.label.SetText
    check.label.SetText = function(label, newText)
        label:SetTextOriginal(newText)
        UpdateHitRect()
    end

    function check:SetChecked(value, silent)
        self.checked = value and true or false
        self.mark:SetText(self.checked and "X" or "")
        if not silent and onChanged then
            onChanged(self.checked)
        end
    end

    function check:GetChecked()
        return self.checked
    end

    check:SetScript("OnClick", function(selfButton)
        selfButton:SetChecked(not selfButton.checked)
    end)

    check:SetChecked(initialValue, true)
    C_Timer.After(0, UpdateHitRect)
    return check
end

function NPR:CreateEditBox(parent, width, height)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetSize(width, height)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(NPRFontNormal)
    editBox:SetTextInsets(6, 6, 0, 0)
    editBox:SetTextColor(unpack(self.theme.text))

    editBox.bg = editBox:CreateTexture(nil, "BACKGROUND")
    editBox.bg:SetAllPoints()
    editBox.bg:SetColorTexture(0, 0, 0, 0.45)

    self:AddBorder(editBox)

    return editBox
end

function NPR:CreateSimpleDropdown(parent, width, items, onChanged)
    local function FindItemIndex(dropdown, value)
        for index, item in ipairs(dropdown.items or {}) do
            if item.value == value then
                return index
            end
        end
        return nil
    end

    local function GetItemDisplay(dropdown, value)
        for _, item in ipairs(dropdown.items or {}) do
            if item.value == value then
                return item.text or item.value or ""
            end
        end
        return ""
    end

    local function SetDropdownDisplay(dropdown, text)
        if dropdown.OverrideText then
            dropdown:OverrideText(text)
        end
        if dropdown.text then
            dropdown.text:SetText(text)
        end
    end

    local function NormalizeDropdownValue(dropdown, value)
        if value ~= nil and FindItemIndex(dropdown, value) then
            return value
        end
        local firstItem = dropdown.items and dropdown.items[1]
        return firstItem and firstItem.value or nil
    end

    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(width, 24)
    dropdown.items = items or {}
    dropdown.value = nil
    dropdown:RegisterForClicks("LeftButtonUp")
    dropdown:SetHitRectInsets(-2, -2, -2, -2)

    dropdown.bg = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.bg:SetAllPoints()
    dropdown.bg:SetColorTexture(unpack(self.theme.panelBackground))

    dropdown.highlight = dropdown:CreateTexture(nil, "HIGHLIGHT")
    dropdown.highlight:SetAllPoints()
    dropdown.highlight:SetColorTexture(unpack(self.theme.hover))

    self:AddBorder(dropdown)

    dropdown.text = self:CreateLabel(dropdown, "", NPRFontNormal)
    dropdown.text:SetPoint("LEFT", dropdown, "LEFT", 8, -1)
    dropdown.text:SetPoint("RIGHT", dropdown, "RIGHT", -18, -1)
    dropdown.text:SetJustifyH("LEFT")

    dropdown.arrow = self:CreateLabel(dropdown, "v", NPRFontBold)
    dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -7, 0)

    dropdown.menu = CreateFrame("Frame", nil, UIParent)
    dropdown.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown.menu:SetFrameLevel(90)
    dropdown.menu:SetWidth(width)
    dropdown.menu:SetClampedToScreen(true)
    dropdown.menu:Hide()
    dropdown.menu.bg = dropdown.menu:CreateTexture(nil, "BACKGROUND")
    dropdown.menu.bg:SetAllPoints()
    dropdown.menu.bg:SetColorTexture(unpack(self.theme.panelBackground))
    self:AddBorder(dropdown.menu)

    dropdown.menu.buttons = {}
    dropdown.closeFrame = CreateFrame("Frame", nil, UIParent)
    dropdown.closeFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown.closeFrame:SetFrameLevel(89)
    dropdown.closeFrame:EnableMouse(true)
    dropdown.closeFrame:Hide()

    local function RefreshMenuVisuals()
        for index, button in ipairs(dropdown.menu.buttons) do
            local item = button.item
            local isActive = item and item.value == dropdown.value
            button.activeBG:SetShown(isActive)
            button.check:SetText(isActive and ">" or "")
            if item then
                if isActive then
                    button.text:SetTextColor(unpack(self.theme.textAccent))
                else
                    button.text:SetTextColor(unpack(self.theme.text))
                end
            end
            if index > #dropdown.items then
                button:Hide()
            end
        end
    end
    dropdown.RefreshMenuVisuals = RefreshMenuVisuals

    function dropdown:DismissMenuDuringCombat()
        self:CloseMenu(true)
        NPR.combatDismissedDropdowns = NPR.combatDismissedDropdowns or {}
        NPR.combatDismissedDropdowns[self] = true
        NPR.pendingDropdownRecovery = true
    end

    local function RebuildMenu()
        local itemHeight = 22
        local itemCount = #dropdown.items

        for index, item in ipairs(dropdown.items) do
            local button = dropdown.menu.buttons[index]
            if not button then
                button = CreateFrame("Button", nil, dropdown.menu)
                button:RegisterForClicks("LeftButtonUp")
                button.bg = button:CreateTexture(nil, "BACKGROUND")
                button.bg:SetAllPoints()
                button.bg:SetColorTexture(0, 0, 0, 0.18)
                button.activeBG = button:CreateTexture(nil, "ARTWORK")
                button.activeBG:SetAllPoints()
                button.activeBG:SetColorTexture(unpack(self.theme.hover))
                button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
                button.highlight:SetAllPoints()
                button.highlight:SetColorTexture(1, 1, 1, 0.06)
                button.text = self:CreateLabel(button, "", NPRFontNormal)
                button.text:SetPoint("LEFT", button, "LEFT", 8, -1)
                button.text:SetPoint("RIGHT", button, "RIGHT", -18, -1)
                button.text:SetJustifyH("LEFT")
                button.check = self:CreateLabel(button, "", NPRFontBold, unpack(self.theme.textAccent))
                button.check:SetPoint("RIGHT", button, "RIGHT", -7, -1)
                button:SetScript("OnClick", function(selfButton)
                    if NPR:IsConfigLockedDown() then
                        NPR:PrintCombatLockdownMessage("Dropdown menus")
                        dropdown:DismissMenuDuringCombat()
                        return
                    end
                    local selectedItem = selfButton.item
                    dropdown:SetSelected(selectedItem and selectedItem.value or nil)
                    dropdown:CloseMenu()
                end)
                dropdown.menu.buttons[index] = button
            end

            button.item = item
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", dropdown.menu, "TOPLEFT", 2, -(2 + (index - 1) * itemHeight))
            button:SetPoint("TOPRIGHT", dropdown.menu, "TOPRIGHT", -2, -(2 + (index - 1) * itemHeight))
            button:SetHeight(itemHeight)
            button.text:SetText(item.text or item.value or "")
            button:Show()
        end

        for index = itemCount + 1, #dropdown.menu.buttons do
            dropdown.menu.buttons[index].item = nil
            dropdown.menu.buttons[index]:Hide()
        end

        dropdown.menu:SetHeight(max(24, itemCount * itemHeight + 4))
        RefreshMenuVisuals()
    end

    function dropdown:CloseMenu(silent)
        self.menu:Hide()
        self.closeFrame:Hide()
        if NPR.activeDropdowns then
            NPR.activeDropdowns[self] = nil
        end
        if not silent then
            RefreshMenuVisuals()
        end
    end

    function dropdown:OpenMenu()
        if #self.items == 0 then
            return
        end
        if NPR:IsConfigLockedDown() then
            NPR:PrintCombatLockdownMessage("Dropdown menus")
            return
        end

        NPR:CloseAllDropdownMenus(self)
        RebuildMenu()
        self.menu:ClearAllPoints()
        local screenHeight = UIParent and UIParent:GetHeight() or 0
        local menuHeight = self.menu:GetHeight()
        local buttonBottom = self:GetBottom() or 0
        local buttonTop = self:GetTop() or 0
        if buttonBottom - menuHeight < 18 and buttonTop + menuHeight < (screenHeight - 18) then
            self.menu:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
        else
            self.menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        end
        self.menu:Show()
        self.menu:Raise()
        self.closeFrame:SetAllPoints(UIParent)
        self.closeFrame:Show()
        NPR.activeDropdowns[self] = true
    end

    function dropdown:SetItems(newItems)
        self.items = newItems or {}
        self.value = NormalizeDropdownValue(self, self.value)
        SetDropdownDisplay(self, GetItemDisplay(self, self.value))
        RebuildMenu()
    end

    function dropdown:SetSelected(value, silent)
        self.value = NormalizeDropdownValue(self, value)
        SetDropdownDisplay(self, GetItemDisplay(self, self.value))
        RefreshMenuVisuals()
        if not silent and onChanged then
            onChanged(self.value)
        end
    end

    function dropdown:GetSelected()
        return self.value
    end

    dropdown:SetScript("OnClick", function(selfButton)
        if selfButton.menu:IsShown() then
            selfButton:CloseMenu()
        else
            selfButton:OpenMenu()
        end
    end)

    dropdown.closeFrame:SetScript("OnMouseDown", function()
        if NPR:IsConfigLockedDown() then
            NPR:PrintCombatLockdownMessage("Dropdown menus")
            dropdown:DismissMenuDuringCombat()
            return
        end
        dropdown:CloseMenu()
    end)
    dropdown:HookScript("OnHide", function(selfButton)
        selfButton:CloseMenu(true)
    end)

    if dropdown.items[1] then
        dropdown:SetSelected(dropdown.items[1].value, true)
        RebuildMenu()
    end

    return dropdown
end

function NPR:SetTooltip(frame, title, body)
    frame.NPRTooltip = {
        title = title,
        body = body,
    }

    if frame.NPRTooltipScriptsInstalled then
        return
    end

    frame.NPRTooltipScriptsInstalled = true
    local previousOnEnter = frame:GetScript("OnEnter")
    local previousOnLeave = frame:GetScript("OnLeave")

    frame:SetScript("OnEnter", function(selfFrame, ...)
        if previousOnEnter then
            previousOnEnter(selfFrame, ...)
        end
        local tooltip = selfFrame.NPRTooltip
        if not tooltip then
            return
        end
        GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip.title or "", 1, 1, 1, true)
        if tooltip.body and tooltip.body ~= "" then
            GameTooltip:AddLine(tooltip.body, 0.88, 0.91, 0.98, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(selfFrame, ...)
        if previousOnLeave then
            previousOnLeave(selfFrame, ...)
        end
        GameTooltip:Hide()
    end)
end
