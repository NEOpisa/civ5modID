from efeitos import c, cidade, capital, predio, feliz, melhoria, unidade, promo, espec, palacio_cultura

CLASSICAS = {
    'POLICY_BRANCH_TRADITION': 'Tradição', 'POLICY_BRANCH_LIBERTY': 'Liberdade', 'POLICY_BRANCH_HONOR': 'Honra',
    'POLICY_BRANCH_PIETY': 'Piedade', 'POLICY_BRANCH_PATRONAGE': 'Mecenato', 'POLICY_BRANCH_AESTHETICS': 'Estética',
    'POLICY_BRANCH_COMMERCE': 'Comércio', 'POLICY_BRANCH_EXPLORATION': 'Exploração', 'POLICY_BRANCH_RATIONALISM': 'Racionalismo',
}


def E(chave, nome, desc, abertura, politicas, final, ideologia):
    return dict(chave=chave, nome=nome, desc=desc, abertura=abertura, politicas=politicas, final=final, ideologia=ideologia)


EVOLUCOES = {
    'POLICY_BRANCH_TRADITION': [
        E('ABSOLUTISMO', 'Absolutismo', 'O poder do rei não tem limites: capital forte, corte luxuosa e maravilhas.',
          [capital('PRODUCTION', 3), palacio_cultura(3)], [
              ('Direito Divino', [feliz('PALACE', 3)]),
              ('Corte Suntuosa', [c('WonderProductionModifier', 25)]),
              ('Exército Real', [c('MilitaryProductionModifier', 15)]),
              ('Intendentes', [cidade('GOLD', 2)]),
              ('Rei Sol', [capital('FOOD', 4), capital('SCIENCE', 4)]),
          ], [c('GoldenAgeTurns', 10), feliz('PALACE', 3)], 'MONARQUIA_CONST'),
        E('PATRIMONIALISMO', 'Patrimonialismo', 'O Estado é propriedade do soberano: terras, rendas e heranças.',
          [cidade('GOLD', 2)], [
              ('Feudos', [melhoria('FARM', 'GOLD', 1), melhoria('PASTURE', 'GOLD', 1)]),
              ('Vassalagem', [c('UnitGoldMaintenanceMod', -20)]),
              ('Senhores da Terra', [c('CityGrowthMod', 20)]),
              ('Herança', [c('BuildingPurchaseCostModifier', -20)]),
              ('Tesouro Pessoal', [predio('MARKET', 'GOLD', 2), predio('BANK', 'GOLD', 2)]),
          ], [c('NumFreeGreatPeople', 1)], 'LIBERTARIANISMO'),
    ],
    'POLICY_BRANCH_LIBERTY': [
        E('REPUBLICANISMO', 'Republicanismo', 'A coisa pública: magistrados eleitos, fórum e cidadãos ativos.',
          [cidade('PRODUCTION', 1), cidade('CULTURE', 1)], [
              ('Senado Eleito', [c('GreatPeopleRateModifier', 20)]),
              ('Cidadania Plena', [c('WorkerSpeedModifier', 25), unidade('WORKER', 1)]),
              ('Fórum Público', [predio('MONUMENT', 'CULTURE', 2)]),
              ('Magistraturas', [c('BuildingProductionModifier', 10)]),
              ('Res Publica', [feliz('PALACE', 4)]),
          ], [c('NumFreeGreatPeople', 1)], 'CAPITALISMO'),
        E('CONTRATUALISMO', 'Contratualismo', 'O governo nasce de um contrato entre os cidadãos e só vale com o consentimento deles.',
          [c('UnhappinessMod', -10)], [
              ('Contrato Social', [feliz('PALACE', 3)]),
              ('Direitos Naturais', [c('CityGrowthMod', 15)]),
              ('Vontade Geral', [cidade('FOOD', 1), cidade('PRODUCTION', 1)]),
              ('Estado de Direito', [predio('COURTHOUSE', 'CULTURE', 2)]),
              ('Consentimento', [c('NewCityExtraPopulation', 1)]),
          ], [c('GoldenAgeTurns', 10)], 'SOCIALDEM'),
    ],
    'POLICY_BRANCH_HONOR': [
        E('ESTRATOCRACIA', 'Estratocracia', 'Os militares governam o Estado: disciplina, quartéis e generais.',
          [c('FreeExperience', 10)], [
              ('Junta Militar', [c('MilitaryProductionModifier', 20)]),
              ('Conscrição', [promo('NVG_DISCIPLINA')]),
              ('Lei Marcial', [c('UnhappinessMod', -10)]),
              ('Quartéis Estatais', [predio('BARRACKS', 'PRODUCTION', 2), feliz('BARRACKS', 1)]),
              ('Estado-Maior', [c('GreatGeneralRateModifier', 50)]),
          ], [unidade('GREAT_GENERAL', 1), c('ExpModifier', 25)], 'COMUNISMO'),
        E('CESARISMO', 'Cesarismo', 'Um líder carismático concentra o poder com apoio do povo e das legiões.',
          [c('CityStrengthMod', 25)], [
              ('Culto ao Líder', [feliz('PALACE', 3), palacio_cultura(3)]),
              ('Pão e Circo', [feliz('COLOSSEUM', 2)]),
              ('Legiões do César', [promo('NVG_GUARDA')]),
              ('Triunfo', [c('GoldenAgeDurationMod', 25)]),
              ('Ditador Perpétuo', [c('UnitGoldMaintenanceMod', -25)]),
          ], [c('GoldenAgeTurns', 12)], 'FASCISMO'),
    ],
    'POLICY_BRANCH_PIETY': [
        E('TEOCRACIA', 'Teocracia', 'Os sacerdotes governam em nome dos deuses.',
          [predio('SHRINE', 'FAITH', 1)], [
              ('Clero Governante', [predio('TEMPLE', 'FAITH', 2)]),
              ('Dízimo', [c('FaithCostModifier', -15)]),
              ('Tribunais Religiosos', [feliz('TEMPLE', 1)]),
              ('Peregrinos', [melhoria('HOLY_SITE', 'GOLD', 3)]),
              ('Sumo Sacerdote', [unidade('PROPHET', 1)]),
          ], [predio('CATHEDRAL', 'FAITH', 2), predio('MOSQUE', 'FAITH', 2), predio('PAGODA', 'FAITH', 2)], 'FUNDAMENTALISMO'),
        E('CESAROPAPISMO', 'Cesaropapismo', 'O soberano também é o chefe da Igreja.',
          [feliz('PALACE', 2)], [
              ('Igreja do Estado', [predio('TEMPLE', 'GOLD', 2)]),
              ('Coroação Sagrada', [palacio_cultura(4)]),
              ('Bispos Nomeados', [predio('SHRINE', 'CULTURE', 1)]),
              ('Concílios', [c('GreatPeopleRateModifier', 15)]),
              ('Cruz e Espada', [promo('NVG_GUERRA_SANTA')]),
          ], [c('GoldenAgeTurns', 10)], 'MONARQUIA_CONST'),
    ],
    'POLICY_BRANCH_PATRONAGE': [
        E('HEGEMONISMO', 'Hegemonismo', 'Uma potência dominante dita as regras às cidades-estado ao redor.',
          [c('MinorFriendshipMinimum', 15)], [
              ('Esferas de Influência', [c('MinorQuestFriendshipMod', 50)]),
              ('Tributo', [c('MinorGoldFriendshipMod', 50)]),
              ('Protetorados', [c('ProtectedMinorPerTurnInfluence', 300)]),
              ('Diplomacia das Canhoneiras', [c('MilitaryProductionModifier', 15)]),
              ('Potência Hegemônica', [feliz('PALACE', 3)]),
          ], [c('NumFreeGreatPeople', 1)], 'FASCISMO'),
        E('FEDERALISMO', 'Federalismo', 'Cidades e povos livres unidos por um pacto, cada um com sua autonomia.',
          [cidade('CULTURE', 1)], [
              ('Autonomia Local', [cidade('PRODUCTION', 1)]),
              ('Pacto Federativo', [c('MinorQuestFriendshipMod', 33)]),
              ('Câmaras Municipais', [feliz('MONUMENT', 1)]),
              ('União dos Estados', [c('NewCityExtraPopulation', 1), c('CityGrowthMod', 10)]),
              ('Constituição Federal', [c('UnhappinessMod', -10)]),
          ], [c('GoldenAgeTurns', 10)], 'ANARQUISMO'),
    ],
    'POLICY_BRANCH_AESTHETICS': [
        E('VANGUARDISMO', 'Vanguardismo', 'A arte na linha de frente da revolução.',
          [predio('AMPHITHEATER', 'CULTURE', 2)], [
              ('Manifesto', [c('GreatWriterRateModifier', 50)]),
              ('Arte Engajada', [c('GreatArtistRateModifier', 50)]),
              ('Escolas de Arte', [predio('OPERA_HOUSE', 'CULTURE', 2)]),
              ('Museu do Povo', [predio('MUSEUM', 'CULTURE', 3)]),
              ('Futurismo', [c('ThemingBonusMultiplier', 50)]),
          ], [c('NumFreeGreatPeople', 1)], 'COMUNISMO'),
        E('NATURALISMO', 'Naturalismo', 'A natureza como mestra da arte e da vida.',
          [predio('GARDEN', 'CULTURE', 2)], [
              ('Pintura ao Ar Livre', [melhoria('CAMP', 'CULTURE', 1)]),
              ('Jardins Botânicos', [feliz('GARDEN', 2)]),
              ('Paisagismo', [c('CulturePerCity', 1)]),
              ('Poesia da Terra', [melhoria('PASTURE', 'CULTURE', 1)]),
              ('Retorno à Natureza', [c('CityGrowthMod', 15)]),
          ], [c('GoldenAgeDurationMod', 50)], 'ECOLOGISMO'),
    ],
    'POLICY_BRANCH_COMMERCE': [
        E('MERCANTILISMO', 'Mercantilismo', 'A riqueza da nação é o ouro acumulado e a balança comercial a favor.',
          [cidade('GOLD', 2)], [
              ('Balança Comercial', [predio('MARKET', 'GOLD', 2)]),
              ('Companhia das Índias', [predio('HARBOR', 'GOLD', 2)]),
              ('Protecionismo', [c('BuildingPurchaseCostModifier', -20)]),
              ('Metalismo', [predio('MINT', 'GOLD', 3)]),
              ('Reserva de Ouro', [predio('BANK', 'GOLD', 3)]),
          ], [predio('STOCK_EXCHANGE', 'GOLD', 4)], 'CAPITALISMO'),
        E('FISIOCRACIA', 'Fisiocracia', 'Toda riqueza vem da terra; o Estado deve deixar o mercado em paz.',
          [melhoria('FARM', 'FOOD', 1)], [
              ('Laissez-faire', [c('BuildingPurchaseCostModifier', -15)]),
              ('Produto Líquido', [melhoria('PLANTATION', 'GOLD', 2)]),
              ('Imposto Único', [cidade('GOLD', 2)]),
              ('Ordem Natural', [c('CityGrowthMod', 15)]),
              ('Livre Circulação', [c('UnitGoldMaintenanceMod', -15)]),
          ], [c('GreatMerchantRateModifier', 100)], 'LIBERTARIANISMO'),
    ],
    'POLICY_BRANCH_EXPLORATION': [
        E('COLONIALISMO', 'Colonialismo', 'Colônias além-mar, missões e riquezas tropicais.',
          [c('NewCityExtraPopulation', 1)], [
              ('Colônias', [unidade('SETTLER', 1)]),
              ('Missões Coloniais', [unidade('MISSIONARY', 1)]),
              ('Engenhos', [melhoria('PLANTATION', 'GOLD', 2)]),
              ('Feitorias', [melhoria('TRADING_POST', 'GOLD', 2)]),
              ('Vice-Reis', [feliz('PALACE', 3)]),
          ], [c('NumFreeGreatPeople', 1)], 'FUNDAMENTALISMO'),
        E('TALASSOCRACIA', 'Talassocracia', 'O império é o mar: portos, frotas e rotas marítimas.',
          [predio('HARBOR', 'PRODUCTION', 2)], [
              ('Marinha Mercante', [predio('SEAPORT', 'GOLD', 3)]),
              ('Armadores', [c('UnitPurchaseCostModifier', -20)]),
              ('Rotas Marítimas', [melhoria('FISHING_BOATS', 'GOLD', 2)]),
              ('Faróis', [predio('LIGHTHOUSE', 'FOOD', 1), predio('LIGHTHOUSE', 'GOLD', 1)]),
              ('Senhores do Mar', [c('GreatAdmiralRateModifier', 50)]),
          ], [unidade('GREAT_ADMIRAL', 1)], 'ANARQUISMO'),
    ],
    'POLICY_BRANCH_RATIONALISM': [
        E('POSITIVISMO', 'Positivismo', 'Só o conhecimento científico é válido: ordem e progresso.',
          [cidade('SCIENCE', 2)], [
              ('Método Científico', [predio('LIBRARY', 'SCIENCE', 2)]),
              ('Engenharia Social', [predio('UNIVERSITY', 'SCIENCE', 2)]),
              ('Ordem e Progresso', [cidade('PRODUCTION', 2)]),
              ('Academias Técnicas', [c('GreatScientistRateModifier', 33)]),
              ('Estatística', [predio('PUBLIC_SCHOOL', 'SCIENCE', 2)]),
          ], [c('NumFreeTechs', 1)], 'TECNOCRACIA'),
        E('UTILITARISMO', 'Utilitarismo', 'A melhor lei é a que traz a maior felicidade para o maior número.',
          [feliz('PALACE', 2)], [
              ('Maior Felicidade', [feliz('PALACE', 3)]),
              ('Saúde Pública', [feliz('AQUEDUCT', 1)]),
              ('Educação Universal', [predio('LIBRARY', 'SCIENCE', 1), predio('LIBRARY', 'CULTURE', 1)]),
              ('Reforma Prisional', [c('UnhappinessMod', -10)]),
              ('Cálculo Moral', [espec('SCIENCE', 1), espec('GOLD', 1)]),
          ], [c('GoldenAgeTurns', 10)], 'SOCIALDEM'),
    ],
}


