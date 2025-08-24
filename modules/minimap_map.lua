local addon = select(2,...);
local config = addon.config;
local atlas = addon.minimap_SetAtlas;
local shown = addon.minimap_SetShown;
local unpack = unpack;
local ipairs = ipairs;
local GetCVar = GetCVar;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;

-- const
local DEFAULT_MINIMAP_WIDTH = Minimap:GetWidth() * 1.36
local DEFAULT_MINIMAP_HEIGHT = Minimap:GetHeight() * 1.36
local BORDER_SIZE = 71*2 * 2^0.5
local blipScale = 1.12  -- Fixed scale for proper minimap layout (not configurable)
local blipDefault = 'interface\\MINIMAP\\OBJECTICONS'

Minimap.BorderTop = Minimap:CreateTexture(nil, 'OVERLAY')
local borderPoint = config.map.border_point
Minimap.BorderTop:SetPoint(borderPoint[1], borderPoint[2], borderPoint[3])
atlas(Minimap.BorderTop, 'ui-hud-minimap-bordertop', true)
-- Set border alpha dynamically
local borderAlpha = addon.db and addon.db.profile and addon.db.profile.map and addon.db.profile.map.border_alpha;
if borderAlpha == nil then
	borderAlpha = config.map.border_alpha;
end
Minimap.BorderTop:SetAlpha(borderAlpha)

-- poi
Minimap:SetStaticPOIArrowTexture(addon._dir..'poi-static')
Minimap:SetCorpsePOIArrowTexture(addon._dir..'poi-corpse')
Minimap:SetPOIArrowTexture(addon._dir..'poi-guard')
Minimap:SetPlayerTexture(addon._dir..'poi-player')
Minimap:SetPlayerTextureHeight(config.map.player_arrow_size);
Minimap:SetPlayerTextureWidth(config.map.player_arrow_size);
-- Set blip texture dynamically
local useNewBlipStyle = addon.db and addon.db.profile and addon.db.profile.map and addon.db.profile.map.blip_skin;
if useNewBlipStyle == nil then
	useNewBlipStyle = config.map.blip_skin;
end
Minimap:SetBlipTexture(useNewBlipStyle and addon._dir..'objecticons' or blipDefault)

-- mail
MiniMapMailBorder:SetTexture(nil)
MiniMapMailFrame:ClearAllPoints()
MiniMapMailFrame:SetPoint('BOTTOMLEFT', Minimap, 'BOTTOMLEFT', -4, -5)
atlas(MiniMapMailIcon, 'ui-hud-minimap-mail-up', true);

-- pvp
MiniMapBattlefieldIcon:Hide()
MiniMapBattlefieldBorder:Hide()
MiniMapBattlefieldFrame:SetSize(44, 44)
MiniMapBattlefieldFrame:ClearAllPoints()
MiniMapBattlefieldFrame:SetPoint('BOTTOMLEFT', Minimap, 0, 18)
MiniMapBattlefieldFrame:SetNormalTexture''
MiniMapBattlefieldFrame:SetPushedTexture''

local faction = strlower(UnitFactionGroup('player'))
atlas(MiniMapBattlefieldFrame:GetNormalTexture(), 'ui-hud-minimap-pvp-'..faction..'-up', true);
atlas(MiniMapBattlefieldFrame:GetPushedTexture(), 'ui-hud-minimap-pvp-'..faction..'-down', true);

MiniMapBattlefieldFrame:SetScript('OnClick', function(self, button)
	GameTooltip:Hide();
	if ( MiniMapBattlefieldFrame.status == "active") then
		if ( button == "RightButton" ) then
			ToggleDropDownMenu(1, nil, MiniMapBattlefieldDropDown, "MiniMapBattlefieldFrame", 0, -5);
		elseif ( IsShiftKeyDown() ) then
			ToggleBattlefieldMinimap();
		else
			ToggleWorldStateScoreFrame();
		end
	elseif ( button == "RightButton" ) then
		ToggleDropDownMenu(1, nil, MiniMapBattlefieldDropDown, "MiniMapBattlefieldFrame", 0, -5);
	end
end)

