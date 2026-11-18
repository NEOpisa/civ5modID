include("nvgdados")

NVG_SINAL = { sujo = false, evo = false, feitos = {} }

local SD
do
	local ok, d = pcall(function() return Modding.OpenSaveData() end)
	if ok and d then
		SD = d
	else
		local memoria = {}
		SD = { GetValue = function(k) return memoria[k] end, SetValue = function(k, v) memoria[k] = v end }
	end
end
local BARBARO = 63

local function Valor(k, padrao)
	local v = SD.GetValue(k)
	if v == nil then return padrao end
	return v
end
local function Guardar(k, v) SD.SetValue(k, v) end

local function Seguro(f, ...)
	local ok, erro = pcall(f, ...)
	if not ok then print("EraDasIdeologias: " .. tostring(erro)) end
	return ok
end

local function Id(tabela, tipo)
	local linha = GameInfo[tabela] and GameInfo[tabela][tipo]
	return linha and linha.ID or -1
end

local function Aleatorio(n)
	if n <= 1 then return 0 end
	return Game.Rand(n, "EraDasIdeologias")
end

local RAMO = {}
for linha in GameInfo.PolicyBranchTypes() do RAMO[linha.Type] = linha.ID end

local NEUTRO = "POLICY_BRANCH_NVG_NEUTRO"
EVOLUCAO = {}
VARIANTE = NVG.variantes
local BLOQUEADO = { [NEUTRO] = true, POLICY_BRANCH_FREEDOM = true, POLICY_BRANCH_ORDER = true, POLICY_BRANCH_AUTOCRACY = true }
for classica, opcoes in pairs(NVG.evolucoes) do
	for i, e in ipairs(opcoes) do
		EVOLUCAO[e.tipo] = { classica = classica, indice = i, nome = e.nome, ideologia = e.ideologia, chave = e.chave,
			variante = "POLICY_BRANCH_NVG_I_" .. e.ideologia .. "_" .. e.chave }
		BLOQUEADO[e.tipo] = true
	end
end
for tipo in pairs(VARIANTE) do BLOQUEADO[tipo] = true end

local ERA_CLASSICA = Id("Eras", "ERA_CLASSICAL")
local TRIBO = Id("Buildings", "BUILDING_NVG_TRIBO")

local function Era(p) return math.max(0, p:GetCurrentEra()) end
local function Mult(p) return Era(p) + 1 end

local function Majors()
	local lista = {}
	for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
		local p = Players[i]
		if p and p:IsAlive() and not p:IsMinorCiv() and not p:IsBarbarian() then table.insert(lista, p) end
	end
	return lista
end

local function Avisar(p, titulo, texto, x, y)
	if p and p:IsHuman() then
		p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, texto, titulo, x or -1, y or -1)
	end
end

local function AvisarTodos(titulo, texto, x, y)
	for _, p in ipairs(Majors()) do Avisar(p, titulo, texto, x, y) end
end

local function NomeRamo(tipo)
	local linha = GameInfo.PolicyBranchTypes[tipo]
	return linha and Locale.ConvertTextKey(linha.Description) or tipo
end

local function VarianteAtual(p)
	for tipo in pairs(VARIANTE) do
		if p:IsPolicyBranchUnlocked(RAMO[tipo]) then return tipo end
	end
	return nil
end

local function Ideologia(p)
	local v = VarianteAtual(p)
	return v and VARIANTE[v].base or nil
end

local function NomeIdeologia(base) return NVG.ideologias[base] and NVG.ideologias[base].nome or base end

local function Ciencia(p, n)
	local tech = p:GetCurrentResearch()
	if tech and tech >= 0 then
		Teams[p:GetTeam()]:GetTeamTechs():ChangeResearchProgress(tech, n, p:GetID())
		return true
	end
	return false
end

local function LugarLivre(x, y, raio)
	raio = raio or 2
	for r = 1, raio do
		for dx = -r, r do
			for dy = -r, r do
				local plot = Map.PlotXYWithRangeCheck(x, y, dx, dy, r)
				if plot and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable()
					and not plot:IsCity() and plot:GetNumUnits() == 0 then
					return plot
				end
			end
		end
	end
	return nil
end

local function MelhorUnidade(p, lista)
	local escolhida = -1
	for _, tipo in ipairs(lista) do
		local u = GameInfo.Units[tipo]
		if u then
			local tech = u.PrereqTech and GameInfo.Technologies[u.PrereqTech]
			if not tech or Teams[p:GetTeam()]:IsHasTech(tech.ID) then escolhida = u.ID end
		end
	end
	return escolhida
end

local INFANTARIA = { "UNIT_WARRIOR", "UNIT_SPEARMAN", "UNIT_SWORDSMAN", "UNIT_PIKEMAN", "UNIT_LONGSWORDSMAN",
	"UNIT_MUSKETMAN", "UNIT_RIFLEMAN", "UNIT_GREAT_WAR_INFANTRY", "UNIT_INFANTRY", "UNIT_MECHANIZED_INFANTRY" }

