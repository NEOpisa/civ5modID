local MOD = arg[1]
local erros = 0
local chamadas = {}
local function marca(n) chamadas[n] = (chamadas[n] or 0) + 1 end

local function evento()
	local fs = {}
	return setmetatable({ Add = function(f) table.insert(fs, f) end }, { __call = function(_, ...) local r; for _, f in ipairs(fs) do r = f(...) end; return r end })
end
local function grupo()
	return setmetatable({}, { __index = function(t, k) local e = evento(); rawset(t, k, e); return e end })
end
Events, GameEvents, LuaEvents = grupo(), grupo(), grupo()

local dados = {}
Modding = { OpenSaveData = function() return { GetValue = function(k) return dados[k] end, SetValue = function(k, v) dados[k] = v end } end }
MapModData = {}
print_ = print
print = function(...) local s = table.concat({ ... }, " "); if s:find("EraDasIdeologias: ") then erros = erros + 1; print_("ERRO", s) end end

local function linhas(lista)
	local t = {}
	for i, l in ipairs(lista) do l.ID = i - 1; t[l.Type] = l; t[i - 1] = l end
	return setmetatable(t, { __call = function() local i = 0; return function() i = i + 1; return lista[i] end end })
end
dofile(arg[2])
GameInfo = {
	PolicyBranchTypes = linhas(FIXTURE.PolicyBranchTypes),
	Policies = linhas(FIXTURE.Policies),
	Eras = linhas({ { Type = "ERA_ANCIENT" }, { Type = "ERA_CLASSICAL" }, { Type = "ERA_MEDIEVAL" }, { Type = "ERA_RENAISSANCE" },
		{ Type = "ERA_INDUSTRIAL" }, { Type = "ERA_MODERN" }, { Type = "ERA_POSTMODERN" }, { Type = "ERA_FUTURE" } }),
	Buildings = linhas({ { Type = "BUILDING_NVG_TRIBO" }, { Type = "BUILDING_MONUMENT" }, { Type = "BUILDING_NVG_DESCONTO" } }),
	Beliefs = linhas({ { Type = "BELIEF_NVG_GUERRA_SANTA" } }),
	UnitPromotions = linhas({ { Type = "PROMOTION_NVG_GUERRA_SANTA" }, { Type = "PROMOTION_NVG_GUARDA" }, { Type = "PROMOTION_NVG_MILICIA" }, { Type = "PROMOTION_NVG_REBELDE" } }),
	Units = linhas({ { Type = "UNIT_WARRIOR" }, { Type = "UNIT_SPEARMAN", PrereqTech = "TECH_BRONZE" }, { Type = "UNIT_INFANTRY", PrereqTech = "TECH_X" }, { Type = "UNIT_SCIENTIST" }, { Type = "UNIT_PROPHET" } }),
	Technologies = linhas({ { Type = "TECH_BRONZE", Era = "ERA_ANCIENT" }, { Type = "TECH_X", Era = "ERA_MODERN" } }),
	Resources = linhas({ { Type = "RESOURCE_OIL" } }),
}
function include(nome) dofile(MOD .. "/Lua/NVGDados.lua") end
local alerta = {}
Controls = setmetatable({}, { __index = function(t, k)
	local c = setmetatable({}, { __index = function(_, m)
		if m == "SetText" then return function(_, x) alerta[k] = x end end
		if m == "SetHide" then return function(_, v) alerta[k .. "_oculto"] = v end end
		if m == "GetSizeX" or m == "GetSizeY" then return function() return 100 end end
		return function() end
	end })
	rawset(t, k, c)
	return c
end })
Mouse = { eLClick = 1 }
local quadro = function() end
ContextPtr = { SetUpdate = function(_, f) quadro = f end }
GameDefines = { MAX_MAJOR_CIVS = 22, MAX_CIV_PLAYERS = 63 }
NotificationTypes = { NOTIFICATION_GENERIC = 1 }
ChatTargetTypes = { CHATTARGET_ALL = 0, CHATTARGET_TEAM = 1, CHATTARGET_PLAYER = 2 }
Locale = { ConvertTextKey = function(k) return k end }

local turno = 0
local emRede = false
Game = {
	GetGameTurn = function() return turno end,
	Rand = function(n) return math.random(0, n - 1) end,
	IsNetworkMultiPlayer = function() return emRede end,
	GetActivePlayer = function() return 0 end,
	GetBeliefsInReligion = function() return { 0 } end,
}

