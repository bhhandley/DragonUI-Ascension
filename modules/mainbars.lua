local addon = select(2,...);
local config = addon.config;
local event = addon.package;
local do_action = addon.functions;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local format = string.format;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup = UnitFactionGroup;
local _G = getfenv(0);

-- const
local faction = UnitFactionGroup('player');
local old = (config.style.xpbar == 'old');
local new = (config.style.xpbar == 'new');
local MainMenuBarMixin = {};
local pUiMainBar = CreateFrame(
	'Frame',
	'pUiMainBar',
	UIParent,
	'MainMenuBarUiTemplate'
);
local pUiMainBarArt = CreateFrame(
	'Frame',
	'pUiMainBarArt',
	pUiMainBar
);
pUiMainBar:SetScale(config.mainbars.scale_actionbar);
pUiMainBarArt:SetFrameStrata('HIGH');
pUiMainBarArt:SetFrameLevel(pUiMainBar:GetFrameLevel() + 4);
pUiMainBarArt:SetAllPoints(pUiMainBar);

-- [MEJORA] Nueva función de ayuda para gestionar el estilo de los grifos
local function UpdateGryphonStyle()
    -- Usamos addon.db.profile para que siempre lea la configuración más actual
    local db_style = addon.db and addon.db.profile and addon.db.profile.style
    if not db_style then db_style = config.style end -- Fallback a la config inicial si la DB no está lista

    local faction = UnitFactionGroup('player')

    if db_style.gryphons == 'old' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -85, -22)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 84, -22)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif db_style.gryphons == 'new' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -95, -23)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 95, -23)
        if faction == 'Alliance' then
            MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
            MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-right', true)
        else
            MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-left', true)
            MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
        end
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif db_style.gryphons == 'flying' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -80, -21)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 80, -21)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    else
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end
end

function MainMenuBarMixin:actionbutton_setup()
	for _,obj in ipairs({MainMenuBar:GetChildren(),MainMenuBarArtFrame:GetChildren()}) do
		obj:SetParent(pUiMainBar)
	end
	
	for index=1, NUM_ACTIONBAR_BUTTONS do
		pUiMainBar:SetFrameRef('ActionButton'..index, _G['ActionButton'..index])
	end
	
	for index=1, NUM_ACTIONBAR_BUTTONS -1 do
		local ActionButtons = _G['ActionButton'..index]
		do_action.SetThreeSlice(ActionButtons);
	end
	
	for index=2, NUM_ACTIONBAR_BUTTONS do
		local ActionButtons = _G['ActionButton'..index]
		ActionButtons:SetParent(pUiMainBar)
		ActionButtons:SetClearPoint('LEFT', _G['ActionButton'..(index-1)], 'RIGHT', 7, 0)
		
		local BottomLeftButtons = _G['MultiBarBottomLeftButton'..index]
		BottomLeftButtons:SetClearPoint('LEFT', _G['MultiBarBottomLeftButton'..(index-1)], 'RIGHT', 7, 0)
		
		local BottomRightButtons = _G['MultiBarBottomRightButton'..index]
		BottomRightButtons:SetClearPoint('LEFT', _G['MultiBarBottomRightButton'..(index-1)], 'RIGHT', 7, 0)
		
		local BonusActionButtons = _G['BonusActionButton'..index]
		BonusActionButtons:SetClearPoint('LEFT', _G['BonusActionButton'..(index-1)], 'RIGHT', 7, 0)
	end
end

function MainMenuBarMixin:actionbar_art_setup()
    -- art
    MainMenuBarArtFrame:SetParent(pUiMainBar)
    for _,art in pairs({MainMenuBarLeftEndCap, MainMenuBarRightEndCap}) do
        art:SetParent(pUiMainBarArt)
        art:SetDrawLayer('ARTWORK')
    end
    
    -- Apply background visibility (call the new function)
    self:update_main_bar_background()
    
    -- [MEJORA] Llamamos a la nueva función en lugar de tener el código aquí
    UpdateGryphonStyle()
end