local function CriarPerto(p, unidade, x, y, promocao)
	local plot = LugarLivre(x, y, 3)
	if not plot or unidade < 0 then return nil end
	local u = p:InitUnit(unidade, plot:GetX(), plot:GetY())
	if u and promocao then
		local pr = Id("UnitPromotions", promocao)
		if pr >= 0 then u:SetHasPromotion(pr, true) end
	end
	return u
end

local function Capital(p) return p:GetCapitalCity() end

local function PromoverExercito(p, promocao)
	local pr = Id("UnitPromotions", promocao)
	if pr < 0 then return end
	for u in p:Units() do
		if u:IsCombatUnit() and not u:IsHasPromotion(pr) then u:SetHasPromotion(pr, true) end
	end
end

local function Tropas(p, n, promocao)
	local c = Capital(p)
	if not c then return end
	local u = MelhorUnidade(p, INFANTARIA)
	for _ = 1, n do CriarPerto(p, u, c:GetX(), c:GetY(), promocao) end
end

local function Presentear(p, d)
	if d.ouro then p:ChangeGold(d.ouro) end
	if d.fe then p:ChangeFaith(d.fe) end
	if d.cultura then p:ChangeJONSCulture(d.cultura) end
	if d.ciencia then Ciencia(p, d.ciencia) end
	if d.eraouro then p:ChangeGoldenAgeTurns(d.eraouro) end
	if d.pop then for cidade in p:Cities() do cidade:ChangePopulation(d.pop, true) end end
	if d.producao then for cidade in p:Cities() do cidade:ChangeProduction(d.producao) end end
	if d.influencia then
		for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
			local m = Players[i]
			if m and m:IsAlive() and m:IsMinorCiv() and Teams[p:GetTeam()]:IsHasMet(m:GetTeam()) then
				m:ChangeMinorCivFriendshipWithMajor(p:GetID(), d.influencia)
			end
		end
	end
	if d.tropas then Tropas(p, d.tropas.n, d.tropas.promo) end
	local c = Capital(p)
	if c and d.unidades then
		for _, u in ipairs(d.unidades) do
			local id = Id("Units", u.tipo)
			for _ = 1, u.n do CriarPerto(p, id, c:GetX(), c:GetY()) end
		end
	end
	if d.exercito then PromoverExercito(p, d.exercito) end
end

function DarPresente(p, variante, forcar)
	local v = VARIANTE[variante]
	if not v or not v.presente then return end
	local chave = "NVG_P_" .. p:GetID() .. "_" .. variante
	if not forcar and Valor(chave, 0) == 1 then return end
	Guardar(chave, 1)
	Presentear(p, v.presente)
	Avisar(p, "Presente: " .. NomeIdeologia(v.base), "Você adotou " .. NomeIdeologia(v.base) .. ": " .. v.presente.texto .. ".")
end

local function Escolhida(p, classica) return Valor("NVG_E_" .. p:GetID() .. "_" .. classica, 0) end

local function DarRamo(p, tipo)
	local linha = GameInfo.PolicyBranchTypes[tipo]
	p:SetPolicyBranchUnlocked(linha.ID, true, false)
	local abertura = GameInfo.Policies[linha.FreePolicy]
	if abertura and not p:HasPolicy(abertura.ID) then p:SetHasPolicy(abertura.ID, true) end
end

local function TirarRamo(p, tipo)
	local linha = GameInfo.PolicyBranchTypes[tipo]
	for pol in GameInfo.Policies() do
		if (pol.PolicyBranchType == tipo or pol.Type == linha.FreePolicy or pol.Type == linha.FreeFinishingPolicy) and p:HasPolicy(pol.ID) then
			p:SetHasPolicy(pol.ID, false)
		end
	end
	p:SetPolicyBranchUnlocked(linha.ID, false, false)
end

local MAX_EVOLUCOES = 4
local DESCONTO = Id("Buildings", "BUILDING_NVG_DESCONTO")

function NumEvolucoes(p)
	local n = 0
	for classica in pairs(NVG.evolucoes) do
		if Escolhida(p, classica) > 0 then n = n + 1 end
	end
	return n
end

local function Desconto(p)
	if DESCONTO < 0 then return end
	local tem = NumEvolucoes(p) == 0
	local capital = p:GetCapitalCity()
	for cidade in p:Cities() do
		local quer = (tem and capital and cidade:GetID() == capital:GetID()) and 1 or 0
		if cidade:GetNumRealBuilding(DESCONTO) ~= quer then cidade:SetNumRealBuilding(DESCONTO, quer) end
	end
end

function Evoluir(p, classica, indice, forcar)
	local opcoes = NVG.evolucoes[classica]
	local e = opcoes and opcoes[indice]
	if not e then return false end
	if not forcar then
		if Escolhida(p, classica) ~= 0 or not p:IsPolicyBranchFinished(RAMO[classica]) then return false end
		if NumEvolucoes(p) >= MAX_EVOLUCOES then return false end
	else
		local antes = Escolhida(p, classica)
		if antes == indice then return false end
		if antes ~= 0 and opcoes[antes] then TirarRamo(p, opcoes[antes].tipo) end
	end
	Guardar("NVG_E_" .. p:GetID() .. "_" .. classica, indice)
	DarRamo(p, e.tipo)
	Desconto(p)
	local extra = Valor("NVG_C_" .. p:GetID(), "") == "" and (" Se for a primeira evolução que você completar, libera " .. NomeIdeologia(e.ideologia) .. ".") or ""
	Avisar(p, "Evolução: " .. e.nome, NomeRamo(classica) .. " virou " .. e.nome .. " (" .. NumEvolucoes(p) .. " de " .. MAX_EVOLUCOES .. " evoluções)." .. extra)
	return true
