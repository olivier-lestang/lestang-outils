# Atelier SQL de conjugaison : source de verite des donnees de conjugaison.
# Schema : brut.json (transport) -> atelier.db (tables normalisees, éditables
# dans un GUI SQLite) -> export -> brut.json (format compact que l'app charge).
# L'app, elle, lit toujours conj_raw dans assets/lestang_outils.db, régénérée
# par construire_bdd.py depuis le brut.json exporté : la rapidité ne change pas.
#
# Usage :
#   python3 outils/atelier.py import [brut.json] [atelier.db]  # (re)remplit l'atelier
#   python3 outils/atelier.py export [atelier.db] [brut.json]   # régénère le brut
#   python3 outils/atelier.py verifier [brut.json] [atelier.db] # compare sans écrire
#   python3 outils/atelier.py stats [atelier.db]
#
# ATTENTION : la colonne defs.etiquette est ETIQUETTE AFFICHEE ; pour
# pl/cs/ro et les glossaires anglais elle sert aussi de nom de source
# (sources.nom). Une edition d'etiquette change donc l'affichage dans l'app.
# id_source est rempli pour les etiquettes correspondant a une source
# connue de SOURCES_CONNUES (y compris Academie, Littré, Webster 1913,
# Real Academia 1913-1914...). IMPORTANT : un import recree l'atelier a
# partir de brut.json, qui ne transporte pas les attributions calculees
# ( fr par comparaison Littré, en par article Webster... ) ni le
# classement des verbes : relancer sources_defs.py puis classes.py.
# SPDX-License-Identifier : MIT
import gzip, base64, json, os, sqlite3, sys
from datetime import date

ICI = os.path.dirname(os.path.abspath(__file__))
PR = {'fr': 'CONJ', 'en': 'EN', 'es': 'ES', 'de': 'DE', 'it': 'IT',
      'pt': 'PT', 'pl': 'PL', 'cs': 'CS', 'ro': 'RO'}
SEC = '\x01'   # mot | definitions
SENS = '\x03'  # sens | sens
ETIQ = '\x04'  # etiquette | texte

# sources sures : etiquette -> (nom de la table sources, caracteristiques)
SOURCES_CONNUES = {
    'angl. Wiktionary': (
        'angl. Wiktionary',
        'Glossaire anglais du Wiktionary anglophone, extraction '
        'kaikki.org (wiktextract), CC BY-SA 4.0'),
    'angl. Wiktionary, trad.': (
        'angl. Wiktionary, trad.',
        'Glossaire anglais du Wiktionary traduit par le projet '
        '(traductions en cours, CC BY-SA 4.0)'),
    'pl. Wiktionary': (
        'pl. Wiktionary',
        'Definition native du Wiktionary polonais, dumps Wikimedia '
        '(plwiktionary), CC BY-SA 4.0'),
    'cs. Wiktionary': (
        'cs. Wiktionary',
        'Definition native du Wiktionary tcheque, dumps Wikimedia '
        '(cswiktionary), CC BY-SA 4.0'),
    'ro. Wiktionary': (
        'ro. Wiktionary',
        'Definition native du Wiktionary roumain, dumps Wikimedia '
        '(rowiktionary), CC BY-SA 4.0'),
    'projet': ('projet', 'Redaction du projet'),
    'Académie 8e (1932-1935)': (
        "Académie 8e (1932-1935)",
        "Dictionnaire de l'Académie française, 8e édition, 1932-1935, "
        'domaine public ; attribué par élimination : sens non retrouvé '
        'dans le Littré ( les définitions françaises historiques viennent '
        "de l'Académie ou du Littré )"),
    'Littré (1872-1877)': (
        'Littré (1872-1877)',
        'Émile Littré, Dictionnaire de la langue française ( 1872-1877 ), '
        'texte du domaine public, numérisation XML oeuvres/littre ; '
        'attribué par comparaison du texte du sens avec l article'),
    'fr. Wiktionary': (
        'fr. Wiktionary',
        'Wiktionnaire fr.wiktionary ( CC BY-SA 4.0 ) ; renvois et formes '
        'alternatives ( alternative form of, archaic spelling... )'),
    'Webster 1913': (
        "Webster 1913",
        "Webster's Revised Unabridged Dictionary, 1913 ( GCIDE ), texte du "
        'domaine public ; numérisation lunixbochs/webster ( code MIT ) ; '
        'attribué par présence d un article verbal'),
    'Real Academia 1913-1914': (
        'Real Academia 1913-1914',
        'Diccionario de la lengua castellana ( Real Academia Española, '
        '14e édition, 1913-1914 ), texte du domaine public'),
    'Glossaire du générateur du projet': (
        'Glossaire du générateur du projet',
        'Glossaires anglais et allemands du générateur du projet web '
        '( SPDX-License-Identifier : MIT )'),
}

