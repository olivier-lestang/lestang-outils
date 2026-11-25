# Definitions natives des Wiktionary monolingues pour fr/es/it/pt/de :
# ajoute, pour chaque verbe de la langue qui a un article dans le
# Wiktionary de sa langue, ses sens natifs EN TETE de la fiche,
# etiquette '<lg>. Wiktionary' ( 'fr. Wiktionnaire' pour le francais ).
# Les verbes couverts perdent leur glose anglaise ( 'angl. Wiktionary',
# qui ne reste, comme secours, que pour les verbes sans article natif ) ;
# les definitions des dictionnaires du domaine public viennent ensuite.
# Donnees : outils/dump_natif.py -> cache durable wikt_natif_fetch.json
# ( dumps Wikimedia des Wiktionary monolingues, CC BY-SA 4.0 ).
# Usage :
#   python3 outils/natifs_wikt.py [atelier.db] [wikt_natif_fetch.json] [--ecrire]
# Sans --ecrire : tour a blanc. SPDX-License-Identifier : MIT
import json
import os
import sqlite3
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
CACHE_DEF = '/home/user/artifacts/wikt_natif_fetch.json'
JOUR = '2026-11-25'

ETIQ = {'fr': 'fr. Wiktionnaire', 'es': 'es. Wiktionary',
        'it': 'it. Wiktionary', 'pt': 'pt. Wiktionary',
        'de': 'de. Wiktionary'}
CARACT = {
    'fr. Wiktionnaire':
        'Definition native du Wiktionnaire francophone, dump Wikimedia '
        'frwiktionary, CC BY-SA 4.0',
    'es. Wiktionary':
        'Definicion nativa del Wikcionario espanol, dump Wikimedia '
        'eswiktionary, CC BY-SA 4.0',
    'it. Wiktionary':
        'Definizione nativa del Wikizionario italiano, dump Wikimedia '
        'itwiktionary, CC BY-SA 4.0',
    'pt. Wiktionary':
        'Definicao nativa do Wikcionario portugues, dump Wikimedia '
        'ptwiktionary, CC BY-SA 4.0',
    'de. Wiktionary':
        'Deutsche Definition des deutschsprachigen Wiktionarys, dump '
        'Wikimedia dewiktionary, CC BY-SA 4.0',
}


def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    atelier = args[0] if args else os.path.join(ICI, 'atelier.db')
    cache_p = args[1] if len(args) > 1 else CACHE_DEF
    cache = json.load(open(cache_p, encoding='utf-8'))

    db = sqlite3.connect(atelier)
    id_s = {n: i for i, n in db.execute('SELECT id, nom FROM sources')}
    for nom, caract in CARACT.items():
        if nom not in id_s:
            cur = db.execute('INSERT INTO sources(nom, caract) VALUES(?,?)',
                             (nom, caract))
            id_s[nom] = cur.lastrowid

    natifs = {}          # langue -> verbe -> sens natifs
    for lg, etiq in ETIQ.items():
        natifs[lg] = {}
        les_verbes = {v for (v,) in db.execute(
            'SELECT verbe FROM verbes WHERE langue=?', (lg,))}
        for v, gloses in cache.get(lg, {}).items():
            if v not in les_verbes:
                continue
            gs = [g.strip(' ,;:.') for g in gloses or []]
            gs = [g for g in gs if len(g) > 1]
            dedup = []
            for g in gs:
                if g not in dedup:
                    dedup.append(g)
            if dedup:
                natifs[lg][v] = dedup[:4]
        print('%s : %d verbes natifs' % (lg, len(natifs[lg])), flush=True)
    if not ecrire:
        print('mode : lecture seule')
        db.close()
        return

    total = 0
    retires = 0
    for lg, etiq in ETIQ.items():
        idw = id_s[etiq]
        for v, gs in natifs[lg].items():
            cur = list(db.execute(
                'SELECT pos, rang, etiquette, texte, id_source, date_ajout '
                'FROM defs WHERE langue=? AND verbe=? ORDER BY rang',
                (lg, v)))
            if not cur:
                continue
            pos = cur[0][0]
            date = cur[0][5] or JOUR
            db.execute('DELETE FROM defs WHERE langue=? AND verbe=?', (lg, v))
            rg = 0
            for g in gs:
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                           (lg, pos, rg, v, etiq, g, idw, JOUR))
                rg += 1
                total += 1
            # natif present : la glose anglaise est retiree ( elle ne
            # reste que pour les verbes sans article natif )
            for c in cur:
                if (c[2] or '') == 'angl. Wiktionary':
                    retires += 1
                    continue
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                           (lg, pos, rg, v, c[2], c[3], c[4], date))
                rg += 1
        db.commit()
        print('%s : ecrit' % lg, flush=True)
    print('sens natifs ecrits : %d | sens anglais retires : %d'
          % (total, retires))
    print('sens sans source :', db.execute(
        'SELECT COUNT(*) FROM defs WHERE id_source IS NULL').fetchone()[0])
    db.close()


if __name__ == '__main__':
    main()