-- zoom button
atlas(MinimapZoomIn:GetNormalTexture(), 'ui-hud-minimap-zoom-in', true)
atlas(MinimapZoomIn:GetPushedTexture(), 'ui-hud-minimap-zoom-in-down', true)
atlas(MinimapZoomIn:GetDisabledTexture(), 'ui-hud-minimap-zoom-in-down', true)
atlas(MinimapZoomIn:GetHighlightTexture(), 'ui-hud-minimap-zoom-in-mouseover', true)
MinimapZoomIn:GetHighlightTexture():SetAlpha(.4)
MinimapZoomIn:GetHighlightTexture():SetBlendMode('ADD')
MinimapZoomIn:SetSize(20, 19)
MinimapZoomIn:ClearAllPoints()
MinimapZoomIn:SetPoint('CENTER', MinimapBackdrop, 'CENTER', 98, -33)

atlas(MinimapZoomOut:GetNormalTexture(), 'ui-hud-minimap-zoom-out', true)
atlas(MinimapZoomOut:GetPushedTexture(), 'ui-hud-minimap-zoom-out-down', true)
atlas(MinimapZoomOut:GetDisabledTexture(), 'ui-hud-minimap-zoom-out-down', true)
atlas(MinimapZoomOut:GetHighlightTexture(), 'ui-hud-minimap-zoom-out-mouseover', true)
MinimapZoomOut:GetHighlightTexture():SetAlpha(.4)
MinimapZoomOut:GetHighlightTexture():SetBlendMode('ADD')
MinimapZoomOut:SetSize(20, 10)
MinimapZoomOut:ClearAllPoints()
MinimapZoomOut:SetPoint('CENTER', MinimapBackdrop, 'CENTER', 80, -51)
MinimapZoomOut:SetHitRectInsets(0,0,0,0)

for _,obj in pairs{MinimapZoomIn,MinimapZoomOut} do shown(obj,config.map.zoom_in_out) end

-- noop
MiniMapWorldMapButton:Hide()
MiniMapWorldMapButton:UnregisterAllEvents()
MinimapNorthTag:SetAlpha(0)
MinimapBorder:Hide()
MinimapBorderTop:Hide()
MinimapCompassTexture:SetAlpha(0)

local MINIMAP_POINTS = {}
for i=1, Minimap:GetNumPoints() do
	MINIMAP_POINTS[i] = {Minimap:GetPoint(i)}
end

for _,regions in ipairs {Minimap:GetChildren()} do
	regions:SetScale(1/blipScale)
end

for _,points in ipairs(MINIMAP_POINTS) do
	Minimap:SetPoint(points[1], points[2], points[3], points[4]/blipScale, points[5]/blipScale)
end

function GetMinimapShape() return "ROUND" end

MinimapCluster:SetScale(config.map.scale)
MinimapCluster:EnableMouse(false)
MinimapCluster:ClearAllPoints()
MinimapCluster:SetPoint('TOPRIGHT', -24, -40)
MinimapCluster:SetHitRectInsets(30, 10, 0, 30)
MinimapCluster:SetFrameStrata('BACKGROUND')
MinimapBackdrop:EnableMouse(false)

-- MiniMap
Minimap:SetMaskTexture(addon._dir..'uiminimapmask.tga')
Minimap:SetWidth(DEFAULT_MINIMAP_WIDTH/blipScale)
Minimap:SetHeight(DEFAULT_MINIMAP_HEIGHT/blipScale)
Minimap:SetScale(blipScale)
Minimap:SetFrameLevel(MinimapCluster:GetFrameLevel() + 1)

Minimap.Circle = MinimapBackdrop:CreateTexture(nil, 'ARTWORK')
Minimap.Circle:SetSize(BORDER_SIZE, BORDER_SIZE)
Minimap.Circle:SetPoint('CENTER', Minimap, 'CENTER')
Minimap.Circle:SetTexture(addon._dir..'uiminimapborder.tga')

-- zone text
MinimapZoneText:ClearAllPoints()
MinimapZoneText:SetSize(120, 12)
MinimapZoneText:SetPoint('TOPLEFT', Minimap.BorderTop, 8, -2)
MinimapZoneText:SetFont(config.assets.font, config.map.zonetext_font_size)
MinimapZoneText:SetJustifyH('LEFT')
MinimapZoneText:SetJustifyV('MIDDLE')

MinimapZoneTextButton:ClearAllPoints()
MinimapZoneTextButton:SetPoint('TOPLEFT', Minimap.BorderTop, 8, 0)

