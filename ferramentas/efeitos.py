import os, re, sqlite3, shutil, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.join(AQUI, '..', 'EraDasIdeologias')
CACHE = os.path.expanduser("~/Games/saves/Aspyr/Sid Meier's Civilization 5/cache")

Y = {'FOOD': ('[ICON_FOOD]', 'Comida'), 'PRODUCTION': ('[ICON_PRODUCTION]', 'Produção'),
     'GOLD': ('[ICON_GOLD]', 'Ouro'), 'SCIENCE': ('[ICON_RESEARCH]', 'Ciência'),
     'CULTURE': ('[ICON_CULTURE]', 'Cultura'), 'FAITH': ('[ICON_PEACE]', 'Fé')}

PREDIO = {'MONUMENT': 'Monumento', 'SHRINE': 'Santuário', 'TEMPLE': 'Templo', 'LIBRARY': 'Biblioteca',
          'UNIVERSITY': 'Universidade', 'PUBLIC_SCHOOL': 'Escola Pública', 'LABORATORY': 'Laboratório',
          'MARKET': 'Mercado', 'BANK': 'Banco', 'STOCK_EXCHANGE': 'Bolsa de Valores', 'FACTORY': 'Fábrica',
          'WORKSHOP': 'Oficina', 'HYDRO_PLANT': 'Hidrelétrica', 'SOLAR_PLANT': 'Usina Solar',
          'GARDEN': 'Jardim', 'COURTHOUSE': 'Tribunal', 'LIGHTHOUSE': 'Farol', 'COLOSSEUM': 'Coliseu', 'AMPHITHEATER': 'Anfiteatro', 'OPERA_HOUSE': 'Ópera', 'MUSEUM': 'Museu',
          'HOSPITAL': 'Hospital', 'AQUEDUCT': 'Aqueduto', 'PALACE': 'Palácio', 'HARBOR': 'Porto',
          'SEAPORT': 'Porto Marítimo', 'CATHEDRAL': 'Catedral', 'MOSQUE': 'Mesquita', 'PAGODA': 'Pagode',
          'POLICE_STATION': 'Delegacia', 'BARRACKS': 'Quartel', 'STADIUM': 'Estádio',
          'BROADCAST_TOWER': 'Torre de Transmissão', 'MINT': 'Casa da Moeda', 'GRANARY': 'Celeiro'}

MELHORIA = {'FARM': 'Fazenda', 'MINE': 'Mina', 'QUARRY': 'Pedreira', 'LUMBERMILL': 'Serraria',
            'PASTURE': 'Pasto', 'PLANTATION': 'Plantação', 'CAMP': 'Acampamento', 'TRADING_POST': 'Entreposto',
            'FISHING_BOATS': 'Barcos de Pesca', 'CUSTOMS_HOUSE': 'Alfândega', 'MANUFACTORY': 'Manufatura',
            'HOLY_SITE': 'Local Sagrado', 'ACADEMY': 'Academia'}

UNIDADE = {'WORKER': 'Trabalhador', 'SETTLER': 'Colono', 'GREAT_GENERAL': 'Grande General',
           'PROPHET': 'Grande Profeta', 'SCIENTIST': 'Grande Cientista', 'ENGINEER': 'Grande Engenheiro',
           'MERCHANT': 'Grande Comerciante', 'ARTIST': 'Grande Artista', 'MISSIONARY': 'Missionário',
           'INQUISITOR': 'Inquisidor', 'INFANTRY': 'Infantaria', 'GREAT_ADMIRAL': 'Grande Almirante'}

