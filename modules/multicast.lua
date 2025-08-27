local addon = select(2,...);
local class = addon._class;
local noop = addon._noop;
local InCombatLockdown = InCombatLockdown;
local UnitAffectingCombat = UnitAffectingCombat;
local hooksecurefunc = hooksecurefunc;
local UIParent = UIParent;
local NUM_POSSESS_SLOTS = NUM_POSSESS_SLOTS or 10;

-- 1. RENAMED ANCHOR: For clarity, as it handles both Totem and Possess bars.
local anchor = CreateFrame('Frame', 'pUiExtraBarHolder', UIParent)
anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 52)
anchor:SetSize(37, 37)

-- 2. RENAMED & SECURED UPDATE FUNCTION
function anchor:update_position()
    if InCombatLockdown() or UnitAffectingCombat('player') then return end

    -- SAFELY read config values each time
    local totemConfig = addon:GetConfigValue("additional", "totem") or {}
    local offsetX = totemConfig.x_position or 0
    local offsetY = totemConfig.y_offset or 0
    
    if IsAddOnLoaded('pretty_actionbar') and _G.pUiMainBar then
        local mainBar = _G.pUiMainBar;
        local leftbar = MultiBarBottomLeft and MultiBarBottomLeft:IsShown();
        local rightbar = MultiBarBottomRight and MultiBarBottomRight:IsShown();
        
        -- SAFELY read config values
        local additionalConfig = addon:GetConfigValue("additional") or {}
        local nobar = 52;
        local leftbarOffset = additionalConfig.leftbar_offset or 90;
        local rightbarOffset = additionalConfig.rightbar_offset or 40;
        local leftOffset = nobar + leftbarOffset;
        local rightOffset = nobar + rightbarOffset;
        
        self:ClearAllPoints();
        
        if leftbar and rightbar then
            self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, leftOffset + offsetY);
        elseif leftbar then
            self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, rightOffset + offsetY);
        elseif rightbar then
            self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, leftOffset + offsetY);
        else
            self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, nobar + offsetY);
        end
    else
        local leftbar = MultiBarBottomLeft and MultiBarBottomLeft:IsShown();
        local rightbar = MultiBarBottomRight and MultiBarBottomRight:IsShown();
        local anchorFrame, anchorPoint, relativePoint, yOffset;
        
        if leftbar or rightbar then
            if leftbar and rightbar then
                anchorFrame = MultiBarBottomRight;
            elseif leftbar then
                anchorFrame = MultiBarBottomLeft;
            else
                anchorFrame = MultiBarBottomRight;
            end
            anchorPoint = 'TOP';
            relativePoint = 'BOTTOM';
            yOffset = 5 + offsetY;
        else
            anchorFrame = addon.pUiMainBar or MainMenuBar;
            anchorPoint = 'TOP';
            relativePoint = 'BOTTOM';
            yOffset = 5 + offsetY;
        end
        
        self:ClearAllPoints();
        self:SetPoint(relativePoint, anchorFrame, anchorPoint, offsetX, yOffset);
    end
end

-- 3. CORRECTED HOOKS: This prevents the "trying to anchor to itself" error.
local MultiBarBottomLeft = _G["MultiBarBottomLeft"]
local MultiBarBottomRight = _G["MultiBarBottomRight"]
for _,bar in pairs({MultiBarBottomLeft,MultiBarBottomRight}) do
    if bar then
        bar:HookScript('OnShow', function() anchor:update_position() end);
        bar:HookScript('OnHide', function() anchor:update_position() end);
    end
end;

local possessbar = CreateFrame('Frame', 'pUiPossessBar', UIParent, 'SecureHandlerStateTemplate')
possessbar:SetAllPoints(anchor)
PossessBarFrame:SetParent(possessbar)
PossessBarFrame:SetClearPoint('BOTTOMLEFT', -68, 0)

