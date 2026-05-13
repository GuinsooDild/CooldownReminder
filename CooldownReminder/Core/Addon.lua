local addonName, NPR = ...

_G[addonName] = NPR

NPR.addonName = addonName
NPR.version = 1
NPR.displayName = "CooldownReminder"
NPR.savedVariablesName = "CooldownReminderDB"
NPR.state = {
    remindersByEncounter = {},
    eventsByEncounter = {},
}

local eventFrame = CreateFrame("Frame")
NPR.eventFrame = eventFrame
NPR.clientUIReady = false

local function SafeCall(func, ...)
    local errorHandler = CallErrorHandler or geterrorhandler()
    local ok, err = xpcall(func, errorHandler, ...)
    if not ok then
        local message = "|cffff5a5a[CooldownReminder]|r Error: " .. tostring(err)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        else
            print(message)
        end
    end
end

local function ShowCompartmentTooltip(button)
    if not button then
        return
    end

    if MenuUtil and MenuUtil.ShowTooltip then
        MenuUtil.ShowTooltip(button, function(tooltip)
            tooltip:SetText("CooldownReminder")
            tooltip:AddLine("Open the current dungeon reminder timeline.", 0.88, 0.91, 0.98, true)
            tooltip:AddLine("Use /crem minimap toggle if you lose the minimap button.", 0.72, 0.78, 0.92, true)
        end)
        return
    end

    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText("CooldownReminder", 1, 1, 1, true)
    GameTooltip:AddLine("Open the current dungeon reminder timeline.", 0.88, 0.91, 0.98, true)
    GameTooltip:AddLine("Use /crem minimap toggle if you lose the minimap button.", 0.72, 0.78, 0.92, true)
    GameTooltip:Show()
end

local function HideCompartmentTooltip(button)
    if MenuUtil and MenuUtil.HideTooltip then
        MenuUtil.HideTooltip(button)
        return
    end

    if GameTooltip then
        GameTooltip:Hide()
    end
end

function NPR:HandleCompartmentClick(buttonName)
    self:ToggleMainWindow("Addon Compartment")
    if self.db and self.db.debug and self.db.debug.enabled then
        self:LogDebug("Addon Compartment click: " .. tostring(buttonName or "unknown"))
    end
end

function NPR:HandleCompartmentEnter(button)
    ShowCompartmentTooltip(button)
end

function NPR:HandleCompartmentLeave(button)
    HideCompartmentTooltip(button)
end

_G[addonName .. "_OnAddonCompartmentClick"] = function(_, buttonName)
    local addon = _G[addonName]
    if addon and addon.HandleCompartmentClick then
        addon:HandleCompartmentClick(buttonName)
    end
end

_G[addonName .. "_OnAddonCompartmentEnter"] = function(_, button)
    local addon = _G[addonName]
    if addon and addon.HandleCompartmentEnter then
        addon:HandleCompartmentEnter(button)
    end
end

_G[addonName .. "_OnAddonCompartmentLeave"] = function(_, button)
    local addon = _G[addonName]
    if addon and addon.HandleCompartmentLeave then
        addon:HandleCompartmentLeave(button)
    end
end

function NPR:InitializeClientUI()
    if self.clientUIReady then
        return
    end

    if self:IsConfigLockedDown() then
        self.pendingClientUIInit = true
        self:PrintCombatLockdownMessage("Client UI initialization")
        return
    end

    self.pendingClientUIInit = nil
    self.clientUIReady = true
    SafeCall(function() self:InitializeWidgets() end)
    SafeCall(function() self:InitializeRuntime() end)
    SafeCall(function() self:InitializeEditor() end)
    SafeCall(function() self:InitializeMainWindow() end)
    SafeCall(function() self:InitializeMinimapButton() end)

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            SafeCall(function()
                self:RefreshAll()
                self:LogWork("Initialized client UI after PLAYER_LOGIN.")
            end)
        end)
    else
        SafeCall(function()
            self:RefreshAll()
            self:LogWork("Initialized client UI after PLAYER_LOGIN.")
        end)
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= addonName then
            return
        end

        SafeCall(function() NPR:InitializeDatabase() end)
        SafeCall(function() NPR:BuildStaticData() end)
        SafeCall(function() NPR:RebuildReminderIndexes() end)
        SafeCall(function() NPR:InitializeTheme() end)
        SafeCall(function() NPR:RegisterSlashCommands() end)
        SafeCall(function() NPR:RegisterCompartment() end)
        SafeCall(function() NPR:LogWork("Initialized addon data and command surface.") end)
    elseif event == "PLAYER_LOGIN" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                NPR:InitializeClientUI()
            end)
        else
            NPR:InitializeClientUI()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        SafeCall(function()
            if NPR.pendingClientUIInit then
                NPR:InitializeClientUI()
            end
            if NPR.pendingDropdownRecovery and NPR.RecoverCombatDropdownMenus then
                NPR:RecoverCombatDropdownMenus()
            end
            if NPR.pendingTimelineRefresh or NPR.pendingFullRefresh or NPR.pendingMinimapRefresh then
                NPR.pendingTimelineRefresh = nil
                NPR.pendingFullRefresh = nil
                NPR.pendingMinimapRefresh = nil
                NPR:RefreshAll()
            end
        end)
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

function NPR:RefreshAll()
    if not self.clientUIReady then
        return
    end

    if self:IsConfigLockedDown() then
        self.pendingFullRefresh = true
        return
    end

    self:RebuildReminderIndexes()
    if self.mainWindow then
        self:RefreshTimeline()
    end
    if self.minimapButton then
        self:UpdateMinimapButtonPosition()
    end
    if self.runtime then
        self.runtime:RefreshDebugText()
    end
end

function NPR:RegisterCompartment()
    -- Retail 11.x/12.x supports TOC-based Addon Compartment callbacks.
    -- Keep this startup stage as a no-op so initialization remains ordered
    -- without relying on a manual registration path that can drift.
    return true
end