-- tracking
MiniMapTracking:ClearAllPoints();
MiniMapTracking:SetPoint('TOPLEFT', Minimap.BorderTop, -28, 7)
MiniMapTrackingButton:ClearAllPoints();
MiniMapTrackingButton:SetPoint('CENTER', MiniMapTracking, 'CENTER')
MiniMapTrackingButtonShine:ClearAllPoints();
MiniMapTrackingButtonShine:SetPoint('CENTER', MiniMapTrackingButton)
MiniMapTrackingButtonBorder:SetTexture(nil)
MiniMapTrackingBackground:SetTexture(nil)

local function Tracking_Update()
	local texture = GetTrackingTexture();
	-- Use dynamic config if available, fallback to static config
	local useOldStyle = addon.db and addon.db.profile and addon.db.profile.map and addon.db.profile.map.tracking_icons;
	if useOldStyle == nil then
		useOldStyle = config.map.tracking_icons;
	end
	
	if useOldStyle then
		-- OLD STYLE: Show tracking icons like in original WoW
		if texture == 'Interface\\Minimap\\Tracking\\None' then
			-- No tracking selected: Show modern binoculars, hide old icon
			-- Clear old icon
			MiniMapTrackingIcon:SetTexture('');
			
			-- Setup modern button appearance
			MiniMapTrackingButton:SetSize(17, 15);
			atlas(MiniMapTrackingIcon, 'ui-hud-minimap-button', true);
			atlas(MiniMapTrackingButton:GetNormalTexture(), 'ui-hud-minimap-tracking-up');
			atlas(MiniMapTrackingButton:GetPushedTexture(), 'ui-hud-minimap-tracking-down');
			atlas(MiniMapTrackingButton:GetHighlightTexture(), 'ui-hud-minimap-tracking-mouseover');
			if MiniMapTrackingButton:GetHighlightTexture() then
				MiniMapTrackingButton:GetHighlightTexture():SetBlendMode('ADD')
			end
		else
			-- Tracking is selected: Show only the specific tracking icon, hide modern elements
			MiniMapTrackingIcon:SetSize(20, 20);
			MiniMapTrackingIcon:SetTexture(texture);
			MiniMapTrackingIcon:SetTexCoord(0,0,0,1,1,0,1,1);
			
			-- Clear modern button textures to avoid overlap, but keep button clickable
			MiniMapTrackingButton:SetNormalTexture('');
			MiniMapTrackingButton:SetPushedTexture('');
			if MiniMapTrackingButton:GetHighlightTexture() then
				MiniMapTrackingButton:GetHighlightTexture():SetTexture('');
			end
		end
	else
		-- MODERN STYLE: Always show modern binoculars button
		MiniMapTrackingButton:SetNormalTexture'';
		MiniMapTrackingButton:SetPushedTexture'';
		MiniMapTrackingButton:SetSize(17, 15);
		
		MiniMapTrackingIcon:ClearAllPoints();
		MiniMapTrackingIcon:SetPoint('CENTER', MiniMapTracking, 'CENTER', 0, 0);
		
		atlas(MiniMapTrackingIcon, 'ui-hud-minimap-button', true);
		atlas(MiniMapTrackingButton:GetNormalTexture(), 'ui-hud-minimap-tracking-up');
		atlas(MiniMapTrackingButton:GetPushedTexture(), 'ui-hud-minimap-tracking-down');
		atlas(MiniMapTrackingButton:GetHighlightTexture(), 'ui-hud-minimap-tracking-mouseover');
		
		MiniMapTrackingButton:GetHighlightTexture():SetBlendMode('ADD')
	end
	MiniMapTrackingIconOverlay:SetAlpha(0);
end
Tracking_Update();
MiniMapTrackingButton:HookScript('OnEvent', Tracking_Update)

-- LFG update
if (not IsAddOnLoaded('pretty_actionbar')) then
	MiniMapLFGFrame.eye.texture:SetTexture(addon._dir..'uigroupfinderflipbookeye.tga')
	MiniMapLFGFrameBorder:SetTexture(nil)
end

-- MiniMap rotate
local m_pi = math.pi
local m_cos = math.cos
local m_sin = math.sin
local function RotateBorder()
	local angle = GetPlayerFacing()
	Minimap.Circle:SetTexCoord(
		m_cos(angle + m_pi*3/4) + 0.5, -m_sin(angle + m_pi*3/4) + 0.5,
		m_cos(angle - m_pi*3/4) + 0.5, -m_sin(angle - m_pi*3/4) + 0.5,
		m_cos(angle + m_pi*1/4) + 0.5, -m_sin(angle + m_pi*1/4) + 0.5,
		m_cos(angle - m_pi*1/4) + 0.5, -m_sin(angle - m_pi*1/4) + 0.5
	)
