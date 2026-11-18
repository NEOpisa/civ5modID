# Era das Ideologias 2.0 (Civilization V)

Precisa do **Brave New World**. Funciona sozinho, em hotseat e online. Online, todos precisam da mesma versão.

Partidas salvas da versão 1 não abrem na 2.0.

## Instalação (DLC, para jogar online)
O mod é instalado como **DLC**: não usa o menu MODS, então o **Multijogador normal** funciona. Todos os jogadores precisam instalar a mesma versão.

- **Linux** (versão nativa ou Windows pelo Proton): abra um terminal nesta pasta e rode `sh instalar-linux.sh`
- **Windows:** dois cliques em `instalar-windows.bat`

Para remover: `sh instalar-linux.sh --remover` ou `instalar-windows.bat remover`.

O instalador tira a versão antiga do menu MODS, se existir, para o jogo não carregar duas vezes, e limpa o cache do jogo. Se a Steam "verificar os arquivos" do Civ V, instale de novo.

**Para jogar:** Multijogador (ou Um Jogador) normal, sem passar pelo MODS. Em Configuração Avançada, a DLC **Era das Ideologias** precisa estar marcada (vem marcada).

A versão nativa do Linux só joga online com quem também usa a nativa (Linux/Mac). Quem usa o Proton joga com quem está no Windows.

## 1. Árvores de política que evoluem
As 9 árvores (Tradição, Liberdade, Honra, Piedade, Mecenato, Estética, Comércio, Exploração e Racionalismo) funcionam como no jogo base.

Até a primeira evolução, as políticas custam **metade da cultura** (a capital recebe o "Estado Nascente"). Depois o preço volta ao normal e sobe a cada política, como no jogo base.

Ao **completar uma árvore**, aparece a escolha entre **2 evoluções**, cada uma mostrada como árvore com os ícones das políticas. Se deixar para depois, um aviso piscante no alto da tela e o botão **EVOLUIR** na própria árvore reabrem a escolha.
- A evolução escolhida abre **de graça**, já com a abertura.
- A outra fecha **para sempre** nesta partida.
- Os bônus da árvore original continuam.
- Na tela de políticas, a evolução aparece no lugar da árvore original: o título vira o nome da evolução e a árvore ganha a cor da ideologia dela.
- **No máximo 4 evoluções por partida.** Depois disso, completar outra árvore não abre evolução.

Cada evolução tem abertura, 5 políticas e bônus ao completar, cerca de 1,5 vez mais forte que uma árvore normal. **Só a primeira evolução que você completar libera ideologia.** As outras dão o bônus final, mas não liberam outra ideologia.

| Árvore | Evolução | Libera |
|---|---|---|
| Tradição | Absolutismo | Monarquia Constitucional |
| | Patrimonialismo | Libertarianismo |
| Liberdade | Republicanismo | Capitalismo |
| | Contratualismo | Social-Democracia |
| Honra | Estratocracia | Comunismo |
| | Cesarismo | Fascismo |
| Piedade | Teocracia | Fundamentalismo |
| | Cesaropapismo | Monarquia Constitucional |
| Mecenato | Hegemonismo | Fascismo |
| | Federalismo | Anarquismo |
| Estética | Vanguardismo | Comunismo |
| | Naturalismo | Ecologismo |
| Comércio | Mercantilismo | Capitalismo |
| | Fisiocracia | Libertarianismo |
| Exploração | Colonialismo | Fundamentalismo |
| | Talassocracia | Anarquismo |
| Racionalismo | Positivismo | Tecnocracia |
| | Utilitarismo | Social-Democracia |

## 2. As 10 ideologias
A escolha de ideologia do Brave New World foi removida: não há escolha na Era Industrial, nem por fábricas, nem opinião pública.

