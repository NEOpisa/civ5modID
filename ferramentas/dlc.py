import hashlib, os, shutil, sqlite3, sys
from loc import caminho as caminho_loc
from xml.sax.saxutils import escape

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.join(AQUI, '..')
MOD = os.path.join(RAIZ, 'EraDasIdeologias')
BASE = os.path.join(AQUI, 'base', 'civ5_bnw.db')
JOGO = os.path.expanduser("~/Games/SteamLibrary/steamapps/common/Sid Meier's Civilization V/steamassets/assets")
SAIDA = os.path.join(RAIZ, 'saida')
PASTA = 'eradasideologias'
GUID = '{5C1E9A47-2B7D-4E83-A6F0-9D24C3B81E62}'
VERSAO = 2

UI = [
    'Lua/NVGDados.lua', 'Lua/EraDasIdeologias.lua', 'Lua/EraDasIdeologias.xml',
    'UI/BoraSeusG.lua', 'UI/BoraSeusG.xml', 'UI/Ideologias.lua', 'UI/Ideologias.xml',
    'Telas/SocialPolicyPopup.lua', 'Telas/SocialPolicyPopup.xml', 'Telas/DiploCorner.lua',
]
CONTEXTOS = [('EraDasIdeologias', 'NVGRegras'), ('Ideologias', 'NVGIdeologias'), ('BoraSeusG', 'NVGMundo')]
CHAVES = ['Type', 'Name', 'Tag']


def instrucoes(caminho):
    texto = open(caminho, encoding='utf-8').read()
    return [l for l in texto.split('\n') if l.strip()]


def tabelas(db):
    return [r[0] for r in db.execute("select name from sqlite_master where type = 'table' and name not like 'sqlite_%'")]


def colunas(db, t):
    return [r[1] for r in db.execute(f'pragma table_info("{t}")')]


def chave(db, t, cols):
    for c in CHAVES:
        if c in cols:
            n, d = db.execute(f'select count(*), count(distinct "{c}") from "{t}"').fetchone()
            if n == d:
                return c
    return None


def foto(db):
    out = {}
    for t in tabelas(db):
        cols = colunas(db, t)
        out[t] = (cols, db.execute(f'select * from "{t}"').fetchall())
    return out


def val(v):
    if isinstance(v, float) and v.is_integer() and False:
        return str(int(v))
    return escape(str(v))


def padrao(v, d):
    if d is None:
        return False
    d = d.strip("'\"").lower()
    if d in ('false', 'true'):
        d = '1' if d == 'true' else '0'
    try:
        return float(v) == float(d)
    except (TypeError, ValueError):
        return str(v) == d


BOOL = set()


def xv(t, c, v):
    if (t, c) in BOOL:
        return 'true' if v else 'false'
    return val(v)


def linha_xml(cols, row, recuo='\t\t', defs=None, t=None):
    defs = defs or {}
    campos = ''.join(f'{recuo}\t<{c}>{xv(t, c, v)}</{c}>\n' for c, v in zip(cols, row) if c != 'ID' and v is not None and not padrao(v, defs.get(c)))
    return f'{recuo}<Row>\n{campos}{recuo}</Row>\n'


def update_xml(k, kv, mudou, recuo='\t\t', t=None):
    sets = ''.join(f'{recuo}\t\t<{c}>{xv(t, c, v)}</{c}>\n' for c, v in mudou)
    return f'{recuo}<Update>\n{recuo}\t<Where {k}="{escape(str(kv))}"/>\n{recuo}\t<Set>\n{sets}{recuo}\t</Set>\n{recuo}</Update>\n'


