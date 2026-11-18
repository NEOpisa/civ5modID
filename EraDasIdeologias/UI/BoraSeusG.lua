include("nvgdados")

local function T(chave) return Locale.ConvertTextKey(chave or "") end

local function Ordenar(lista)
	table.sort(lista, function(a, b) return a.nome < b.nome end)
	return lista
end

local function DeTabela(tabela, filtro, nenhum)
	local lista = {}
	for linha in GameInfo[tabela]() do
		if not filtro or filtro(linha) then
			table.insert(lista, { id = linha.ID, nome = T(linha.Description) })
		end
	end
	Ordenar(lista)
	if nenhum then table.insert(lista, 1, { id = -1, nome = nenhum }) end
	return lista
end

local EVENTOS = { "Peste", "Grande Despertar", "Corrida do Ouro", "Invasão Bárbara", "Profeta Errante", "Guerra Santa",
	"Revolução Científica", "Revolução Cultural", "Quebra da Bolsa", "Crise do Petróleo", "Corrida Espacial", "Pandemia Global" }

local LISTAS = {
	tech = function() return DeTabela("Technologies") end,
	era = function()
		local l = {}
		for e in GameInfo.Eras() do table.insert(l, { id = e.ID, nome = T(e.Description) }) end
		return l
	end,
	politica = function() return DeTabela("Policies") end,
	ideologia = function()
		local l = {}
		for tipo, v in pairs(NVG.variantes) do
			local origem = GameInfo.PolicyBranchTypes[v.origem]
			table.insert(l, { id = GameInfo.PolicyBranchTypes[tipo].ID, nome = NVG.ideologias[v.base].nome .. " (via " .. T(origem.Description) .. ")" })
		end
		return Ordenar(l)
	end,
	evolucao = function()
		local l = {}
		for classica, opcoes in pairs(NVG.evolucoes) do
			for _, e in ipairs(opcoes) do
				table.insert(l, { id = GameInfo.PolicyBranchTypes[e.tipo].ID, nome = T(GameInfo.PolicyBranchTypes[classica].Description) .. " > " .. e.nome })
			end
		end
		return Ordenar(l)
	end,
	unidade = function() return DeTabela("Units") end,
	promocao = function() return DeTabela("UnitPromotions") end,
	terreno = function() return DeTabela("Terrains") end,
	relevo = function()
		return { { id = PlotTypes.PLOT_LAND, nome = "Plano" }, { id = PlotTypes.PLOT_HILLS, nome = "Colina" },
			{ id = PlotTypes.PLOT_MOUNTAIN, nome = "Montanha" }, { id = PlotTypes.PLOT_OCEAN, nome = "Água" } }
	end,
	vegetacao = function() return DeTabela("Features", nil, "(nenhuma)") end,
	recurso = function() return DeTabela("Resources", nil, "(nenhum)") end,
	melhoria = function() return DeTabela("Improvements", nil, "(nenhuma)") end,
	predio = function() return DeTabela("Buildings", function(b) return b.Type ~= "BUILDING_NVG_TRIBO" end) end,
	religiao = function() return DeTabela("Religions", function(r) return r.Type ~= "RELIGION_PANTHEON" end) end,
	evento = function()
		local l = {}
		for i, n in ipairs(EVENTOS) do table.insert(l, { id = i, nome = n }) end
		return l
	end,
}