SCHEMA = """
CREATE TABLE sources (
    id      INTEGER PRIMARY KEY,
    nom     TEXT UNIQUE NOT NULL,
    caract  TEXT NOT NULL DEFAULT ''
);
CREATE TABLE defs (
    langue      TEXT NOT NULL,
    pos         INTEGER NOT NULL,   -- rang de l entree dans le blob
    rang        INTEGER NOT NULL,   -- rang du sens dans l entree
    verbe       TEXT NOT NULL,
    etiquette   TEXT,               -- NULL : pas d etiquette dans le brut
    texte       TEXT NOT NULL,
    id_source   INTEGER REFERENCES sources(id),
    date_ajout  TEXT NOT NULL,
    PRIMARY KEY (langue, pos, rang)
);
CREATE INDEX defs_verbe ON defs(langue, verbe);
CREATE TABLE verbes (
    langue      TEXT NOT NULL,
    ligne       INTEGER NOT NULL,   -- groupe de modele dans le blob
    col         INTEGER NOT NULL,
    verbe       TEXT NOT NULL,
    segment     TEXT NOT NULL,      -- morceau brut (formes inclues)
    date_ajout  TEXT NOT NULL,
    groupe      INTEGER,            -- fr/es/it/pt 1..3, ro I..IV (1..4)
    particularite TEXT,             -- en: regulier/irregulier/double ;
                                     -- de: faible/forte ; pl/cs: -terminaison
    PRIMARY KEY (langue, ligne, col)
);
CREATE INDEX verbes_verbe ON verbes(langue, verbe);
CREATE TABLE verbes_lignes (
    langue TEXT NOT NULL,
    ligne  INTEGER NOT NULL,
    PRIMARY KEY (langue, ligne)
);
CREATE TABLE modeles (
    langue  TEXT NOT NULL,
    ligne   INTEGER NOT NULL,
    contenu TEXT NOT NULL,          -- une ligne de la colonne tpl
    PRIMARY KEY (langue, ligne)
);
CREATE TABLE vsrc (
    langue TEXT NOT NULL,
    pos    INTEGER NOT NULL,
    verbe  TEXT NOT NULL,
    PRIMARY KEY (langue, pos)
);
"""


def defs_txt(b, lg):
    p = PR[lg]
    k = cle(p, 'DEFS_B64')
    if k in b:
        return gzip.decompress(base64.b64decode(b[k])).decode('utf-8'), True
    return b[cle(p, 'DEFS_STR')], False


def cle(p, quoi):
    """Cle brute : CONJ_* pour le fr, sinon <LG>_* ; VSRC toujours <LG>_."""
    if p == 'CONJ':
        return ('FR_' if quoi == 'VSRC_STR' else 'CONJ_') + quoi
    return p + '_' + quoi