local plots = {}
local function NovoPlot(x, y)
	local p = { x = x, y = y, unidades = {}, dono = -1 }
	local m = {}
	function m:GetX() return self.x end
	function m:GetY() return self.y end
	function m:IsWater() return false end
	function m:IsMountain() return false end
	function m:IsImpassable() return false end
	function m:IsCity() return self.cidade ~= nil end
	function m:GetPlotCity() return self.cidade end
	function m:GetNumUnits() return #self.unidades end
	function m:GetUnit(i) return self.unidades[i + 1] end
	function m:GetOwner() return self.dono end
	setmetatable(m, { __index = function(_, k) return function() marca("plot:" .. k) end end })
	return setmetatable(p, { __index = m })
end
Map = {
	GetPlot = function(x, y) if x < 0 or y < 0 or x > 20 or y > 20 then return nil end plots[x * 100 + y] = plots[x * 100 + y] or NovoPlot(x, y); return plots[x * 100 + y] end,
	PlotXYWithRangeCheck = function(x, y, dx, dy) return Map.GetPlot(x + dx, y + dy) end,
	GetNumPlots = function() return 441 end,
	GetPlotByIndex = function(i) return Map.GetPlot(i % 21, math.floor(i / 21)) end,
	RecalculateAreas = function() marca("RecalculateAreas") end,
}

local function NovaUnidade(dono, tipo, x, y)
	local u = { dono = dono, tipo = tipo, x = x, y = y, promos = {} }
	local m = {}
	function m:IsCombatUnit() return true end
	function m:IsHasPromotion(p) return self.promos[p] end
	function m:SetHasPromotion(p, v) self.promos[p] = v; marca("promo") end
	function m:GetX() return self.x end
	function m:GetY() return self.y end
	setmetatable(m, { __index = function(_, k) return function() marca("unit:" .. k) end end })
	setmetatable(u, { __index = m })
	table.insert(Map.GetPlot(x, y).unidades, u)
	return u
end

local function NovaCidade(dono, x, y, cap)
	local c = { dono = dono, x = x, y = y, pop = 6, cap = cap, predios = {} }
	local m = {}
	function m:GetX() return self.x end
	function m:GetY() return self.y end
	function m:GetID() return self.x * 100 + self.y end
	function m:GetName() return "Cidade" .. self.x end
	function m:IsCapital() return self.cap end
	function m:GetPopulation() return self.pop end
	function m:ChangePopulation(n) self.pop = self.pop + n end
	function m:SetPopulation(n) self.pop = n end
	function m:GetOwner() return self.dono end
	function m:GetNumRealBuilding(b) return self.predios[b] or 0 end
	function m:SetNumRealBuilding(b, n) self.predios[b] = n end
	function m:GetProductionNeeded() return 100 end
	function m:GetProduction() return 10 end
	setmetatable(m, { __index = function(_, k) return function() marca("city:" .. k) end end })
	setmetatable(c, { __index = m })
	Map.GetPlot(x, y).cidade = c
	return c
end

Teams = {}
Players = {}
local function DoRamo(pol)
	return pol.PolicyBranchType
