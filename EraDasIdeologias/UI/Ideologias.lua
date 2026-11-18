include("InstanceManager")
include("IconSupport")
include("nvgdados")

local cartoes = InstanceManager:new("Cartao", "Raiz", Controls.Cartoes)
local iconesPainel = InstanceManager:new("Icone", "Botao", Controls.PainelIcones)
local iconesOpcao = {
	InstanceManager:new("Icone", "Botao", Controls.Opcao1Icones),
	InstanceManager:new("Icone", "Botao", Controls.Opcao2Icones),
}

local ORDEM = { "CAPITALISMO", "COMUNISMO", "FASCISMO", "SOCIALDEM", "ANARQUISMO", "LIBERTARIANISMO",
	"TECNOCRACIA", "ECOLOGISMO", "MONARQUIA_CONST", "FUNDAMENTALISMO" }

local FUNDO_IDEOLOGIA = {
	CAPITALISMO = "SocialPoliciesFreedom.dds", SOCIALDEM = "SocialPoliciesFreedom.dds",
	LIBERTARIANISMO = "SocialPoliciesFreedom.dds", ECOLOGISMO = "SocialPoliciesFreedom.dds",
	COMUNISMO = "SocialPoliciesOrder.dds", ANARQUISMO = "SocialPoliciesOrder.dds", TECNOCRACIA = "SocialPoliciesOrder.dds",
	FASCISMO = "SocialPoliciesAutocracy.dds", MONARQUIA_CONST = "SocialPoliciesAutocracy.dds",
	FUNDAMENTALISMO = "SocialPoliciesAutocracy.dds",
}

local FUNDO_CLASSICA = {
	POLICY_BRANCH_TRADITION = "Assets/UI/Art/Icons/SocialPoliciesTradition.dds",
	POLICY_BRANCH_LIBERTY = "Assets/UI/Art/Icons/SocialPoliciesLiberty.dds",
	POLICY_BRANCH_HONOR = "SocialPoliciesHonor.dds",
	POLICY_BRANCH_PIETY = "SocialPoliciesPiety.dds",
	POLICY_BRANCH_PATRONAGE = "SocialPoliciesPatronage.dds",
	POLICY_BRANCH_AESTHETICS = "PolicyBranch_Aesthetics.dds",
	POLICY_BRANCH_COMMERCE = "SocialPoliciesCommerce.dds",
	POLICY_BRANCH_EXPLORATION = "PolicyBranch_Exploration.dds",
	POLICY_BRANCH_RATIONALISM = "SocialPoliciesRationalism.dds",
}

local POSICOES = { { 16, 106 }, { 71, 106 }, { 126, 106 }, { 16, 200 }, { 126, 200 } }

local CHEIO = { x = 1, y = 1, z = 1, w = 1 }
local APAGADO = { x = 1, y = 1, z = 1, w = 0.35 }

local pedidos = {}
local confirmar
local evoAberta
local selBase, selVar

local function T(chave) return Locale.ConvertTextKey(chave or "") end
local function Ramo(tipo) return GameInfo.PolicyBranchTypes[tipo] end
local function Eu() return Players[Game.GetActivePlayer()] end
local function Cor(base, texto) return "[COLOR_NVG_" .. base .. "]" .. texto .. "[ENDCOLOR]" end
local function Tinta(base, forca)
	local c = NVG.cores[base]
	forca = forca or 1
	return { x = 1 - (1 - c.r) * forca, y = 1 - (1 - c.g) * forca, z = 1 - (1 - c.b) * forca, w = 1 }
end
local function NomeRamo(tipo) return T(Ramo(tipo).Description) end
local function EmRede() return Game.IsNetworkMultiPlayer() end

local function Estado()
	local r = {}
	LuaEvents.NVG_Consultar(Game.GetActivePlayer(), r)
	r.liberadas = r.liberadas or {}
	r.pendentes = r.pendentes or {}
	r.escolhas = r.escolhas or {}
	r.caminho = r.caminho or ""
	return r
end

local function Aberto()
	return not (Controls.Janela:IsHidden() and Controls.Evolucao:IsHidden() and Controls.Confirmar:IsHidden())
end

local function Mostrar()
	if ContextPtr:IsHidden() then UIManager:QueuePopup(ContextPtr, PopupPriority.InGameUtmost) end
