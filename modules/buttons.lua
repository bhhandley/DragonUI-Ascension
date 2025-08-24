local addon = select(2,...);
local config = addon.config;
local action = addon.functions;
local unpack = unpack;
local select = select;
local format = string.format;
local match = string.match;
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS;
local NUM_SHAPESHIFT_SLOTS = NUM_SHAPESHIFT_SLOTS;
local NUM_POSSESS_SLOTS = NUM_POSSESS_SLOTS;
local VEHICLE_MAX_ACTIONBUTTONS = VEHICLE_MAX_ACTIONBUTTONS;
local hooksecurefunc = hooksecurefunc;
local GetName = GetName;
local _G = getfenv(0);

-- RANGE_INDICATOR = "•";

local actionbars = {
	'ActionButton',
	'MultiBarBottomLeftButton',
	'MultiBarBottomRightButton',
	'MultiBarRightButton',
	'MultiBarLeftButton',
};

addon.buttons_iterator = function()
	local index = 0
	local barIndex = 1
	return function()
		index = index + 1
		if index > 12 then
			index = 1
			barIndex = barIndex + 1
		end
		if actionbars[barIndex] then
			return _G[actionbars[barIndex]..index]
		end
	end
end

local function actionbuttons_grid()
	for index=1, NUM_ACTIONBAR_BUTTONS do
		local ActionButtons = _G[format('ActionButton%d', index)]
		ActionButtons:SetAttribute('showgrid', 1)
		ActionButton_ShowGrid(ActionButtons)
	end
end

local function is_petaction(self, name)
	local spec = self:GetName():match(name)
	if (spec) then return true else return false end
end

local function fix_texture(self, texture)
	if texture and texture ~= config.assets.normal then
		self:SetNormalTexture(config.assets.normal)
	end
end

local function setup_background(button, anchor, shadow)
	if not button or button.shadow then return; end
	if shadow and not button.shadow then
		local shadow = button:CreateTexture(nil, 'ARTWORK', nil, 1)
		shadow:SetPoint('TOPRIGHT', anchor, 3.8, 3.8)
		shadow:SetPoint('BOTTOMLEFT', anchor, -3.8, -3.8)
		shadow:set_atlas('ui-hud-actionbar-iconframe-flyoutbordershadow', true)
		button.shadow = shadow;
	end

	local background = button:CreateTexture(nil, 'BACKGROUND');
	background:SetAllPoints(anchor);
	background:set_atlas('ui-hud-actionbar-iconframe-slot');
	background:Show();
	
	return background;
end

local function actionbuttons_hotkey(button)
	if not button then return; end
	local buttonName = button:GetName();
	if not buttonName then return; end
	
	local hotkey = _G[buttonName..'HotKey'];
	if not hotkey then return; end
	
	local text = hotkey:GetText();
	if not text then return; end
	
	local db = addon.db.profile.buttons
	if not db or not db.hotkey then return end
	
	if RANGE_INDICATOR and text == RANGE_INDICATOR then
		if db.hotkey.range then
			hotkey:SetText(RANGE_INDICATOR);
		else
			hotkey:SetText'';
		end
	else
		hotkey:SetAlpha(db.hotkey.show and 1 or 0)
		
		if addon.GetKeyText then
			hotkey:SetText(addon.GetKeyText(text));
		else
			hotkey:SetText(text);
		end
		
		if db.hotkey.font then
			hotkey:SetFont(unpack(db.hotkey.font));
		end
		
		hotkey:SetShadowOffset(-1.3, -1.1);
		
		if db.hotkey.shadow then
			hotkey:SetShadowColor(unpack(db.hotkey.shadow));
		end
	end
end

local function main_buttons(button)
	if not button or button.__styled then return; end

	local name = button:GetName();
	local normal = _G[name..'NormalTexture'] or button:GetNormalTexture();
	local icon = _G[name..'Icon']
	local flash = _G[name..'Flash']
	local cooldown = _G[name..'Cooldown']
	local border = _G[name..'Border']
	
	normal:ClearAllPoints()
	normal:SetPoint('TOPRIGHT', button, 2.2, 2.3)
	normal:SetPoint('BOTTOMLEFT', button, -2.2, -2.2)
	normal:SetVertexColor(1, 1, 1, 1)
	normal:SetDrawLayer('OVERLAY')

	if flash then
		flash:set_atlas('ui-hud-actionbar-iconframe-flash')
	end

	if icon then
		icon:SetTexCoord(.05, .95, .05, .95)
		icon:SetDrawLayer('BORDER')
	end

	if cooldown then
		cooldown:ClearAllPoints()
		cooldown:SetAllPoints(button)
		cooldown:SetFrameLevel(button:GetParent():GetFrameLevel() +1)
	end
	
	if border then
		border:set_atlas('_ui-hud-actionbar-iconborder-checked')
		border:SetAllPoints(normal)
	end
	
	-- apply textures
	button:GetCheckedTexture():set_atlas('_ui-hud-actionbar-iconborder-checked')
	button:GetPushedTexture():set_atlas('_ui-hud-actionbar-iconborder-pushed')
	button:SetHighlightTexture(config.assets.highlight)
	button:GetCheckedTexture():SetAllPoints(normal)
	button:GetPushedTexture():SetAllPoints(normal)
	button:GetHighlightTexture():SetAllPoints(normal)
	button:GetCheckedTexture():SetDrawLayer('OVERLAY')
	button:GetPushedTexture():SetDrawLayer('OVERLAY')

	button.background = setup_background(button, normal, true)
	
	button.__styled = true