local ACOES = {
	{ "OURO", "Dar/tirar Ouro", v = 500, dica = "Valor negativo tira." },
	{ "FE", "Dar/tirar Fé", v = 300 },
	{ "CULTURA", "Dar/tirar Cultura", v = 300 },
	{ "CIENCIA", "Dar Ciência (pesquisa atual)", v = 300 },
	{ "ERA_OURO", "Turnos de Era de Ouro", v = 10 },
	{ "POLITICAS", "Políticas grátis", v = 1 },
	{ "INFLUENCIA", "Influência com cidade-estado", v = 50, q = "Cidade-estado" },
	{ "TECH", "Dar tecnologia", t = "tech" },
	{ "TECHS_ERA", "Dar todas as tecnologias até a era", t = "era" },
	{ "POLITICA", "Dar política", t = "politica" },
	{ "EVOLUCAO", "Dar evolução de árvore", t = "evolucao", dica = "Abre a evolução de graça e fecha a outra da mesma árvore." },
	{ "IDEOLOGIA", "Trocar ideologia na hora", t = "ideologia", dica = "Sem anarquia e sem crise. Tira as políticas da ideologia antiga." },
	{ "PRESENTE", "Repetir presente de ideologia", t = "ideologia" },
	{ "REVELAR", "Revelar o mapa" },
	{ "GUERRA", "Alvo declara guerra ao Jogador 2", q = "Jogador 2" },
	{ "PAZ", "Alvo faz paz com o Jogador 2", q = "Jogador 2" },
	{ "UNIDADE", "Criar unidade", t = "unidade", v = 1, h = true, dica = "Valor = quantidade (até 10)." },
	{ "UNIDADE_APAGAR", "Apagar unidades do hexágono", h = true },
	{ "UNIDADE_CURAR", "Curar unidades do hexágono", h = true },
	{ "UNIDADE_XP", "Dar experiência às unidades do hexágono", v = 30, h = true },
	{ "UNIDADE_PROMOCAO", "Dar promoção às unidades do hexágono", t = "promocao", h = true },
	{ "TERRENO", "Mudar terreno", t = "terreno", h = true },
	{ "RELEVO", "Mudar relevo (plano/colina/montanha/água)", t = "relevo", h = true },
	{ "VEGETACAO", "Mudar vegetação", t = "vegetacao", h = true },
	{ "RECURSO", "Colocar recurso", t = "recurso", v = 2, h = true, dica = "Valor = quantidade (recursos estratégicos)." },
	{ "MELHORIA", "Colocar melhoria", t = "melhoria", h = true },
	{ "DONO_HEX", "Dar o hexágono ao alvo", h = true },
	{ "CIDADE_CRIAR", "Fundar cidade para o alvo", h = true },
	{ "CIDADE_DONO", "Dar a cidade do hexágono ao alvo", h = true },
	{ "CIDADE_POP", "Mudar população da cidade", v = 3, h = true, dica = "Valor negativo diminui." },
	{ "CIDADE_PRODUCAO", "Terminar a produção da cidade", h = true },
	{ "CIDADE_PREDIO", "Construir prédio na cidade", t = "predio", h = true },
	{ "CIDADE_RELIGIAO", "Converter a cidade", t = "religiao", h = true },
	{ "CIDADE_RESISTENCIA", "Turnos de resistência na cidade", v = 3, h = true },
	{ "CIDADE_APAGAR", "Apagar a cidade (não capital)", h = true },
	{ "EVENTO", "Disparar evento mundial", t = "evento" },
}

local acao, alvo, alvo2, tipo = 1, -1, -1, -1
local hexX, hexY = -1, -1
local listaTipo, listaJogadores, listaMinors = {}, {}, {}
local escolhendo = false

local function Status(texto) Controls.Status:SetText(texto or "") end

local function Encher(pd, itens, aoEscolher)
	pd:ClearEntries()
	for i, it in ipairs(itens) do
		local inst = {}
		pd:BuildEntry("InstanceOne", inst)
		inst.Button:SetText(it.nome)
		inst.Button:SetVoid1(i)
	end
	pd:CalculateInternals()
	pd:RegisterSelectionCallback(function(i)
		local it = itens[i]
		if it then
			pd:GetButton():SetText(it.nome)
			aoEscolher(it)
		end
	end)
	if itens[1] then
		pd:GetButton():SetText(itens[1].nome)
		aoEscolher(itens[1])
	else
		pd:GetButton():SetText("")
	end
end

local function Nome(p)
	local n = p:GetCivilizationShortDescription()
	if p:IsHuman() and p:GetNickName() ~= "" then n = n .. " (" .. p:GetNickName() .. ")" end
	if p:IsMinorCiv() then n = "* " .. n end
	return n
end

local function Jogadores()
	listaJogadores, listaMinors = {}, {}
	for i = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
		local p = Players[i]
		if p and p:IsAlive() and not p:IsBarbarian() then
			local it = { id = i, nome = Nome(p) }
			table.insert(listaJogadores, it)
			if p:IsMinorCiv() then table.insert(listaMinors, it) end
		end
	end
	local eu = Game.GetActivePlayer()
	table.sort(listaJogadores, function(a, b)
		if (a.id == eu) ~= (b.id == eu) then return a.id == eu end
		return a.nome < b.nome
	end)
	Ordenar(listaMinors)
end

local function AtualizarHex()
	if hexX >= 0 then
		local plot = Map.GetPlot(hexX, hexY)
		local cidade = plot and plot:GetPlotCity()
		Controls.HexTexto:SetText(hexX .. ", " .. hexY .. (cidade and (" " .. cidade:GetName()) or ""))
	else
		Controls.HexTexto:SetText("nenhum")
	end
end