end

local MinimapRotate = CreateFrame("Frame")
MinimapRotate:Hide()
MinimapRotate:SetScript("OnUpdate", RotateBorder)
hooksecurefunc('Minimap_UpdateRotationSetting',function()
	if (GetCVar("rotateMinimap") == "1") then
		MinimapRotate:Show()
		Minimap.Circle:SetSize(200 * 2^0.5, 200 * 2^0.5)
	else
		MinimapRotate:Hide()
		Minimap.Circle:SetTexCoord(0, 1, 0, 1)
		Minimap.Circle:SetSize(BORDER_SIZE, BORDER_SIZE)
	end
end)

-- mousewheel zooming
Minimap:EnableMouseWheel(true)
Minimap:SetScript('OnMouseWheel',function(self, delta)
	if delta > 0 then
		_G.MinimapZoomIn:Click()
	elseif delta < 0 then
		_G.MinimapZoomOut:Click()
	end
end)

-- Fix for minimap ping points not updating as your character moves.
-- Original code taken from AntiRadarJam by Lombra with permission.
do
	MinimapPing:HookScript("OnUpdate", function(self, elapsed)
		if self.fadeOut or self.timer > MINIMAPPING_FADE_TIMER then
			Minimap_SetPing(Minimap:GetPingPosition())
		end
	end)
end

-- Refresh function for minimap configuration changes
function addon.RefreshMinimap()
	if not Minimap then return end
	
	-- Update minimap cluster scale (not the minimap itself, which uses fixed blipScale)
	local scale = addon.db.profile.map.scale;
	if scale then
		MinimapCluster:SetScale(scale);
	end
	
	-- Update border alpha - use the correct border element we created
	local borderAlpha = addon.db.profile.map.border_alpha;
	if Minimap.BorderTop then
		Minimap.BorderTop:SetAlpha(borderAlpha);
	end
	
	-- Update blip skin (new/old style)
	local useNewBlipStyle = addon.db.profile.map.blip_skin;
	if useNewBlipStyle ~= nil then
		local blipTexture = useNewBlipStyle and addon._dir..'objecticons' or blipDefault;
		Minimap:SetBlipTexture(blipTexture);
	end
	
	-- Update player arrow size
	local arrowSize = addon.db.profile.map.player_arrow_size;
	if arrowSize then
		Minimap:SetPlayerTextureHeight(arrowSize);
		Minimap:SetPlayerTextureWidth(arrowSize);
		
		if MinimapCompassTexture then
			MinimapCompassTexture:SetSize(arrowSize, arrowSize);
		end
		if _G.Minimap.PlayerModel then
			_G.Minimap.PlayerModel:SetSize(arrowSize, arrowSize);
		end
	end
	
	-- Update tracking icons - handled entirely by Tracking_Update function
	if Tracking_Update then
		Tracking_Update();
	end
	
	-- Update zoom buttons
	local zoomButtons = addon.db.profile.map.zoom_in_out;
	if MinimapZoomIn and MinimapZoomOut then
		if zoomButtons then
			MinimapZoomIn:Show();
			MinimapZoomOut:Show();
		else
			MinimapZoomIn:Hide();
			MinimapZoomOut:Hide();
		end
	end
	
	-- Update zone text font size
	local zoneTextSize = addon.db.profile.map.zonetext_font_size;
	if zoneTextSize then
		if MinimapZoneText then
			local font = MinimapZoneText:GetFont();
			if font then
				MinimapZoneText:SetFont(font, zoneTextSize, "OUTLINE");
			end
		end
		if _G.MinimapCluster and _G.MinimapCluster.ZoneText then
			local font = _G.MinimapCluster.ZoneText:GetFont();
			if font then
				_G.MinimapCluster.ZoneText:SetFont(font, zoneTextSize, "OUTLINE");
			end
		end
	end
end

