import hashlib, os, sys, uuid, shutil

AQUI = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.join(AQUI, '..', 'EraDasIdeologias')
ID = 'a7f3c2d1-5e8b-4c6a-9f20-3b1d7e4a9c55'
VERSAO = 2

ARQUIVOS = [
    ('SQL/Dados.sql', False), ('SQL/Textos.sql', False),
    ('Lua/NVGDados.lua', True), ('Lua/EraDasIdeologias.lua', True), ('Lua/EraDasIdeologias.xml', True),
    ('UI/BoraSeusG.lua', True), ('UI/BoraSeusG.xml', True), ('UI/Ideologias.lua', True), ('UI/Ideologias.xml', True),
    ('Telas/SocialPolicyPopup.lua', True), ('Telas/SocialPolicyPopup.xml', True), ('Telas/DiploCorner.lua', True),
]


def md5(p):
    return hashlib.md5(open(os.path.join(MOD, p), 'rb').read()).hexdigest().upper()


def modinfo():
    files = '\n'.join(f'    <File md5="{md5(p)}" import="{1 if imp else 0}">{p.lower()}</File>' for p, imp in ARQUIVOS)
    return f'''<?xml version="1.0" encoding="utf-8"?>
<Mod id="{ID}" version="{VERSAO}">
  <Properties>
    <Name>Era das Ideologias</Name>
    <Teaser>Arvores que evoluem, 10 ideologias, religiao turbinada e eventos mundiais</Teaser>
    <Description>Completar uma arvore de politica libera 1 de 2 evolucoes; completar a evolucao libera uma ideologia (10 no total, com versoes diferentes conforme a origem). Guerra Fria, revolucoes, 12 eventos mundiais e 7 crencas novas.</Description>
    <Authors>NEO</Authors>
    <HideSetupGame>0</HideSetupGame>
    <AffectsSavedGames>1</AffectsSavedGames>
    <MinCompatibleSaveVersion>2</MinCompatibleSaveVersion>
    <SupportsSinglePlayer>1</SupportsSinglePlayer>
    <SupportsMultiplayer>1</SupportsMultiplayer>
    <SupportsHotSeat>1</SupportsHotSeat>
    <SupportsMac>1</SupportsMac>
    <ReloadAudioSystem>0</ReloadAudioSystem>
    <ReloadLandmarkSystem>0</ReloadLandmarkSystem>
    <ReloadStrategicViewSystem>0</ReloadStrategicViewSystem>
    <ReloadUnitSystem>0</ReloadUnitSystem>
  </Properties>
  <Dependencies />
  <References />
  <Blocks />
  <Files>
{files}
  </Files>
  <Actions>
    <OnModActivated>
      <UpdateDatabase>sql/dados.sql</UpdateDatabase>
      <UpdateDatabase>sql/textos.sql</UpdateDatabase>
    </OnModActivated>
  </Actions>
  <EntryPoints>
    <EntryPoint type="InGameUIAddin" file="lua/eradasideologias.lua">
      <Name>EraDasIdeologias</Name>
      <Description>Regras do mod</Description>
    </EntryPoint>
    <EntryPoint type="InGameUIAddin" file="ui/boraseusg.lua">
      <Name>Mundo</Name>
      <Description>Interface</Description>
    </EntryPoint>
    <EntryPoint type="InGameUIAddin" file="ui/ideologias.lua">
      <Name>Ideologias</Name>
      <Description>Aba de ideologias e escolha de evolucao</Description>
    </EntryPoint>
  </EntryPoints>
</Mod>
'''


if __name__ == '__main__':
    nome = f'Era das Ideologias (v {VERSAO})'
    open(os.path.join(MOD, nome + '.modinfo'), 'w').write(modinfo())
    for p in os.listdir(MOD):
        if p.endswith('.modinfo') and p != nome + '.modinfo':
            os.remove(os.path.join(MOD, p))
    print(nome)