def diferenca(antes, depois, db_depois, avisos):
    blocos = []
    for t, (cols, linhas) in depois.items():
        cols_a, linhas_a = antes.get(t, (cols, []))
        k = chave(db_depois, t, cols)
        info = db_depois.execute(f'pragma table_info("{t}")').fetchall()
        defs = {r[1]: r[4] for r in info}
        BOOL.update((t, r[1]) for r in info if (r[2] or '').lower() == 'boolean')
        partes = []
        if k:
            i = cols.index(k)
            velho = {r[i]: r for r in linhas_a}
            for r in linhas:
                a = velho.get(r[i])
                if a is None:
                    partes.append(linha_xml(cols, r, defs=defs, t=t))
                else:
                    mudou = [(c, v) for c, v, w in zip(cols, r, a) if c != 'ID' and v != w]
                    if any(v is None for _, v in mudou):
                        avisos.append(f'{t}.{r[i]}: NULL em update')
                        mudou = [(c, v) for c, v in mudou if v is not None]
                    if mudou:
                        partes.append(update_xml(k, r[i], mudou, t=t))
            novos = {r[i] for r in linhas}
            for kv in velho:
                if kv not in novos:
                    partes.append(f'\t\t<Delete {k}="{escape(str(kv))}"/>\n')
        else:
            sem_id = lambda rs: [tuple(v for c, v in zip(cols, r) if c != 'ID') for r in rs]
            restante = {}
            for r in sem_id(linhas_a):
                restante[r] = restante.get(r, 0) + 1
            cols_sem = [c for c in cols if c != 'ID']
            for r in sem_id(linhas):
                if restante.get(r, 0) > 0:
                    restante[r] -= 1
                else:
                    partes.append(linha_xml(cols_sem, r, defs=defs, t=t))
            for r, n in restante.items():
                if n > 0:
                    avisos.append(f'{t}: {n} linha(s) apagada(s) sem chave')
        if partes:
            blocos.append(f'\t<{t}>\n' + ''.join(partes) + f'\t</{t}>\n')
    return '<?xml version="1.0" encoding="utf-8"?>\n<GameData>\n' + ''.join(blocos) + '</GameData>\n'


def dados(tmp, avisos):
    db_tmp = os.path.join(tmp, 'dlc_base.db')
    shutil.copy(BASE, db_tmp)
    db = sqlite3.connect(db_tmp)
    antes = foto(db)
    for l in instrucoes(os.path.join(MOD, 'SQL', 'Dados.sql')):
        db.execute(l)
    db.commit()
    return diferenca(antes, foto(db), db, avisos)


def textos(avisos):
    loc = sqlite3.connect(':memory:')
    loc.execute('create table Language_en_US (Tag text primary key, Text text)')
    src = sqlite3.connect(caminho_loc())
    loc.executemany('insert or replace into Language_en_US values (?, ?)', src.execute("select Tag, Text from LocalizedText where Language = 'en_US'"))
    antes = foto(loc)
    for l in instrucoes(os.path.join(MOD, 'SQL', 'Textos.sql')):
        loc.execute(l)
    return diferenca(antes, foto(loc), loc, avisos)


def ingame():
    origem = os.path.join(JOGO, 'dlc', 'expansion2', 'ui', 'ingame', 'ingame.xml')
    texto = open(origem, encoding='utf-8-sig').read()
    novos = ''.join(f'\t\t<LuaContext FileName="{f}" ID="{i}" Hidden="0"/>\n' for f, i in CONTEXTOS)
    marca = '\t\t<LuaContext FileName="Assets/UI/InGame/TopPanel"'
    if marca not in texto:
        sys.exit('ingame.xml: TopPanel não encontrado')
    return texto.replace(marca, novos + marca, 1)


