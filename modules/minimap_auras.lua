local addon = select(2,...);
local config = addon.config;
local atlas = addon.minimap_SetAtlas;
local shown = addon.minimap_SetShown;
local mixin = addon.minimap_Mixin;
local select = select;
local pairs = pairs;
local ceil = math.ceil;
local _G = _G;

local Minimap = Minimap;
local TempEnchant1 = TempEnchant1;
local TempEnchant2 = TempEnchant2;
local UnitHasVehicleUI = UnitHasVehicleUI;
local hooksecurefunc = hooksecurefunc;

local AuraFrameMixin = {};

-- Function to refresh the position of auras based on database settings
function addon:RefreshAuraPosition()
    if not TempEnchant1 then return end

    -- Read horizontal and vertical offsets from the database
    local x_offset = (addon.db.profile.map.auras and addon.db.profile.map.auras.x_offset) or -80
    local y_offset = (addon.db.profile.map.auras and addon.db.profile.map.auras.y_offset) or 24

    -- Reposition the main enchant frame
    TempEnchant1:ClearAllPoints()
    TempEnchant1:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', x_offset, y_offset)

    -- Reposition secondary enchant and consolidated buffs frames
    TempEnchant2:ClearAllPoints()
    TempEnchant2:SetPoint('TOPRIGHT', TempEnchant1, 'TOPLEFT', -5, 0)
    ConsolidatedBuffs:ClearAllPoints()
    ConsolidatedBuffs:SetPoint('TOPRIGHT', TempEnchant1)

    -- Force update of all buff and debuff anchors to reflect new positions
    BuffFrame_UpdateAllBuffAnchors()
    if DebuffButton_UpdateAnchors then
        DebuffButton_UpdateAnchors("DebuffButton", 1)
    end
end

-- Function to position the first buff button, considering vehicle UI and existing enchants
function AuraFrameMixin:UpdateFirstButton(button)
	if button and button:IsShown() then
		button:ClearAllPoints()
		if UnitHasVehicleUI('player') then
			button:SetPoint('TOPRIGHT', TempEnchant1)
			return
		else
			if BuffFrame.numEnchants > 0 then
				button:SetPoint('TOPRIGHT', _G['TempEnchant'..BuffFrame.numEnchants], 'TOPLEFT', -5, 0)
				return
			else
				button:SetPoint('TOPRIGHT', TempEnchant1)
				return
			end
		end
	end
end

-- Function to update the anchors of all buff buttons in a grid layout
function AuraFrameMixin:UpdateBuffsAnchor()
	local previousBuff, aboveBuff
	local numBuffs = 0
	local numTotal = BuffFrame.numEnchants
	
	for index=1, BUFF_ACTUAL_DISPLAY do
		local buff = _G['BuffButton'..index]
		if not buff then return end
		
		numBuffs = numBuffs + 1
		numTotal = numTotal + 1
        
		buff:ClearAllPoints()
		if numBuffs == 1 then
			AuraFrameMixin:UpdateFirstButton(buff)
		elseif numBuffs > 1 and mod(numTotal, BUFFS_PER_ROW) == 1 then
			if numTotal == BUFFS_PER_ROW + 1 then
				buff:SetPoint('TOP', TempEnchant1, 'BOTTOM', 0, -BUFF_ROW_SPACING)
			else
				buff:SetPoint('TOP', aboveBuff, 'BOTTOM', 0, -BUFF_ROW_SPACING)
			end
			aboveBuff = buff
		else
			buff:SetPoint('TOPRIGHT', previousBuff, 'TOPLEFT', -5, 0)
		end
		previousBuff = buff
	end
end