end
local function NovoJogador(id, minor)
	local p = { id = id, ouro = 100, cidades = {}, unidades = {}, ramos = {}, pols = {}, era = 0, minor = minor, feliz = 5, anarquia = 0 }
	local m = {}
	function m:GetID() return self.id end
	function m:IsAlive() return true end
	function m:IsMinorCiv() return self.minor end
	function m:IsBarbarian() return self.id == 63 end
	function m:IsHuman() return self.id == 0 end
	function m:GetTeam() return self.id end
	function m:GetCurrentEra() return self.era end
	function m:IsPolicyBranchUnlocked(b) return self.ramos[b] or false end
	function m:SetPolicyBranchUnlocked(b, v) self.ramos[b] = v end
	function m:HasPolicy(i) return self.pols[i] or false end
	function m:SetHasPolicy(i, v) self.pols[i] = v end
	function m:IsPolicyBranchFinished(b)
		local tipo = GameInfo.PolicyBranchTypes[b].Type
		local n = 0
		for pol in GameInfo.Policies() do
			if pol.PolicyBranchType == tipo then
				n = n + 1
				if not self.pols[pol.ID] then return false end
			end
		end
		return n > 0
	end
	function m:ChangeAnarchyNumTurns(n) self.anarquia = self.anarquia + n end
	function m:GetGold() return self.ouro end
	function m:ChangeGold(n) self.ouro = self.ouro + n end
	function m:Cities() local i = 0; return function() i = i + 1; return self.cidades[i] end end
	function m:Units() local i = 0; return function() i = i + 1; return self.unidades[i] end end
	function m:GetCapitalCity() return self.cidades[1] end
	function m:InitUnit(t, x, y) local u = NovaUnidade(self.id, t, x, y); table.insert(self.unidades, u); return u end
	function m:InitCity(x, y) table.insert(self.cidades, NovaCidade(self.id, x, y, false)) end
	function m:GetCurrentResearch() return 0 end
	function m:GetReligionCreatedByPlayer() return 1 end
	function m:GetExcessHappiness() return self.feliz end
	function m:GetNickName() return "Neo" end
	function m:GetName() return "Jogador" .. self.id end
	function m:GetCivilizationShortDescription() return "Civ" .. self.id end
	function m:GetNumResourceTotal() return 2 end
	function m:IsTurnActive() return true end
	function m:AddNotification(_, texto, titulo) if self.id == 0 then table.insert(avisos, titulo) end end
	setmetatable(m, { __index = function(_, k) return function() marca("player:" .. k) end end })
	Players[id] = setmetatable(p, { __index = m })
	Teams[id] = setmetatable({}, { __index = function(_, k)
		if k == "IsHasMet" then return function() return true end end
		if k == "IsHasTech" then return function() return false end end
		if k == "IsAtWar" then return function() return true end end
		if k == "GetTeamTechs" then return function() return { ChangeResearchProgress = function() marca("ciencia") end } end end
		return function() marca("team:" .. k) end
	end })
end
avisos = {}
for i = 0, 3 do NovoJogador(i, false) end
NovoJogador(30, true)
NovoJogador(63, false)
Players[63].IsAlive = function() return false end
for i = 0, 3 do table.insert(Players[i].cidades, NovaCidade(i, 2 + i * 4, 5, true)); table.insert(Players[i].cidades, NovaCidade(i, 2 + i * 4, 10, false)) end

local function R(t) return GameInfo.PolicyBranchTypes[t].ID end
local function P(t) return GameInfo.Policies[t].ID end
local function Completar(pl, ramo)
	for pol in GameInfo.Policies() do if pol.PolicyBranchType == ramo then pl.pols[pol.ID] = true end end
end
local function Turno()
	turno = turno + 1
	for i = 0, 3 do GameEvents.PlayerDoTurn(i) end
	quadro()
end
local function ok(c, msg) if not c then erros = erros + 1; print_("FALHOU", msg) end end

local pendente = 0
LuaEvents.NVG_EvolucaoPendente.Add(function() pendente = pendente + 1 end)

dofile(MOD .. "/Lua/EraDasIdeologias.lua")
Events.LoadScreenClose()

ok(Players[2]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_NEUTRO")), "NEUTRO não liberado")
for _, t in ipairs({ "POLICY_BRANCH_NVG_E_ABSOLUTISMO", "POLICY_BRANCH_NVG_I_FASCISMO_CESARISMO", "POLICY_BRANCH_FREEDOM", "POLICY_BRANCH_NVG_NEUTRO" }) do
	ok(GameEvents.PlayerCanAdoptPolicyBranch(0, R(t)) == false, "dá para comprar " .. t)
end
ok(GameEvents.PlayerCanAdoptPolicyBranch(0, R("POLICY_BRANCH_HONOR")) == true, "Honra trancada")

Completar(Players[0], "POLICY_BRANCH_TRADITION")
Completar(Players[1], "POLICY_BRANCH_HONOR")
Turno()
ok(pendente > 0, "humano não recebeu aviso de evolução")
local evo1 = Players[1]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_ESTRATOCRACIA")) or Players[1]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_CESARISMO"))
ok(evo1, "IA não evoluiu Honra")
ok(not (Players[1]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_ESTRATOCRACIA")) and Players[1]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_CESARISMO"))), "IA ficou com as duas")