def I(nome, desc, comuns, origens):
    return dict(nome=nome, desc=desc, comuns=comuns, origens=origens)


def O(desc, abertura, politicas, final, presente):
    return dict(desc=desc, abertura=abertura, politicas=politicas, final=final, presente=presente)


IDEOLOGIAS = {
    'CAPITALISMO': I('Capitalismo', 'Mercado, lucro e propriedade privada.', [
        ('Bolsa de Valores', [predio('STOCK_EXCHANGE', 'GOLD', 4)]),
        ('Propriedade Privada', [c('BuildingPurchaseCostModifier', -25)]),
    ], {
        'REPUBLICANISMO': O('Capitalismo liberal: cidadãos livres, imprensa livre e gênios.',
                            [c('GreatPeopleRateModifier', 15), cidade('CULTURE', 1)],
                            [('Democracia Liberal', [feliz('PALACE', 4), c('UnhappinessMod', -10)]),
                             ('Sufrágio Universal', [c('GoldenAgeDurationMod', 50), cidade('CULTURE', 1)]),
                             ('Imprensa Livre', [predio('BROADCAST_TOWER', 'CULTURE', 3), c('GreatWriterRateModifier', 50)])],
                            [c('NumFreeGreatPeople', 1), feliz('PALACE', 5)],
                            {'ouro': 250, 'unidades': [('UNIT_MERCHANT', 1)]}),
        'MERCANTILISMO': O('Capitalismo de Estado: monopólios, portos e cofres cheios.',
                           [melhoria('CUSTOMS_HOUSE', 'GOLD', 2), predio('HARBOR', 'GOLD', 2)],
                           [('Companhias das Índias', [predio('SEAPORT', 'GOLD', 3), c('GreatAdmiralRateModifier', 50)]),
                            ('Protecionismo', [predio('FACTORY', 'GOLD', 3), predio('WORKSHOP', 'PRODUCTION', 2)]),
                            ('Casa da Moeda Real', [predio('MINT', 'GOLD', 3), capital('GOLD', 10)])],
                           [capital('GOLD', 25), unidade('GREAT_ADMIRAL', 1)],
                           {'ouro': 800}),
    }),
    'COMUNISMO': I('Comunismo', 'Os meios de produção nas mãos do povo e do partido.', [
        ('Plano Quinquenal', [melhoria('MINE', 'PRODUCTION', 1), melhoria('QUARRY', 'PRODUCTION', 1)]),
        ('Coletivização', [melhoria('FARM', 'FOOD', 1)]),
    ], {
        'ESTRATOCRACIA': O('Comunismo de caserna: o partido é o exército.',
                           [c('MilitaryProductionModifier', 15), predio('BARRACKS', 'PRODUCTION', 2)],
                           [('Exército Vermelho', [promo('NVG_GUARDA')]),
                            ('Comissários Políticos', [c('ExpModifier', 50), c('FreeExperience', 15)]),
                            ('Economia de Guerra', [c('UnitGoldMaintenanceMod', -25), predio('FACTORY', 'PRODUCTION', 2)])],
                           [unidade('GREAT_GENERAL', 2), c('GreatGeneralRateModifier', 50)],
                           {'tropas': (3, 'PROMOTION_NVG_GUARDA'), 'producao': 30}),
        'VANGUARDISMO': O('Comunismo de vanguarda: intelectuais, artistas e cientistas guiam a revolução.',
                          [predio('MONUMENT', 'CULTURE', 2), predio('LIBRARY', 'SCIENCE', 1)],
                          [('Realismo Socialista', [c('GreatArtistRateModifier', 50), c('GreatWriterRateModifier', 50)]),
                           ('Academia de Ciências', [predio('UNIVERSITY', 'SCIENCE', 3), c('GreatScientistRateModifier', 25)]),
                           ('Fábricas do Povo', [predio('FACTORY', 'PRODUCTION', 3)])],
                          [c('NumFreeTechs', 1), c('CulturePerCity', 2)],
                          {'cultura': 400, 'ciencia': 400}),
    }),
    'FASCISMO': I('Fascismo', 'Nação, líder e guerra acima de tudo.', [
        ('Nacionalismo', [promo('NVG_DISCIPLINA')]),
        ('Propaganda', [feliz('BROADCAST_TOWER', 2)]),
    ], {
        'CESARISMO': O('Fascismo do líder: culto à pessoa e guerra relâmpago.',
                       [c('MilitaryProductionModifier', 15), palacio_cultura(3)],
                       [('Culto à Personalidade', [feliz('PALACE', 5), palacio_cultura(3)]),
                        ('Guerra Relâmpago', [c('FreeExperience', 20)]),
                        ('Guarda Pretoriana', [promo('NVG_GUARDA'), c('CityStrengthMod', 25)])],
                       [c('GoldenAgeTurns', 15), unidade('GREAT_GENERAL', 1)],
                       {'tropas': (3, 'PROMOTION_NVG_GUARDA')}),
        'HEGEMONISMO': O('Fascismo imperial: dominar vizinhos e cidades-estado.',
                         [c('MinorFriendshipMinimum', 20)],
                         [('Espaço Vital', [c('NewCityExtraPopulation', 2), unidade('SETTLER', 1)]),
                          ('Eixo', [c('ProtectedMinorPerTurnInfluence', 300), c('MinorQuestFriendshipMod', 50)]),
                          ('Estado Corporativo', [c('UnhappinessMod', -10), c('BuildingProductionModifier', 15)])],
                         [c('MinorGoldFriendshipMod', 100), cidade('PRODUCTION', 2)],
                         {'ouro': 300, 'influencia': 40}),
    }),
    'SOCIALDEM': I('Social-Democracia', 'Estado de bem-estar: saúde, escola e felicidade para todos.', [
        ('Saúde Universal', [feliz('HOSPITAL', 2)]),
        ('Escola Pública Gratuita', [predio('PUBLIC_SCHOOL', 'SCIENCE', 3)]),
    ], {
        'CONTRATUALISMO': O('Social-democracia do pacto: o Estado cuida e o povo cresce.',
                            [feliz('PALACE', 3), c('UnhappinessMod', -5)],
                            [('Pacto Social', [c('UnhappinessMod', -15)]),
                             ('Previdência', [c('CityGrowthMod', 25)]),
                             ('Sindicatos', [cidade('PRODUCTION', 2)])],
                            [feliz('PALACE', 8), c('GoldenAgeTurns', 8)],
                            {'pop': 1}),
        'UTILITARISMO': O('Social-democracia técnica: o maior bem para o maior número, medido pela ciência.',
                          [cidade('SCIENCE', 2)],
                          [('Pesquisa Pública', [predio('LABORATORY', 'SCIENCE', 4)]),
                           ('Bem Comum', [predio('LIBRARY', 'SCIENCE', 2), feliz('UNIVERSITY', 1)]),
                           ('Eficiência Pública', [c('WorkerSpeedModifier', 25), melhoria('FARM', 'FOOD', 1)])],
                          [c('NumFreeTechs', 2)],
                          {'ciencia': 500}),
    }),
    'ANARQUISMO': I('Anarquismo', 'Sem Estado e sem patrões: comunas livres e ajuda mútua.', [
        ('Ajuda Mútua', [c('CityGrowthMod', 20)]),
        ('Sem Patrões', [c('UnitGoldMaintenanceMod', -30)]),
    ], {
        'FEDERALISMO': O('Anarquismo de comunas: cidades livres federadas, milícias e arte.',
                         [cidade('FOOD', 2)],
                         [('Comunas Livres', [cidade('PRODUCTION', 2)]),
                          ('Milícias Populares', [promo('NVG_MILICIA'), c('CityStrengthMod', 25)]),
                          ('Arte Livre', [c('GreatArtistRateModifier', 33), c('GreatWriterRateModifier', 33), c('GreatMusicianRateModifier', 33)])],
                         [feliz('PALACE', 10), c('CulturePerCity', 2)],
                         {'tropas': (2, 'PROMOTION_NVG_MILICIA'), 'cultura': 250}),
        'TALASSOCRACIA': O('Anarquismo pirata: repúblicas do mar, saque e liberdade.',
                           [predio('HARBOR', 'PRODUCTION', 2), melhoria('FISHING_BOATS', 'FOOD', 1)],
                           [('Repúblicas Piratas', [c('UnitPurchaseCostModifier', -33)]),
                            ('Libertália', [predio('HARBOR', 'GOLD', 3), predio('SEAPORT', 'GOLD', 3)]),
                            ('Irmandade da Costa', [c('GreatAdmiralRateModifier', 100), c('ExpModifier', 25)])],
                           [unidade('GREAT_ADMIRAL', 1), cidade('GOLD', 3)],
                           {'ouro': 500, 'unidades': [('UNIT_GREAT_ADMIRAL', 1)]}),
    }),
    'LIBERTARIANISMO': I('Libertarianismo', 'Mercado sem amarras e Estado mínimo.', [
        ('Impostos Mínimos', [c('BuildingPurchaseCostModifier', -25)]),
        ('Empreendedorismo', [c('GreatMerchantRateModifier', 50)]),
    ], {
        'PATRIMONIALISMO': O('Libertarianismo de dono: o país é propriedade de quem governa.',
                             [capital('GOLD', 8)],
                             [('Cidades Privadas', [melhoria('CUSTOMS_HOUSE', 'GOLD', 4)]),
                              ('Segurança Privada', [promo('NVG_MILICIA'), c('UnitPurchaseCostModifier', -25)]),
                              ('Feudos Corporativos', [capital('PRODUCTION', 10)])],
                             [capital('GOLD', 25), c('NumFreeGreatPeople', 1)],
                             {'ouro': 700}),
        'FISIOCRACIA': O('Libertarianismo da terra: a riqueza nasce do campo e do livre mercado.',
                         [melhoria('FARM', 'GOLD', 1)],
                         [('Mão Invisível', [predio('MARKET', 'GOLD', 3), predio('BANK', 'GOLD', 3)]),
                          ('Agronegócio', [melhoria('PLANTATION', 'GOLD', 2), melhoria('PASTURE', 'GOLD', 2)]),
                          ('Terra Livre', [c('WorkerSpeedModifier', 50), c('CityGrowthMod', 15)])],
                         [cidade('GOLD', 4), cidade('FOOD', 2)],
                         {'ouro': 400, 'unidades': [('UNIT_WORKER', 2)]}),
    }),
    'TECNOCRACIA': I('Tecnocracia', 'O governo dos especialistas: ciência e indústria acima de tudo.', [
        ('Meritocracia Científica', [c('GreatScientistRateModifier', 50)]),
        ('Laboratórios Nacionais', [predio('LABORATORY', 'SCIENCE', 4)]),
        ('Automação', [melhoria('MANUFACTORY', 'PRODUCTION', 3), predio('FACTORY', 'PRODUCTION', 2)]),
        ('Planejamento Algorítmico', [cidade('PRODUCTION', 2)]),
        ('Programa Espacial', [c('EnablesSSPartHurry', 1), c('EnablesSSPartPurchase', 1)]),
    ], {'POSITIVISMO': O('Ordem e progresso: a ciência governa.', [cidade('SCIENCE', 3)], [], [c('NumFreeTechs', 2)],
                         {'ciencia': 600, 'unidades': [('UNIT_SCIENTIST', 1)]})}),
    'ECOLOGISMO': I('Ecologismo', 'Viver em paz com a natureza.', [
        ('Energia Limpa', [predio('SOLAR_PLANT', 'PRODUCTION', 4), predio('HYDRO_PLANT', 'PRODUCTION', 4)]),
        ('Agricultura Orgânica', [melhoria('FARM', 'FOOD', 1)]),
        ('Ecoturismo', [c('TradeRouteTourismModifier', 25)]),
        ('Parques Nacionais', [c('CulturePerCity', 2)]),
        ('Cidades Verdes', [feliz('PALACE', 4), c('CityGrowthMod', 15)]),
    ], {'NATURALISMO': O('A natureza em primeiro lugar.', [predio('GARDEN', 'CULTURE', 3)], [], [c('GoldenAgeTurns', 15)],
                         {'cultura': 400, 'eraouro': 5})}),
    'MONARQUIA_CONST': I('Monarquia Constitucional', 'O rei reina, o parlamento governa.', [
        ('Parlamento', [c('GreatPeopleRateModifier', 20)]),
        ('Coroa Simbólica', [feliz('PALACE', 4)]),
    ], {
        'ABSOLUTISMO': O('Monarquia da corte: a coroa ainda manda, agora com parlamento.',
                         [palacio_cultura(4), capital('PRODUCTION', 3)],
                         [('Guarda Real', [promo('NVG_GUARDA')]),
                          ('Nobreza Fundiária', [capital('FOOD', 5), capital('SCIENCE', 5)]),
                          ('Corte Suntuosa', [c('WonderProductionModifier', 25), c('MinorGoldFriendshipMod', 50)])],
                         [c('GoldenAgeTurns', 12), c('NumFreeGreatPeople', 1)],
                         {'cultura': 300, 'ouro': 200, 'influencia': 30}),
        'CESAROPAPISMO': O('Monarquia sagrada: o rei também é chefe da Igreja.',
                           [predio('TEMPLE', 'FAITH', 2)],
                           [('Igreja Nacional', [predio('CATHEDRAL', 'CULTURE', 2), predio('MOSQUE', 'CULTURE', 2), predio('PAGODA', 'CULTURE', 2)]),
                            ('Defensor da Fé', [c('FaithCostModifier', -25)]),
                            ('Unção Real', [feliz('TEMPLE', 1), predio('PALACE', 'FAITH', 5)])],
                           [unidade('PROPHET', 1), c('GoldenAgeTurns', 8)],
                           {'fe': 400}),
    }),
    'FUNDAMENTALISMO': I('Fundamentalismo', 'A fé governa o Estado.', [
        ('Leis Religiosas', [c('UnhappinessMod', -10)]),
        ('Clero Estatal', [c('FaithCostModifier', -25)]),
    ], {
        'TEOCRACIA': O('Fundamentalismo do templo: sacerdotes governam e a fé enche os cofres da alma.',
                       [predio('SHRINE', 'FAITH', 2), predio('TEMPLE', 'FAITH', 2)],
                       [('Teocracia Total', [predio('CATHEDRAL', 'FAITH', 3), predio('MOSQUE', 'FAITH', 3), predio('PAGODA', 'FAITH', 3)]),
                        ('Inquisição', [unidade('INQUISITOR', 2), c('CatchSpiesModifier', 25)]),
                        ('Sacerdócio', [feliz('TEMPLE', 1), feliz('SHRINE', 1)])],
                       [unidade('PROPHET', 2)],
                       {'fe': 500}),
        'COLONIALISMO': O('Fundamentalismo de cruzada: conquistar e converter terras novas.',
                          [c('NewCityExtraPopulation', 1), c('MilitaryProductionModifier', 10)],
                          [('Missões', [unidade('MISSIONARY', 2)]),
                           ('Conversão pela Espada', [promo('NVG_GUERRA_SANTA')]),
                           ('Colônias da Fé', [unidade('SETTLER', 1), melhoria('PLANTATION', 'FAITH', 1)])],
                          [c('FreeExperience', 20), c('ExpModifier', 25)],
                          {'fe': 250, 'unidades': [('UNIT_MISSIONARY', 2)], 'exercito': 'PROMOTION_NVG_GUERRA_SANTA'}),
    }),
}

ICONE_IDEOLOGIA = {
    'CAPITALISMO': ('POLICY_ATLAS', 25), 'SOCIALDEM': ('POLICY_ATLAS', 25), 'LIBERTARIANISMO': ('POLICY_ATLAS', 25),
    'ECOLOGISMO': ('POLICY_ATLAS', 25), 'COMUNISMO': ('POLICY_ATLAS_EXP2', 11), 'ANARQUISMO': ('POLICY_ATLAS_EXP2', 11),
    'TECNOCRACIA': ('POLICY_ATLAS_EXP2', 11), 'FASCISMO': ('POLICY_ATLAS_EXP2', 10), 'MONARQUIA_CONST': ('POLICY_ATLAS_EXP2', 10),
    'FUNDAMENTALISMO': ('POLICY_ATLAS_EXP2', 10),
}
