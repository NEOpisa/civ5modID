local MOD, FIX = arg[1], arg[2]
local Q
Q = setmetatable({}, { __index = function() return Q end, __call = function() return Q end })
local function evento() local fs = {}; return setmetatable({ Add = function(f) table.insert(fs, f) end }, { __call = function(_, ...) for _, f in ipairs(fs) do f(...) end end }) end
local function grupo() return setmetatable({}, { __index = function(t, k) local e = evento(); rawset(t, k, e); return e end }) end
Events, GameEvents, LuaEvents = grupo(), grupo(), grupo()
local escondidos = {}
local function Controle(nome)
	return setmetatable({}, { __index = function(_, k)
		if k == "SetHide" then return function(self, v) escondidos[self] = v end end
		if k == "SetText" then return function(self, t) assert(type(t) == "string", nome) end end
		return function() return 0, 0 end
	end })
end
Controls = setmetatable({}, { __index = function(t, k) local c = Controle(k); rawset(t, k, c); return c end })
ContextPtr = { SetInputHandler = function() end, SetShowHideHandler = function() end, IsHidden = function() return false end }
local criados = 0
InstanceManager = { new = function() return { ResetInstances = function() end, GetInstance = function() criados = criados + 1; return setmetatable({}, { __index = function(t, k) local c = Controle(k); rawset(t, k, c); return c end }) end } end }
dofile(FIX)
local function linhas(lista)
	local t = {}
	for i, l in ipairs(lista) do l.ID = i - 1; t[l.Type] = l; t[i - 1] = l; l.GridX = l.GridX or 1; l.GridY = l.GridY or 1 end
	return setmetatable(t, { __call = function() local i = 0; return function() i = i + 1; return lista[i] end end })
end
GameInfo = { PolicyBranchTypes = linhas(FIXTURE.PolicyBranchTypes), Policies = linhas(FIXTURE.Policies), Policy_PrereqPolicies = function() return function() end end, Eras = {} }
GameInfoTypes = {}
function include(n) if n == "nvgdados" then dofile(MOD .. "/Lua/NVGDados.lua") end end
Locale = { ConvertTextKey = function(k) return tostring(k) end, ToUpper = string.upper, Lookup = function(k) return k end }
Mouse = { eLClick = 1 }
Game = { GetActivePlayer = function() return 0 end, IsOption = function() return false end }
GameOptionTypes = {}
OptionsManager = { GetPolicyInfo = function() return false end }
function CivIconHookup() end
function IconHookup() end
function RegisterTabBehavior() return function() end end
UIManager = Q
ButtonPopupTypes = Q
KeyEvents = Q
Keys = Q
Teams = { [0] = { GetCurrentEra = function() return 3 end } }
local un = { [GameInfo.PolicyBranchTypes.POLICY_BRANCH_HONOR.ID] = true, [GameInfo.PolicyBranchTypes.POLICY_BRANCH_NVG_E_CESARISMO.ID] = true,
	[GameInfo.PolicyBranchTypes.POLICY_BRANCH_NVG_I_FASCISMO_CESARISMO.ID] = true }
Players = { [0] = setmetatable({}, { __index = function(_, k)
	if k == "IsPolicyBranchUnlocked" then return function(_, b) return un[b] or false end end
	if k == "IsPolicyBranchFinished" then return function(_, b) return GameInfo.PolicyBranchTypes[b].Type == "POLICY_BRANCH_TRADITION" end end
	if k == "HasPolicy" or k == "CanAdoptPolicy" or k == "IsPolicyBlocked" or k == "IsPolicyBranchBlocked" or k == "CanUnlockPolicyBranch" then return function() return false end end
	if k == "GetDominantPolicyBranchForTitle" then return function() return -1 end end
	return function() return 0 end
end }) }
dofile(MOD .. "/Telas/SocialPolicyPopup.lua")
UpdateDisplay()
print("ícones criados:", criados)
print("Tradição: botão Evoluir visível =", escondidos[Controls["BranchButton" .. GameInfo.PolicyBranchTypes.POLICY_BRANCH_TRADITION.ID]] == false)
