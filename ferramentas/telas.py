import os, re, sys

JOGO = os.path.expanduser("~/Games/SteamLibrary/steamapps/common/Sid Meier's Civilization V/steamassets/assets/dlc/expansion2/ui/ingame/popups")
RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "EraDasIdeologias", "Telas")

IDS = {'TRADITION': 0, 'LIBERTY': 1, 'HONOR': 2, 'PIETY': 3, 'PATRONAGE': 4, 'AESTHETICS': 5, 'COMMERCE': 6, 'EXPLORATION': 7, 'RATIONALISM': 8}

CLASSICAS = ["TRADITION", "LIBERTY", "HONOR", "PIETY", "PATRONAGE", "AESTHETICS", "COMMERCE", "EXPLORATION", "RATIONALISM"]


def trocar(s, a, b, n=1):
    if s.count(a) != n:
        sys.exit("trecho %r aparece %d vezes" % (a[:60], s.count(a)))
    return s.replace(a, b)


TOPO = '''include( "InstanceManager" );
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
'''

def original(nome):
    bak = os.path.join(JOGO, "..", "..", "..", "nvg_original", nome + ".orig")
    return bak if os.path.exists(bak) else os.path.join(JOGO, nome)


lua = open(original("socialpolicypopup.lua"), encoding="latin-1").read()
lua = trocar(lua, 'include( "InstanceManager" );', TOPO)
lua = trocar(lua, 'function GetPipe(branchType)\n\tlocal controlTable = nil;',
             'function GetPipe(branchType)\n\tlocal controlTable = nil;\n\tif NVG.variantes[branchType] then return NVG_CANO_NULO end\n\tbranchType = NVG_ORIGEM[branchType] or branchType;')
lua = trocar(lua, '\t\tif (iBranch ~= nil) then\n\t\t\t\n\t\t\tlocal controlTable = nil;\n',
             '\t\tif (iBranch ~= nil) then\n\t\t\t\n\t\t\tlocal controlTable = nil;\n\t\t\tlocal nvgRamo = iBranch;\n\t\t\tiBranch = NVG_ORIGEM[iBranch] or iBranch;\n')
lua = trocar(lua, '\t\t\t\t-- store this away for later\n\t\t\t\tpolicyIcons[i] = controlTable;',
             '\t\t\t\t-- store this away for later\n\t\t\t\tpolicyIcons[i] = controlTable;\n\t\t\t\tNVG_ICONES[nvgRamo] = NVG_ICONES[nvgRamo] or {};\n\t\t\t\ttable.insert(NVG_ICONES[nvgRamo], controlTable);')
lua = trocar(lua, 'if (iBranch ~= nil and not GameInfo.PolicyBranchTypes[iBranch].PurchaseByLevel) then',
             'if (iBranch ~= nil and policyIcons[i] ~= nil and not GameInfo.PolicyBranchTypes[iBranch].PurchaseByLevel) then')
ini = lua.index('\t-- Adjust Ideology')
fim = lua.index('\nend\nEvents.EventPoliciesDirty.Add( UpdateDisplay );')
lua = lua[:ini] + '\tNVG_Ajustar(player);' + lua[fim:]
lua = trocar(lua, 'Controls.ToIdeologyTab:RegisterCallback(Mouse.eLClick, function() TabSelect(g_Tabs["Ideologies"]) end);',
             'Controls.ToIdeologyTab:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_AbrirIdeologias() end);\n'
             'Controls.TabButtonIdeologies:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_AbrirIdeologias() end);\n'
             'LuaEvents.NVG_Atualizar.Add(function() if not ContextPtr:IsHidden() then UpdateDisplay() end end);')
open(os.path.join(SAIDA, "SocialPolicyPopup.lua"), "w", encoding="utf-8").write(lua)

xml = open(original("socialpolicypopup.xml"), encoding="latin-1").read()
for c in CLASSICAS:
    a = 'String="TXT_KEY_POLICY_BRANCH_%s_CAP" Font="TwCenMT20"' % c
    xml = trocar(xml, a, a + ' ID="NVGTitulo%d"' % IDS[c])
open(os.path.join(SAIDA, "SocialPolicyPopup.xml"), "w", encoding="utf-8").write(xml)

print("telas ok")