end

function Pendentes(p)
	local lista = {}
	if NumEvolucoes(p) >= MAX_EVOLUCOES then return lista end
	for classica in pairs(NVG.evolucoes) do
		if Escolhida(p, classica) == 0 and p:IsPolicyBranchFinished(RAMO[classica]) then table.insert(lista, classica) end
	end
	table.sort(lista)
	return lista
end

local function Caminho(p) return Valor("NVG_C_" .. p:GetID(), "") end

local TIPOS_EVO = {}
for tipo in pairs(EVOLUCAO) do table.insert(TIPOS_EVO, tipo) end
table.sort(TIPOS_EVO)

local function MarcarCaminho(p)
	local pid = p:GetID()
	for _, tipo in ipairs(TIPOS_EVO) do
		local e = EVOLUCAO[tipo]
		if p:IsPolicyBranchUnlocked(RAMO[tipo]) and p:IsPolicyBranchFinished(RAMO[tipo]) and Valor("NVG_F_" .. pid .. "_" .. e.chave, 0) == 0 then
			Guardar("NVG_F_" .. pid .. "_" .. e.chave, 1)
			if Caminho(p) == "" then
				Guardar("NVG_C_" .. pid, tipo)
				Avisar(p, "Ideologia liberada: " .. NomeIdeologia(e.ideologia), e.nome .. " completo! Adote " .. NomeIdeologia(e.ideologia) .. " na aba Ideologias da tela de políticas.")
			else
				Avisar(p, e.nome .. " completo", "Você recebeu o bônus final de " .. e.nome .. ". A ideologia vem só da primeira evolução completa.")
			end
		end
	end
end

function Liberadas(p)
	local lista = {}
	local caminho = Caminho(p)
	if caminho ~= "" and EVOLUCAO[caminho] then lista[EVOLUCAO[caminho].variante] = true end
	return lista
end

function AdotarIdeologia(p, variante, forcar)
	local v = VARIANTE[variante]
	if not v then return false end
	if not forcar and not Liberadas(p)[variante] then return false end
	local atual = VarianteAtual(p)
	if atual == variante then return false end
	if atual then
		TirarRamo(p, atual)
		if not forcar then p:ChangeAnarchyNumTurns(2) end
	end
	DarRamo(p, variante)
	DarPresente(p, variante)
	local caminho = Caminho(p)
	if not forcar and caminho ~= "" and v.origem ~= caminho then
		Guardar("NVG_T_" .. p:GetID(), 0)
		p:ChangeAnarchyNumTurns(1)
		Avisar(p, "Crise de legitimidade", NomeIdeologia(v.base) .. " não veio do seu caminho (" .. NomeRamo(caminho) .. "). A Tradição zerou e o país tem mais 1 turno de anarquia.")
	else
		Avisar(p, "Ideologia: " .. NomeIdeologia(v.base), "Seu país agora segue: " .. NomeIdeologia(v.base) .. ".")
	end
	return true
end

local function Regime(p)
	local pid = p:GetID()
	if not p:IsPolicyBranchUnlocked(RAMO[NEUTRO]) then p:SetPolicyBranchUnlocked(RAMO[NEUTRO], true, false) end

	MarcarCaminho(p)
	Desconto(p)

	if not p:IsHuman() then
		for _, classica in ipairs(Pendentes(p)) do Evoluir(p, classica, 1 + Aleatorio(2)) end
		if not VarianteAtual(p) then
			local opcoes = {}
			for v in pairs(Liberadas(p)) do table.insert(opcoes, v) end
			table.sort(opcoes)
			if #opcoes > 0 then AdotarIdeologia(p, opcoes[1 + Aleatorio(#opcoes)]) end
		end
	elseif p:GetID() == Game.GetActivePlayer() and #Pendentes(p) > 0 then
		NVG_SINAL.evo = true
	end

	local caminho = Caminho(p)
	if caminho == "" then return end
	local atual = VarianteAtual(p)
	if atual and VARIANTE[atual].origem ~= caminho then return end
	local t = math.min(60, Valor("NVG_T_" .. pid, 0) + 1)
	Guardar("NVG_T_" .. pid, t)
	local m = Mult(p)
	local ouro, fe = math.floor(t / 4) * m, math.floor(t / 6) * m
	if ouro > 0 then p:ChangeGold(ouro) end
	if fe > 0 then p:ChangeFaith(fe) end
	local nome = EVOLUCAO[caminho] and EVOLUCAO[caminho].nome or ""
	if t == 20 and Valor("NVG_T20_" .. pid, 0) == 0 then
		Guardar("NVG_T20_" .. pid, 1)
		p:ChangeGoldenAgeTurns(6)
		Avisar(p, "Tradição 20", "20 turnos fiel ao " .. nome .. ": 6 turnos de Era de Ouro.")
	elseif (t == 40 or t == 60) and Valor("NVG_T" .. t .. "_" .. pid, 0) == 0 then
		Guardar("NVG_T" .. t .. "_" .. pid, 1)
		p:ChangeNumFreePolicies(1)
		Avisar(p, "Tradição " .. t, t .. " turnos fiel ao " .. nome .. ": 1 política grátis.")
	end