end

local function TalvezFechar()
	if not Aberto() and not ContextPtr:IsHidden() then UIManager:DequeuePopup(ContextPtr) end
end

local function PodeEnviar()
	if not EmRede() then return true end
	local eu = Eu()
	return eu:IsTurnActive() and not eu:HasReceivedNetTurnComplete()
end

local function Status(texto) Controls.Status:SetText(texto or "") end

local function Pedir(c)
	if not PodeEnviar() then
		Status("[COLOR_NEGATIVE_TEXT]Escolha antes de encerrar o seu turno.[ENDCOLOR]")
		return false
	end
	c.p = Game.GetActivePlayer()
	LuaEvents.NVG_Pedir(c)
	if EmRede() then Status("Enviado: vale quando o turno passar.") end
	return true
end

local function Perguntar(texto, sim)
	confirmar = sim
	Controls.ConfirmarTexto:SetText(texto)
	local h = math.max(60, math.min(Controls.ConfirmarTexto:GetSizeY() + 6, 380))
	Controls.ConfirmarRolagem:SetSizeY(h)
	Controls.ConfirmarBarra:SetSizeY(math.max(h - 36, 24))
	Controls.ConfirmarRolagem:CalculateInternalSize()
	Controls.ConfirmarRolagem:SetScrollValue(0)
	Controls.ConfirmarCaixa:SetSizeY(h + 130)
	Controls.ConfirmarCaixa:ReprocessAnchoring()
	Controls.Confirmar:SetHide(false)
	Mostrar()
end

local function Icone(inst, pol, x, y, estado, aoClicar)
	inst.Botao:SetOffsetVal(x, y)
	local atlas = estado == "tem" and pol.IconAtlasAchieved or pol.IconAtlas
	IconHookup(pol.PortraitIndex, 64, atlas or pol.IconAtlas, inst.Imagem)
	inst.Imagem:SetColor(estado == "apagado" and APAGADO or CHEIO)
	inst.Botao:SetToolTipString(T(pol.Help))
	inst.Botao:SetDisabled(aoClicar == nil)
	if aoClicar then inst.Botao:RegisterCallback(Mouse.eLClick, aoClicar) end
end

local Atualizar

local function Origens(base)
	local nomes = {}
	for _, tipo in ipairs(NVG.ideologias[base].variantes) do table.insert(nomes, NomeRamo(NVG.variantes[tipo].origem)) end
	return table.concat(nomes, " ou ")
end

local function Escolher(base, var)
	selBase = base
	selVar = var or NVG.ideologias[base].variantes[1]
	Atualizar()
end

local function Cartoes(est)
	cartoes:ResetInstances()
	local atualBase = est.atual and NVG.variantes[est.atual].base
	for i, base in ipairs(ORDEM) do
		local ideo = NVG.ideologias[base]
		local inst = cartoes:GetInstance()
		inst.Raiz:SetOffsetVal(((i - 1) % 2) * 222, math.floor((i - 1) / 2) * 104)
		local abertura = GameInfo.Policies[NVG.variantes[ideo.variantes[1]].abertura]
		IconHookup(abertura.PortraitIndex, 64, abertura.IconAtlas, inst.Icone)
		inst.Faixa:SetTexture(FUNDO_IDEOLOGIA[base])
		inst.Faixa:SetColor(Tinta(base, 0.8))
		inst.Nome:SetText(Cor(base, ideo.nome))
		local liberada
		for _, tipo in ipairs(ideo.variantes) do if est.liberadas[tipo] then liberada = tipo end end
		local situacao
		if atualBase == base then
			situacao = "[COLOR_POSITIVE_TEXT]Ideologia atual[ENDCOLOR]"
			inst.Icone:SetColor(CHEIO)
		elseif liberada then
			situacao = "[COLOR_POSITIVE_TEXT]Liberada![ENDCOLOR]"
			inst.Icone:SetColor(CHEIO)
		else
			situacao = "[COLOR_GREY]Trancada[ENDCOLOR]"
			for _, tipo in ipairs(ideo.variantes) do
				if est.caminho ~= "" and NVG.variantes[tipo].origem == est.caminho then situacao = "[COLOR_YELLOW]Sua rota[ENDCOLOR]" end
			end
			inst.Icone:SetColor(APAGADO)
		end
		inst.Situacao:SetText(situacao)
		inst.Textos:CalculateSize()
		inst.Textos:ReprocessAnchoring()
		inst.Raiz:SetToolTipString(Cor(base, ideo.nome) .. "[NEWLINE]Vem de: " .. Origens(base))
		inst.Selecao:SetHide(selBase ~= base)
		inst.Raiz:RegisterCallback(Mouse.eLClick, function() Escolher(base, liberada or (atualBase == base and est.atual) or nil) end)
	end
