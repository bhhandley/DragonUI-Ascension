local addon = select(2,...);
local config = addon.config;
local class = addon._class;
local noop = addon._noop;
local select = select;
local InCombatLockdown = InCombatLockdown;
local UnitAffectingCombat = UnitAffectingCombat;
local hooksecurefunc = hooksecurefunc;
local UIParent = UIParent;
local NUM_POSSESS_SLOTS = NUM_POSSESS_SLOTS or 10;

-- Create anchor frame for hybrid positioning system (like petbar.lua)
local anchor = CreateFrame('Frame', 'pUiTotemBarHolder', UIParent)
-- Set initial position - will be updated by totembar_update when config is ready
anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 52) -- Fallback position using default
anchor:SetSize(37, 37)

-- method update position using relative anchoring (hybrid system like petbar)
function anchor:totembar_update()
	if not InCombatLockdown() and not UnitAffectingCombat('player') then
		-- Read config values dynamically each time
		local offsetX = (addon.db.profile.additional.totem and addon.db.profile.additional.totem.x_position) or 0;
		local offsetY = (addon.db.profile.additional.totem and addon.db.profile.additional.totem.y_offset) or 0;
		
		-- Check if pretty_actionbar addon is loaded and use its positioning system
		if IsAddOnLoaded('pretty_actionbar') and _G.pUiMainBar then
			-- Use pretty_actionbar's exact logic (replicated from working petbar)
			local mainBar = _G.pUiMainBar;
			local leftbar = MultiBarBottomLeft and MultiBarBottomLeft:IsShown();
			local rightbar = MultiBarBottomRight and MultiBarBottomRight:IsShown();
			
			-- Values from configuration (compatible with pretty_actionbar)
			local nobar = 52;          -- Hardcoded optimal position for pretty_actionbar compatibility
			local leftbarOffset = addon.db.profile.additional.leftbar_offset or 90;  -- Offset when bottom left is shown  
			local rightbarOffset = addon.db.profile.additional.rightbar_offset or 40; -- Offset when bottom right is shown
			local leftOffset = nobar + leftbarOffset;   -- 142
			local rightOffset = nobar + rightbarOffset; -- 92
			
			self:ClearAllPoints();
			
			if leftbar and rightbar then
				-- Both bars shown, use leftOffset (positions above bottom right which is highest)
				self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, leftOffset + offsetY);
			elseif leftbar then
				-- Only left bar shown, use rightOffset (lower position)
				self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, rightOffset + offsetY);
			elseif rightbar then
				-- Only right bar shown, use leftOffset (higher position)
				self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, leftOffset + offsetY);
			else
				-- No extra bars, use default position
				self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, nobar + offsetY);
			end
		else
			-- Fallback to standard Blizzard frames (relative anchoring)
			local leftbar = MultiBarBottomLeft and MultiBarBottomLeft:IsShown();
			local rightbar = MultiBarBottomRight and MultiBarBottomRight:IsShown();
			local anchorFrame, anchorPoint, relativePoint, yOffset;
			
			if leftbar or rightbar then
				-- If extra bars are shown, anchor above the highest one
				if leftbar and rightbar then
					-- Both bars shown, bottom right is higher, so anchor to it
					anchorFrame = MultiBarBottomRight;
				elseif leftbar then
					anchorFrame = MultiBarBottomLeft;
				else
					anchorFrame = MultiBarBottomRight;
				end
				anchorPoint = 'TOP';
				relativePoint = 'BOTTOM';
				yOffset = 5 + offsetY; -- Add custom Y offset
			else
				-- No extra bars, anchor above main bar
				anchorFrame = addon.pUiMainBar or MainMenuBar;
				anchorPoint = 'TOP';
				relativePoint = 'BOTTOM';
				yOffset = 5 + offsetY; -- Add custom Y offset
			end
			
			self:ClearAllPoints();
			self:SetPoint(relativePoint, anchorFrame, anchorPoint, offsetX, yOffset);
		end
	end
end

-- Force totem bar initialization regardless of conditions
local function ForceTotemBarInitialization()
	if config and config.additional then
		-- Force anchor update
		if anchor and anchor.totembar_update then
			anchor:totembar_update()
		end
		-- Show anchor frame
		if anchor then
			anchor:Show()
		end
	end
end

-- Set initial position when DragonUI is fully initialized
addon.core.RegisterMessage(addon, "DRAGONUI_READY", ForceTotemBarInitialization);