-- 4. SECURED BUTTON POSITIONING FUNCTION
local function possessbutton_position()
    -- SAFELY read config values
    local additionalConfig = addon:GetConfigValue("additional") or {}
    local btnsize = additionalConfig.size or 37;
    local space = additionalConfig.spacing or 4;
    
    for index=1, NUM_POSSESS_SLOTS do
        local button = _G['PossessButton'..index];
        button:ClearAllPoints();
        button:SetParent(possessbar);
        button:SetSize(btnsize, btnsize);
        if index == 1 then
            button:SetPoint('BOTTOMLEFT', 0, 0);
        else
            button:SetPoint('LEFT', _G['PossessButton'..index-1], 'RIGHT', space, 0);
        end
        button:Show();
        possessbar:SetAttribute('addchild', button);
    end
    if addon.possessbuttons_template then
        addon.possessbuttons_template();
    end
    RegisterStateDriver(possessbar, 'visibility', '[vehicleui][@vehicle,exists] hide; show');
end

-- 5. SIMPLIFIED INITIALIZATION: One reliable event after the addon is ready.
local function InitializeBars()
    possessbutton_position()
    anchor:update_position()
end
addon.core.RegisterMessage(addon, "DRAGONUI_READY", InitializeBars);

-- Shaman-specific multicast handling (no changes needed here, logic is sound)
if MultiCastActionBarFrame and class == 'SHAMAN' then
    MultiCastActionBarFrame:SetScript('OnUpdate', nil)
    MultiCastActionBarFrame:SetScript('OnShow', nil)
    MultiCastActionBarFrame:SetScript('OnHide', nil)
    
    MultiCastActionBarFrame:SetParent(possessbar)
    MultiCastActionBarFrame:ClearAllPoints()
    MultiCastActionBarFrame:SetPoint('BOTTOMLEFT', possessbar, 'BOTTOMLEFT', 0, 0)
    
    MultiCastActionBarFrame:Show()
    
    hooksecurefunc('MultiCastActionButton_Update',function(actionButton)
        if not InCombatLockdown() then
            actionButton:SetAllPoints(actionButton.slotButton)
        end
    end);
    
    MultiCastActionBarFrame.SetParent = noop;
    MultiCastActionBarFrame.SetPoint = noop;
    if MultiCastRecallSpellButton then
        MultiCastRecallSpellButton.SetPoint = noop;
    end
end

-- 6. SECURED REFRESH FUNCTION
function addon.RefreshMulticast()
    if InCombatLockdown() or UnitAffectingCombat("player") then return end
    
    -- SAFELY read config values
    local additionalConfig = addon:GetConfigValue("additional") or {}
    local btnsize = additionalConfig.size or 37;
    local space = additionalConfig.spacing or 4;
    
    for index = 1, NUM_POSSESS_SLOTS do
        local button = _G["PossessButton"..index];
        if button then
            button:SetSize(btnsize, btnsize);
            button:ClearAllPoints();
            if index == 1 then
                button:SetPoint('BOTTOMLEFT', possessbar, 'BOTTOMLEFT', 0, 0);
            else
                button:SetPoint('LEFT', _G["PossessButton"..(index-1)], 'RIGHT', space, 0);
            end
        end
    end
    
    if class == 'SHAMAN' and MultiCastActionBarFrame then
        for i = 1, 4 do
            local button = _G["MultiCastActionButton"..i];
            if button then
                button:SetSize(btnsize, btnsize);
                button:ClearAllPoints();
                if i == 1 then
                    button:SetPoint('BOTTOMLEFT', MultiCastActionBarFrame, 'BOTTOMLEFT', 0, 0);
                else
                    button:SetPoint('LEFT', _G["MultiCastActionButton"..(i-1)], 'RIGHT', space, 0);
                end
            end
        end
        
        if MultiCastRecallSpellButton then
            MultiCastRecallSpellButton:SetSize(btnsize, btnsize);
        end
    end
    
    anchor:update_position();
end