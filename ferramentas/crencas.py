CRENCAS = [
    ('NVG_DIZIMO_IMPERIAL', 'Dízimo Imperial', 'Founder', '+3 [ICON_GOLD] Ouro para você por cidade que segue a sua religião.', {'GoldPerFollowingCity': 3}, {}),
    ('NVG_PAZ_DIVINA', 'Paz Divina', 'Founder', '+1 [ICON_HAPPINESS_1] felicidade para você por cidade que segue a sua religião.', {'HappinessPerFollowingCity': 1}, {}),
    ('NVG_FERVOR', 'Fervor', 'Follower', 'Templos +2 [ICON_PEACE] Fé e Santuários +1 [ICON_PEACE] Fé.', {}, {'predio': [('TEMPLE', 'FAITH', 2), ('SHRINE', 'FAITH', 1)]}),
    ('NVG_MOSTEIROS', 'Mosteiros Trabalhadores', 'Follower', '+2 [ICON_PRODUCTION] Produção e +1 [ICON_FOOD] Comida nas cidades seguidoras.', {}, {'cidade': [('PRODUCTION', 2), ('FOOD', 1)]}),
    ('NVG_GUERRA_SANTA', 'Guerra Santa', 'Enhancer', '+30% de força contra cidades de outra religião, e as unidades militares do fundador ganham a promoção Guerra Santa (+15%).', {'CombatModifierEnemyCities': 30}, {}),
    ('NVG_INQUISICAO', 'Inquisição Suprema', 'Enhancer', 'Missionários 50% mais baratos; quando a sua religião converte uma cidade, mais seguidores das outras religiões somem.', {'MissionaryCostModifier': -50, 'OtherReligionPressureErosion': 50}, {}),
    ('NVG_EVANGELHO_FOGO', 'Evangelho de Fogo', 'Enhancer', 'A religião se espalha 50% mais longe e 50% mais forte; Missionários +50% de força.', {'SpreadDistanceModifier': 50, 'SpreadStrengthModifier': 50, 'MissionaryStrengthModifier': 50}, {}),
]

