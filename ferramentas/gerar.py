import os, shutil, sqlite3, sys

from efeitos import T, q, descrever, sql_efeito, PROMOS
from crencas import CRENCAS
from loc import caminho as caminho_loc
from conteudo import CLASSICAS, EVOLUCOES, IDEOLOGIAS, ICONE_IDEOLOGIA

AQUI = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.join(AQUI, '..', 'EraDasIdeologias')
BASE = os.path.join(AQUI, 'base', 'civ5_bnw.db')
NEUTRO = 'POLICY_BRANCH_NVG_NEUTRO'


def efeitos_txt(efeitos):
    return '[NEWLINE]'.join('[ICON_BULLET]' + descrever(e) for e in efeitos)


ATLAS_OK = {'POLICY_ATLAS': 'POLICY_A_ATLAS', 'POLICY_ATLAS_EXP2': 'POLICY_A_ATLAS_EXP2'}


def politica(s, tipo, ramo, nome, efeitos, x, y, atlas, idx, extra='', atlas_ok=None):
    ramo_sql = q(ramo) if ramo else 'NULL'
    atlas_ok = atlas_ok or ATLAS_OK.get(atlas, atlas)
    s.append(f"INSERT INTO Policies (Type, Description, Civilopedia, Strategy, Help, PolicyBranchType, CultureCost, GridX, GridY, Level, PortraitIndex, IconAtlas, IconAtlasAchieved) VALUES ({q(tipo)}, 'TXT_KEY_{tipo}', 'TXT_KEY_{tipo}_HELP', 'TXT_KEY_{tipo}_HELP', 'TXT_KEY_{tipo}_HELP', {ramo_sql}, 10, {x}, {y}, 0, {idx}, {q(atlas)}, {q(atlas_ok)});")
    for e in efeitos:
        sql_efeito(tipo, e, s)
    T[f'TXT_KEY_{tipo}'] = nome
    T[f'TXT_KEY_{tipo}_HELP'] = f'[COLOR_POSITIVE_TEXT]{nome}[ENDCOLOR]{extra}[NEWLINE]{efeitos_txt(efeitos)}'


def ramo(s, tipo, nome, ajuda, abertura, final):
    s.append(f"INSERT INTO PolicyBranchTypes (Type, Description, Help, Title, FreePolicy, FreeFinishingPolicy, PurchaseByLevel) VALUES ({q(tipo)}, 'TXT_KEY_{tipo}', 'TXT_KEY_{tipo}_HELP', 'TXT_KEY_{tipo}', {q(abertura)}, {q(final)}, 0);")
    T[f'TXT_KEY_{tipo}'] = nome
    T[f'TXT_KEY_{tipo}_CAP'] = nome.upper()
    T[f'TXT_KEY_{tipo}_HELP'] = ajuda


CORES = {
    'CAPITALISMO': (0.30, 0.55, 1.00), 'COMUNISMO': (0.95, 0.20, 0.20), 'FASCISMO': (0.60, 0.42, 0.25),
    'SOCIALDEM': (1.00, 0.45, 0.60), 'ANARQUISMO': (0.55, 0.55, 0.55), 'LIBERTARIANISMO': (1.00, 0.85, 0.20),
    'TECNOCRACIA': (0.25, 0.90, 0.95), 'ECOLOGISMO': (0.35, 0.85, 0.35), 'MONARQUIA_CONST': (0.70, 0.45, 1.00),
    'FUNDAMENTALISMO': (1.00, 0.95, 0.80),
}