def importer(chemin_brut, chemin_db):
    b = json.load(open(chemin_brut, encoding='utf-8'))
    if os.path.exists(chemin_db):
        os.remove(chemin_db)
    db = sqlite3.connect(chemin_db)
    db.executescript(SCHEMA)
    aujourdhui = date.today().isoformat()
    for nom, (n, c) in SOURCES_CONNUES.items():
        db.execute('INSERT INTO sources(nom, caract) VALUES(?,?)', (n, c))
    for lg in PR:
        p = PR[lg]
        # tpl (les lignes vides comptent : pl/cs/ro ont un tpl entierement vide)
        for i, ligne in enumerate(b[cle(p, 'TPL_STR')].split('\n')):
            db.execute('INSERT INTO modeles VALUES(?,?,?)', (lg, i, ligne))
        # verbes (lignes de groupes, entrees separees par des virgules) ;
        # chaque ligne existe dans verbes_lignes, meme sans aucun verbe
        for i, grp in enumerate(b[cle(p, 'VERBS_STR')].split('\n')):
            db.execute('INSERT INTO verbes_lignes VALUES(?,?)', (lg, i))
            for j, seg in enumerate(grp.split(',')):
                if seg:
                    db.execute('INSERT INTO verbes VALUES(?,?,?,?,?,?,?,?)',
                                (lg, i, j, seg.split(':')[0], seg,
                                 aujourdhui, None, None))
        # vsrc
        for i, v in enumerate(b[cle(p, 'VSRC_STR')].split('\n')):
            if v:
                db.execute('INSERT INTO vsrc VALUES(?,?,?)', (lg, i, v))
        # defs
        d, _ = defs_txt(b, lg)
        for pos, entree in enumerate(d.split('\x02')):
            if not entree:
                continue
            verbe, _, reste = entree.partition(SEC)
            for rang, sens in enumerate(reste.split(SENS)):
                if ETIQ in sens:
                    et, _, tx = sens.partition(ETIQ)
                else:
                    et, tx = None, sens
                id_src = db.execute('SELECT id FROM sources WHERE nom=?',
                                    (et,)).fetchone() if et is not None else None
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                            (lg, pos, rang, verbe, et, tx,
                             id_src[0] if id_src else None, aujourdhui))
    db.commit()
    stats(db)
    db.close()
    print('import fini : %s' % chemin_db)


def exporter(chemin_db, chemin_brut):
    db = sqlite3.connect(chemin_db)
    b = json.load(open(chemin_brut, encoding='utf-8'))
    changes = []
    for lg in PR:
        p = PR[lg]
        orig_str, etait_b64 = defs_txt(b, lg)
        # tpl
        lignes = [r[0] for r in db.execute(
            'SELECT contenu FROM modeles WHERE langue=? ORDER BY ligne', (lg,))]
        b[cle(p, 'TPL_STR')] = '\n'.join(lignes)
        # verbes
        grps = {}
        for ligne, col, seg in db.execute(
                'SELECT ligne, col, segment FROM verbes WHERE langue=? '
                'ORDER BY ligne, col', (lg,)):
            grps.setdefault(ligne, {})[col] = seg
        lignes_verbes = [r[0] for r in db.execute(
            'SELECT ligne FROM verbes_lignes WHERE langue=? ORDER BY ligne',
            (lg,))]
        b[cle(p, 'VERBS_STR')] = '\n'.join(
            ','.join(v for _, v in sorted(grps.get(l, {}).items()))
            for l in lignes_verbes)
        # vsrc
        vs = [r[0] for r in db.execute(
            'SELECT verbe FROM vsrc WHERE langue=? ORDER BY pos', (lg,))]
        b[cle(p, 'VSRC_STR')] = '\n'.join(vs)
        # defs
        ent = {}
        for pos, rang, verbe, et, tx in db.execute(
                'SELECT pos, rang, verbe, etiquette, texte FROM defs '
                'WHERE langue=? ORDER BY pos, rang', (lg,)):
            sens = (ETIQ.join([et, tx]) if et is not None else tx)
            ent.setdefault(pos, []).append((verbe, sens))
        morceaux = []
        for pos in sorted(ent):
            v, premier = ent[pos][0]
            morceaux.append(v + SEC + SENS.join(s for _, s in ent[pos]))
        nouveau = '\x02'.join(morceaux)
        for v, reste in ((m.split(SEC, 1) + [''])[:2] for m in morceaux):
            for sens in reste.split(SENS):
                # \x01/\x02/\x03 interdits ; un second \x04 est permis
                # (le moteur ne coupe que sur le premier, cf. conjSens)
                for ch in ('\x01', '\x02', '\x03'):
                    assert ch not in sens, 'controle %r dans %r' % (ch, sens)
        if nouveau != orig_str:
            # ne reecrit que si le contenu a change : la recompression gzip
            # produirait sinon des octets differents pour le meme texte
            if etait_b64:
                b[cle(p, 'DEFS_B64')] = base64.b64encode(
                    gzip.compress(nouveau.encode('utf-8'), 6)).decode()
                b.pop(cle(p, 'DEFS_STR'), None)
            else:
                b[cle(p, 'DEFS_STR')] = nouveau
        changes.append((lg, orig_str == nouveau))
    db.close()
    with open(chemin_brut, 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))
    ok = all(x for _, x in changes)
    print('export : ' + ('identique a l original' if ok else 'MODIFIE')
          + ' (' + ', '.join('%s:%s' % (l, 'ok' if x else 'change')
                              for l, x in changes) + ')')
    print('brut.json regenere : %s' % chemin_brut)