function MainMenuBarMixin:update_main_bar_background()
    local alpha = (addon.db and addon.db.profile and addon.db.profile.buttons and addon.db.profile.buttons.hide_main_bar_background) and 0 or 1
    
    -- TU CÓDIGO ACTUAL QUE FUNCIONA (fondos de botones)
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G["ActionButton" .. i]
        if button then
            if button.NormalTexture then button.NormalTexture:SetAlpha(alpha) end
            for j = 1, button:GetNumRegions() do
                local region = select(j, button:GetRegions())
                if region and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" and region ~= button:GetNormalTexture() then
                    region:SetAlpha(alpha)
                end
            end
        end
    end
    
    
    if pUiMainBar then
        -- 1. Oculta las texturas sueltas dentro de pUiMainBar
        for i = 1, pUiMainBar:GetNumRegions() do
            local region = select(i, pUiMainBar:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                local texPath = region:GetTexture()
                if texPath and not string.find(texPath, "ICON") then
                    region:SetAlpha(alpha)
                end
            end
        end

        -- 2. Oculta las texturas de los frames hijos, PERO con más protecciones
        for i = 1, pUiMainBar:GetNumChildren() do
            local child = select(i, pUiMainBar:GetChildren())
            local name = child and child:GetName()
            
            -- PROTECCIONES COMPLETAS: Añadimos todos los elementos del micromenú
            if child and name ~= "pUiMainBarArt" 
                    and not string.find(name or "", "ActionButton")
                    and name ~= "MainMenuExpBar" 
                    and name ~= "ReputationWatchBar"
                    and name ~= "MultiBarBottomLeft"
                    and name ~= "MultiBarBottomRight"
                    and name ~= "MicroButtonAndBagsBar"
                    and not string.find(name or "", "MicroButton")  -- Protege todos los botones del micromenú
                    and not string.find(name or "", "Bag")          -- Protege las bolsas
                    and name ~= "CharacterMicroButton"
                    and name ~= "SpellbookMicroButton"
                    and name ~= "TalentMicroButton"
                    and name ~= "AchievementMicroButton"
                    and name ~= "QuestLogMicroButton"
                    and name ~= "SocialsMicroButton"
                    and name ~= "PVPMicroButton"
                    and name ~= "LFGMicroButton"
                    and name ~= "MainMenuMicroButton"
                    and name ~= "HelpMicroButton" then
                
                for j = 1, child:GetNumRegions() do
                    local region = select(j, child:GetRegions())
                    if region and region:GetObjectType() == "Texture" then
                        region:SetAlpha(alpha)
                    end
                end
            end
        end
    end
end


function MainMenuBarMixin:actionbar_setup()
	ActionButton1:SetParent(pUiMainBar)
	ActionButton1:SetClearPoint('BOTTOMLEFT', pUiMainBar, 2, 2)
	MultiBarBottomLeftButton1:SetClearPoint('BOTTOMLEFT', ActionButton1, 'BOTTOMLEFT', 0, 48)
	
	if config.buttons.pages.show then
		do_action.SetNumPagesButton(ActionBarUpButton, pUiMainBarArt, 'pageuparrow', 8)
		do_action.SetNumPagesButton(ActionBarDownButton, pUiMainBarArt, 'pagedownarrow', -14)
		
		MainMenuBarPageNumber:SetParent(pUiMainBarArt)
		MainMenuBarPageNumber:SetClearPoint('CENTER', ActionBarDownButton, -1, 12)
		local pagesFont = config.buttons.pages.font
		MainMenuBarPageNumber:SetFont(pagesFont[1], pagesFont[2], pagesFont[3])
		MainMenuBarPageNumber:SetShadowColor(0, 0, 0, 1)
		MainMenuBarPageNumber:SetShadowOffset(1.2, -1.2)
		MainMenuBarPageNumber:SetDrawLayer('OVERLAY', 7)
	else
		ActionBarUpButton:Hide();
		ActionBarDownButton:Hide();
		MainMenuBarPageNumber:Hide();
	end
	MultiBarBottomLeft:SetParent(pUiMainBar)
	MultiBarBottomRight:SetParent(pUiMainBar)
	MultiBarBottomRight:EnableMouse(false)
	MultiBarBottomRight:SetClearPoint('BOTTOMLEFT', MultiBarBottomLeftButton1, 'TOPLEFT', 0, 8)
	MultiBarRight:SetClearPoint('TOPRIGHT', UIParent, 'RIGHT', -6, (Minimap:GetHeight() * 1.3))
	MultiBarRight:SetScale(config.mainbars.scale_rightbar)
	MultiBarLeft:SetScale(config.mainbars.scale_leftbar)

	-- MultiBarLeft:SetParent(UIParent)
	MultiBarLeft:SetClearPoint('TOPRIGHT', MultiBarRight, 'TOPLEFT', -7, 0)
end

event:RegisterEvents(function()
	MainMenuBarPageNumber:SetText(GetActionBarPage());
end,
	'ACTIONBAR_PAGE_CHANGED'
);

function MainMenuBarMixin:statusbar_setup()
	for _,bar in pairs({MainMenuExpBar,ReputationWatchStatusBar}) do
		bar:GetStatusBarTexture():SetDrawLayer('BORDER')
		bar.status = bar:CreateTexture(nil, 'ARTWORK')
		if old then
			bar:SetSize(545, 10)
			bar.status:SetPoint('CENTER', 0, -1)
			bar.status:SetSize(545, 14)
			bar.status:set_atlas('ui-hud-experiencebar')
		elseif new then
			bar:SetSize(537, 10)
			bar.status:SetPoint('CENTER', 0, -2)
			bar.status:set_atlas('ui-hud-experiencebar-round', true)
			ReputationWatchStatusBar:SetStatusBarTexture(addon._dir..'statusbarfill.tga')
			ReputationWatchStatusBarBackground:set_atlas('ui-hud-experiencebar-background', true)
			ExhaustionTick:GetNormalTexture():set_atlas('ui-hud-experiencebar-frame-pip')
			ExhaustionTick:GetHighlightTexture():set_atlas('ui-hud-experiencebar-frame-pip-mouseover')
			ExhaustionTick:GetHighlightTexture():SetBlendMode('ADD')
		else
			bar.status:Hide()
		end
	end
	
	MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 0, 6)
	MainMenuExpBar:SetFrameLevel(10)
	ReputationWatchBar:SetParent(pUiMainBar)
	ReputationWatchBar:SetFrameLevel(10)
	ReputationWatchBar:SetWidth(ReputationWatchStatusBar:GetWidth())
	ReputationWatchBar:SetHeight(ReputationWatchStatusBar:GetHeight())
	
	MainMenuBarExpText:SetParent(MainMenuExpBar)
	MainMenuBarExpText:SetClearPoint('CENTER', MainMenuExpBar, 'CENTER', 0, old and 0 or 1)
	
	if new then
		for _,obj in pairs{MainMenuExpBar:GetRegions()} do 
			if obj:GetObjectType() == 'Texture' and obj:GetDrawLayer() == 'BACKGROUND' then
				obj:set_atlas('ui-hud-experiencebar-background', true)
			end
		end
	end
