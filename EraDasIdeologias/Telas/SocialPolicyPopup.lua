
-------------------------------------------------
-- SocialPolicy Chooser Popup
-------------------------------------------------

include( "IconSupport" );
include( "InstanceManager" );
include( "nvgdados" );

NVG_ORIGEM = {}
for classica, opcoes in pairs(NVG.evolucoes) do
	for _, e in ipairs(opcoes) do NVG_ORIGEM[e.tipo] = classica end
end

local NVG_NULO = setmetatable({}, { __index = function() return function() end end })
local NVG_CANO_NULO = { ConnectorImage = NVG_NULO }
local NVG_ICONES = {}

local NVG_FUNDOS = {
	CAPITALISMO = "SocialPoliciesFreedom.dds", SOCIALDEM = "SocialPoliciesFreedom.dds",
	LIBERTARIANISMO = "SocialPoliciesFreedom.dds", ECOLOGISMO = "SocialPoliciesFreedom.dds",
	COMUNISMO = "SocialPoliciesOrder.dds", ANARQUISMO = "SocialPoliciesOrder.dds", TECNOCRACIA = "SocialPoliciesOrder.dds",
	FASCISMO = "SocialPoliciesAutocracy.dds", MONARQUIA_CONST = "SocialPoliciesAutocracy.dds",
	FUNDAMENTALISMO = "SocialPoliciesAutocracy.dds",
}

local function NVG_Escolhida(player, classica)
	for _, e in ipairs(NVG.evolucoes[classica] or {}) do
		local linha = GameInfo.PolicyBranchTypes[e.tipo]
		if linha and player:IsPolicyBranchUnlocked(linha.ID) then return e end
	end
	return nil
end

local function NVG_Mostrar(lista, mostrar)
	for _, c in ipairs(lista or {}) do c.PolicyIcon:SetHide(not mostrar) end
end

local NVG_BACK = { POLICY_BRANCH_TRADITION = 0, POLICY_BRANCH_LIBERTY = 1, POLICY_BRANCH_HONOR = 2, POLICY_BRANCH_PIETY = 3,
	POLICY_BRANCH_PATRONAGE = 4, POLICY_BRANCH_RATIONALISM = 5, POLICY_BRANCH_EXPLORATION = 6, POLICY_BRANCH_COMMERCE = 7,
	POLICY_BRANCH_AESTHETICS = 8 }
local NVG_MAX = 4
local NVG_AVISADO = false

local function NVG_Tinta(base, forca)
	local c = NVG.cores[base]
	return { x = 1 - (1 - c.r) * forca, y = 1 - (1 - c.g) * forca, z = 1 - (1 - c.b) * forca, w = 1 }
end

local function NVG_Cor(base, texto) return "[COLOR_NVG_" .. base .. "]" .. texto .. "[ENDCOLOR]" end

function NVG_Ajustar(player)
	local usadas = 0
	for classica in pairs(NVG.evolucoes) do
		if NVG_Escolhida(player, classica) then usadas = usadas + 1 end
	end
	for classica in pairs(NVG.evolucoes) do
		local linha = GameInfo.PolicyBranchTypes[classica]
		local evo = NVG_Escolhida(player, classica)
		NVG_Mostrar(NVG_ICONES[classica], evo == nil)
		for _, e in ipairs(NVG.evolucoes[classica]) do NVG_Mostrar(NVG_ICONES[e.tipo], evo ~= nil and evo.tipo == e.tipo) end
		local ajuda = Locale.ConvertTextKey(evo and GameInfo.PolicyBranchTypes[evo.tipo].Help or linha.Help)
		local titulo = Controls["NVGTitulo" .. linha.ID]
		if titulo then
			titulo:SetText(evo and NVG_Cor(evo.ideologia, Locale.ToUpper(evo.nome)) or Locale.ConvertTextKey(linha.Description .. "_CAP"))
		end
		local fundo = Controls["BranchBack" .. NVG_BACK[classica]]
		if fundo then
			fundo:SetToolTipString(ajuda)
			if evo then fundo:SetColor(NVG_Tinta(evo.ideologia, 0.6)) end
		end
		local botao = Controls["BranchButton" .. linha.ID]
		local cadeado = Controls["Lock" .. linha.ID]
		if botao then
			if evo then
				botao:SetHide(false)
				botao:SetDisabled(false)
				botao:SetText(NVG_Cor(evo.ideologia, evo.nome))
				botao:SetToolTipString(ajuda)
				botao:RegisterCallback(Mouse.eLClick, function() end)
				if cadeado then cadeado:SetHide(true) end
			elseif player:IsPolicyBranchFinished(linha.ID) then
				botao:SetHide(false)
				if cadeado then cadeado:SetHide(true) end
				if usadas < NVG_MAX then
					botao:SetDisabled(false)
					botao:SetText("[COLOR_POSITIVE_TEXT]EVOLUIR[ENDCOLOR]")
					botao:SetToolTipString("Árvore completa: escolha 1 de 2 evoluções. A outra fecha para sempre.")
					botao:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_EscolherEvolucao(classica) end)
				else
					botao:SetDisabled(true)
					botao:SetText("Limite de evoluções")
					botao:SetToolTipString("Você já tem " .. NVG_MAX .. " evoluções, o máximo por partida.")
				end
			else
				botao:RegisterCallback(Mouse.eLClick, PolicyBranchSelected)
			end
		end
	end
	NVG_AVISADO = true

	local atual
	for tipo, v in pairs(NVG.variantes) do
		if player:IsPolicyBranchUnlocked(GameInfo.PolicyBranchTypes[tipo].ID) then atual = v end
	end
	Controls.IdeologyDetails:SetHide(false)
	Controls.IdeologyGenericHeader:SetHide(false)
	Controls.IdeologyHeader:SetText("Evoluções: " .. usadas .. " de " .. NVG_MAX)
	if atual then
		local nome = NVG.ideologias[atual.base].nome
		Controls.IdeologyImage1:SetTexture(NVG_FUNDOS[atual.base] or "PolicyBranch_Ideology.dds")
		Controls.IdeologyImage1:SetColor(NVG_Tinta(atual.base, 0.8))
		Controls.IdeologyGenericHeader:SetText(NVG_Cor(atual.base, Locale.ToUpper(nome)))
		local n = 0
		for _, p in ipairs(atual.politicas) do
			if player:HasPolicy(GameInfo.Policies[p].ID) then n = n + 1 end
		end
		Controls.Level1Tenets:SetText(n .. " de 5 políticas")
		Controls.Level2Tenets:SetText(player:HasPolicy(GameInfo.Policies[atual.final].ID) and "[COLOR_POSITIVE_TEXT]Completa[ENDCOLOR]" or "")
	else
		Controls.IdeologyImage1:SetTexture("PolicyBranch_Ideology.dds")
		Controls.IdeologyImage1:SetColor({ x = 1, y = 1, z = 1, w = 1 })
		Controls.IdeologyGenericHeader:SetText("IDEOLOGIA")
		Controls.Level1Tenets:SetText("Nenhuma ainda")
		Controls.Level2Tenets:SetText("Complete uma evolução")
	end
	Controls.Level3Tenets:SetText("")
	Controls.TenetsStack:CalculateSize()
	Controls.TenetsStack:ReprocessAnchoring()