end

GameEvents.PlayerCanAdoptPolicyBranch.Add(function(pid, ramo)
	local linha = GameInfo.PolicyBranchTypes[ramo]
	if linha and BLOQUEADO[linha.Type] then return false end
	return true
end)

GameEvents.PlayerAdoptPolicy.Add(function(pid)
	local p = Players[pid]
	if not p then return end
	Seguro(MarcarCaminho, p)
	if p:IsHuman() and pid == Game.GetActivePlayer() then
		if #Pendentes(p) > 0 then NVG_SINAL.evo = true end
		NVG_SINAL.sujo = true
	end
end)

local function Tribo(p)
	if TRIBO < 0 then return end
	local tem = Era(p) < ERA_CLASSICA and 1 or 0
	for cidade in p:Cities() do
		if cidade:GetNumRealBuilding(TRIBO) ~= tem then cidade:SetNumRealBuilding(TRIBO, tem) end
	end
end

local function GuerraFria(p)
	local minha = Ideologia(p)
	if not minha then return end
	local time = Teams[p:GetTeam()]
	local ouro, ciencia, cultura = 0, 0, 0
	for _, o in ipairs(Majors()) do
		if o:GetID() ~= p:GetID() and time:IsHasMet(o:GetTeam()) then
			local dela = Ideologia(o)
			if dela == minha then
				ouro = ouro + 3
			elseif dela then
				ciencia = ciencia + 2
				cultura = cultura + 2
			end
		end
	end
	if ouro > 0 then p:ChangeGold(ouro) end
	if ciencia > 0 then Ciencia(p, ciencia) end
	if cultura > 0 then p:ChangeJONSCulture(cultura) end
end

local GUERRA_SANTA = Id("Beliefs", "BELIEF_NVG_GUERRA_SANTA")

local function ReligiaoGuerreira(p)
	if GUERRA_SANTA < 0 then return end
	local r = p:GetReligionCreatedByPlayer()
	if not r or r <= 0 then return end
	for _, b in ipairs(Game.GetBeliefsInReligion(r)) do
		if b == GUERRA_SANTA then
			PromoverExercito(p, "PROMOTION_NVG_GUERRA_SANTA")
			return
		end
	end
end

local function Revolucoes(p)
	if Era(p) < ERA_CLASSICA then return end
	if p:GetExcessHappiness() >= -5 then return end
	for cidade in p:Cities() do
		if not cidade:IsCapital() and cidade:GetPopulation() >= 4 and Aleatorio(100) < 8 then
			local u = MelhorUnidade(p, INFANTARIA)
			local n = 1 + Aleatorio(2)
			for _ = 1, n do CriarPerto(Players[BARBARO], u, cidade:GetX(), cidade:GetY(), "PROMOTION_NVG_REBELDE") end
			cidade:ChangeResistanceTurns(2)
			Avisar(p, "Revolução em " .. cidade:GetName(), "O povo de " .. cidade:GetName() .. " se revoltou: " .. n .. " rebelde(s) apareceram e a cidade parou por 2 turnos.", cidade:GetX(), cidade:GetY())
			return
		end
	end
end

local function MaiorEra()
	local e = 0
	for _, p in ipairs(Majors()) do e = math.max(e, Era(p)) end
	return e
end

local function TemIdeologia(p, lista)
	local i = Ideologia(p)
	for _, t in ipairs(lista) do if i == t then return true end end
	return false
end

local function MaiorCidade(p)
	local melhor
	for cidade in p:Cities() do
		if not melhor or cidade:GetPopulation() > melhor:GetPopulation() then melhor = cidade end
	end
	return melhor
end

