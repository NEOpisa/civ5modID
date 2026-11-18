import os, shutil, sqlite3, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
destino = sys.argv[1]
tmp = destino + '.db'
shutil.copy(os.path.join(AQUI, 'base', 'civ5_bnw.db'), tmp)
db = sqlite3.connect(tmp)
db.executescript(open(os.path.join(AQUI, '..', 'EraDasIdeologias', 'SQL', 'Dados.sql'), encoding='utf-8').read())


def lua(v):
    if v is None:
        return 'nil'
    if isinstance(v, (int, float)):
        return str(v)
    return '"' + str(v).replace('\\', '\\\\').replace('"', '\\"') + '"'


saida = ['FIXTURE = {}']
for tabela, cols in [('PolicyBranchTypes', ['Type', 'Description', 'Help', 'FreePolicy', 'FreeFinishingPolicy', 'PurchaseByLevel']),
                     ('Policies', ['Type', 'Description', 'Help', 'PolicyBranchType', 'GridX', 'GridY', 'PortraitIndex', 'IconAtlas', 'IconAtlasAchieved'])]:
    saida.append(f'FIXTURE.{tabela} = {{')
    for linha in db.execute(f'select {", ".join(cols)} from {tabela} order by ID'):
        campos = ', '.join(f'{c} = {lua(v if not (c == "PurchaseByLevel") else (v == 1 and "true" or None))}' for c, v in zip(cols, linha))
        saida.append('\t{ ' + campos.replace('"true"', 'true') + ' },')
    saida.append('}')
db.close()
os.remove(tmp)
open(destino, 'w', encoding='utf-8').write('\n'.join(saida) + '\n')