end

include( "CommonBehaviors" );

local m_PopupInfo = nil;

local g_LibertyPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.LibertyPanel );
local g_TraditionPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.TraditionPanel );
local g_HonorPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.HonorPanel );
local g_PietyPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.PietyPanel );
local g_AestheticsPipeManager = InstanceManager:new ( "ConnectorPipe", "ConnectorImage", Controls.AestheticsPanel );
local g_PatronagePipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.PatronagePanel );
local g_CommercePipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.CommercePanel );
local g_ExplorationPipeManager = InstanceManager:new ( "ConnectorPipe", "ConnectorImage", Controls.ExplorationPanel );
local g_RationalismPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.RationalismPanel );

local g_LibertyInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.LibertyPanel );
local g_TraditionInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.TraditionPanel );
local g_HonorInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.HonorPanel );
local g_PietyInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.PietyPanel );
local g_AestheticsInstanceManager = InstanceManager:new ( "PolicyButton", "PolicyIcon", Controls.AestheticsPanel );
local g_PatronageInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.PatronagePanel );
local g_CommerceInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.CommercePanel );
local g_ExplorationInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.ExplorationPanel );
local g_RationalismInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.RationalismPanel );

local g_TenetInstanceManager = InstanceManager:new( "TenetChoice", "TenetButton", Controls.TenetStack );

include( "FLuaVector" );

local fullColor = {x = 1, y = 1, z = 1, w = 1};
local fadeColor = {x = 1, y = 1, z = 1, w = 0};
local fadeColorRV = {x = 1, y = 1, z = 1, w = 0.2};
local pinkColor = {x = 2, y = 0, z = 2, w = 1};
local lockTexture = "48Lock.dds";
local checkTexture = "48Checked.dds";

local hTexture = "Connect_H.dds";
local vTexture = "Connect_V.dds";

local topRightTexture =		"Connect_JonCurve_TopRight.dds"
local topLeftTexture =		"Connect_JonCurve_TopLeft.dds"
local bottomRightTexture =	"Connect_JonCurve_BottomRight.dds"
local bottomLeftTexture =	"Connect_JonCurve_BottomLeft.dds"

local policyIcons = {};

local g_PolicyXOffset = 28;
local g_PolicyYOffset = 68;

local g_PolicyPipeXOffset = 28;
local g_PolicyPipeYOffset = 68;

local m_gPolicyID;
local m_gAdoptingPolicy;

g_Tabs = {
	["SocialPolicies"] = {
		Button = Controls.TabButtonSocialPolicies,
		Panel = Controls.SocialPolicyPane,
		SelectHighlight = Controls.TabButtonSocialPoliciesHL,
	},
	
	["Ideologies"] = {
		Button = Controls.TabButtonIdeologies,
		Panel = Controls.IdeologyPane,
		SelectHighlight = Controls.TabButtonIdeologiesHL,
	},
}

local g_IdeologyBackgrounds = {
		[0] = "PolicyBranch_Ideology.dds",
		POLICY_BRANCH_AUTOCRACY = "SocialPoliciesAutocracy.dds",
		POLICY_BRANCH_FREEDOM = "SocialPoliciesFreedom.dds",
		POLICY_BRANCH_ORDER = "SocialPoliciesOrder.dds",
}

-------------------------------------------------
-- On Policy Selected
-------------------------------------------------
function PolicySelected( policyIndex )
    
    print("Clicked on Policy: " .. tostring(policyIndex));
    
	if policyIndex == -1 then
		return;
	end
    local player = Players[Game.GetActivePlayer()];   
    if player == nil then
		return;
    end
    
    local bHasPolicy = player:HasPolicy(policyIndex);
    local bCanAdoptPolicy = player:CanAdoptPolicy(policyIndex);
    
    print("bHasPolicy: " .. tostring(bHasPolicy));
    print("bCanAdoptPolicy: " .. tostring(bCanAdoptPolicy));
    print("Policy Blocked: " .. tostring(player:IsPolicyBlocked(policyIndex)));
    
    local bPolicyBlocked = false;
    
    -- If we can get this, OR we already have it, see if we can unblock it first
    if (bHasPolicy or bCanAdoptPolicy) then
    
		-- Policy blocked off right now? If so, try to activate
		if (player:IsPolicyBlocked(policyIndex)) then
			
			bPolicyBlocked = true;
			
			local strPolicyBranch = GameInfo.Policies[policyIndex].PolicyBranchType;
			local iPolicyBranch = GameInfoTypes[strPolicyBranch];
			
			print("Policy Branch: " .. tostring(iPolicyBranch));
			
			local popupInfo = {
				Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_POLICY_BRANCH_SWITCH,
				Data1 = iPolicyBranch;
			}
			Events.SerialEventGameMessagePopup(popupInfo);
			
		end
    end
    
    -- Can adopt Policy right now - don't try this if we're going to unblock the Policy instead
    if (bCanAdoptPolicy and not bPolicyBlocked) then
		m_gPolicyID = policyIndex;
		m_gAdoptingPolicy = true;
		Controls.PolicyConfirm:SetHide(false);
		Controls.BGBlock:SetHide(true);
	end
	