local function MostrarAcao()
	local a = ACOES[acao]
	Controls.LinhaTipo:SetHide(a.t == nil)
	Controls.LinhaValor:SetHide(a.v == nil)
	Controls.LinhaHex:SetHide(not a.h)
	Controls.LinhaAlvo2:SetHide(a.q == nil)
	Controls.Dica:SetText(a.dica or "")
	if a.v then Controls.Valor:SetText(tostring(a.v)) end
	if a.t then
		listaTipo = LISTAS[a.t]()
		Encher(Controls.ListaTipo, listaTipo, function(it) tipo = it.id end)
	else
		tipo = -1
	end
	if a.q then
		Controls.RotuloAlvo2:SetText(a.q)
		Encher(Controls.ListaAlvo2, a.q == "Cidade-estado" and listaMinors or listaJogadores, function(it) alvo2 = it.id end)
	else
		alvo2 = -1
	end
	Status("")
end

local function Abrir()
	Jogadores()
	Encher(Controls.ListaAlvo, listaJogadores, function(it) alvo = it.id end)
	MostrarAcao()
	AtualizarHex()
	Controls.Fundo:SetHide(false)
end

local function Fechar() Controls.Fundo:SetHide(true) end

local itensAcao = {}
for i, a in ipairs(ACOES) do itensAcao[i] = { id = i, nome = a[2] } end

local function Aplicar()
	local a = ACOES[acao]
	if a.h and hexX < 0 then Status("Escolha um hexágono primeiro.") return end
	if Game.IsNetworkMultiPlayer() then
		local eu = Players[Game.GetActivePlayer()]
		if not eu:IsTurnActive() or eu:HasReceivedNetTurnComplete() then
			Status("Envie antes de encerrar o seu turno.")
			return
		end
	end
	local v = tonumber(Controls.Valor:GetText()) or a.v or 0
	LuaEvents.NVG_BSG_Pedir({ a = a[1], p = alvo, q = alvo2, v = math.floor(v), t = tipo, x = hexX, y = hexY })
	if Game.IsNetworkMultiPlayer() then
		Status("Enviado: vale para todos quando o turno passar.")
	else
		Status("Feito: " .. a[2])
	end
end

Controls.Fechar:RegisterCallback(Mouse.eLClick, Fechar)
Controls.Aplicar:RegisterCallback(Mouse.eLClick, Aplicar)
Controls.EscolherHex:RegisterCallback(Mouse.eLClick, function()
	escolhendo = true
	Controls.Fundo:SetHide(true)
	Controls.Escolhendo:SetHide(false)
end)
Controls.HexSelecao:RegisterCallback(Mouse.eLClick, function()
	local u = UI.GetHeadSelectedUnit()
	local c = UI.GetHeadSelectedCity()
	if c then hexX, hexY = c:GetX(), c:GetY()
	elseif u then hexX, hexY = u:GetX(), u:GetY()
	else Status("Nada selecionado.") end
	AtualizarHex()
end)

Encher(Controls.ListaAcao, itensAcao, function(it)
	acao = it.id
	if not Controls.Fundo:IsHidden() then MostrarAcao() end
end)

local function FimEscolha(pegou)
	escolhendo = false
	Controls.Escolhendo:SetHide(true)
	if pegou then
		local x, y = UI.GetMouseOverHex()
		if x and Map.GetPlot(x, y) then hexX, hexY = x, y end
	end
	AtualizarHex()
	Controls.Fundo:SetHide(false)
end

ContextPtr:SetInputHandler(function(msg, tecla)
	if escolhendo then
		if msg == MouseEvents.LButtonDown then return true end
		if msg == MouseEvents.LButtonUp then FimEscolha(true) return true end
		if msg == KeyEvents.KeyDown and tecla == Keys.VK_ESCAPE then FimEscolha(false) return true end
		return false
	end
	if msg ~= KeyEvents.KeyDown then return false end
	local aberto = not Controls.Fundo:IsHidden()
	if aberto and tecla == Keys.VK_ESCAPE then Fechar() return true end
	if tecla == Keys.G and UIManager:GetControl() and UIManager:GetShift() and UIManager:GetAlt() then
		if aberto then Fechar() else Abrir() end
		return true
	end
	return false
end)

LuaEvents.NVG_BSG_Feito.Add(function(de, a)
	if de == Game.GetActivePlayer() and Game.IsNetworkMultiPlayer() then
		Status("Aplicado: " .. a)
	end
end)

Events.LoadScreenClose.Add(Fechar)
Events.GameplaySetActivePlayer.Add(Fechar)