Para usar as ideologias, abra a aba **Ideologias** na tela de políticas, o botão **Ver ideologias** no quadro de ideologia ou o aviso no alto da tela quando uma ideologia for liberada. A janela mostra as 10 ideologias em cartões coloridos; clique em uma para ver a árvore dela (e, quando houver, as duas versões conforme a origem). Na sua ideologia, clique nos ícones coloridos para comprar as políticas.
- Cada ideologia é uma árvore: abertura grátis ao adotar, 5 políticas pagas com cultura e bônus ao completar.
- **Uma ideologia por vez.** Se trocar, você perde as políticas da ideologia antiga.
- **A origem muda a ideologia.** Quando a mesma ideologia pode vir de 2 evoluções, cada versão tem abertura, 3 das 5 políticas, bônus final e presente próprios; só 2 políticas são iguais. As políticas próprias usam os ícones da árvore de origem. Tecnocracia e Ecologismo têm uma origem só.

| Ideologia | Em comum | Versão por origem (abertura própria, 3 políticas próprias, bônus final e presente próprios) |
|---|---|---|
| Capitalismo | Bolsa de Valores, Propriedade Privada | **Republicanismo:** Capitalismo liberal: cidadãos livres, imprensa livre e gênios. Políticas: Democracia Liberal, Sufrágio Universal, Imprensa Livre. Presente: +250 Ouro, 1 Grande Comerciante.<br>**Mercantilismo:** Capitalismo de Estado: monopólios, portos e cofres cheios. Políticas: Companhias das Índias, Protecionismo, Casa da Moeda Real. Presente: +800 Ouro. |
| Comunismo | Plano Quinquenal, Coletivização | **Estratocracia:** Comunismo de caserna: o partido é o exército. Políticas: Exército Vermelho, Comissários Políticos, Economia de Guerra. Presente: +30 produção em cada cidade, 3 tropas com Guarda Ideológica.<br>**Vanguardismo:** Comunismo de vanguarda: intelectuais, artistas e cientistas guiam a revolução. Políticas: Realismo Socialista, Academia de Ciências, Fábricas do Povo. Presente: +400 Cultura, +400 Ciência. |
| Fascismo | Nacionalismo, Propaganda | **Cesarismo:** Fascismo do líder: culto à pessoa e guerra relâmpago. Políticas: Culto à Personalidade, Guerra Relâmpago, Guarda Pretoriana. Presente: 3 tropas com Guarda Ideológica.<br>**Hegemonismo:** Fascismo imperial: dominar vizinhos e cidades-estado. Políticas: Espaço Vital, Eixo, Estado Corporativo. Presente: +300 Ouro, +40 de influência com as cidades-estado conhecidas. |
| Social-Democracia | Saúde Universal, Escola Pública Gratuita | **Contratualismo:** Social-democracia do pacto: o Estado cuida e o povo cresce. Políticas: Pacto Social, Previdência, Sindicatos. Presente: +1 população em cada cidade.<br>**Utilitarismo:** Social-democracia técnica: o maior bem para o maior número, medido pela ciência. Políticas: Pesquisa Pública, Bem Comum, Eficiência Pública. Presente: +500 Ciência. |
| Anarquismo | Ajuda Mútua, Sem Patrões | **Federalismo:** Anarquismo de comunas: cidades livres federadas, milícias e arte. Políticas: Comunas Livres, Milícias Populares, Arte Livre. Presente: +250 Cultura, 2 tropas com Milícia Popular.<br>**Talassocracia:** Anarquismo pirata: repúblicas do mar, saque e liberdade. Políticas: Repúblicas Piratas, Libertália, Irmandade da Costa. Presente: +500 Ouro, 1 Grande Almirante. |
| Libertarianismo | Impostos Mínimos, Empreendedorismo | **Patrimonialismo:** Libertarianismo de dono: o país é propriedade de quem governa. Políticas: Cidades Privadas, Segurança Privada, Feudos Corporativos. Presente: +700 Ouro.<br>**Fisiocracia:** Libertarianismo da terra: a riqueza nasce do campo e do livre mercado. Políticas: Mão Invisível, Agronegócio, Terra Livre. Presente: +400 Ouro, 2 Trabalhadores. |
| Tecnocracia | Meritocracia Científica, Laboratórios Nacionais, Automação, Planejamento Algorítmico, Programa Espacial | **Positivismo:** Ordem e progresso: a ciência governa. Presente: +600 Ciência, 1 Grande Cientista. |
| Ecologismo | Energia Limpa, Agricultura Orgânica, Ecoturismo, Parques Nacionais, Cidades Verdes | **Naturalismo:** A natureza em primeiro lugar. Presente: +400 Cultura, 5 turnos de Era de Ouro. |
| Monarquia Constitucional | Parlamento, Coroa Simbólica | **Absolutismo:** Monarquia da corte: a coroa ainda manda, agora com parlamento. Políticas: Guarda Real, Nobreza Fundiária, Corte Suntuosa. Presente: +200 Ouro, +300 Cultura, +30 de influência com as cidades-estado conhecidas.<br>**Cesaropapismo:** Monarquia sagrada: o rei também é chefe da Igreja. Políticas: Igreja Nacional, Defensor da Fé, Unção Real. Presente: +400 Fé. |
| Fundamentalismo | Leis Religiosas, Clero Estatal | **Teocracia:** Fundamentalismo do templo: sacerdotes governam e a fé enche os cofres da alma. Políticas: Teocracia Total, Inquisição, Sacerdócio. Presente: +500 Fé.<br>**Colonialismo:** Fundamentalismo de cruzada: conquistar e converter terras novas. Políticas: Missões, Conversão pela Espada, Colônias da Fé. Presente: +250 Fé, 2 Missionários, todo o exército ganha Guerra Santa. |