end

-------------------------------------------------
-- On Policy Branch Selected
-------------------------------------------------
function PolicyBranchSelected( policyBranchIndex )
    
    --print("Clicked on PolicyBranch: " .. tostring(policyBranchIndex));
    
	if policyBranchIndex == -1 then
		return;
	end
    local player = Players[Game.GetActivePlayer()];   
    if player == nil then
		return;
    end
    
    local bHasPolicyBranch = player:IsPolicyBranchUnlocked(policyBranchIndex);
    local bCanAdoptPolicyBranch = player:CanUnlockPolicyBranch(policyBranchIndex);
    
    --print("bHasPolicyBranch: " .. tostring(bHasPolicyBranch));
    --print("bCanAdoptPolicyBranch: " .. tostring(bCanAdoptPolicyBranch));
   -- print("PolicyBranch Blocked: " .. tostring(player:IsPolicyBranchBlocked(policyBranchIndex)));
    
    local bUnblockingPolicyBranch = false;
    
    -- If we can get this, OR we already have it, see if we can unblock it first
    if (bHasPolicyBranch or bCanAdoptPolicyBranch) then
    
		-- Policy Branch blocked off right now? If so, try to activate
		if (player:IsPolicyBranchBlocked(policyBranchIndex)) then
			
			bUnblockingPolicyBranch = true;
			
			local popupInfo = {
				Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_POLICY_BRANCH_SWITCH,
				Data1 = policyBranchIndex;
			}
			Events.SerialEventGameMessagePopup(popupInfo);
		end
    end
    
    -- Can adopt Policy Branch right now - don't try this if we're going to unblock the Policy Branch instead
    if (bCanAdoptPolicyBranch and not bUnblockingPolicyBranch) then
		m_gPolicyID = policyBranchIndex;
		m_gAdoptingPolicy = false;
		Controls.PolicyConfirm:SetHide(false);
		Controls.BGBlock:SetHide(true);
	end
end

-------------------------------------------------
-------------------------------------------------
function OnPopupMessage(popupInfo)
	
	local popupType = popupInfo.Type;
	if popupType ~= ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY then
		return;
	end
	
	m_PopupInfo = popupInfo;

	UpdateDisplay();
	
	if(m_PopupInfo.Data2 == 2) then
		TabSelect(g_Tabs["Ideologies"]);
	else
		TabSelect(g_Tabs["SocialPolicies"]);
	end
	
	if( m_PopupInfo.Data1 == 1 ) then
    	if( ContextPtr:IsHidden() == false ) then
    	    OnClose();
    	else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
    	end
	else
    	UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy );
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopupMessage );

-------------------------------------------------
-------------------------------------------------
function UpdateDisplay()

    local player = Players[Game.GetActivePlayer()];
   	CivIconHookup( player:GetID(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

	print ("In UpdateDisplay()");

    local pTeam = Teams[player:GetTeam()];
    
    if player == nil then
		return;
    end
    
    local playerHas1City = player:GetNumCities() > 0;
    
    local bShowAll = OptionsManager.GetPolicyInfo();
    
    local szText = Locale.ConvertTextKey("TXT_KEY_NEXT_POLICY_COST_LABEL", player:GetNextPolicyCost());
    Controls.NextCost:SetText(szText);
    
    szText = Locale.ConvertTextKey("TXT_KEY_CURRENT_CULTURE_LABEL", player:GetJONSCulture());
    Controls.CurrentCultureLabel:SetText(szText);
    
    szText = Locale.ConvertTextKey("TXT_KEY_CULTURE_PER_TURN_LABEL", player:GetTotalJONSCulturePerTurn());
    Controls.CulturePerTurnLabel:SetText(szText);
    
    local iTurns;
    local iCultureNeeded = player:GetNextPolicyCost() - player:GetJONSCulture();
    if (iCultureNeeded <= 0) then
		iTurns = 0;
    else
		if (player:GetTotalJONSCulturePerTurn() == 0) then
			iTurns = "?";
		else
			iTurns = iCultureNeeded / player:GetTotalJONSCulturePerTurn();
			iTurns = iTurns + 1;
			iTurns = math.floor(iTurns);
		end
    end
    szText = Locale.ConvertTextKey("TXT_KEY_NEXT_POLICY_TURN_LABEL", iTurns);
    Controls.NextPolicyTurnLabel:SetText(szText);
    
    -- Player Title
    local iDominantBranch = player:GetDominantPolicyBranchForTitle();
    if (iDominantBranch ~= -1) then
		
		local strTextKey = GameInfo.PolicyBranchTypes[iDominantBranch].Title;
		
		local strText = Locale.ConvertTextKey(strTextKey, player:GetNameKey(), player:GetCivilizationShortDescriptionKey());
		
	    Controls.PlayerTitleLabel:SetHide(false);
	    Controls.PlayerTitleLabel:SetText(strText);
	else
	    Controls.PlayerTitleLabel:SetHide(true);
    end
    
    -- Free Policies
    local iNumFreePolicies = player:GetNumFreePolicies();
    if (iNumFreePolicies > 0) then
	    szText = Locale.ConvertTextKey("TXT_KEY_FREE_POLICIES_LABEL", iNumFreePolicies);
	    Controls.FreePoliciesLabel:SetText( szText );
	    Controls.FreePoliciesLabel:SetHide( false );
	else
	    Controls.FreePoliciesLabel:SetHide( true );
    end
    
	Controls.InfoStack:ReprocessAnchoring();
	Controls.InfoStack2:ReprocessAnchoring();
    
	--szText = Locale.ConvertTextKey( "TXT_KEY_SOCIAL_POLICY_DIRECTIONS" );
    --Controls.ReminderText:SetText( szText );

	local justLooking = true;
	if player:GetJONSCulture() >= player:GetNextPolicyCost() then
		justLooking = false;
	end
	
	-- Adjust Policy Branches
	local i = 0;
	local numUnlockedBranches = player:GetNumPolicyBranchesUnlocked();
--	if numUnlockedBranches > 0 then
		local policyBranchInfo = GameInfo.PolicyBranchTypes[i];
		while policyBranchInfo ~= nil and not policyBranchInfo.PurchaseByLevel do
			local numString = tostring( i );
			
			local buttonName = "BranchButton"..numString;
			local backName = "BranchBack"..numString;
			local DisabledBoxName = "DisabledBox"..numString;
			local LockedBoxName = "LockedBox"..numString;
			local ImageMaskName = "ImageMask"..numString;
			local DisabledMaskName = "DisabledMask"..numString;
			--local EraLabelName = "EraLabel"..numString;
			
			local thisButton = Controls[buttonName];
			local thisBack = Controls[backName];
			local thisDisabledBox = Controls[DisabledBoxName];
			local thisLockedBox = Controls[LockedBoxName];
			
			local thisImageMask = Controls[ImageMaskName];
			local thisDisabledMask = Controls[DisabledMaskName];
			
			
			if(thisImageMask == nil) then
				print(ImageMaskName);
			end
			--local thisEraLabel = Controls[EraLabelName];
			
			local strToolTip = Locale.ConvertTextKey(policyBranchInfo.Help);
			
			-- Era Prereq
			local iEraPrereq = GameInfoTypes[policyBranchInfo.EraPrereq]
			local bEraLock = false;
			if (iEraPrereq ~= nil and pTeam:GetCurrentEra() < iEraPrereq) then
				bEraLock = true;
			else
				--thisEraLabel:SetHide(true);
			end
			
			local lockName = "Lock"..numString;
			local thisLock = Controls[lockName];
			
			-- Branch is not yet unlocked
			if not player:IsPolicyBranchUnlocked( i ) then
				
				-- Cannot adopt this branch right now
				if (policyBranchInfo.LockedWithoutReligion and Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)) then
					strToolTip = strToolTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_RELIGION");

				elseif (not player:CanUnlockPolicyBranch(i)) then
					
					strToolTip = strToolTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK");
					
					-- Not in prereq Era
					if (bEraLock) then
						local strEra = GameInfo.Eras[iEraPrereq].Description;
						strToolTip = strToolTip .. " " .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_ERA", strEra);
						
						-- Era Label
						--local strEraTitle = "[COLOR_WARNING_TEXT]" .. Locale.ConvertTextKey(strEra) .. "[ENDCOLOR]";
						local strEraTitle = Locale.ConvertTextKey(strEra);
						thisButton:SetText( strEraTitle );
						--thisEraLabel:SetText(strEraTitle);
						--thisEraLabel:SetHide( true );
						
						--thisButton:SetHide( true );
						
					-- Don't have enough Culture Yet
					else
						strToolTip = strToolTip .. " " .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_CULTURE", player:GetNextPolicyCost());
						thisButton:SetHide( false );
						thisButton:SetText( Locale.ConvertTextKey( "TXT_KEY_POP_ADOPT_BUTTON" ) );
						--thisEraLabel:SetHide( true );
					end
					
					thisLock:SetHide( false );
					thisButton:SetDisabled( true );
				-- Can adopt this branch right now
				else
					strToolTip = strToolTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_UNLOCK_SPEND", player:GetNextPolicyCost());
					thisLock:SetHide( true );
					--thisEraLabel:SetHide( true );
					thisButton:SetDisabled( false );
					thisButton:SetHide( false );
					thisButton:SetText( Locale.ConvertTextKey( "TXT_KEY_POP_ADOPT_BUTTON" ) );
				end
				
				if(not playerHas1City) then
					thisButton:SetDisabled(true);
				end
				
				thisBack:SetColor( fadeColor );
				thisLockedBox:SetHide(false);
				
				thisImageMask:SetHide(true);
				thisDisabledMask:SetHide(false);
				
			-- Branch is unlocked, but blocked by another branch
			elseif (player:IsPolicyBranchBlocked(i)) then
				thisButton:SetHide( false );
				thisBack:SetColor( fadeColor );
				thisLock:SetHide( false );
				thisLockedBox:SetHide(true);
				
				strToolTip = strToolTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_BLOCKED");
				
			-- Branch is unlocked already
			else
				thisButton:SetHide( true );
				thisBack:SetColor( fullColor );
				thisLockedBox:SetHide(true);
				
				thisImageMask:SetHide(false);
				thisDisabledMask:SetHide(true);
			end
			
			-- Update tooltips
			thisButton:SetToolTipString(strToolTip);
			
			-- If the player doesn't have the era prereq, then dim out the branch
			if (bEraLock) then
				thisDisabledBox:SetHide(false);
				thisLockedBox:SetHide(true);
			else
				thisDisabledBox:SetHide(true);
			end
			
			if (bShowAll) then
				thisDisabledBox:SetHide(true);
				thisLockedBox:SetHide(true);
			end
			
			i = i + 1;
			policyBranchInfo = GameInfo.PolicyBranchTypes[i];
		end
	--else
		--local policyBranchInfo = GameInfo.PolicyBranchTypes[i];
		--while policyBranchInfo ~= nil do
			--local numString = tostring(i);
			--local buttonName = "BranchButton"..numString;
			--local backName = "BranchBack"..numString;
			--local thisButton = Controls[buttonName];
			--local thisBack = Controls[backName];
			--thisBack:SetColor( fullColor );
			--thisButton:SetHide( true );
			--i = i + 1;
			--policyBranchInfo = GameInfo.PolicyBranchTypes[i];
		--end
	--end
	
	-- Adjust Policy buttons
	
	
	i = 0;
	local policyInfo = GameInfo.Policies[i];
	while policyInfo ~= nil do
		
		local iBranch = policyInfo.PolicyBranchType;
		
		-- If this is nil it means the Policy is a freebie handed out with the Branch, so don't display it
		if (iBranch ~= nil and policyIcons[i] ~= nil and not GameInfo.PolicyBranchTypes[iBranch].PurchaseByLevel) then
			
			local thisPolicyIcon = policyIcons[i];
			
			-- Tooltip
			local strTooltip = Locale.ConvertTextKey( policyInfo.Help );
			
			-- Player already has Policy
			if player:HasPolicy( i ) then
				--thisPolicyIcon.Lock:SetTexture( checkTexture ); 
				--thisPolicyIcon.Lock:SetHide( true ); 
				thisPolicyIcon.MouseOverContainer:SetHide( true );
				thisPolicyIcon.PolicyIcon:SetDisabled( true );
				--thisPolicyIcon.PolicyIcon:SetVoid1( -1 );
				thisPolicyIcon.PolicyImage:SetColor( fullColor );
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlasAchieved, thisPolicyIcon.PolicyImage );
			elseif(not playerHas1City) then
				--thisPolicyIcon.Lock:SetTexture( lockTexture ); 
				thisPolicyIcon.MouseOverContainer:SetHide( true );
				--thisPolicyIcon.Lock:SetHide( true ); 
				thisPolicyIcon.PolicyIcon:SetDisabled( true );
				--thisPolicyIcon.Lock:SetHide( false ); 
				--thisPolicyIcon.PolicyIcon:SetVoid1( -1 );
				thisPolicyIcon.PolicyImage:SetColor( fadeColorRV );
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlas, thisPolicyIcon.PolicyImage );
				-- Tooltip
				strTooltip = strTooltip .. "[NEWLINE][NEWLINE]"
			
			-- Can adopt the Policy right now
			elseif player:CanAdoptPolicy( i ) then
				--thisPolicyIcon.Lock:SetHide( true ); 
				thisPolicyIcon.MouseOverContainer:SetHide( false );
				thisPolicyIcon.PolicyIcon:SetDisabled( false );
				if justLooking then
					--thisPolicyIcon.PolicyIcon:SetVoid1( -1 );
					thisPolicyIcon.PolicyImage:SetColor( fullColor );
				else
					thisPolicyIcon.PolicyIcon:SetVoid1( i ); -- indicates policy to be chosen
					thisPolicyIcon.PolicyImage:SetColor( fullColor );
				end
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlas, thisPolicyIcon.PolicyImage );
				
			-- Policy is unlocked, but we lack culture
			elseif player:CanAdoptPolicy(i, true) then
				--thisPolicyIcon.Lock:SetTexture( lockTexture ); 
				thisPolicyIcon.MouseOverContainer:SetHide( true );
				--thisPolicyIcon.Lock:SetHide( true ); 
				thisPolicyIcon.PolicyIcon:SetDisabled( true );
				--thisPolicyIcon.Lock:SetHide( false ); 
				--thisPolicyIcon.PolicyIcon:SetVoid1( -1 );
				thisPolicyIcon.PolicyImage:SetColor( fadeColorRV );
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlas, thisPolicyIcon.PolicyImage );
				-- Tooltip
				strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_CULTURE", player:GetNextPolicyCost());
			else
				--thisPolicyIcon.Lock:SetTexture( lockTexture ); 
				thisPolicyIcon.MouseOverContainer:SetHide( true );
				--thisPolicyIcon.Lock:SetHide( true ); 
				thisPolicyIcon.PolicyIcon:SetDisabled( true );
				--thisPolicyIcon.Lock:SetHide( false ); 
				--thisPolicyIcon.PolicyIcon:SetVoid1( -1 );
				thisPolicyIcon.PolicyImage:SetColor( fadeColorRV );
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlas, thisPolicyIcon.PolicyImage );
				-- Tooltip
				strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_CANNOT_UNLOCK");
			end
			
			-- Policy is Blocked
			if player:IsPolicyBlocked(i) then
				thisPolicyIcon.PolicyImage:SetColor( fadeColorRV );
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlas, thisPolicyIcon.PolicyImage );
				
				-- Update tooltip if we have this Policy
				if player:HasPolicy( i ) then
					strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_BLOCKED");
				end
			end
				
			thisPolicyIcon.PolicyIcon:SetToolTipString( strTooltip );
		end
		
		i = i + 1;
		policyInfo = GameInfo.Policies[i];
	end
	
	NVG_Ajustar(player);