end

local function Painel(eu, est)
	local v = NVG.variantes[selVar]
	local ideo = NVG.ideologias[selBase]
	local ramo = Ramo(selVar)
	local atual = est.atual == selVar

	for i = 1, 2 do
		local botao = Controls["Via" .. i]
		local tipo = ideo.variantes[i]
		botao:SetHide(tipo == nil or #ideo.variantes < 2)
		if tipo then
			local marca = tipo == selVar and "[COLOR_POSITIVE_TEXT]» [ENDCOLOR]" or ""
			botao:SetText(marca .. "Vinda do " .. NomeRamo(NVG.variantes[tipo].origem))
			botao:RegisterCallback(Mouse.eLClick, function() Escolher(selBase, tipo) end)
		end
	end

	Controls.PainelFundo:SetTexture(FUNDO_IDEOLOGIA[selBase])
	Controls.PainelFundo:SetColor(Tinta(selBase, 0.85))
	Controls.PainelTitulo:SetText(Cor(selBase, Locale.ToUpper(ideo.nome)))
	local abertura = GameInfo.Policies[v.abertura]
	local final = GameInfo.Policies[v.final]
	Controls.PainelAbertura:SetText((eu:HasPolicy(abertura.ID) and "[ICON_STAR] " or "") .. "Abertura grátis ao adotar")
	Controls.PainelAbertura:SetToolTipString(T(abertura.Help))
	Controls.PainelTopo:CalculateSize()
	Controls.PainelTopo:ReprocessAnchoring()
	Controls.PainelFinal:SetText((eu:HasPolicy(final.ID) and "[ICON_STAR] " or "") .. "Completa: bônus final")
	Controls.PainelFinal:SetToolTipString(T(final.Help))

	iconesPainel:ResetInstances()
	for i, tipo in ipairs(v.politicas) do
		local pol = GameInfo.Policies[tipo]
		local estado, clique = "apagado", nil
		if atual and eu:HasPolicy(pol.ID) then
			estado = "tem"
		elseif atual and eu:CanAdoptPolicy(pol.ID) then
			estado = "pode"
			clique = function()
				Perguntar("Adotar " .. T(pol.Description) .. "?[NEWLINE][NEWLINE]" .. T(pol.Help), function()
					Network.SendUpdatePolicies(pol.ID, true, true)
					Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY")
				end)
			end
		elseif atual and eu:CanAdoptPolicy(pol.ID, true) then
			estado = "falta"
		end
		local inst = iconesPainel:GetInstance()
		Icone(inst, pol, POSICOES[i][1], POSICOES[i][2], estado, clique)
	end

	Controls.DetNome:SetText(Cor(selBase, ideo.nome))
	local origem = NomeRamo(v.origem)
	local linha = "Vinda do " .. origem
	if atual then linha = linha .. " · [COLOR_POSITIVE_TEXT]sua ideologia[ENDCOLOR]"
	elseif est.liberadas[selVar] then linha = linha .. " · [COLOR_POSITIVE_TEXT]liberada[ENDCOLOR]" end
	Controls.DetTexto:SetText(linha .. "[NEWLINE][NEWLINE]" .. T(ramo.Help))
	Controls.DetRolagem:CalculateInternalSize()
	Controls.DetRolagem:SetScrollValue(0)

	Controls.Cultura:SetText("[ICON_CULTURE] Cultura: " .. eu:GetJONSCulture() .. " (+" .. eu:GetTotalJONSCulturePerTurn() .. " por turno) · próxima política: " .. eu:GetNextPolicyCost())

	local dica = ""
	Controls.Acao:RegisterCallback(Mouse.eLClick, function() end)
	if atual then
		Controls.Acao:SetText("Ideologia atual")
		Controls.Acao:SetDisabled(true)
		dica = "Clique nos ícones coloridos para adotar políticas."
	elseif est.liberadas[selVar] then
		local atualBase = est.atual and NVG.variantes[est.atual].base
		Controls.Acao:SetText(est.atual and ("Trocar para " .. ideo.nome) or ("Adotar " .. ideo.nome))
		Controls.Acao:SetDisabled(false)
		Controls.Acao:RegisterCallback(Mouse.eLClick, function()
			local aviso = "Adotar " .. Cor(selBase, ideo.nome) .. "?[NEWLINE][NEWLINE]A abertura vem de graça, junto com o presente da ideologia."
			if est.atual then
				aviso = "Trocar para " .. Cor(selBase, ideo.nome) .. "?[NEWLINE][NEWLINE][COLOR_NEGATIVE_TEXT]2 turnos de anarquia e você perde as políticas de " .. NVG.ideologias[atualBase].nome .. ".[ENDCOLOR]"
			end
			local var = selVar
			Perguntar(aviso, function()
				if Pedir({ a = "ADOTAR", t = Ramo(var).ID }) and not EmRede() then Status(ideo.nome .. " adotado.") end
			end)
		end)
	else
		Controls.Acao:SetText("Trancada")
		Controls.Acao:SetDisabled(true)
		if est.caminho ~= "" then
			dica = "Só a primeira evolução completa libera ideologia. A sua foi " .. NomeRamo(est.caminho) .. "."
		else
			dica = "Complete o " .. origem .. " antes de qualquer outra evolução para liberar esta versão."
		end
	end
	Controls.AcaoDica:SetText(dica)
end

Atualizar = function()
	if Controls.Janela:IsHidden() then return end
	local eu = Eu()
	if not eu then return end
	local est = Estado()
	if not selBase then
		local var = est.atual
		if not var then for t in pairs(est.liberadas) do var = t end end
		if var then selBase, selVar = NVG.variantes[var].base, var else selBase, selVar = ORDEM[1], NVG.ideologias[ORDEM[1]].variantes[1] end
	end

	local nomes = {}
	for classica, opcoes in pairs(NVG.evolucoes) do
		local k = est.escolhas[classica] or 0
		if k > 0 and opcoes[k] then table.insert(nomes, opcoes[k].nome) end
	end
	table.sort(nomes)
	local texto = "Evoluções: [COLOR_POSITIVE_TEXT]" .. (est.evolucoes or #nomes) .. " de " .. (est.maximo or 4) .. "[ENDCOLOR]"
	if #nomes > 0 then texto = texto .. " (" .. table.concat(nomes, ", ") .. ")" end
	if est.caminho ~= "" then texto = texto .. " · Caminho: " .. NomeRamo(est.caminho) end
	if #est.pendentes > 0 then texto = texto .. " · [COLOR_POSITIVE_TEXT]evolução para escolher![ENDCOLOR]" end
	Controls.Resumo:SetText(texto)

	Cartoes(est)
	Painel(eu, est)
end

local function AbrirJanela()
	Status("")
	selBase = nil
	Controls.Janela:SetHide(false)
	Mostrar()
	Atualizar()
end

local function FecharJanela()
	Controls.Janela:SetHide(true)
	TalvezFechar()
end

local function MostrarEvolucao(classica)
	local opcoes = NVG.evolucoes[classica]
	if not opcoes then return end
	local est = Estado()
	evoAberta = classica
	Controls.EvoTitulo:SetText("EVOLUÇÃO DE " .. Locale.ToUpper(NomeRamo(classica)))
	local sub = "Escolha uma: a outra fecha para sempre. Os bônus de " .. NomeRamo(classica) .. " continuam."
	sub = sub .. "[NEWLINE]Evoluções usadas: " .. (est.evolucoes or 0) .. " de " .. (est.maximo or 4)
	if est.caminho == "" then sub = sub .. " · a primeira que você completar libera a ideologia dela" end
	Controls.EvoSub:SetText(sub)
	for i = 1, 2 do
		local e = opcoes[i]
		Controls["Opcao" .. i .. "Fundo"]:SetTexture(FUNDO_CLASSICA[classica])
		Controls["Opcao" .. i .. "Fundo"]:SetColor(Tinta(e.ideologia, 0.6))
		Controls["Opcao" .. i .. "Nome"]:SetText(Cor(e.ideologia, Locale.ToUpper(e.nome)))
		Controls["Opcao" .. i .. "Texto"]:SetText(T(Ramo(e.tipo).Help))
		Controls["Opcao" .. i .. "Rolagem"]:CalculateInternalSize()
		Controls["Opcao" .. i .. "Rolagem"]:SetScrollValue(0)
		iconesOpcao[i]:ResetInstances()
		for pol in GameInfo.Policies() do
			if pol.PolicyBranchType == e.tipo then
				Icone(iconesOpcao[i]:GetInstance(), pol, (pol.GridX - 1) * 28 + 16, (pol.GridY - 1) * 68 + 12, "pode", nil)
			end
		end
		Controls["Opcao" .. i]:SetText("Escolher " .. e.nome)
		Controls["Opcao" .. i]:RegisterCallback(Mouse.eLClick, function()
			Perguntar("Escolher " .. Cor(e.ideologia, e.nome) .. "?[NEWLINE][NEWLINE][COLOR_NEGATIVE_TEXT]" .. opcoes[3 - i].nome .. " fecha para sempre.[ENDCOLOR]", function()
				if Pedir({ a = "EVOLUIR", t = Ramo(classica).ID, v = i }) then
					pedidos[classica] = Game.GetGameTurn()
					Controls.Evolucao:SetHide(true)
					evoAberta = nil
				end
			end)
		end)
	end
	Controls.Evolucao:SetHide(false)
	Mostrar()
end

local function ProximaEvolucao()
	if not Controls.Evolucao:IsHidden() then return end
	local est = Estado()
	for _, classica in ipairs(est.pendentes) do
		if pedidos[classica] ~= Game.GetGameTurn() then
			MostrarEvolucao(classica)
			return
		end
	end
end

local function Adiar()
	if evoAberta then pedidos[evoAberta] = Game.GetGameTurn() end
	Controls.Evolucao:SetHide(true)
	evoAberta = nil
	TalvezFechar()
end

Controls.Fechar:RegisterCallback(Mouse.eLClick, FecharJanela)
Controls.Depois:RegisterCallback(Mouse.eLClick, Adiar)
Controls.Sim:RegisterCallback(Mouse.eLClick, function()
	Controls.Confirmar:SetHide(true)
	local f = confirmar
	confirmar = nil
	if f then f() end
	Atualizar()
	TalvezFechar()
end)
Controls.Nao:RegisterCallback(Mouse.eLClick, function()
	Controls.Confirmar:SetHide(true)
	confirmar = nil
	TalvezFechar()
end)

LuaEvents.NVG_AbrirIdeologias.Add(AbrirJanela)
LuaEvents.NVG_EscolherEvolucao.Add(function(classica)
	pedidos[classica] = nil
	MostrarEvolucao(classica)
end)
LuaEvents.NVG_EvolucaoPendente.Add(function(pid)
	if pid == Game.GetActivePlayer() then ProximaEvolucao() end
end)
LuaEvents.NVG_Atualizar.Add(function() Atualizar() end)
Events.EventPoliciesDirty.Add(function() Atualizar() end)

ContextPtr:SetInputHandler(function(msg, tecla)
	if ContextPtr:IsHidden() then return false end
	if msg == KeyEvents.KeyDown and (tecla == Keys.VK_ESCAPE or tecla == Keys.VK_RETURN) then
		if not Controls.Confirmar:IsHidden() then
			Controls.Confirmar:SetHide(true)
			confirmar = nil
		elseif not Controls.Evolucao:IsHidden() then
			Adiar()
			return true
		else
			Controls.Janela:SetHide(true)
		end
		TalvezFechar()
		return true
	end
	return false
end)

local function Limpar()
	Controls.Janela:SetHide(true)
	Controls.Confirmar:SetHide(true)
	Controls.Evolucao:SetHide(true)
	pedidos = {}
	TalvezFechar()
end

ContextPtr:SetHide(true)
Events.GameplaySetActivePlayer.Add(Limpar)
Events.LoadScreenClose.Add(function()
	Limpar()
	ProximaEvolucao()
end)