def verifier(chemin_brut, chemin_db):
    """Reconstruit les 4 chaines depuis l atelier et les compare au brut."""
    db = sqlite3.connect(chemin_db)
    b = json.load(open(chemin_brut, encoding='utf-8'))
    for lg in PR:
        p = PR[lg]
        orig, _ = defs_txt(b, lg)
        reconstruits = {}
        # tpl
        reconstruits['tpl'] = '\n'.join(r[0] for r in db.execute(
            'SELECT contenu FROM modeles WHERE langue=? ORDER BY ligne', (lg,)))
        # verbes
        grps = {}
        for ligne, col, seg in db.execute(
                'SELECT ligne, col, segment FROM verbes WHERE langue=? '
                'ORDER BY ligne, col', (lg,)):
            grps.setdefault(ligne, {})[col] = seg
        lv = [r[0] for r in db.execute(
            'SELECT ligne FROM verbes_lignes WHERE langue=? ORDER BY ligne',
            (lg,))]
        reconstruits['verbs'] = '\n'.join(
            ','.join(v for _, v in sorted(grps.get(l, {}).items()))
            for l in lv)
        # vsrc
        reconstruits['vsrc'] = '\n'.join(r[0] for r in db.execute(
            'SELECT verbe FROM vsrc WHERE langue=? ORDER BY pos', (lg,)))
        # defs
        ent = {}
        for pos, rang, verbe, et, tx in db.execute(
                'SELECT pos, rang, verbe, etiquette, texte FROM defs '
                'WHERE langue=? ORDER BY pos, rang', (lg,)):
            ent.setdefault(pos, []).append(
                (verbe, ETIQ.join([et, tx]) if et is not None else tx))
        reconstruits['defs'] = '\x02'.join(
            ent[pos][0][0] + SEC + SENS.join(s for _, s in ent[pos])
            for pos in sorted(ent))
        attendus = {'tpl': b[cle(p, 'TPL_STR')],
                    'verbs': b[cle(p, 'VERBS_STR')],
                    'vsrc': b[cle(p, 'VSRC_STR')],
                    'defs': orig}
        diffs = [k for k in attendus if attendus[k] != reconstruits[k]]
        if diffs:
            print('DIVERGENCE %s : %s' % (lg, ', '.join(diffs)))
            db.close()
            sys.exit(1)
        print('%s : tpl/verbs/vsrc/defs concordent' % lg)
    db.close()
    print('atelier et brut.json concordent totalement.')


def stats(db):
    print('sources : %d' % db.execute(
        'SELECT COUNT(*) FROM sources').fetchone()[0])
    for lg in PR:
        n = db.execute('SELECT COUNT(*) FROM defs WHERE langue=?', (lg,)).fetchone()[0]
        v = db.execute('SELECT COUNT(*) FROM verbes WHERE langue=?', (lg,)).fetchone()[0]
        s = db.execute('SELECT COUNT(*) FROM defs WHERE langue=? '
                       'AND id_source IS NULL', (lg,)).fetchone()[0]
        print('%s : %d verbes, %d sens, %d sens sans source rattachee'
              % (lg, v, n, s))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'stats'
    def_brut = os.path.join(ICI, 'brut.json')
    def_atel = os.path.join(ICI, 'atelier.db')
    # import/verifier : brut puis atelier ; export/stats : atelier puis brut
    a2 = sys.argv[2] if len(sys.argv) > 2 else (
        def_atel if cmd in ('export', 'stats') else def_brut)
    a3 = sys.argv[3] if len(sys.argv) > 3 else (
        def_brut if cmd == 'export' else def_atel)
    if cmd == 'import':
        importer(a2, a3)
        db = sqlite3.connect(a3)
        stats(db)
        db.close()
    elif cmd == 'export':
        exporter(a2, a3)
        verifier(a3, a2)
    elif cmd == 'verifier':
        verifier(a3, a2) if False else verifier(a2, a3)
    elif cmd == 'stats':
        db = sqlite3.connect(a2)
        stats(db)
        db.close()
    else:
        print(__doc__)


if __name__ == '__main__':
    main()
