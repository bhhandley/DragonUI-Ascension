local addon = select(2, ...)

-- Conflicting addons database
local CONFLICTING_ADDONS = {
    ["unitframelayers"] = {
        name = "UnitFrameLayers",
        reason = "Conflicts with DragonUI's custom unit frame textures and power bar system.",
        severity = "high"
    }
}

local warningShown = {}

-- Core functions
local function ScanForConflicts()
    local conflicts = {}
    for addonName, addonInfo in pairs(CONFLICTING_ADDONS) do
        if IsAddOnLoaded(addonName) then
            table.insert(conflicts, { name = addonName, info = addonInfo })
        end
    end
    return conflicts
end

local function ShowConflictWarning(conflictInfo)
    local addonName = conflictInfo.name
    local addonInfo = conflictInfo.info
    
    if warningShown[addonName] then return end
    warningShown[addonName] = true
    
    StaticPopupDialogs["DRAGONUI_ADDON_CONFLICT"] = {
        text = string.format(
            "|cFFFF0000DragonUI Conflict Warning|r\n\n" ..
            "The addon |cFFFFFF00%s|r conflicts with DragonUI.\n\n" ..
            "|cFFFF9999Reason:|r %s\n\n" ..
            "Disable the conflicting addon now?",
            addonInfo.name, addonInfo.reason
        ),
        button1 = "Disable Addon",
        button2 = "Remind Later",
        OnAccept = function() DisableAddOn(addonName) ReloadUI() end,
        OnCancel = function() warningShown[addonName] = false end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3
    }
    
    StaticPopup_Show("DRAGONUI_ADDON_CONFLICT")
end

-- Event handling and initialization
local function InitializeConflictDetection()
    local detectionFrame = CreateFrame("Frame")
    detectionFrame:RegisterEvent("ADDON_LOADED")
    detectionFrame:RegisterEvent("PLAYER_LOGIN")
    
    detectionFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and CONFLICTING_ADDONS[addonName] then
            local timer = CreateFrame("Frame")
            timer.elapsed = 0
            timer:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed >= 2 then
                    self:SetScript("OnUpdate", nil)
                    ShowConflictWarning({ name = addonName, info = CONFLICTING_ADDONS[addonName] })
                end
            end)
        elseif event == "PLAYER_LOGIN" then
            local timer = CreateFrame("Frame")
            timer.elapsed = 0
            timer:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed >= 5 then
                    self:SetScript("OnUpdate", nil)
                    for _, conflict in ipairs(ScanForConflicts()) do
                        ShowConflictWarning(conflict)
                    end
                end
            end)
        end
    end)
    
    -- Slash commands
    SLASH_DRAGONUI_CONFLICT1 = "/dragonconflict"
    SlashCmdList["DRAGONUI_CONFLICT"] = function()
        local conflicts = ScanForConflicts()
        if #conflicts == 0 then
            print("|cFF00FF00DragonUI:|r No conflicting addons detected.")
        else
            print("|cFFFF6600DragonUI:|r Found " .. #conflicts .. " conflicting addon(s).")
            for _, conflict in ipairs(conflicts) do
                ShowConflictWarning(conflict)
            end
        end
    end
end

-- Public API
addon.ScanForConflicts = function() return ScanForConflicts() end
addon.IsConflictingAddon = function(name) return CONFLICTING_ADDONS[name] ~= nil end
addon.AddConflictingAddon = function(name, info) 
    CONFLICTING_ADDONS[name] = info
    if IsAddOnLoaded(name) then
        ShowConflictWarning({ name = name, info = info })
    end
end

InitializeConflictDetection()