SABORES = {
    'CAPITALISMO': [('FLAVOR_GOLD', 20), ('FLAVOR_GROWTH', 10)],
    'COMUNISMO': [('FLAVOR_PRODUCTION', 20), ('FLAVOR_OFFENSE', 10)],
    'FASCISMO': [('FLAVOR_OFFENSE', 20), ('FLAVOR_MILITARY_TRAINING', 15)],
    'SOCIALDEM': [('FLAVOR_HAPPINESS', 20), ('FLAVOR_GROWTH', 10)],
    'ANARQUISMO': [('FLAVOR_DEFENSE', 15), ('FLAVOR_CULTURE', 15)],
    'LIBERTARIANISMO': [('FLAVOR_GOLD', 25)],
    'TECNOCRACIA': [('FLAVOR_SCIENCE', 25)],
    'ECOLOGISMO': [('FLAVOR_CULTURE', 20), ('FLAVOR_HAPPINESS', 10)],
    'MONARQUIA_CONST': [('FLAVOR_DIPLOMACY', 20), ('FLAVOR_CULTURE', 10)],
    'FUNDAMENTALISMO': [('FLAVOR_RELIGION', 25)],
}


def sabor(s, tipo, lista):
    for f, n in lista:
        s.append(f"INSERT INTO Policy_Flavors (PolicyType, FlavorType, Flavor) VALUES ({q(tipo)}, {q(f)}, {n});")


NOMES_UNIDADE = {'UNIT_MERCHANT': 'Grande Comerciante', 'UNIT_GREAT_ADMIRAL': 'Grande Almirante', 'UNIT_SCIENTIST': 'Grande Cientista',
                 'UNIT_WORKER': 'Trabalhador', 'UNIT_MISSIONARY': 'Missionário', 'UNIT_GREAT_GENERAL': 'Grande General'}


def texto_presente(d):
    partes = []
    for k, icone, nome in (('ouro', '[ICON_GOLD]', 'Ouro'), ('fe', '[ICON_PEACE]', 'Fé'), ('cultura', '[ICON_CULTURE]', 'Cultura'), ('ciencia', '[ICON_RESEARCH]', 'Ciência')):
        if d.get(k):
            partes.append(f'+{d[k]} {icone} {nome}')
    if d.get('eraouro'):
        partes.append(f"{d['eraouro']} turnos de [ICON_GOLDEN_AGE] Era de Ouro")
    if d.get('pop'):
        partes.append(f"+{d['pop']} [ICON_CITIZEN] população em cada cidade")
    if d.get('producao'):
        partes.append(f"+{d['producao']} [ICON_PRODUCTION] produção em cada cidade")
    if d.get('influencia'):
        partes.append(f"+{d['influencia']} de influência com as cidades-estado conhecidas")
    if d.get('tropas'):
        n, pr = d['tropas']
        partes.append(f"{n} tropas com {PROMOS[pr.replace('PROMOTION_', '')][0]}")
    for u, n in d.get('unidades', []):
        nome = NOMES_UNIDADE[u]
        partes.append(f'{n} {nome}' + (('es' if nome.endswith('r') else 's') if n > 1 else ''))
    if d.get('exercito'):
        partes.append(f"todo o exército ganha {PROMOS[d['exercito'].replace('PROMOTION_', '')][0]}")
    assert partes, d
    return ', '.join(partes)