end
Events.EventPoliciesDirty.Add( UpdateDisplay );

-------------------------------------------------
-- On Tenet Selected
-------------------------------------------------
function TenetSelect(ideologyButtonNumber)

	if ideologyButtonNumber == nil then
		return;
	end

	local iLevel = math.floor(ideologyButtonNumber / 10);

    local player = Players[Game.GetActivePlayer()];   
    if player == nil then
		return;
	else
		Controls.ChooseTenet:SetHide(false);
		Controls.BGBlock:SetHide(true);
		
		g_TenetInstanceManager:ResetInstances();
		 
		local availableTenets = {};
		for i,v in ipairs(player:GetAvailableTenets(iLevel)) do
			local tenet = GameInfo.Policies[v];
			if (tenet ~= nil) then
				local entry = g_TenetInstanceManager:GetInstance();
				if (tenet.Help ~= nil) then
					entry.TenetLabel:LocalizeAndSetText(tenet.Help);
				else
					local szName = Locale.ConvertTextKey(tenet.Description);
					entry.TenetLabel:SetText("[COLOR_POSITIVE_TEXT]" .. szName .. "[ENDCOLOR]");
				end
				
				local tbW, tbH = entry.TenetButton:GetSizeVal();
				local tlW, tlH = entry.TenetLabel:GetSizeVal();
				
				local newHeight = tlH + 30;
				
				entry.TenetButton:SetSizeVal(tbW, newHeight);
				entry.Box:SetSizeVal(tbW, newHeight);
				
				entry.TenetButton:ReprocessAnchoring();
				
				entry.TenetButton:RegisterCallback(Mouse.eLClick, function()
					ChooseTenet(v, tenet.Description);
				end);
			end
		end
    end
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnCancel( )
	Controls.ChooseTenet:SetHide(true);
	Controls.BGBlock:SetHide(false);	