def pacote():
    chave_md5 = hashlib.md5(f'{GUID}{VERSAO}'.encode()).hexdigest()
    return f'''<?xml version="1.0" encoding="utf-8"?>
<Civ5Package>
	<GUID>{GUID}</GUID>
	<SteamApp>99999</SteamApp>
	<Version>{VERSAO}</Version>
	<Priority>400</Priority>
	<Ownership>FREE</Ownership>
	<Key>{chave_md5}</Key>
	<PTags>
		<Tag>Version</Tag>
		<Tag>Ownership</Tag>
	</PTags>
	<Name>
		<Value language="en_US">Era das Ideologias</Value>
	</Name>
	<Description>
		<Value language="en_US">Era das Ideologias {VERSAO}</Value>
	</Description>
	<Gameplay>
		<GameData>nvg_dados.xml</GameData>
		<TextData>nvg_textos.xml</TextData>
		<Directory>Gameplay</Directory>
	</Gameplay>
	<UISkin name="Expansion2Primary" set="Expansion2" platform="Common">
		<Skin>
			<Paks>
			</Paks>
		</Skin>
		<GameplaySkin>
			<Directory>UI</Directory>
			<Paks>
			</Paks>
		</GameplaySkin>
	</UISkin>
	<Paks>
	</Paks>
</Civ5Package>
'''


def gerar(tmp):
    avisos = []
    destino = os.path.join(SAIDA, 'dlc', PASTA)
    if os.path.isdir(destino):
        shutil.rmtree(destino)
    os.makedirs(os.path.join(destino, 'gameplay', 'xml', 'text', 'en_us'))
    os.makedirs(os.path.join(destino, 'ui'))
    open(os.path.join(destino, 'gameplay', 'xml', 'nvg_dados.xml'), 'w', encoding='utf-8').write(dados(tmp, avisos))
    open(os.path.join(destino, 'gameplay', 'xml', 'text', 'en_us', 'nvg_textos.xml'), 'w', encoding='utf-8').write(textos(avisos))
    for p in UI:
        shutil.copy(os.path.join(MOD, p), os.path.join(destino, 'ui', os.path.basename(p).lower()))
    open(os.path.join(destino, 'ui', 'ingame.xml'), 'w', encoding='utf-8').write(ingame())
    open(os.path.join(destino, PASTA + '.civ5pkg'), 'w', encoding='utf-8').write(pacote())
    return destino, avisos


def conferir(destino):
    db = sqlite3.connect(':memory:')
    shutil.copy(BASE, os.path.join(TMP, 'dlc_conf.db'))
    db = sqlite3.connect(os.path.join(TMP, 'dlc_conf.db'))
    import xml.etree.ElementTree as ET
    conv = lambda x: {'true': 1, 'false': 0}.get(x, x)
    raiz = ET.parse(os.path.join(destino, 'gameplay', 'xml', 'nvg_dados.xml')).getroot()
    for tab in raiz:
        for op in tab:
            if op.tag == 'Row':
                cs = [c.tag for c in op]
                db.execute(f'insert into "{tab.tag}" ({", ".join(cs)}) values ({", ".join("?" * len(cs))})', [conv(c.text) for c in op])
            elif op.tag == 'Update':
                w = op.find('Where').attrib
                s = [(c.tag, conv(c.text)) for c in op.find('Set')]
                (wk, wv), = w.items()
                db.execute(f'update "{tab.tag}" set {", ".join(c + " = ?" for c, _ in s)} where {wk} = ?', [v for _, v in s] + [wv])
            elif op.tag == 'Delete':
                (wk, wv), = op.attrib.items()
                db.execute(f'delete from "{tab.tag}" where {wk} = ?', [wv])
    ref = sqlite3.connect(os.path.join(TMP, 'dlc_base.db'))
    erros = []
    for t in tabelas(ref):
        cs = [c for c in colunas(ref, t) if c != 'ID']
        sel = ', '.join(f'"{c}"' for c in cs)
        a = sorted(map(repr, ref.execute(f'select {sel} from "{t}"').fetchall()))
        b = sorted(map(repr, db.execute(f'select {sel} from "{t}"').fetchall()))
        if a != b:
            erros.append(f'{t}: diferente ({len(a)} x {len(b)} linhas)')
    return erros


if __name__ == '__main__':
    TMP = os.environ.get('NVG_TMP', '/tmp')
    destino, avisos = gerar(TMP)
    erros = conferir(destino)
    for a in avisos + erros:
        print('AVISO', a)
    print(destino)