end

event:RegisterEvents(function(self)
	self:UnregisterEvent('PLAYER_ENTERING_WORLD');
	local exhaustionStateID = GetRestState();
	ExhaustionTick:SetParent(pUiMainBar);
	ExhaustionTick:SetFrameLevel(MainMenuExpBar:GetFrameLevel() +2);
	if new then
		ExhaustionLevelFillBar:SetHeight(MainMenuExpBar:GetHeight());
		ExhaustionLevelFillBar:set_atlas('ui-hud-experiencebar-fill-prediction');
		ExhaustionTick:SetSize(10, 14);
		ExhaustionTick:SetClearPoint('CENTER', ExhaustionLevelFillBar, 'RIGHT', 0, 2);

		MainMenuExpBar:SetStatusBarTexture(addon._dir..'uiexperiencebar');
		MainMenuExpBar:SetStatusBarColor(1, 1, 1, 1);
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
			MainMenuExpBar:GetStatusBarTexture():SetTexCoord(574/2048, 1137/2048, 34/64, 43/64);
			ExhaustionLevelFillBar:SetVertexColor(0.0, 0, 1, 0.45);
		elseif exhaustionStateID == 2 then
			MainMenuExpBar:GetStatusBarTexture():SetTexCoord(1/2048, 570/2048, 42/64, 51/64);
			ExhaustionLevelFillBar:SetVertexColor(0.58, 0.0, 0.55, 0.45);
		end
	else
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
		end
	end
end,
	'PLAYER_ENTERING_WORLD',
	'UPDATE_EXHAUSTION'
);



hooksecurefunc('ReputationWatchBar_Update',function()
	local name = GetWatchedFactionInfo();
	if name then
		local abovexp = config.xprepbar.repbar_abovexp_offset;
		local default = config.xprepbar.repbar_offset;
		ReputationWatchBar:SetClearPoint('BOTTOM', UIParent, 0, MainMenuExpBar:IsShown() and abovexp or default);
		ReputationWatchBarOverlayFrame:SetClearPoint('BOTTOM', UIParent, 0, MainMenuExpBar:IsShown() and abovexp or default);
		ReputationWatchStatusBar:SetHeight(10)
		ReputationWatchStatusBar:SetClearPoint('TOPLEFT', ReputationWatchBar, 0, 3)
		ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, old and 0 or 1);
		ReputationWatchStatusBarBackground:SetAllPoints(ReputationWatchStatusBar)
	end
end)

-- method update position
function pUiMainBar:actionbar_update()
	-- Read config values dynamically each time
	local db_xprepbar = addon.db.profile.xprepbar
	local both = db_xprepbar.bothbar_offset;
	local single = db_xprepbar.singlebar_offset;
	local nobar	= db_xprepbar.nobar_offset;

	
	
	local xpbar = MainMenuExpBar:IsShown();
	local repbar = ReputationWatchBar:IsShown();
	if not InCombatLockdown() and not UnitAffectingCombat('player') then
		if xpbar and repbar then
			self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, both);
		elseif xpbar then
			self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, single);
		elseif repbar then
			self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, single);
		else
			self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, nobar);
		end
	end
end