def gerar(base):
    s = []
    lua = {'evolucoes': {}, 'ideologias': {}, 'variantes': {}}
    lua['cores'] = {k: {'r': r, 'g': g, 'b': b} for k, (r, g, b) in CORES.items()}

    s.append("INSERT INTO BuildingClasses (Type, DefaultBuilding, Description) VALUES ('BUILDINGCLASS_NVG_TRIBO', 'BUILDING_NVG_TRIBO', 'TXT_KEY_BUILDING_NVG_TRIBO');")
    s.append("INSERT INTO Buildings (Type, BuildingClass, Cost, FaithCost, GreatWorkCount, GoldMaintenance, PrereqTech, Description, Help, NeverCapture, NukeImmune, ConquestProb, HurryCostModifier, MinAreaSize, IconAtlas, PortraitIndex) VALUES ('BUILDING_NVG_TRIBO', 'BUILDINGCLASS_NVG_TRIBO', -1, -1, -1, 0, NULL, 'TXT_KEY_BUILDING_NVG_TRIBO', 'TXT_KEY_BUILDING_NVG_TRIBO_HELP', 1, 1, 0, -1, -1, 'BW_ATLAS_1', 0);")
    for y in ('FOOD', 'PRODUCTION', 'CULTURE'):
        s.append(f"INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield) VALUES ('BUILDING_NVG_TRIBO', 'YIELD_{y}', 1);")
    T['TXT_KEY_BUILDING_NVG_TRIBO'] = 'Tribo'
    T['TXT_KEY_BUILDING_NVG_TRIBO_HELP'] = 'Enquanto você está na Era Antiga: +1 [ICON_FOOD] Comida, +1 [ICON_PRODUCTION] Produção e +1 [ICON_CULTURE] Cultura nesta cidade.'

    for p, (nome, ajuda, cols, idx) in PROMOS.items():
        extra = ''.join(f', {k}' for k in cols)
        vals = ''.join(f', {v}' for v in cols.values())
        s.append(f"INSERT INTO UnitPromotions (Type, Description, Help, Sound, CannotBeChosen, LostWithUpgrade, PortraitIndex, IconAtlas, PediaType, PediaEntry{extra}) VALUES ('PROMOTION_{p}', 'TXT_KEY_PROMOTION_{p}', 'TXT_KEY_PROMOTION_{p}_HELP', 'AS2D_IF_LEVELUP', 1, 0, {idx}, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_{p}'{vals});")
        s.append(f"INSERT INTO UnitPromotions_UnitCombats (PromotionType, UnitCombatType) SELECT 'PROMOTION_{p}', UnitCombatType FROM UnitPromotions_UnitCombats WHERE PromotionType = 'PROMOTION_NATIONALISM';")
        T[f'TXT_KEY_PROMOTION_{p}'] = nome
        T[f'TXT_KEY_PROMOTION_{p}_HELP'] = ajuda

    s.append(f"INSERT INTO PolicyBranchTypes (Type, Description, Help, Title, PurchaseByLevel) VALUES ('{NEUTRO}', 'TXT_KEY_{NEUTRO}', 'TXT_KEY_{NEUTRO}', 'TXT_KEY_{NEUTRO}', 1);")
    T[f'TXT_KEY_{NEUTRO}'] = 'Sem ideologia'
    s.append("UPDATE Buildings SET XBuiltTriggersIdeologyChoice = 0;")
    for chave, (r, g, b) in CORES.items():
        s.append(f"INSERT INTO Colors (Type, Red, Green, Blue, Alpha) VALUES ('COLOR_NVG_{chave}', {r}, {g}, {b}, 1.0);")
    s.append("INSERT INTO BuildingClasses (Type, DefaultBuilding, Description) VALUES ('BUILDINGCLASS_NVG_DESCONTO', 'BUILDING_NVG_DESCONTO', 'TXT_KEY_BUILDING_NVG_DESCONTO');")
    s.append("INSERT INTO Buildings (Type, BuildingClass, Cost, FaithCost, GreatWorkCount, GoldMaintenance, PrereqTech, Description, Help, NeverCapture, NukeImmune, ConquestProb, HurryCostModifier, MinAreaSize, PolicyCostModifier, IconAtlas, PortraitIndex) VALUES ('BUILDING_NVG_DESCONTO', 'BUILDINGCLASS_NVG_DESCONTO', -1, -1, -1, 0, NULL, 'TXT_KEY_BUILDING_NVG_DESCONTO', 'TXT_KEY_BUILDING_NVG_DESCONTO_HELP', 1, 1, 0, -1, -1, -50, 'BW_ATLAS_1', 0);")
    T['TXT_KEY_BUILDING_NVG_DESCONTO'] = 'Estado Nascente'
    T['TXT_KEY_BUILDING_NVG_DESCONTO_HELP'] = 'Até a sua primeira evolução, as políticas custam metade da [ICON_CULTURE] Cultura.'


    for classica, opcoes in EVOLUCOES.items():
        originais = base.execute("select Type, GridX, GridY, PortraitIndex, IconAtlas, IconAtlasAchieved from Policies where PolicyBranchType = ? order by ID", (classica,)).fetchall()
        assert len(originais) == 5, classica
        mapa = {}
        lua['evolucoes'][classica] = []
        for ev in opcoes:
            tipo = f"POLICY_BRANCH_NVG_E_{ev['chave']}"
            ab, fin = f"POLICY_NVG_E_{ev['chave']}", f"POLICY_NVG_E_{ev['chave']}_FINAL"
            ideo = ev['ideologia']
            linhas = [f"[COLOR_POSITIVE_TEXT]{ev['nome']}[ENDCOLOR] (evolução de {CLASSICAS[classica]})", ev['desc'], '',
                      '[COLOR_YELLOW]Ao adotar:[ENDCOLOR][NEWLINE]' + efeitos_txt(ev['abertura']), '',
                      '[COLOR_YELLOW]Ao completar:[ENDCOLOR][NEWLINE]' + efeitos_txt(ev['final']),
                      f"[ICON_BULLET]Se for a sua [COLOR_POSITIVE_TEXT]primeira[ENDCOLOR] evolução completa, libera a ideologia [COLOR_NVG_{ideo}]{IDEOLOGIAS[ideo]['nome']}[ENDCOLOR]"]
            ramo(s, tipo, ev['nome'], '[NEWLINE]'.join(linhas), ab, fin)
            politica(s, ab, None, ev['nome'], ev['abertura'], 0, 0, originais[0][4], originais[0][3])
            politica(s, fin, None, ev['nome'] + ' completo', ev['final'], 0, 0, originais[0][4], originais[0][3])
            for (otipo, gx, gy, idx, atlas, atlas_ok), (pnome, pef) in zip(originais, ev['politicas']):
                ptipo = f"POLICY_NVG_E_{ev['chave']}_{len(mapa) % 5 + 1}"
                mapa[otipo] = ptipo
                politica(s, ptipo, tipo, pnome, pef, gx, gy, atlas, idx, f" ({ev['nome']})", atlas_ok)
                orig = base.execute("select FlavorType, Flavor from Policy_Flavors where PolicyType = ?", (otipo,)).fetchall()
                sabor(s, ptipo, [(f, int(n * 1.5)) for f, n in orig] or SABORES[ideo])
            for otipo, _, _, _, _, _ in originais:
                for (pre,) in base.execute("select PrereqPolicy from Policy_PrereqPolicies where PolicyType = ?", (otipo,)):
                    s.append(f"INSERT INTO Policy_PrereqPolicies (PolicyType, PrereqPolicy) VALUES ({q(mapa[otipo])}, {q(mapa[pre])});")
            mapa.clear()
            lua['evolucoes'][classica].append({'tipo': tipo, 'nome': ev['nome'], 'ideologia': ideo, 'chave': ev['chave']})

    for chave, ideo in IDEOLOGIAS.items():
        atlas, idx = ICONE_IDEOLOGIA[chave]
        lua['ideologias'][chave] = {'nome': ideo['nome'], 'variantes': []}
        for origem, o in ideo['origens'].items():
            classica, evo = next((cl, e) for cl, op in EVOLUCOES.items() for e in op if e['chave'] == origem)
            assert evo['ideologia'] == chave, (chave, origem)
            icones = base.execute("select PortraitIndex, IconAtlas, IconAtlasAchieved from Policies where PolicyBranchType = ? order by ID", (classica,)).fetchall()
            tipo = f'POLICY_BRANCH_NVG_I_{chave}_{origem}'
            ab, fin = f'POLICY_NVG_I_{chave}_{origem}', f'POLICY_NVG_I_{chave}_{origem}_FINAL'
            todas = ideo['comuns'] + o['politicas']
            assert len(todas) == 5, chave
            presente = texto_presente(o['presente'])
            linhas = [f"[COLOR_NVG_{chave}]{ideo['nome']}[ENDCOLOR] (vinda do {evo['nome']})", o['desc'], '',
                      '[COLOR_YELLOW]Presente ao adotar:[ENDCOLOR] ' + presente, '',
                      '[COLOR_YELLOW]Abertura:[ENDCOLOR][NEWLINE]' + efeitos_txt(o['abertura']), '',
                      '[COLOR_YELLOW]Políticas:[ENDCOLOR]'] + [
                      f'[ICON_BULLET]{n}' + (f' [COLOR_POSITIVE_TEXT](só do {evo["nome"]})[ENDCOLOR]' if k >= len(ideo['comuns']) and o['politicas'] else '')
                      for k, (n, _) in enumerate(todas)] + [
                      '', '[COLOR_YELLOW]Ao completar:[ENDCOLOR][NEWLINE]' + efeitos_txt(o['final'])]
            ramo(s, tipo, ideo['nome'], '[NEWLINE]'.join(linhas), ab, fin)
            politica(s, ab, None, ideo['nome'], o['abertura'], 0, 0, atlas, idx)
            politica(s, fin, None, ideo['nome'] + ' completo', o['final'], 0, 0, atlas, idx)
            pos = [(1, 1), (3, 1), (5, 1), (2, 2), (4, 2)]
            tipos = []
            for n, ((pnome, pef), (x, y)) in enumerate(zip(todas, pos), 1):
                ptipo = f'POLICY_NVG_I_{chave}_{origem}_{n}'
                propria = n > len(ideo['comuns']) and o['politicas']
                extra = f" (só no {ideo['nome']} vindo do {evo['nome']})" if propria else ''
                if propria:
                    pidx, patlas, pok = icones[(n - len(ideo['comuns']) - 1) % len(icones)]
                    politica(s, ptipo, tipo, pnome, pef, x, y, patlas, pidx, extra, pok)
                else:
                    politica(s, ptipo, tipo, pnome, pef, x, y, atlas, idx, extra)
                sabor(s, ptipo, SABORES[chave])
                tipos.append(ptipo)
            s.append(f"INSERT INTO Policy_PrereqPolicies (PolicyType, PrereqPolicy) VALUES ({q(tipos[3])}, {q(tipos[0])});")
            s.append(f"INSERT INTO Policy_PrereqPolicies (PolicyType, PrereqPolicy) VALUES ({q(tipos[4])}, {q(tipos[2])});")
            evo_tipo = f'POLICY_BRANCH_NVG_E_{origem}'
            lua['ideologias'][chave]['variantes'].append(tipo)
            p = dict(o['presente'])
            if 'tropas' in p:
                p['tropas'] = {'n': p['tropas'][0], 'promo': p['tropas'][1]}
            if 'unidades' in p:
                p['unidades'] = [{'tipo': u, 'n': k} for u, k in p['unidades']]
            p['texto'] = presente
            lua['variantes'][tipo] = {'base': chave, 'origem': evo_tipo, 'politicas': tipos, 'abertura': ab, 'final': fin, 'presente': p}

    for chave, nome, slot, ajuda, cols, sub in CRENCAS:
        b = 'BELIEF_' + chave
        colunas = ''.join(f', {k}' for k in cols)
        vals = ''.join(f', {v}' for v in cols.values())
        s.append(f"INSERT INTO Beliefs (Type, Description, ShortDescription, {slot}{colunas}) VALUES ({q(b)}, 'TXT_KEY_{b}', 'TXT_KEY_{b}_SHORT', 1{vals});")
        for bc, y, n in sub.get('predio', []):
            s.append(f"INSERT INTO Belief_BuildingClassYieldChanges (BeliefType, BuildingClassType, YieldType, YieldChange) VALUES ({q(b)}, 'BUILDINGCLASS_{bc}', 'YIELD_{y}', {n});")
        for y, n in sub.get('cidade', []):
            s.append(f"INSERT INTO Belief_CityYieldChanges (BeliefType, YieldType, Yield) VALUES ({q(b)}, 'YIELD_{y}', {n});")
        T[f'TXT_KEY_{b}_SHORT'] = nome
        T[f'TXT_KEY_{b}'] = ajuda

    s.append('UPDATE Worlds SET MaxActiveReligions = MaxActiveReligions + 1;')
    s.append("UPDATE Defines SET Value = 150 WHERE Name = 'RELIGION_MIN_FAITH_FIRST_PROPHET';")
    s.append("UPDATE Defines SET Value = 75 WHERE Name = 'RELIGION_FAITH_DELTA_NEXT_PROPHET';")
    s.append("UPDATE Defines SET Value = 13 WHERE Name = 'RELIGION_ADJACENT_CITY_DISTANCE';")
    s.append("UPDATE Defines SET Value = 8 WHERE Name = 'RELIGION_BASE_CHANCE_PROPHET_SPAWN';")
    return s, lua