LuaEvents.NVG_Pedir({ a = "EVOLUIR", p = 0, t = R("POLICY_BRANCH_TRADITION"), v = 1 })
ok(Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_ABSOLUTISMO")), "Absolutismo não abriu")
ok(Players[0]:HasPolicy(P("POLICY_NVG_E_ABSOLUTISMO")), "abertura do Absolutismo não veio")
LuaEvents.NVG_Pedir({ a = "EVOLUIR", p = 0, t = R("POLICY_BRANCH_TRADITION"), v = 2 })
ok(not Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_PATRIMONIALISMO")), "abriu a segunda evolução")

local est = {}
LuaEvents.NVG_Consultar(0, est)
ok(not est.liberadas["POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO"], "liberou ideologia antes de completar")
LuaEvents.NVG_Pedir({ a = "ADOTAR", p = 0, t = R("POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO") })
ok(not Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO")), "adotou ideologia trancada")

Completar(Players[0], "POLICY_BRANCH_NVG_E_ABSOLUTISMO")
Turno()
est = {}
LuaEvents.NVG_Consultar(0, est)
ok(est.liberadas["POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO"], "Monarquia Constitucional não liberou")
ok(est.caminho == "POLICY_BRANCH_NVG_E_ABSOLUTISMO", "caminho errado: " .. tostring(est.caminho))
local ouro = Players[0].ouro
LuaEvents.NVG_Pedir({ a = "ADOTAR", p = 0, t = R("POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO") })
ok(Players[0]:HasPolicy(P("POLICY_NVG_I_MONARQUIA_CONST_ABSOLUTISMO")), "abertura da ideologia não veio")
ok(dados["NVG_P_0_POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO"] == 1, "presente não registrado")
ok(Players[0].ouro >= ouro + 200, "presente de ouro do Absolutismo não veio")
ok(Players[0].anarquia == 0, "anarquia na primeira ideologia")

Completar(Players[1], "POLICY_BRANCH_NVG_E_ESTRATOCRACIA")
Completar(Players[1], "POLICY_BRANCH_NVG_E_CESARISMO")
for _ = 1, 25 do Turno() end
est = {}
LuaEvents.NVG_Consultar(1, est)
ok(est.atual ~= nil, "IA não adotou ideologia")
LuaEvents.NVG_Consultar(0, est)
ok(est.tradicao >= 20, "tradição não cresceu: " .. tostring(est.tradicao))

local DESC = GameInfo.Buildings.BUILDING_NVG_DESCONTO.ID
ok(Players[0].cidades[1].predios[DESC] == 0, "desconto continuou depois da evolução")
ok(Players[3].cidades[1].predios[DESC] == 1, "sem desconto antes da evolução")
ok(Players[3].cidades[2].predios[DESC] ~= 1, "desconto fora da capital")

Completar(Players[0], "POLICY_BRANCH_HONOR")
Turno()
LuaEvents.NVG_Pedir({ a = "EVOLUIR", p = 0, t = R("POLICY_BRANCH_HONOR"), v = 1 })
Completar(Players[0], "POLICY_BRANCH_NVG_E_ESTRATOCRACIA")
Turno()
est = {}
LuaEvents.NVG_Consultar(0, est)
ok(not est.liberadas["POLICY_BRANCH_NVG_I_COMUNISMO_ESTRATOCRACIA"], "segunda evolução liberou ideologia")
ok(est.evolucoes == 2, "contagem de evoluções: " .. tostring(est.evolucoes))
LuaEvents.NVG_Pedir({ a = "ADOTAR", p = 0, t = R("POLICY_BRANCH_NVG_I_COMUNISMO_ESTRATOCRACIA") })
ok(not Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_I_COMUNISMO_ESTRATOCRACIA")), "adotou ideologia da segunda evolução")
ok(Players[0].anarquia == 0, "anarquia sem troca")

for _, par in ipairs({ { "POLICY_BRANCH_PIETY", 1 }, { "POLICY_BRANCH_COMMERCE", 2 } }) do
	Completar(Players[0], par[1])
	LuaEvents.NVG_Pedir({ a = "EVOLUIR", p = 0, t = R(par[1]), v = par[2] })
end
Completar(Players[0], "POLICY_BRANCH_RATIONALISM")
Turno()
est = {}
LuaEvents.NVG_Consultar(0, est)
ok(est.evolucoes == 4, "não chegou a 4 evoluções: " .. tostring(est.evolucoes))
ok(#est.pendentes == 0, "quinta evolução ficou pendente")
LuaEvents.NVG_Pedir({ a = "EVOLUIR", p = 0, t = R("POLICY_BRANCH_RATIONALISM"), v = 1 })
ok(not Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_POSITIVISMO")), "passou do limite de 4")

LuaEvents.NVG_Pedir({ a = "IDEOLOGIA", p = 0, t = R("POLICY_BRANCH_NVG_I_COMUNISMO_ESTRATOCRACIA") })
ok(Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_I_COMUNISMO_ESTRATOCRACIA")), "rede não forçou ideologia")
ok(not Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_I_MONARQUIA_CONST_ABSOLUTISMO")), "ideologia antiga continuou")
ok(not Players[0]:HasPolicy(P("POLICY_NVG_I_MONARQUIA_CONST_ABSOLUTISMO")), "abertura antiga continuou")

LuaEvents.NVG_Pedir({ a = "EVOLUCAO", p = 0, t = R("POLICY_BRANCH_NVG_E_PATRIMONIALISMO") })
ok(Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_PATRIMONIALISMO")) and not Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_ABSOLUTISMO")), "rede não trocou a evolução")

quadro()
local feitos = 0
LuaEvents.NVG_BSG_Feito.Add(function() feitos = feitos + 1 end)
local acoes = { "OURO", "FE", "CULTURA", "CIENCIA", "ERA_OURO", "POLITICAS", "INFLUENCIA", "TECH", "TECHS_ERA", "POLITICA",
	"IDEOLOGIA", "PRESENTE", "EVOLUCAO", "REVELAR", "GUERRA", "PAZ", "UNIDADE", "UNIDADE_APAGAR", "UNIDADE_CURAR", "UNIDADE_XP", "UNIDADE_PROMOCAO",
	"TERRENO", "RELEVO", "VEGETACAO", "RECURSO", "MELHORIA", "DONO_HEX", "CIDADE_CRIAR", "CIDADE_DONO", "CIDADE_POP", "CIDADE_PRODUCAO",
	"CIDADE_PREDIO", "CIDADE_RELIGIAO", "CIDADE_RESISTENCIA", "CIDADE_APAGAR", "EVENTO" }
for _, a in ipairs(acoes) do
	local alvo2 = a == "INFLUENCIA" and 30 or 1
	local x, y = 6, 10
	if a == "CIDADE_CRIAR" then x, y = 15, 15 end
	local t = 1
	if a == "IDEOLOGIA" or a == "PRESENTE" then t = R("POLICY_BRANCH_NVG_I_FASCISMO_CESARISMO") end
	if a == "EVOLUCAO" then t = R("POLICY_BRANCH_NVG_E_TEOCRACIA") end
	if a == "EVENTO" then t = 9 end
	LuaEvents.NVG_BSG_Pedir({ a = a, p = 0, q = alvo2, v = 3, t = t, x = x, y = y })
end
quadro()
ok(feitos == #acoes, "ações de rede: " .. feitos .. " de " .. #acoes)
ok(Players[0]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_I_FASCISMO_CESARISMO")), "rede não trocou ideologia")

emRede = true
local enviado
Network = { SendChat = function(texto) enviado = texto end }
LuaEvents.NVG_BSG_Pedir({ a = "OURO", p = 2, q = -1, v = 250, t = -1, x = -1, y = -1 })
local antes = Players[2].ouro
Events.GameMessageChat(0, -1, enviado, ChatTargetTypes.CHATTARGET_ALL)
ok(Players[2].ouro == antes, "aplicou antes do fim do turno")
LuaEvents.NVG_Pedir({ a = "EVOLUIR", p = 2, t = R("POLICY_BRANCH_HONOR"), v = 1 })
Completar(Players[2], "POLICY_BRANCH_HONOR")
Events.GameMessageChat(0, -1, enviado, ChatTargetTypes.CHATTARGET_ALL)
turno = turno + 1
GameEvents.PlayerDoTurn(0)
ok(Players[2].ouro >= antes + 250, "comando em rede não aplicou")
ok(not Players[2]:IsPolicyBranchUnlocked(R("POLICY_BRANCH_NVG_E_ESTRATOCRACIA")), "jogador 0 escolheu evolução do jogador 2")

print_("alerta:", alerta.AlertaTexto, "oculto:", alerta.Alerta_oculto)
print_("avisos ao humano:", #avisos)
for i = 1, #avisos do print_("  " .. avisos[i]) end
print_("ERROS:", erros)
os.exit(erros == 0 and 0 or 1)