end
Controls.TenetCancelButton:RegisterCallback( Mouse.eLClick, OnCancel );
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnClose()
    UIManager:DequeuePopup( ContextPtr );
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

----------------------------------------------------------------
----------------------------------------------------------------
function OnPolicyInfo( bIsChecked )
	local bUpdateScreen = false;
	
	if (bIsChecked ~= OptionsManager.GetPolicyInfo()) then
		bUpdateScreen = true;
	end
	
    OptionsManager.SetPolicyInfo_Cached( bIsChecked );
    OptionsManager.CommitGameOptions();
    
    if (bUpdateScreen) then
		Events.EventPoliciesDirty();
	end
end
Controls.PolicyInfo:RegisterCheckHandler( OnPolicyInfo );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    ----------------------------------------------------------------        
    -- Key Down Processing
    ----------------------------------------------------------------        
    if uiMsg == KeyEvents.KeyDown then
        if (wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE) then
			if(Controls.PolicyConfirm:IsHidden() and Controls.TenetConfirm:IsHidden() and Controls.ChooseTenet:IsHidden() and Controls.ChangeIdeologyConfirm:IsHidden())then
	            OnClose();
	        else
				if(Controls.TenetConfirm:IsHidden()) then
					Controls.ChooseTenet:SetHide(true);
					Controls.PolicyConfirm:SetHide(true);
					Controls.BGBlock:SetHide(false);
				
				else
					Controls.TenetConfirm:SetHide(true);
				end
			end
			return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );

function GetPipe(branchType)
	local controlTable = nil;
	if NVG.variantes[branchType] then return NVG_CANO_NULO end
	branchType = NVG_ORIGEM[branchType] or branchType;
	-- decide which panel it goes on
	if branchType == "POLICY_BRANCH_LIBERTY" then
		controlTable = g_LibertyPipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_TRADITION" then
		controlTable = g_TraditionPipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_HONOR" then
		controlTable = g_HonorPipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_PIETY" then
		controlTable = g_PietyPipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_AESTHETICS" then
		controlTable = g_AestheticsPipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_PATRONAGE" then
		controlTable = g_PatronagePipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_COMMERCE" then
		controlTable = g_CommercePipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_EXPLORATION" then
		controlTable = g_ExplorationPipeManager:GetInstance();
	elseif branchType == "POLICY_BRANCH_RATIONALISM" then
		controlTable = g_RationalismPipeManager:GetInstance();
	end
	return controlTable;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Init()

	local bDisablePolicies = Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES);
	
	Controls.LabelPoliciesDisabled:SetHide(not bDisablePolicies);
	Controls.InfoStack:SetHide(bDisablePolicies);
	Controls.InfoStack2:SetHide(bDisablePolicies);
	
	-- Activate the Branch buttons
	local i = 0;
	local policyBranchInfo = GameInfo.PolicyBranchTypes[i];
	while policyBranchInfo ~= nil and not policyBranchInfo.PurchaseByLevel do
		local buttonName = "BranchButton"..tostring( i );
		local thisButton = Controls[buttonName];
		thisButton:SetVoid1( i ); -- indicates type
		thisButton:RegisterCallback( Mouse.eLClick, PolicyBranchSelected );
		i = i + 1;
		policyBranchInfo = GameInfo.PolicyBranchTypes[i];
	end

	-- add the pipes
	local policyPipes = {};
	for row in GameInfo.Policies() do
		policyPipes[row.Type] = 
		{
			upConnectionLeft = false;
			upConnectionRight = false;
			upConnectionCenter = false;
			upConnectionType = 0;
			downConnectionLeft = false;
			downConnectionRight = false;
			downConnectionCenter = false;
			downConnectionType = 0;
			yOffset = 0;
			policyType = row.Type;
		};
	end
	
	local cnxCenter = 1
	local cnxLeft = 2
	local cnxRight = 4

	-- Figure out which top and bottom adapters we need
	for row in GameInfo.Policy_PrereqPolicies() do
		local prereq = GameInfo.Policies[row.PrereqPolicy];
		local policy = GameInfo.Policies[row.PolicyType];
		if policy and prereq then
			if policy.GridX < prereq.GridX then
				policyPipes[policy.Type].upConnectionRight = true;
				policyPipes[prereq.Type].downConnectionLeft = true;
			elseif policy.GridX > prereq.GridX then
				policyPipes[policy.Type].upConnectionLeft = true;
				policyPipes[prereq.Type].downConnectionRight = true;
			else -- policy.GridX == prereq.GridX
				policyPipes[policy.Type].upConnectionCenter = true;
				policyPipes[prereq.Type].downConnectionCenter = true;
			end
			local yOffset = (policy.GridY - prereq.GridY) - 1;
			if yOffset > policyPipes[prereq.Type].yOffset then
				policyPipes[prereq.Type].yOffset = yOffset;
			end
		end
	end

	for pipeIndex, thisPipe in pairs(policyPipes) do
		if thisPipe.upConnectionLeft then
			thisPipe.upConnectionType = thisPipe.upConnectionType + cnxLeft;
		end 
		if thisPipe.upConnectionRight then
			thisPipe.upConnectionType = thisPipe.upConnectionType + cnxRight;
		end 
		if thisPipe.upConnectionCenter then
			thisPipe.upConnectionType = thisPipe.upConnectionType + cnxCenter;
		end 
		if thisPipe.downConnectionLeft then
			thisPipe.downConnectionType = thisPipe.downConnectionType + cnxLeft;
		end 
		if thisPipe.downConnectionRight then
			thisPipe.downConnectionType = thisPipe.downConnectionType + cnxRight;
		end 
		if thisPipe.downConnectionCenter then
			thisPipe.downConnectionType = thisPipe.downConnectionType + cnxCenter;
		end 
	end

	-- three passes down, up, connection
	-- connection
	for row in GameInfo.Policy_PrereqPolicies() do
		local prereq = GameInfo.Policies[row.PrereqPolicy];
		local policy = GameInfo.Policies[row.PolicyType];
		if policy and prereq then
		
			local thisPipe = policyPipes[row.PrereqPolicy];
		
			if policy.GridY - prereq.GridY > 1 or policy.GridY - prereq.GridY < -1 then
				local xOffset = (prereq.GridX-1)*g_PolicyPipeXOffset + 30;
				local pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset, (prereq.GridY-1)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(vTexture);
				local size = { x = 19; y = g_PolicyPipeYOffset*(policy.GridY - prereq.GridY - 1); };
				pipe.ConnectorImage:SetSize(size);
			end
			
			if policy.GridX - prereq.GridX == 1 then
				local xOffset = (prereq.GridX-1)*g_PolicyPipeXOffset + 30;
				local pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset + 16, (prereq.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(hTexture);
				local size = { x = 19; y = 19; };
				pipe.ConnectorImage:SetSize(size);
			end
			if policy.GridX - prereq.GridX == 2 then
				local xOffset = (prereq.GridX-1)*g_PolicyPipeXOffset + 30;
				local pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset + 16, (prereq.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(hTexture);
				local size = { x = 40; y = 19; };
				pipe.ConnectorImage:SetSize(size);
			end
			if policy.GridX - prereq.GridX == -2 then
				local xOffset = (policy.GridX-1)*g_PolicyPipeXOffset + 30;
				local pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset + 16, (prereq.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(hTexture);
				local size = { x = 40; y = 19; };
				pipe.ConnectorImage:SetSize(size);
			end
			if policy.GridX - prereq.GridX == -1 then
				local xOffset = (policy.GridX-1)*g_PolicyPipeXOffset + 30;
				local pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset + 16, (prereq.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(hTexture);
				local size = { x = 20; y = 19; };
				pipe.ConnectorImage:SetSize(size);
			end
			
		end
	end
	
	-- Down	
	for pipeIndex, thisPipe in pairs(policyPipes) do
		local policy = GameInfo.Policies[thisPipe.policyType];
		local xOffset = (policy.GridX-1)*g_PolicyPipeXOffset + 30;
		if thisPipe.downConnectionType >= 1 then
			
			local startPipe = GetPipe(policy.PolicyBranchType);
			startPipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 48 );
			startPipe.ConnectorImage:SetTexture(vTexture);
			
			local pipe = GetPipe(policy.PolicyBranchType);			
			if thisPipe.downConnectionType == 1 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(vTexture);
			elseif thisPipe.downConnectionType == 2 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomRightTexture);
			elseif thisPipe.downConnectionType == 3 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe = GetPipe(policy.PolicyBranchType);			
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomRightTexture);
			elseif thisPipe.downConnectionType == 4 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomLeftTexture);
			elseif thisPipe.downConnectionType == 5 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe = GetPipe(policy.PolicyBranchType);			
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomLeftTexture);
			elseif thisPipe.downConnectionType == 6 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomRightTexture);
				pipe = GetPipe(policy.PolicyBranchType);		
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomLeftTexture);
			else
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe = GetPipe(policy.PolicyBranchType);		
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomRightTexture);
				pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
				pipe.ConnectorImage:SetTexture(bottomLeftTexture);
			end
		end
	end

	-- Up
	for pipeIndex, thisPipe in pairs(policyPipes) do
		local policy = GameInfo.Policies[thisPipe.policyType];
		local xOffset = (policy.GridX-1)*g_PolicyPipeXOffset + 30;
		
		if thisPipe.upConnectionType >= 1 then
			
			local startPipe = GetPipe(policy.PolicyBranchType);
			startPipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 0 );
			startPipe.ConnectorImage:SetTexture(vTexture);
			
			local pipe = GetPipe(policy.PolicyBranchType);			
			if thisPipe.upConnectionType == 1 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(vTexture);
			elseif thisPipe.upConnectionType == 2 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topRightTexture);
			elseif thisPipe.upConnectionType == 3 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe = GetPipe(policy.PolicyBranchType);			
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topRightTexture);
			elseif thisPipe.upConnectionType == 4 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topLeftTexture);
			elseif thisPipe.upConnectionType == 5 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe = GetPipe(policy.PolicyBranchType);			
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topLeftTexture);
			elseif thisPipe.upConnectionType == 6 then
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topRightTexture);
				pipe = GetPipe(policy.PolicyBranchType);		
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topLeftTexture);
			else
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe = GetPipe(policy.PolicyBranchType);		
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topRightTexture);
				pipe = GetPipe(policy.PolicyBranchType);
				pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
				pipe.ConnectorImage:SetTexture(topLeftTexture);
			end
		end
	end

	-- Add Policy buttons
	i = 0;
	policyInfo = GameInfo.Policies[i];
	while policyInfo ~= nil do
		
		local iBranch = policyInfo.PolicyBranchType;
		
		-- If this is nil it means the Policy is a freebie handed out with the Branch, so don't display it
		if (iBranch ~= nil) then
			
			local controlTable = nil;
			local nvgRamo = iBranch;
			iBranch = NVG_ORIGEM[iBranch] or iBranch;
			
			-- decide which panel it goes on
			if iBranch == "POLICY_BRANCH_LIBERTY" then
				controlTable = g_LibertyInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_TRADITION" then
				controlTable = g_TraditionInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_HONOR" then
				controlTable = g_HonorInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_PIETY" then
				controlTable = g_PietyInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_AESTHETICS" then
				controlTable = g_AestheticsInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_PATRONAGE" then
				controlTable = g_PatronageInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_COMMERCE" then
				controlTable = g_CommerceInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_EXPLORATION" then
				controlTable = g_ExplorationInstanceManager:GetInstance();
			elseif iBranch == "POLICY_BRANCH_RATIONALISM" then
				controlTable = g_RationalismInstanceManager:GetInstance();
			end
			
			if (controlTable ~= nil) then
				IconHookup( policyInfo.PortraitIndex, 64, policyInfo.IconAtlas, controlTable.PolicyImage );

				-- this math should match Russ's mocked up layout
				controlTable.PolicyIcon:SetOffsetVal((policyInfo.GridX-1)*g_PolicyXOffset+16,(policyInfo.GridY-1)*g_PolicyYOffset+12);
				controlTable.PolicyIcon:SetVoid1( i ); -- indicates which policy
				controlTable.PolicyIcon:RegisterCallback( Mouse.eLClick, PolicySelected );
			
				-- store this away for later
				policyIcons[i] = controlTable;
				NVG_ICONES[nvgRamo] = NVG_ICONES[nvgRamo] or {};
				table.insert(NVG_ICONES[nvgRamo], controlTable);
			end
		end
		
		i = i + 1;
		policyInfo = GameInfo.Policies[i];
	end
	