def textos():
    out = [f'INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES ({q(k)}, {q(v)});' for k, v in T.items()]
    for b, nome in CLASSICAS.items():
        out.append(f"UPDATE Language_en_US SET Text = {q(nome)} WHERE Tag = 'TXT_KEY_{b}';")
        out.append(f"UPDATE Language_en_US SET Text = {q(nome.upper())} WHERE Tag = 'TXT_KEY_{b}_CAP';")
        evos = ' ou '.join(e['nome'] for e in EVOLUCOES[b])
        out.append(f"UPDATE Language_en_US SET Text = {q('[COLOR_POSITIVE_TEXT]' + nome + '[ENDCOLOR]: ao completar, escolha a evolução: ' + evos + ' (máximo de 4 evoluções por partida).[NEWLINE][NEWLINE]')} || Text WHERE Tag = 'TXT_KEY_{b}_HELP';")
    out.append("UPDATE Language_en_US SET Text = 'Ideologias' WHERE Tag = 'TXT_KEY_POLICYSCREEN_IDEOLOGIES_TAB';")
    out.append("UPDATE Language_en_US SET Text = 'Ver ideologias' WHERE Tag = 'TXT_KEY_POLICYSCREEN_TO_IDEOLOGY_BUTTON';")
    out.append("UPDATE Language_en_US SET Text = 'IDEOLOGIA' WHERE Tag = 'TXT_KEY_POLICYSCREEN_IDEOLOGYPANEL_TITLE';")
    return out