COL = {
    'UnhappinessMod': lambda v: f'{v:+d}% de [ICON_HAPPINESS_4] infelicidade da população',
    'GreatPeopleRateModifier': lambda v: f'+{v}% de nascimento de Grandes Pessoas',
    'GreatScientistRateModifier': lambda v: f'+{v}% de nascimento de Grandes Cientistas',
    'GreatMerchantRateModifier': lambda v: f'+{v}% de nascimento de Grandes Comerciantes',
    'GreatArtistRateModifier': lambda v: f'+{v}% de nascimento de Grandes Artistas',
    'GreatWriterRateModifier': lambda v: f'+{v}% de nascimento de Grandes Escritores',
    'GreatMusicianRateModifier': lambda v: f'+{v}% de nascimento de Grandes Músicos',
    'GreatGeneralRateModifier': lambda v: f'+{v}% de nascimento de Grandes Generais',
    'MilitaryProductionModifier': lambda v: f'+{v}% de [ICON_PRODUCTION] produção de unidades militares',
    'WonderProductionModifier': lambda v: f'+{v}% de [ICON_PRODUCTION] produção de Maravilhas',
    'BuildingProductionModifier': lambda v: f'+{v}% de [ICON_PRODUCTION] produção de construções',
    'UnitPurchaseCostModifier': lambda v: f'Unidades {-v}% mais baratas com [ICON_GOLD] Ouro',
    'BuildingPurchaseCostModifier': lambda v: f'Construções {-v}% mais baratas com [ICON_GOLD] Ouro',
    'FaithCostModifier': lambda v: f'Compras com [ICON_PEACE] Fé {-v}% mais baratas',
    'UnitGoldMaintenanceMod': lambda v: f'Manutenção de unidades {-v}% mais barata',
    'CityGrowthMod': lambda v: f'+{v}% de crescimento das cidades',
    'FreeExperience': lambda v: f'Novas unidades nascem com +{v} de experiência',
    'ExpModifier': lambda v: f'+{v}% de experiência em combate',
    'CityStrengthMod': lambda v: f'+{v}% de defesa das cidades',
    'GoldenAgeDurationMod': lambda v: f'[ICON_GOLDEN_AGE] Eras de Ouro duram {v}% mais',
    'GoldenAgeTurns': lambda v: f'Começa uma [ICON_GOLDEN_AGE] Era de Ouro de {v} turnos',
    'NumFreeTechs': lambda v: f'{v} tecnologia(s) grátis',
    'NumFreeGreatPeople': lambda v: f'{v} Grande Pessoa grátis à sua escolha',
    'WorkerSpeedModifier': lambda v: f'Trabalhadores {v}% mais rápidos',
    'NewCityExtraPopulation': lambda v: f'Cidades novas nascem com +{v} de [ICON_CITIZEN] população',
    'SharedIdeologyTourismModifier': lambda v: f'+{v}% de [ICON_TOURISM] Turismo para quem tem a mesma ideologia',
    'ProtectedMinorPerTurnInfluence': lambda v: f'+{v // 100} de influência por turno com cidades-estado protegidas',
    'MinorFriendshipMinimum': lambda v: f'Influência mínima de {v} com todas as cidades-estado',
    'MinorGoldFriendshipMod': lambda v: f'Presentes em ouro a cidades-estado rendem +{v}% de influência',
    'MinorQuestFriendshipMod': lambda v: f'Missões de cidades-estado rendem +{v}% de influência',
    'CulturePerCity': lambda v: f'+{v} [ICON_CULTURE] Cultura em cada cidade',
    'HappinessPerXPopulation': lambda v: f'+1 [ICON_HAPPINESS_1] felicidade a cada {v} habitantes de cada cidade',
    'CatchSpiesModifier': lambda v: f'+{v}% de chance de pegar espiões inimigos',
    'StealTechFasterModifier': lambda v: f'Seus espiões roubam tecnologia {v}% mais rápido',
    'ThemingBonusMultiplier': lambda v: f'Bônus de tema dos museus +{v}%',
    'SharedIdeologyTradeGoldChange': lambda v: f'+{v} [ICON_GOLD] Ouro por rota comercial com quem tem a mesma ideologia',
    'InternalTradeRouteYieldModifier': lambda v: f'Rotas comerciais internas rendem +{v}%',
    'EnablesSSPartHurry': lambda v: 'Peças de nave espacial podem ser aceleradas com Engenheiros',
    'EnablesSSPartPurchase': lambda v: 'Peças de nave espacial podem ser compradas com [ICON_GOLD] Ouro',
    'HappinessPerGarrisonedUnit': lambda v: f'+{v} [ICON_HAPPINESS_1] felicidade por cidade com guarnição',
    'GreatAdmiralRateModifier': lambda v: f'+{v}% de nascimento de Grandes Almirantes',
    'TradeRouteTourismModifier': lambda v: f'+{v}% de [ICON_TOURISM] Turismo com quem tem rota comercial com você',
    'CulturePerGarrisonedUnit': lambda v: f'+{v} [ICON_CULTURE] Cultura por cidade com guarnição',
}

PROMOS = {
    'NVG_GUERRA_SANTA': ('Guerra Santa', '+15% de [ICON_STRENGTH] força em combate.', {'CombatPercent': 15}, 59),
    'NVG_GUARDA': ('Guarda Ideológica', '+10% de [ICON_STRENGTH] força em combate.', {'CombatPercent': 10}, 59),
    'NVG_MILICIA': ('Milícia Popular', '+20% de [ICON_STRENGTH] força em território próprio.', {'FriendlyLandsModifier': 20}, 59),
    'NVG_GUERRILHA': ('Guerrilha', '+25% de [ICON_STRENGTH] força em terreno acidentado.', {'RoughAttack': 25, 'RoughDefense': 25}, 59),
    'NVG_DISCIPLINA': ('Disciplina de Ferro', '+15% de [ICON_STRENGTH] força em território próprio e +10% fora.', {'FriendlyLandsModifier': 15, 'OutsideFriendlyLandsModifier': 10}, 59),
    'NVG_REBELDE': ('Rebelde', '+10% de [ICON_STRENGTH] força em combate.', {'CombatPercent': 10}, 59),
}


