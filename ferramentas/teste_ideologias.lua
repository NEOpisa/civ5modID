local MOD, FIX = arg[1], arg[2]
local erros = 0
local function evento()
	local fs = {}
	return setmetatable({ Add = function(f) table.insert(fs, f) end }, { __call = function(_, ...) local r; for _, f in ipairs(fs) do r = f(...) end; return r end })
end
local function grupo() return setmetatable({}, { __index = function(t, k) local e = evento(); rawset(t, k, e); return e end }) end
Events, GameEvents, LuaEvents = grupo(), grupo(), grupo()
local textos = {}
local function Controle(nome)
	local c = { oculto = true }
	return setmetatable(c, { __index = function(_, k)
		if k == "SetHide" then return function(self, v) self.oculto = v end end
		if k == "IsHidden" then return function(self) return self.oculto end end
		if k == "SetText" then return function(self, t) assert(type(t) == "string", nome .. " texto não é string"); textos[#textos + 1] = t end end
		if k == "RegisterCallback" then return function(self, _, f) self.f = f end end
		if k == "GetSizeX" or k == "GetSizeY" then return function() return 100 end end
		return function() end
	end })
end
Controls = setmetatable({}, { __index = function(t, k) local c = Controle(k); rawset(t, k, c); return c end })
local ctxOculto = false
local fila = 0
ContextPtr = { SetInputHandler = function() end, IsHidden = function() return ctxOculto end, SetHide = function(_, v) ctxOculto = v end }
UIManager = { QueuePopup = function() ctxOculto = false; fila = fila + 1 end, DequeuePopup = function() ctxOculto = true; fila = fila - 1 end }
PopupPriority = { InGameUtmost = 1 }
function IconHookup(i, n, atlas, img) assert(atlas, "atlas nil"); assert(img, "imagem nil") end
InstanceManager = { new = function() return { ResetInstances = function() end, GetInstance = function() return setmetatable({}, { __index = function(t, k) local c = Controle(k); rawset(t, k, c); return c end }) end } end }
Mouse = { eLClick = 1 }
Keys = {}
KeyEvents = {}
Locale = { ConvertTextKey = function(k) return tostring(k) end, ToUpper = string.upper }
dofile(FIX)
local function linhas(lista)
	local t = {}
	for i, l in ipairs(lista) do l.ID = i - 1; t[l.Type] = l; t[i - 1] = l end
	return setmetatable(t, { __call = function() local i = 0; return function() i = i + 1; return lista[i] end end })
end
GameInfo = { PolicyBranchTypes = linhas(FIXTURE.PolicyBranchTypes), Policies = linhas(FIXTURE.Policies) }
function include(n) if n == "nvgdados" then dofile(MOD .. "/Lua/NVGDados.lua") end end
Game = { GetActivePlayer = function() return 0 end, IsNetworkMultiPlayer = function() return false end, GetGameTurn = function() return 5 end }
local pols = {}
Players = { [0] = { HasPolicy = function(_, i) return pols[i] end, CanAdoptPolicy = function(_, i, b) return i % 2 == 0 end, GetNextPolicyCost = function() return 300 end, GetJONSCulture = function() return 120 end, GetTotalJONSCulturePerTurn = function() return 9 end,
	IsTurnActive = function() return true end, HasReceivedNetTurnComplete = function() return false end } }
Network = { SendUpdatePolicies = function() end }

local estado = { evolucoes = 2, maximo = 4, pendentes = { "POLICY_BRANCH_TRADITION" }, liberadas = { POLICY_BRANCH_NVG_I_FASCISMO_CESARISMO = true, POLICY_BRANCH_NVG_I_COMUNISMO_ESTRATOCRACIA = true },
	atual = "POLICY_BRANCH_NVG_I_FASCISMO_CESARISMO", caminho = "POLICY_BRANCH_NVG_E_ESTRATOCRACIA", tradicao = 4, escolhas = { POLICY_BRANCH_HONOR = 1 } }
LuaEvents.NVG_Consultar.Add(function(pid, r) for k, v in pairs(estado) do r[k] = v end end)
local pedidos = {}
LuaEvents.NVG_Pedir.Add(function(c) pedidos[#pedidos + 1] = c end)

dofile(MOD .. "/UI/Ideologias.lua")
assert(ctxOculto, "contexto não começa oculto")
Events.LoadScreenClose()
assert(not ctxOculto and fila == 1, "evolução não foi para a fila de popups")
assert(not Controls.Evolucao.oculto, "diálogo de evolução não abriu")
Controls.Opcao2.f()
assert(not Controls.Confirmar.oculto, "confirmação não abriu")
Controls.Sim.f()
assert(pedidos[1] and pedidos[1].a == "EVOLUIR" and pedidos[1].v == 2, "pedido de evolução errado")
LuaEvents.NVG_AbrirIdeologias()
assert(not Controls.Janela.oculto, "janela não abriu")
estado.atual = nil
LuaEvents.NVG_Atualizar()
Controls.Fechar.f()
assert(ctxOculto and fila == 0, "janela não saiu da fila: " .. fila)
print("telas ok, textos:", #textos)