-- Hook the main action bars to trigger repositioning when they show/hide
local MultiBarBottomLeft = _G["MultiBarBottomLeft"]
local MultiBarBottomRight = _G["MultiBarBottomRight"]

for _,bar in pairs({MultiBarBottomLeft,MultiBarBottomRight}) do
	if bar then
		bar:HookScript('OnShow',function()
			-- Combat protection - defer updates during combat
			if InCombatLockdown() or UnitAffectingCombat("player") then
				return
			end
			-- Update anchor position using hybrid system
			if anchor and anchor.totembar_update then
				anchor:totembar_update();
			end
		end);
		bar:HookScript('OnHide',function()
			-- Combat protection - defer updates during combat
			if InCombatLockdown() or UnitAffectingCombat("player") then
				return
			end
			-- Update anchor position using hybrid system
			if anchor and anchor.totembar_update then
				anchor:totembar_update();
			end
		end);
	end
end;

local possessbar = CreateFrame('Frame', 'pUiPossessBar', UIParent, 'SecureHandlerStateTemplate')
possessbar:SetAllPoints(anchor)  -- Anchor to our hybrid anchor frame
PossessBarFrame:SetParent(possessbar)
PossessBarFrame:SetClearPoint('BOTTOMLEFT', -68, 0)

local function possessbutton_position()
	-- Read config values dynamically
	local btnsize = config.additional.size;
	local space = config.additional.spacing;
	
	local button
	for index=1, NUM_POSSESS_SLOTS do
		button = _G['PossessButton'..index];
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

-- Register to call after all modules are loaded
addon.package:RegisterEvents(function()
	possessbutton_position();
end, 'PLAYER_LOGIN');

-- Additional late initialization when player is fully loaded
addon.package:RegisterEvents(function()
	-- Force initialization after a short delay when player enters world
	local initFrame = CreateFrame("Frame")
	local elapsed = 0
	initFrame:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed >= 1.0 then -- Wait 1 second after entering world
			self:SetScript("OnUpdate", nil)
			ForceTotemBarInitialization()
		end
	end)
end, 'PLAYER_ENTERING_WORLD');

-- Shaman-specific multicast handling
if MultiCastActionBarFrame and class == 'SHAMAN' then
	-- Clean up any existing scripts
	MultiCastActionBarFrame:SetScript('OnUpdate', nil)
	MultiCastActionBarFrame:SetScript('OnShow', nil)
	MultiCastActionBarFrame:SetScript('OnHide', nil)
	
	-- Parent to our possessbar and position it
	MultiCastActionBarFrame:SetParent(possessbar)
	MultiCastActionBarFrame:ClearAllPoints()
	MultiCastActionBarFrame:SetPoint('BOTTOMLEFT', possessbar, 'BOTTOMLEFT', 0, 0)
	
	-- Ensure multicast bar is visible for shamans
	MultiCastActionBarFrame:Show()
	
	-- Hook the multicast button update function
	hooksecurefunc('MultiCastActionButton_Update',function(actionButton)
		if not InCombatLockdown() then
			actionButton:SetAllPoints(actionButton.slotButton)
		end
	end);
	
	-- Disable Blizzard positioning
	MultiCastActionBarFrame.SetParent = noop;
	MultiCastActionBarFrame.SetPoint = noop;
	if MultiCastRecallSpellButton then
		MultiCastRecallSpellButton.SetPoint = noop;
	end
end

-- Refresh function for multicast/possess bar configuration changes
function addon.RefreshMulticast()
	-- Combat protection - defer updates during combat
	if InCombatLockdown() or UnitAffectingCombat("player") then
		return
	end
	
	-- Ensure we have a valid database before proceeding
	if not addon.db or not addon.db.profile or not addon.db.profile.additional then
		return
	end
	
	local btnsize = addon.db.profile.additional.size;
	local space = addon.db.profile.additional.spacing;
	
	-- Update button size and spacing for possess buttons
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
	
	-- Update multicast frame position (for shamans)
	if class == 'SHAMAN' and MultiCastActionBarFrame then
		-- Update multicast buttons (relative to MultiCastActionBarFrame)
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
		
		-- Update the recall button if it exists
		if MultiCastRecallSpellButton then
			MultiCastRecallSpellButton:SetSize(btnsize, btnsize);
		end
	end
	
	-- Update position using the hybrid anchoring system (like petbar)
	if anchor and anchor.totembar_update then
		anchor:totembar_update();
	end
end
