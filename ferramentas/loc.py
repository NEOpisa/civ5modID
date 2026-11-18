import os, sqlite3
import xml.etree.ElementTree as ET

AQUI = os.path.dirname(os.path.abspath(__file__))
JOGO = os.path.expanduser("~/Games/SteamLibrary/steamapps/common/Sid Meier's Civilization V/steamassets/assets")
SAIDA = os.path.join(AQUI, 'base', 'loc_en.db')
ORDEM = ['gameplay/xml/newtext', 'dlc/shared', 'dlc/dlc_01', 'dlc/dlc_07', 'dlc/expansion/gameplay', 'dlc/expansion/dlc', 'dlc/expansion2']


def campo(el, nome):
    if nome in el.attrib:
        return el.attrib[nome]
    filho = el.find(nome)
    return filho.text if filho is not None else None


def arquivos(pasta):
    for raiz, _, nomes in sorted(os.walk(pasta)):
        if 'scenario' in raiz.lower():
            continue
        for n in sorted(nomes):
            if n.lower().endswith('.xml'):
                yield os.path.join(raiz, n)


def montar():
    textos = {}
    for parte in ORDEM:
        for arq in arquivos(os.path.join(JOGO, parte)):
            try:
                raiz = ET.parse(arq).getroot()
            except ET.ParseError:
                continue
            for tab in raiz.findall('Language_en_US'):
                for op in tab:
                    if op.tag in ('Row', 'Replace'):
                        tag = campo(op, 'Tag')
                        if tag:
                            textos[tag] = campo(op, 'Text') or ''
                    elif op.tag == 'Update':
                        w, s = op.find('Where'), op.find('Set')
                        tag = w is not None and w.attrib.get('Tag')
                        if tag and s is not None:
                            t = campo(s, 'Text')
                            if t is not None:
                                textos[tag] = t
                    elif op.tag == 'Delete':
                        textos.pop(op.attrib.get('Tag'), None)
    if os.path.exists(SAIDA):
        os.remove(SAIDA)
    db = sqlite3.connect(SAIDA)
    db.execute("create table LocalizedText (Language text, Tag text, Text text)")
    db.executemany("insert into LocalizedText values ('en_US', ?, ?)", textos.items())
    db.commit()
    return len(textos)


def caminho():
    if not os.path.exists(SAIDA):
        montar()
    return SAIDA


if __name__ == '__main__':
    print(montar())