A IA segue as mesmas regras: escolhe evoluções, adota ideologias e compra as políticas delas.

## 3. Caminho, Tradição e crise
A **primeira evolução que você completa** vira o caminho do seu país.

**Tradição:** cada turno com a ideologia do seu caminho soma 1 ponto (até 60), que rende ouro e fé por turno.
- Aos 20 pontos: 6 turnos de Era de Ouro.
- Aos 40 e aos 60 pontos: 1 política grátis.

A Tradição só corre enquanto a sua ideologia for a do seu caminho.

## 4. Era Antiga: Tribo
Até a Era Clássica, toda cidade recebe a **Tribo** (+1 comida, +1 produção, +1 cultura).

## 5. Religião turbinada
- **7 crenças novas:**
  - Fundador: Dízimo Imperial e Paz Divina.
  - Seguidor: Fervor e Mosteiros Trabalhadores.
  - Reforço: Guerra Santa, Inquisição Suprema e Evangelho de Fogo.
- **Guerra Santa:** +30% contra cidades de outra religião, e o exército do fundador ganha a promoção Guerra Santa (+15%).
- O mapa aceita **uma religião a mais**, os profetas ficam mais baratos e aparecem mais, e a religião se espalha mais longe.

## 6. Guerra Fria
A cada turno, cada civilização conhecida com a **mesma ideologia** dá +3 de ouro, e cada **rival ideológico** dá +2 de ciência e +2 de cultura.

## 7. Eventos mundiais
A cada 15 a 30 turnos acontece um evento sorteado de acordo com a era: Peste, Grande Despertar, Corrida do Ouro, Invasão Bárbara, Profeta Errante, Guerra Santa, Revolução Científica, Revolução Cultural, Quebra da Bolsa, Crise do Petróleo, Corrida Espacial ou Pandemia Global. Cada ideologia reage de um jeito.

## 8. Revoluções
Da Era Clássica em diante, se a felicidade do império estiver abaixo de −5, cada cidade com 4 habitantes ou mais (menos a capital) tem 8% de chance por turno de se revoltar: aparecem rebeldes bárbaros e a cidade fica 2 turnos em resistência.