end

function OnYes( )
	Controls.PolicyConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
	
	Network.SendUpdatePolicies(m_gPolicyID, m_gAdoptingPolicy, true);
	Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");		
	--Game.DoFromUIDiploEvent( FromUIDiploEventTypes.FROM_UI_DIPLO_EVENT_HUMAN_DECLARES_WAR, g_iAIPlayer, 0, 0 );
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );

function OnNo( )
	Controls.PolicyConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );


function ChooseTenet(tenet, name)
	g_SelectedTenet = tenet;
	Controls.LabelConfirmTenet:LocalizeAndSetText("TXT_KEY_POLICYSCREEN_CONFIRM_TENET", name);
	Controls.TenetConfirm:SetHide(false);
end

					
function OnTenetConfirmYes( )

	Controls.TenetConfirm:SetHide(true);
	Controls.ChooseTenet:SetHide(true);
	Controls.BGBlock:SetHide(false);
	
	Network.SendUpdatePolicies(g_SelectedTenet, true, true);
	Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");		
end
Controls.TenetConfirmYes:RegisterCallback( Mouse.eLClick, OnTenetConfirmYes );

function OnTenetConfirmNo( )
	Controls.TenetConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
end
Controls.TenetConfirmNo:RegisterCallback( Mouse.eLClick, OnTenetConfirmNo );


function ChooseChangeIdeology()
    local player = Players[Game.GetActivePlayer()];
	local iAnarchyTurns = GameDefines["SWITCH_POLICY_BRANCHES_ANARCHY_TURNS"];
	local eCurrentIdeology = player:GetLateGamePolicyTree();
	local iCurrentIdeologyTenets = player:GetNumPoliciesInBranch(eCurrentIdeology);
	local iPreferredIdeologyTenets = iCurrentIdeologyTenets - GameDefines["SWITCH_POLICY_BRANCHES_TENETS_LOST"];
	if (iPreferredIdeologyTenets < 0) then
		iPreferredIdeologyTenets = 0;
	end
	local iUnhappiness = player:GetPublicOpinionUnhappiness();
	local strCurrentIdeology = GameInfo.PolicyBranchTypes[eCurrentIdeology].Description;	
	local ePreferredIdeology = player:GetPublicOpinionPreferredIdeology();
	local strPreferredIdeology = GameInfo.PolicyBranchTypes[ePreferredIdeology].Description;
	Controls.LabelConfirmChangeIdeology:LocalizeAndSetText("TXT_KEY_POLICYSCREEN_CONFIRM_CHANGE_IDEOLOGY", iAnarchyTurns, iCurrentIdeologyTenets, strCurrentIdeology, iPreferredIdeologyTenets, strPreferredIdeology, iUnhappiness);
	Controls.ChangeIdeologyConfirm:SetHide(false);
end

function OnChangeIdeologyConfirmYes( )

	Controls.ChangeIdeologyConfirm:SetHide(true);
	Network.SendChangeIdeology();
	Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");	
end
Controls.ChangeIdeologyConfirmYes:RegisterCallback( Mouse.eLClick, OnChangeIdeologyConfirmYes );

function OnChangeIdeologyConfirmNo( )
	Controls.ChangeIdeologyConfirm:SetHide(true);
end
Controls.ChangeIdeologyConfirmNo:RegisterCallback( Mouse.eLClick, OnChangeIdeologyConfirmNo );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
    if( not bInitState ) then
        Controls.PolicyInfo:SetCheck( OptionsManager.GetPolicyInfo() );
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnActivePlayerChanged()
	if (not Controls.PolicyConfirm:IsHidden() or not Controls.TenetConfirm:IsHidden() or not Controls.ChangeIdeologyConfirm:IsHidden()) then
		Controls.TenetConfirm:SetHide(true);
		Controls.ChangeIdeologyConfirm:SetHide(true);
		Controls.PolicyConfirm:SetHide(true);
    	Controls.BGBlock:SetHide(false);
	end
	OnClose();
end
Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged);

Init();

-- Register tabbing behavior and assign global TabSelect routine.
TabSelect = RegisterTabBehavior(g_Tabs, g_Tabs["SocialPolicies"]);

Controls.ToIdeologyTab:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_AbrirIdeologias() end);
Controls.TabButtonIdeologies:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_AbrirIdeologias() end);
LuaEvents.NVG_Atualizar.Add(function() if not ContextPtr:IsHidden() then UpdateDisplay() end end);