-- Fix quest tracker position to give more separation from minimap
local function FixQuestTrackerPosition(forceReposition)
	-- Quest tracker frames in WoW 3.3.5a
	local questFrames = {
		WatchFrame,
		_G.WatchFrame,
		_G.QuestWatchFrame,
		_G.ObjectiveTrackerFrame
	}
	
	for _, frame in pairs(questFrames) do
		if frame then
			-- Store original position if not already stored
			if not frame.originalPoints then
				frame.originalPoints = {}
				for i = 1, frame:GetNumPoints() do
					frame.originalPoints[i] = {frame:GetPoint(i)}
				end
			end
			
			-- Check if it needs repositioning - always reposition during initial load or when forced
			local needsReposition = forceReposition or false
			
			if not needsReposition then
				-- Check current position - if it's in the problematic area, reposition it
				for i = 1, frame:GetNumPoints() do
					local point, relative, relativePoint, x, y = frame:GetPoint(i)
					
					-- Check if positioned relative to minimap elements
					if relative and (
						relative == Minimap or 
						relative == MinimapCluster or 
						relative == MinimapBackdrop or
						(relative.GetName and relative:GetName() and string.find(relative:GetName(), "Minimap"))
					) then
						needsReposition = true
						break
					end
					
					-- Check if positioned in problematic coordinates (too close to minimap area)
					if relative == UIParent and x and y then
						-- Minimap is roughly at TOPRIGHT -24, -40 scaled, so avoid the area around it
						local minimapX = -24
						local minimapY = -40
						local minimapWidth = 200 -- approximate minimap cluster width
						local minimapHeight = 200 -- approximate minimap cluster height
						
						-- If quest tracker is positioned too close to minimap area, reposition it
						if x > (minimapX - minimapWidth) and x < (minimapX + 50) and 
						   y < (minimapY + 50) and y > (minimapY - minimapHeight) then
							needsReposition = true
							break
						end
					end
				end
			end
			
			-- Always reposition if needed or forced
			if needsReposition then
				frame:ClearAllPoints()
				-- Use dynamic config if available, fallback to default position
				local questTrackerX = addon.db and addon.db.profile and addon.db.profile.map and addon.db.profile.map.quest_tracker_x or -100
				local questTrackerY = addon.db and addon.db.profile and addon.db.profile.map and addon.db.profile.map.quest_tracker_y or -290
				frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", questTrackerX, questTrackerY)
				break -- Only handle the first valid frame found
			end
		end
	end
end

-- Function to refresh quest tracker position (for real-time config changes)
function addon:RefreshQuestTrackerPosition()
	-- When called from options, only update position without detection logic
	local questFrames = {
		WatchFrame,
		_G.WatchFrame,
		_G.QuestWatchFrame,
		_G.ObjectiveTrackerFrame
	}
	
	for _, frame in pairs(questFrames) do
		if frame then
			frame:ClearAllPoints()
			-- Use current config values
			local questTrackerX = addon.db.profile.map.quest_tracker_x or -100
			local questTrackerY = addon.db.profile.map.quest_tracker_y or -290
			frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", questTrackerX, questTrackerY)
			break -- Only handle the first valid frame found
		end
	end
end

-- Timer frame for delayed execution (WoW 3.3.5a compatible)
local questTrackerTimer = CreateFrame("Frame")
local questTrackerDelay = 0
questTrackerTimer:SetScript("OnUpdate", function(self, elapsed)
	questTrackerDelay = questTrackerDelay + elapsed
	if questTrackerDelay >= 1 then -- Reduced delay for faster application
		FixQuestTrackerPosition() -- Don't force when called from timer
		questTrackerDelay = 0
		self:Hide() -- Stop the timer
	end
end)

-- Apply quest tracker fix
local questTrackerFrame = CreateFrame("Frame")
questTrackerFrame:RegisterEvent("ADDON_LOADED")
questTrackerFrame:RegisterEvent("PLAYER_LOGIN")
questTrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
questTrackerFrame:RegisterEvent("QUEST_LOG_UPDATE")
questTrackerFrame:RegisterEvent("QUEST_WATCH_UPDATE")
questTrackerFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and select(1, ...) == "DragonUI" then
		-- Apply fix immediately and after a short delay
		FixQuestTrackerPosition()
		questTrackerDelay = 0
		questTrackerTimer:Show()
	elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		-- Apply fix when entering world in case position gets reset
		FixQuestTrackerPosition()
		questTrackerDelay = 0
		questTrackerTimer:Show()
	elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_WATCH_UPDATE" then
		-- Apply fix when quest tracker updates (in case it gets repositioned)
		FixQuestTrackerPosition()
	end
end)

-- Also apply fix immediately on file load
FixQuestTrackerPosition()