-- Function to update the anchor of a specific debuff button
function AuraFrameMixin:UpdateDeBuffsAnchor(index)
	local numBuffs = BUFF_ACTUAL_DISPLAY + BuffFrame.numEnchants
	local numRows = ceil(numBuffs/BUFFS_PER_ROW)
	local buffHeight = TempEnchant1:GetHeight();

	local buff = _G[self..index]
	if not buff then return end
	buff:ClearAllPoints()
	if index > 1 and mod(index, BUFFS_PER_ROW) == 1 then
		buff:SetPoint('TOP', _G[self..(index-BUFFS_PER_ROW)], 'BOTTOM', 0, -BUFF_ROW_SPACING);
	elseif index == 1 then
		if numRows < 2 then
			buff:SetPoint('TOPRIGHT', ConsolidatedBuffs, 'BOTTOMRIGHT', -80, -1*((2*BUFF_ROW_SPACING)+buffHeight));
		else
			buff:SetPoint('TOPRIGHT', ConsolidatedBuffs, 'BOTTOMRIGHT', -80, -numRows*(BUFF_ROW_SPACING+buffHeight));
		end
	else
		buff:SetPoint('RIGHT', _G[self..(index-1)], 'LEFT', -5, 0);
	end
end

-- Function to create and configure the collapse/expand button for auras
function AuraFrameMixin:UpdateCollapseAndExpandButtonAnchor()
	local arrow = CreateFrame('Button', 'CollapseAndExpandButton', _G.MinimapCluster)
	arrow:SetSize(13, 26)
	arrow:SetPoint('LEFT', TempEnchant1, 'RIGHT', 2, 0)
	arrow:SetNormalTexture''
	arrow:SetPushedTexture''
	arrow:SetHighlightTexture''
	arrow:RegisterForClicks('LeftButtonUp')

	local normal = arrow:GetNormalTexture()
	atlas(normal, 'ui-hud-aura-arrow-invert')

	local pushed = arrow:GetPushedTexture()
	atlas(pushed, 'ui-hud-aura-arrow-invert')

	local highlight = arrow:GetHighlightTexture()
	atlas(highlight, 'ui-hud-aura-arrow-invert')
	highlight:SetAlpha(.2)
	highlight:SetBlendMode('ADD')
	
	arrow.collapse = false
	arrow:SetScript('OnClick',function(self)
		self.collapse = not self.collapse
		if self.collapse then
			atlas(normal, 'ui-hud-aura-arrow')
			atlas(pushed, 'ui-hud-aura-arrow')
			atlas(highlight, 'ui-hud-aura-arrow')
			BuffFrame:Hide()
			-- shown(ConsolidatedBuffs, GetCVar("consolidateBuffs"))
			-- ConsolidatedBuffs:Hide()
		else
			atlas(normal, 'ui-hud-aura-arrow-invert')
			atlas(pushed, 'ui-hud-aura-arrow-invert')
			atlas(highlight, 'ui-hud-aura-arrow-invert')
			BuffFrame:Show()
			-- shown(ConsolidatedBuffs, GetCVar("consolidateBuffs"))
		end
	end)
	self.arrow = arrow
end
AuraFrameMixin:UpdateCollapseAndExpandButtonAnchor();

-- Function to show/hide the collapse button based on number of buffs
function AuraFrameMixin:RefreshCollapseExpandButtonState(numBuffs)
    shown(self.arrow, numBuffs > 0);
end

-- Replace Blizzard's buff update functions with our custom ones for full control
BuffFrame_UpdateAllBuffAnchors = AuraFrameMixin.UpdateBuffsAnchor
DebuffButton_UpdateAnchors = AuraFrameMixin.UpdateDeBuffsAnchor

mixin(addon._map, AuraFrameMixin);

-- [[ REFRESH LOGIC BASED ON UNITFRAME.LUA ]]

-- 1. Call the function once on load to set initial position.
addon:RefreshAuraPosition()

-- 2. Register the refresh function directly with AceDB database.
--    This is the correct method and ensures it executes when profile changes.
local function RegisterProfileCallbacks()
    if addon and addon.db and addon.db.RegisterCallback then
        -- When profile changes, is copied, or reset, call RefreshAuraPosition.
        addon.db:RegisterCallback("OnProfileChanged", addon.RefreshAuraPosition)
        addon.db:RegisterCallback("OnProfileCopied", addon.RefreshAuraPosition)
        addon.db:RegisterCallback("OnProfileReset", addon.RefreshAuraPosition)
    end
end

-- 3. Use a frame to register the callback safely when the addon has loaded.
local callbackFrame = CreateFrame("Frame")
callbackFrame:RegisterEvent("ADDON_LOADED")
callbackFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "DragonUI" then
        RegisterProfileCallbacks()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)