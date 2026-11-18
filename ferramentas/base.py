import os, shutil, sqlite3

AQUI = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.expanduser("~/.local/share/Aspyr/Sid Meier's Civilization 5/cache")
DESTINO = os.path.join(AQUI, 'base', 'civ5_bnw.db')


def limpar():
    shutil.copy(os.path.join(CACHE, 'Civ5DebugDatabase.db'), DESTINO)
    db = sqlite3.connect(DESTINO)
    tabelas = [r[0] for r in db.execute("select name from sqlite_master where type='table'")]
    for t in tabelas:
        cols = [r[1] for r in db.execute(f'pragma table_info("{t}")')]
        for c in cols:
            if c in ('Type', 'PolicyType', 'BeliefType', 'BuildingType', 'PromotionType', 'PolicyBranchType', 'BuildingClass', 'BuildingClassType'):
                db.execute(f'delete from "{t}" where "{c}" like \'%NVG%\'')
    db.execute("update PolicyBranchTypes set EraPrereq = NULL where Type in ('POLICY_BRANCH_TRADITION','POLICY_BRANCH_LIBERTY','POLICY_BRANCH_HONOR')")
    db.execute("delete from PolicyBranch_Disables where PolicyBranchType in ('POLICY_BRANCH_TRADITION','POLICY_BRANCH_LIBERTY','POLICY_BRANCH_HONOR')")
    if db.execute("select MaxActiveReligions from Worlds where Type='WORLDSIZE_STANDARD'").fetchone()[0] == 6:
        db.execute('update Worlds set MaxActiveReligions = MaxActiveReligions - 1')
    for nome, v in (('RELIGION_MIN_FAITH_FIRST_PROPHET', 200), ('RELIGION_FAITH_DELTA_NEXT_PROPHET', 100),
                    ('RELIGION_ADJACENT_CITY_DISTANCE', 10), ('RELIGION_BASE_CHANCE_PROPHET_SPAWN', 5)):
        db.execute('update Defines set Value = ? where Name = ?', (v, nome))
    db.commit()
    resto = sum(db.execute(f'select count(*) from "{t}" where rowid in (select rowid from "{t}")').fetchone()[0] * 0 for t in tabelas)
    print('NVG restante:', db.execute("select count(*) from Policies where Type like '%NVG%'").fetchone()[0],
          db.execute("select count(*) from PolicyBranchTypes").fetchone()[0], 'ramos',
          db.execute("select count(*) from Policies").fetchone()[0], 'políticas',
          db.execute("select count(*) from Beliefs").fetchone()[0], 'crenças')


if __name__ == '__main__':
    limpar()