def c(nome, v): return ('col', nome, v)
def cidade(y, n): return ('cidade', y, n)
def capital(y, n): return ('capital', y, n)
def predio(b, y, n): return ('predio', b, y, n)
def feliz(b, n): return ('feliz', b, n)
def melhoria(i, y, n): return ('melhoria', i, y, n)
def unidade(u, n): return ('unidade', u, n)
def promo(p): return ('promo', p)
def espec(y, n): return ('espec', y, n)
def palacio_cultura(n): return ('cultpredio', 'PALACE', n)



def q(s): return "'" + s.replace("'", "''") + "'"


def descrever(efeito):
    k = efeito[0]
    if k == 'col':
        return COL[efeito[1]](efeito[2])
    if k == 'cidade':
        i, n = Y[efeito[1]]; return f'+{efeito[2]} {i} {n} em cada cidade'
    if k == 'capital':
        i, n = Y[efeito[1]]; return f'+{efeito[2]} {i} {n} na capital'
    if k == 'predio':
        i, n = Y[efeito[2]]; return f'{PREDIO[efeito[1]]}: +{efeito[3]} {i} {n}'
    if k == 'feliz':
        if efeito[1] == 'PALACE': return f'+{efeito[2]} [ICON_HAPPINESS_1] felicidade'
        return f'{PREDIO[efeito[1]]}: +{efeito[2]} [ICON_HAPPINESS_1] felicidade'
    if k == 'melhoria':
        i, n = Y[efeito[2]]; return f'{MELHORIA[efeito[1]]}: +{efeito[3]} {i} {n}'
    if k == 'unidade':
        return f'Ganha {efeito[2]} {UNIDADE[efeito[1]]}' + ('s' if efeito[2] > 1 and not UNIDADE[efeito[1]].endswith('r') else ('es' if efeito[2] > 1 else ''))
    if k == 'promo':
        n, h, _, _ = PROMOS[efeito[1]]; return f'Unidades militares ganham [COLOR_POSITIVE_TEXT]{n}[ENDCOLOR]: {h}'
    if k == 'espec':
        i, n = Y[efeito[1]]; return f'Especialistas +{efeito[2]} {i} {n}'
    if k == 'cultpredio':
        return f'Palácio: +{efeito[2]} [ICON_CULTURE] Cultura'
    raise ValueError(efeito)


def sql_efeito(pol, e, out):
    k = e[0]
    if k == 'col':
        out.append(f'UPDATE Policies SET {e[1]} = {e[2]} WHERE Type = {q(pol)};')
        if e[1] == 'NumFreeGreatPeople' or e[1] == 'NumFreeTechs' or e[1] == 'GoldenAgeTurns':
            out.append(f'UPDATE Policies SET OneShot = 1 WHERE Type = {q(pol)};')
    elif k == 'cidade':
        out.append(f"INSERT INTO Policy_CityYieldChanges (PolicyType, YieldType, Yield) VALUES ({q(pol)}, 'YIELD_{e[1]}', {e[2]});")
    elif k == 'capital':
        out.append(f"INSERT INTO Policy_CapitalYieldChanges (PolicyType, YieldType, Yield) VALUES ({q(pol)}, 'YIELD_{e[1]}', {e[2]});")
    elif k == 'predio':
        out.append(f"INSERT INTO Policy_BuildingClassYieldChanges (PolicyType, BuildingClassType, YieldType, YieldChange) VALUES ({q(pol)}, 'BUILDINGCLASS_{e[1]}', 'YIELD_{e[2]}', {e[3]});")
    elif k == 'feliz':
        out.append(f"INSERT INTO Policy_BuildingClassHappiness (PolicyType, BuildingClassType, Happiness) VALUES ({q(pol)}, 'BUILDINGCLASS_{e[1]}', {e[2]});")
    elif k == 'melhoria':
        out.append(f"INSERT INTO Policy_ImprovementYieldChanges (PolicyType, ImprovementType, YieldType, Yield) VALUES ({q(pol)}, 'IMPROVEMENT_{e[1]}', 'YIELD_{e[2]}', {e[3]});")
    elif k == 'unidade':
        out.append(f"INSERT INTO Policy_FreeUnitClasses (PolicyType, UnitClassType, Count) VALUES ({q(pol)}, 'UNITCLASS_{e[1]}', {e[2]});")
        out.append(f'UPDATE Policies SET IncludesOneShotFreeUnits = 1 WHERE Type = {q(pol)};')
    elif k == 'promo':
        out.append(f"INSERT INTO Policy_FreePromotions (PolicyType, PromotionType) VALUES ({q(pol)}, 'PROMOTION_{e[1]}');")
    elif k == 'espec':
        out.append(f"INSERT INTO Policy_SpecialistExtraYields (PolicyType, YieldType, Yield) VALUES ({q(pol)}, 'YIELD_{e[1]}', {e[2]});")
    elif k == 'cultpredio':
        out.append(f"INSERT INTO Policy_BuildingClassCultureChanges (PolicyType, BuildingClassType, CultureChange) VALUES ({q(pol)}, 'BUILDINGCLASS_{e[1]}', {e[2]});")



T = {}