event:RegisterEvents(function()
	pUiMainBar:actionbar_update();
end,
	'PLAYER_LOGIN','ADDON_LOADED'
);

-- Set initial position when DragonUI is fully initialized
local function ForceInitialUpdate()
	pUiMainBar:actionbar_update();
end

addon.core.RegisterMessage(addon, "DRAGONUI_READY", ForceInitialUpdate);

local MainMenuExpBar = _G["MainMenuExpBar"]
local ReputationWatchBar = _G["ReputationWatchBar"]

for _,bar in pairs({MainMenuExpBar, ReputationWatchBar}) do
	if bar then
		bar:HookScript('OnShow',function()
			if not InCombatLockdown() and not UnitAffectingCombat('player') then
				pUiMainBar:actionbar_update();
			end
		end);
		bar:HookScript('OnHide',function()
			if not InCombatLockdown() and not UnitAffectingCombat('player') then
				pUiMainBar:actionbar_update();
			end
		end);
	end
end;

function addon.RefreshXpRepBarPosition()
	if pUiMainBar and pUiMainBar.actionbar_update then
		pUiMainBar:actionbar_update()
	end
end

function addon.RefreshRepBarPosition()
	if ReputationWatchBar_Update then
		ReputationWatchBar_Update()
	end
end

-- [NUEVO] Función para actualizar dinámicamente la posición de las barras superiores
function addon.RefreshUpperActionBarsPosition()
    if not MultiBarBottomLeftButton1 or not MultiBarBottomRight then return end

    -- Decide el desplazamiento vertical basado en la configuración
    local yOffset1, yOffset2
    if addon.db and addon.db.profile.buttons.hide_main_bar_background then
        -- Valores cuando el fondo está OCULTO (barras más cerca)
        yOffset1 = 45 -- Originalmente 48
        yOffset2 = 8  -- Originalmente 8
    else
        -- Valores por defecto cuando el fondo está VISIBLE
        yOffset1 = 48
        yOffset2 = 8
    end

    -- Vuelve a anclar las barras con el nuevo desplazamiento
    MultiBarBottomLeftButton1:SetClearPoint('BOTTOMLEFT', ActionButton1, 'BOTTOMLEFT', 0, yOffset1)
    MultiBarBottomRight:SetClearPoint('BOTTOMLEFT', MultiBarBottomLeftButton1, 'TOPLEFT', 0, yOffset2)
end

function MainMenuBarMixin:initialize()
	self:actionbutton_setup();
	self:actionbar_setup();
	self:actionbar_art_setup();
	self:statusbar_setup();
end
addon.pUiMainBar = pUiMainBar;
MainMenuBarMixin:initialize();

-- Refresh function for configuration changes
function addon.RefreshMainbars()
    if not pUiMainBar then return end
    
    local db_mainbars = addon.db.profile.mainbars
    local db_style = addon.db.profile.style
    local db_buttons = addon.db.profile.buttons
    
    -- Update scales
    pUiMainBar:SetScale(db_mainbars.scale_actionbar);
    if MultiBarLeft then MultiBarLeft:SetScale(db_mainbars.scale_leftbar); end
    if MultiBarRight then MultiBarRight:SetScale(db_mainbars.scale_rightbar); end
    if VehicleMenuBar then VehicleMenuBar:SetScale(db_mainbars.scale_vehicle); end
    
    -- Update Page Buttons visibility
    if db_buttons.pages.show then
        ActionBarUpButton:Show()
        ActionBarDownButton:Show()
        MainMenuBarPageNumber:Show()
    else
        ActionBarUpButton:Hide()
        ActionBarDownButton:Hide()
        MainMenuBarPageNumber:Hide()
    end

    -- Update main bar background visibility (call the new function)
    MainMenuBarMixin:update_main_bar_background()

	-- [NUEVO] Llama a la función de reposicionamiento de las barras superiores
    addon.RefreshUpperActionBarsPosition()

    -- Update XP bar style
    local old = (db_style.xpbar == 'old');
    local new = (db_style.xpbar == 'new');
    if old then
        if MainMenuExpBar then MainMenuExpBar:SetStatusBarTexture("Interface\\MainMenuBar\\UI-XP-Bar"); end
        if ReputationWatchStatusBar then ReputationWatchStatusBar:SetStatusBarTexture("Interface\\MainMenuBar\\UI-XP-Bar"); end
    elseif new then
        if MainMenuExpBar then MainMenuExpBar:SetStatusBarTexture("Interface\\MainMenuBar\\UI-ExperienceBar"); end
        if ReputationWatchStatusBar then ReputationWatchStatusBar:SetStatusBarTexture("Interface\\MainMenuBar\\UI-ExperienceBar"); end
    end
    
    -- [MEJORA] Llamamos a la nueva función en lugar de repetir todo el código
    UpdateGryphonStyle()
end