local EVENTOS = {
	{ id = "PESTE", nome = "Peste", era = { 0, 4 }, f = function()
		for _, p in ipairs(Majors()) do
			if not TemIdeologia(p, { "SOCIALDEM" }) then
				local c = MaiorCidade(p)
				if c and c:GetPopulation() > 3 then c:ChangePopulation(-1, true) end
			end
		end
		return "Uma peste varreu o mundo: a maior cidade de cada civilização perdeu 1 habitante."
	end },
	{ id = "DESPERTAR", nome = "Grande Despertar", era = { 1, 7 }, f = function()
		for _, p in ipairs(Majors()) do
			local n = 30 * Mult(p)
			if TemIdeologia(p, { "FUNDAMENTALISMO" }) then n = n * 2 end
			p:ChangeFaith(n)
		end
		return "Um Grande Despertar religioso: todos ganham Fé (dobro para o Fundamentalismo)."
	end },
	{ id = "OURO", nome = "Corrida do Ouro", era = { 0, 7 }, f = function()
		local lista = Majors()
		local sorteados = {}
		for _ = 1, math.min(3, #lista) do
			local p = lista[1 + Aleatorio(#lista)]
			p:ChangeGold(80 * Mult(p))
			table.insert(sorteados, p:GetCivilizationShortDescription())
		end
		return "Corrida do Ouro! Acharam ouro em: " .. table.concat(sorteados, ", ") .. "."
	end },
	{ id = "INVASAO", nome = "Invasão Bárbara", era = { 0, 5 }, f = function()
		local lista = Majors()
		local p = lista[1 + Aleatorio(#lista)]
		local c = MaiorCidade(p)
		if not c then return nil end
		local u = MelhorUnidade(p, INFANTARIA)
		for _ = 1, 3 do CriarPerto(Players[BARBARO], u, c:GetX(), c:GetY()) end
		return "Uma horda bárbara surgiu perto de " .. c:GetName() .. " (" .. p:GetCivilizationShortDescription() .. ")."
	end },
	{ id = "PROFETA", nome = "Profeta Errante", era = { 0, 7 }, f = function()
		local lista = Majors()
		local p = lista[1 + Aleatorio(#lista)]
		local c = Capital(p)
		if not c then return nil end
		CriarPerto(p, Id("Units", "UNIT_PROPHET"), c:GetX(), c:GetY())
		return "Um Grande Profeta errante chegou a " .. p:GetCivilizationShortDescription() .. "."
	end },
	{ id = "GUERRA_SANTA", nome = "Guerra Santa", era = { 1, 5 }, f = function()
		for _, p in ipairs(Majors()) do
			local r = p:GetReligionCreatedByPlayer()
			if r and r > 0 then PromoverExercito(p, "PROMOTION_NVG_GUERRA_SANTA") end
		end
		return "Guerra Santa! Os exércitos de quem fundou uma religião ganham a promoção Guerra Santa."
	end },
	{ id = "CIENTIFICA", nome = "Revolução Científica", era = { 2, 7 }, f = function()
		for _, p in ipairs(Majors()) do
			local n = 60 * Mult(p)
			if TemIdeologia(p, { "TECNOCRACIA" }) then n = n * 2 end
			Ciencia(p, n)
		end
		return "Revolução Científica: todos avançam na pesquisa (dobro para a Tecnocracia)."
	end },
	{ id = "REVOLUCAO_CULTURAL", nome = "Revolução Cultural", era = { 3, 7 }, f = function()
		for _, p in ipairs(Majors()) do p:ChangeJONSCulture(50 * Mult(p)) end
		return "Revolução Cultural: todos ganham Cultura."
	end },
	{ id = "BOLSA", nome = "Quebra da Bolsa", era = { 4, 7 }, f = function()
		for _, p in ipairs(Majors()) do
			if TemIdeologia(p, { "CAPITALISMO", "LIBERTARIANISMO" }) then
				p:ChangeGold(-math.floor(p:GetGold() * 0.3))
			elseif TemIdeologia(p, { "COMUNISMO", "ANARQUISMO" }) then
				p:ChangeJONSCulture(60 * Mult(p))
			else
				p:ChangeGold(-math.floor(p:GetGold() * 0.1))
			end
		end
		return "A Bolsa quebrou! Capitalistas e libertários perdem 30% do ouro, outros 10%; comunistas e anarquistas ganham Cultura."
	end },
	{ id = "PETROLEO", nome = "Crise do Petróleo", era = { 5, 7 }, f = function()
		local oleo = Id("Resources", "RESOURCE_OIL")
		for _, p in ipairs(Majors()) do
			local n = oleo >= 0 and p:GetNumResourceTotal(oleo, true) or 0
			if n > 0 then p:ChangeGold(25 * n) else p:ChangeGold(-math.floor(p:GetGold() * 0.15)) end
		end
		return "Crise do Petróleo: quem tem petróleo lucra 25 de ouro por unidade; quem não tem perde 15% do ouro."
	end },
	{ id = "ESPACIAL", nome = "Corrida Espacial", era = { 6, 7 }, f = function()
		for _, p in ipairs(Majors()) do
			local n = 100 * Mult(p)
			if TemIdeologia(p, { "TECNOCRACIA", "COMUNISMO", "CAPITALISMO" }) then n = n * 2 end
			Ciencia(p, n)
		end
		return "Corrida Espacial: todos avançam na pesquisa; Tecnocracia, Capitalismo e Comunismo ganham o dobro."
	end },
	{ id = "PANDEMIA", nome = "Pandemia Global", era = { 5, 7 }, f = function()
		for _, p in ipairs(Majors()) do
			if not TemIdeologia(p, { "SOCIALDEM", "TECNOCRACIA" }) then
				for cidade in p:Cities() do
					if cidade:GetPopulation() > 6 then cidade:ChangePopulation(-1, true) end
				end
			end
		end
		return "Pandemia Global: cidades grandes perdem 1 habitante (Social-Democracia e Tecnocracia estão imunes)."
	end },
}

local EVENTO_POR_ID = {}
for i, e in ipairs(EVENTOS) do EVENTO_POR_ID[e.id] = e; e.n = i end

local function Disparar(e)
	local texto
	Seguro(function() texto = e.f() end)
	if texto then AvisarTodos("Evento mundial: " .. e.nome, texto) end
end

local function EventosMundiais()
	local turno = Game.GetGameTurn()
	local prox = Valor("NVG_EV", -1)
	if prox < 0 then
		Guardar("NVG_EV", turno + 25 + Aleatorio(11))
		return
	end
	if turno < prox then return end
	Guardar("NVG_EV", turno + 15 + Aleatorio(16))
	local era = MaiorEra()
	local validos = {}
	for _, e in ipairs(EVENTOS) do
		if era >= e.era[1] and era <= e.era[2] then table.insert(validos, e) end
	end
	if #validos > 0 then Disparar(validos[1 + Aleatorio(#validos)]) end
end

local function Plot(c)
	if c.x and c.x >= 0 then return Map.GetPlot(c.x, c.y) end
	return nil
end

local function TodasTechsAte(p, era)
	local time = Teams[p:GetTeam()]
	for t in GameInfo.Technologies() do
		local e = GameInfo.Eras[t.Era]
		if e and e.ID <= era and not time:IsHasTech(t.ID) then time:SetHasTech(t.ID, true, p:GetID(), true, true) end
	end
end

local ACOES = {
	OURO = function(p, c) p:ChangeGold(c.v) end,
	FE = function(p, c) p:ChangeFaith(c.v) end,
	CULTURA = function(p, c) p:ChangeJONSCulture(c.v) end,
	CIENCIA = function(p, c) Ciencia(p, c.v) end,
	ERA_OURO = function(p, c) p:ChangeGoldenAgeTurns(c.v) end,
	POLITICAS = function(p, c) p:ChangeNumFreePolicies(c.v) end,
	PRINCIPIOS = function(p, c) p:ChangeNumFreeTenets(c.v, false) end,
	INFLUENCIA = function(p, c)
		local m = Players[c.q]
		if m and m:IsMinorCiv() then m:ChangeMinorCivFriendshipWithMajor(p:GetID(), c.v) end
	end,
	TECH = function(p, c) Teams[p:GetTeam()]:SetHasTech(c.t, true, p:GetID(), true, true) end,
	TECHS_ERA = function(p, c) TodasTechsAte(p, c.t) end,
	POLITICA = function(p, c) p:SetHasPolicy(c.t, true) end,
	IDEOLOGIA = function(p, c)
		local linha = GameInfo.PolicyBranchTypes[c.t]
		if linha and VARIANTE[linha.Type] then AdotarIdeologia(p, linha.Type, true) end
	end,
	PRESENTE = function(p, c)
		local linha = GameInfo.PolicyBranchTypes[c.t]
		local v = linha and VARIANTE[linha.Type]
		if v then DarPresente(p, linha.Type, true) end
	end,
	EVOLUCAO = function(p, c)
		local linha = GameInfo.PolicyBranchTypes[c.t]
		local e = linha and EVOLUCAO[linha.Type]
		if e then Evoluir(p, e.classica, e.indice, true) end
	end,
	REVELAR = function(p)
		local time = p:GetTeam()
		for i = 0, Map.GetNumPlots() - 1 do
			local plot = Map.GetPlotByIndex(i)
			plot:SetRevealed(time, true)
			plot:UpdateFog()
		end
	end,
	GUERRA = function(p, c)
		local o = Players[c.q]
		if o and o:GetTeam() ~= p:GetTeam() then Teams[p:GetTeam()]:DeclareWar(o:GetTeam()) end
	end,
	PAZ = function(p, c)
		local o = Players[c.q]
		if o and Teams[p:GetTeam()]:IsAtWar(o:GetTeam()) then Teams[p:GetTeam()]:MakePeace(o:GetTeam()) end
	end,
	UNIDADE = function(p, c)
		local plot = Plot(c)
		if not plot then return end
		for _ = 1, math.max(1, math.min(10, c.v)) do
			if plot:GetNumUnits() == 0 or plot:GetOwner() == p:GetID() then
				p:InitUnit(c.t, plot:GetX(), plot:GetY())
			else
				CriarPerto(p, c.t, plot:GetX(), plot:GetY())
			end
		end
	end,
	UNIDADE_APAGAR = function(_, c)
		local plot = Plot(c)
		if not plot then return end
		for i = plot:GetNumUnits() - 1, 0, -1 do
			local u = plot:GetUnit(i)
			if u then u:Kill(true, -1) end
		end
	end,
	UNIDADE_CURAR = function(_, c)
		local plot = Plot(c)
		if not plot then return end
		for i = 0, plot:GetNumUnits() - 1 do
			local u = plot:GetUnit(i)
			if u then u:SetDamage(0) end
		end
	end,
	UNIDADE_XP = function(_, c)
		local plot = Plot(c)
		if not plot then return end
		for i = 0, plot:GetNumUnits() - 1 do
			local u = plot:GetUnit(i)
			if u then u:ChangeExperience(c.v) end
		end
	end,
	UNIDADE_PROMOCAO = function(_, c)
		local plot = Plot(c)
		if not plot then return end
		for i = 0, plot:GetNumUnits() - 1 do
			local u = plot:GetUnit(i)
			if u then u:SetHasPromotion(c.t, true) end
		end
	end,
	TERRENO = function(_, c)
		local plot = Plot(c)
		if plot and not plot:IsCity() then plot:SetTerrainType(c.t, false, true) end
	end,
	RELEVO = function(_, c)
		local plot = Plot(c)
		if plot and not plot:IsCity() then
			plot:SetPlotType(c.t, true, true)
			Map.RecalculateAreas()
		end
	end,
	VEGETACAO = function(_, c)
		local plot = Plot(c)
		if plot then plot:SetFeatureType(c.t, -1) end
	end,
	RECURSO = function(_, c)
		local plot = Plot(c)
		if plot then plot:SetResourceType(c.t, math.max(1, c.v)) end
	end,
	MELHORIA = function(_, c)
		local plot = Plot(c)
		if plot then plot:SetImprovementType(c.t) end
	end,
	DONO_HEX = function(p, c)
		local plot = Plot(c)
		if plot and not plot:IsCity() then plot:SetOwner(p:GetID(), -1, true, true) end
	end,
	CIDADE_CRIAR = function(p, c)
		local plot = Plot(c)
		if plot and not plot:IsCity() and not plot:IsWater() then p:InitCity(plot:GetX(), plot:GetY()) end
	end,
	CIDADE_DONO = function(p, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade and cidade:GetOwner() ~= p:GetID() then p:AcquireCity(cidade, false, true) end
	end,
	CIDADE_POP = function(_, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade then cidade:SetPopulation(math.max(1, cidade:GetPopulation() + c.v), true) end
	end,
	CIDADE_PRODUCAO = function(_, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade then
			local falta = cidade:GetProductionNeeded() - cidade:GetProduction()
			if falta > 0 then cidade:ChangeProduction(falta) end
		end
	end,
	CIDADE_PREDIO = function(_, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade then cidade:SetNumRealBuilding(c.t, 1) end
	end,
	CIDADE_RELIGIAO = function(_, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade then cidade:AdoptReligionFully(c.t) end
	end,
	CIDADE_RESISTENCIA = function(_, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade then cidade:ChangeResistanceTurns(c.v) end
	end,
	CIDADE_APAGAR = function(_, c)
		local plot = Plot(c)
		local cidade = plot and plot:GetPlotCity()
		if cidade and not cidade:IsCapital() then cidade:Kill() end
	end,
	EVENTO = function(_, c)
		local e = EVENTOS[c.t]
		if e then Disparar(e) end
	end,
}


local JOGADOR = {
	EVOLUIR = function(p, c)
		local linha = GameInfo.PolicyBranchTypes[c.t]
		if linha then Evoluir(p, linha.Type, c.v) end
	end,
	ADOTAR = function(p, c)
		local linha = GameInfo.PolicyBranchTypes[c.t]
		if linha then AdotarIdeologia(p, linha.Type) end
	end,
}

local function Executar(de, c)
	local alvo = Players[c.p]
	if not alvo or not alvo:IsAlive() then return end
	local f = JOGADOR[c.a]
	if f then
		if de == c.p then Seguro(f, alvo, c) end
		NVG_SINAL.sujo = true
		return
	end
	f = ACOES[c.a]
	if not f then return end
	if Seguro(f, alvo, c) then
		table.insert(NVG_SINAL.feitos, { de, c.a, c.p })
	end
	NVG_SINAL.sujo = true
end

local PREFIXO = "#N#"

local function Codificar(s)
	local t, k = {}, Game.GetGameTurn() % 97
	for i = 1, #s do
		t[i] = string.format("%02x", (string.byte(s, i) + k + i * 13) % 256)
	end
	return table.concat(t)
end

local function Decodificar(h)
	local t, k = {}, Game.GetGameTurn() % 97
	local i = 0
	for par in string.gmatch(h, "%x%x") do
		i = i + 1
		t[i] = string.char((tonumber(par, 16) - k - i * 13) % 256)
	end
	return table.concat(t)
end

local function Serializar(c)
	local campos = { c.a or "", c.p or -1, c.q or -1, c.v or 0, c.t or -1, c.x or -1, c.y or -1, Game.GetGameTurn() }
	for i, v in ipairs(campos) do campos[i] = tostring(v) end
	return PREFIXO .. Codificar(table.concat(campos, "|"))
end

local function Dividir(s)
	local t, i = {}, 1
	while true do
		local j = string.find(s, "|", i, true)
		if not j then table.insert(t, string.sub(s, i)) break end
		table.insert(t, string.sub(s, i, j - 1))
		i = j + 1
	end
	return t
end

local function Ler(texto)
	local partes = Dividir(Decodificar(string.sub(texto, 4)))
	local n = function(i) return tonumber(partes[i]) or -1 end
	return { a = partes[1], p = n(2), q = n(3), v = tonumber(partes[4]) or 0, t = n(5), x = n(6), y = n(7), turno = n(8) }
end

local fila = {}

local function EmRede() return Game.IsNetworkMultiPlayer() end

Events.GameMessageChat.Add(function(de, para, texto, alvo)
	if string.sub(texto or "", 1, 3) ~= PREFIXO then return end
	local c = Ler(texto)
	if c.turno == Game.GetGameTurn() then table.insert(fila, { de = de, c = c }) end
end)

local function Pedir(c)
	local eu = Game.GetActivePlayer()
	if EmRede() then
		Network.SendChat(Serializar(c), -1, -1)
	else
		Executar(eu, c)
		Events.SerialEventGameDataDirty()
	end
end

LuaEvents.NVG_BSG_Pedir.Add(Pedir)
LuaEvents.NVG_Pedir.Add(Pedir)

LuaEvents.NVG_Consultar.Add(function(pid, resposta)
	local p = Players[pid]
	if not p then return end
	resposta.emRede = EmRede()
	resposta.pendentes = Pendentes(p)
	resposta.liberadas = Liberadas(p)
	resposta.atual = VarianteAtual(p)
	resposta.caminho = Caminho(p)
	resposta.tradicao = Valor("NVG_T_" .. pid, 0)
	resposta.evolucoes = NumEvolucoes(p)
	resposta.maximo = MAX_EVOLUCOES
	resposta.escolhas = {}
	for classica in pairs(NVG.evolucoes) do resposta.escolhas[classica] = Escolhida(p, classica) end
end)

local ultimoTurno = -1

GameEvents.PlayerDoTurn.Add(function(pid)
	local turno = Game.GetGameTurn()
	if turno ~= ultimoTurno then
		ultimoTurno = turno
		local pendentes = fila
		fila = {}
		for _, item in ipairs(pendentes) do Executar(item.de, item.c) end
		Seguro(EventosMundiais)
	end
	local p = Players[pid]
	if not p or not p:IsAlive() or p:IsMinorCiv() or p:IsBarbarian() then return end
	Seguro(Tribo, p)
	Seguro(Regime, p)
	Seguro(GuerraFria, p)
	Seguro(ReligiaoGuerreira, p)
	Seguro(Revolucoes, p)
end)

local function Preparar()
	for _, p in ipairs(Majors()) do
		if not p:IsPolicyBranchUnlocked(RAMO[NEUTRO]) then p:SetPolicyBranchUnlocked(RAMO[NEUTRO], true, false) end
		Desconto(p)
	end
	local eu = Players[Game.GetActivePlayer()]
	if eu and #Pendentes(eu) > 0 then NVG_SINAL.evo = true end
end

local function Encaixar()
	local w = math.max(320, Controls.AlertaTexto:GetSizeX() + 56)
	Controls.Alerta:SetSizeX(w)
	Controls.AlertaAnim:SetSizeX(w)
	Controls.AlertaBrilho:SetSizeX(w)
	Controls.Alerta:SetHide(false)
end

local function Alerta()
	local eu = Players[Game.GetActivePlayer()]
	if not eu then return end
	local pend = Pendentes(eu)
	if #pend > 0 then
		local classica = pend[1]
		Controls.AlertaTexto:SetText("[ICON_CULTURE] Evolução disponível: " .. NomeRamo(classica) .. " (clique para escolher)")
		Controls.Alerta:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_EscolherEvolucao(classica) end)
		Encaixar()
		return
	end
	local caminho = Caminho(eu)
	local atual = VarianteAtual(eu)
	if caminho ~= "" and not atual then
		local base = EVOLUCAO[caminho].ideologia
		Controls.AlertaTexto:SetText("[ICON_CULTURE] Ideologia liberada: [COLOR_NVG_" .. base .. "]" .. NomeIdeologia(base) .. "[ENDCOLOR] (clique para adotar)")
		Controls.Alerta:RegisterCallback(Mouse.eLClick, function() LuaEvents.NVG_AbrirIdeologias() end)
		Encaixar()
		return
	end
	Controls.Alerta:SetHide(true)
end

LuaEvents.NVG_Atualizar.Add(function() Seguro(Alerta) end)
Events.SerialEventGameDataDirty.Add(function() Seguro(Alerta) end)
Events.ActivePlayerTurnStart.Add(function() Seguro(Alerta) end)
Events.GameplaySetActivePlayer.Add(function() Seguro(Alerta) end)

Events.LoadScreenClose.Add(function() Seguro(Preparar); Seguro(Alerta) end)

ContextPtr:SetUpdate(function()
	local sinal = NVG_SINAL
	if not (sinal.sujo or sinal.evo or #sinal.feitos > 0) then return end
	local feitos = sinal.feitos
	local evo = sinal.evo
	sinal.sujo, sinal.evo, sinal.feitos = false, false, {}
	for _, f in ipairs(feitos) do LuaEvents.NVG_BSG_Feito(f[1], f[2], f[3]) end
	Seguro(Alerta)
	LuaEvents.NVG_Atualizar()
	if evo then LuaEvents.NVG_EvolucaoPendente(Game.GetActivePlayer()) end
end)
Seguro(Preparar)

MapModData.NVG_EVENTOS = {}
for i, e in ipairs(EVENTOS) do MapModData.NVG_EVENTOS[i] = e.nome end

print("EraDasIdeologias 2.0 carregado")