def lua_tabela(v, n=0):
    if isinstance(v, dict):
        itens = ', '.join(f'[{lua_tabela(k)}] = {lua_tabela(x, n + 1)}' for k, x in v.items())
        return '{ ' + itens + ' }'
    if isinstance(v, list):
        return '{ ' + ', '.join(lua_tabela(x, n + 1) for x in v) + ' }'
    if isinstance(v, str):
        return '"' + v.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return str(v)


def validar(sql, txt):
    tmp = os.path.join(os.environ.get('NVG_TMP', '/tmp'), 'civ5_validar.db')
    shutil.copy(BASE, tmp)
    db = sqlite3.connect(tmp)
    erros = []
    for linha in sql:
        try:
            db.execute(linha)
        except Exception as e:
            erros.append(f'{e}: {linha[:140]}')
    tipos = lambda t: {r[0] for r in db.execute(f'select Type from {t}')}
    refs = [
        ('Policy_CityYieldChanges', 'YieldType', 'Yields'), ('Policy_BuildingClassYieldChanges', 'BuildingClassType', 'BuildingClasses'),
        ('Policy_BuildingClassHappiness', 'BuildingClassType', 'BuildingClasses'), ('Policy_ImprovementYieldChanges', 'ImprovementType', 'Improvements'),
        ('Policy_FreeUnitClasses', 'UnitClassType', 'UnitClasses'), ('Policy_FreePromotions', 'PromotionType', 'UnitPromotions'),
        ('Policy_SpecialistExtraYields', 'YieldType', 'Yields'), ('Policy_CapitalYieldChanges', 'YieldType', 'Yields'),
        ('Policy_BuildingClassCultureChanges', 'BuildingClassType', 'BuildingClasses'),
        ('Policies', 'PolicyBranchType', 'PolicyBranchTypes'), ('Belief_BuildingClassYieldChanges', 'BuildingClassType', 'BuildingClasses'),
        ('Buildings', 'BuildingClass', 'BuildingClasses'), ('UnitPromotions_UnitCombats', 'UnitCombatType', 'UnitCombatInfos'),
        ('Policy_PrereqPolicies', 'PrereqPolicy', 'Policies'), ('Policy_PrereqPolicies', 'PolicyType', 'Policies'),
        ('PolicyBranchTypes', 'FreePolicy', 'Policies'), ('PolicyBranchTypes', 'FreeFinishingPolicy', 'Policies'),
    ]
    for tab, col, alvo in refs:
        ok = tipos(alvo)
        for (v,) in db.execute(f'select distinct {col} from {tab} where {col} is not null'):
            if v not in ok:
                erros.append(f'{tab}.{col} = {v} não existe em {alvo}')
    for (pol,) in db.execute("select PolicyType from Policy_PrereqPolicies p where (select PolicyBranchType from Policies where Type = p.PolicyType) is not (select PolicyBranchType from Policies where Type = p.PrereqPolicy)"):
        erros.append(f'pré-requisito de outro ramo: {pol}')
    for (r, n) in db.execute("select PolicyBranchType, count(*) from Policies where PolicyBranchType like '%NVG%' group by 1"):
        if n != 5:
            erros.append(f'{r} tem {n} políticas')
    for (d, h) in db.execute("select Description, Help from Policies where Type like 'POLICY_NVG_%'"):
        for u in (d, h):
            if u not in T:
                erros.append(f'texto faltando: {u}')
    loc = sqlite3.connect(':memory:')
    loc.execute('create table Language_en_US (ID integer primary key, Tag text unique, Text text, Gender text, Plurality text)')
    src = sqlite3.connect(caminho_loc())
    loc.executemany('insert into Language_en_US (Tag, Text) values (?, ?)', src.execute("select Tag, Text from LocalizedText where Language = 'en_US'"))
    for linha in txt:
        try:
            loc.execute(linha)
        except Exception as e:
            erros.append(f'texto: {e}: {linha[:100]}')
    for b in CLASSICAS:
        if not loc.execute("select 1 from Language_en_US where Tag = ?", (f'TXT_KEY_{b}_CAP',)).fetchone():
            erros.append(f'sem _CAP: {b}')
    resumo = db.execute("select count(*) from PolicyBranchTypes where Type like '%NVG%'").fetchone()[0], db.execute("select count(*) from Policies where Type like 'POLICY_NVG%'").fetchone()[0]
    return erros, resumo


if __name__ == '__main__':
    base = sqlite3.connect(BASE)
    sql, lua = gerar(base)
    txt = textos()
    os.makedirs(os.path.join(MOD, 'SQL'), exist_ok=True)
    open(os.path.join(MOD, 'SQL', 'Dados.sql'), 'w').write('\n'.join(sql) + '\n')
    open(os.path.join(MOD, 'SQL', 'Textos.sql'), 'w').write('\n'.join(txt) + '\n')
    open(os.path.join(MOD, 'Lua', 'NVGDados.lua'), 'w').write('NVG = ' + lua_tabela(lua) + '\n')
    erros, resumo = validar(sql, txt)
    for e in erros:
        print('ERRO', e)
    print('ramos novos:', resumo[0], 'políticas novas:', resumo[1], 'linhas SQL:', len(sql), 'textos:', len(txt), 'erros:', len(erros))
    sys.exit(1 if erros else 0)