end

local function additional_buttons(button)
	if not button then return; end
	
	button:SetNormalTexture(config.assets.normal)
	if button.background then return; end

	local name = button:GetName();
	local icon = _G[name..'Icon']
	local flash = _G[name..'Flash']
	local normal = _G[name..'NormalTexture2'] or _G[name..'NormalTexture']
	local cooldown = _G[name..'Cooldown']
	local castable = _G[name..'AutoCastable']

	normal:ClearAllPoints()
	normal:SetPoint('TOPRIGHT', button, 2.2, 2.3)
	normal:SetPoint('BOTTOMLEFT', button, -2.2, -2.2)

	-- apply textures
	button:GetCheckedTexture():set_atlas('_ui-hud-actionbar-iconborder-checked')
	button:GetPushedTexture():set_atlas('_ui-hud-actionbar-iconborder-pushed')
	button:SetHighlightTexture(config.assets.highlight)
	button:GetCheckedTexture():SetAllPoints(normal)
	button:GetPushedTexture():SetAllPoints(normal)
	button:GetHighlightTexture():SetAllPoints(normal)

	if cooldown then
		cooldown:ClearAllPoints()
		cooldown:SetAllPoints(button)
		cooldown:SetFrameLevel(button:GetParent():GetFrameLevel() +1)
	end

	if icon then
		icon:SetTexCoord(.05, .95, .05, .95)
		icon:SetPoint('TOPRIGHT', button, 1, 1)
		icon:SetPoint('BOTTOMLEFT', button, -1, -1)
		icon:SetDrawLayer('BORDER')
	end

	if flash then
		flash:set_atlas('ui-hud-actionbar-iconframe-flash')
	end
	
	if castable then
		castable:ClearAllPoints()
		castable:SetPoint('TOP', 0, 14)
		castable:SetPoint('BOTTOM', 0, -15)
	end

	if is_petaction(button, 'PetActionButton') then
		hooksecurefunc(button, "SetNormalTexture", fix_texture)
	end
	button.background = setup_background(button, normal, false)
end

local function actionbuttons_update(button)
	if not button then return; end
	local name = button:GetName();
	if name:find('MultiCast') then return; end
	button:SetNormalTexture(config.assets.normal);
end

-- Refresh function for button configuration changes
function addon.RefreshButtons()
    local function safeRefresh()
        local db = addon.db.profile.buttons
        if not db then return end

        for button in addon.buttons_iterator() do
            if button and button.background then
                local buttonName = button:GetName()
                if buttonName then
                    local isMainActionButton = buttonName:match("^ActionButton%d+$")

                    -- Only Action Background
                    if db.only_actionbackground and not isMainActionButton then
                        button.background:Hide()
                    else
                        button.background:Show()
                    end

                    -- Hotkey & Range Indicator
                    pcall(actionbuttons_hotkey, button)

                    -- Macro text
                    local macros = _G[buttonName .. 'Name']
                    if macros and db.macros then
						if db.macros.show then
							macros:Show()
						else
							macros:Hide()
						end
                        if db.macros.color then macros:SetVertexColor(unpack(db.macros.color)) end
                        if db.macros.font then macros:SetFont(unpack(db.macros.font)) end
                    end

                    -- Count text
                    local count = _G[buttonName .. 'Count']
                    if count and db.count then
                        count:SetAlpha(db.count.show and 1 or 0)
                    end

                    -- Border color
                    local border = _G[buttonName .. 'Border']
                    if border and db.border_color then
                        border:SetVertexColor(unpack(db.border_color))
                    end
					
					-- Equipped action border
					if border then
						if IsEquippedAction(button.action) then
							border:SetAlpha(1)
						else
							border:SetAlpha(0)
						end
					end

					-- Force a full update of the button to refresh range indicators
					ActionButton_Update(button)
                end
            end
        end
    end

    pcall(safeRefresh)
end

-- main buttons
for button in addon.buttons_iterator() do
	main_buttons(button)
	button:SetSize(37, 37)
end

-- i really don't want to do it with a hook
addon.package:RegisterEvents(function()
	for button in addon.buttons_iterator() do
		actionbuttons_hotkey(button)
	end
end,
	'UPDATE_BINDINGS'
);

-- vehicle buttons
function addon.vehiclebuttons_template()
	if UnitHasVehicleUI('player') then
		for index=1, VEHICLE_MAX_ACTIONBUTTONS do
			main_buttons(_G['VehicleMenuBarActionButton'..index])
		end
	end
end

-- possess buttons
function addon.possessbuttons_template()
	for index=1, NUM_POSSESS_SLOTS do
		additional_buttons(_G['PossessButton'..index])
	end
end

-- petbar buttons
function addon.petbuttons_template()
	for index=1, NUM_PET_ACTION_SLOTS do
		additional_buttons(_G['PetActionButton'..index])
	end
end

-- stancebar buttons
function addon.stancebuttons_template()
	for index=1, NUM_SHAPESHIFT_SLOTS do
		additional_buttons(_G['ShapeshiftButton'..index])
	end
end

-- setup grid
local function actionbuttons_showgrid(button)
	local borderColor = config.buttons.border_color
	_G[button:GetName()..'NormalTexture']:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

addon.package:RegisterEvents(function()
	actionbuttons_grid();
	addon.RefreshButtons();
	collectgarbage();
end,
	'PLAYER_LOGIN'
);

hooksecurefunc('ActionButton_Update', actionbuttons_update);
hooksecurefunc('ActionButton_ShowGrid', actionbuttons_showgrid);
