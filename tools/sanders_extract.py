# Extrait du Sanders, Woerterbuch der Deutschen Sprache (1876, 3 vol.,
# OCR maison Tesseract frk, sanders_ak/lr/sz.txt) les definitions des
# verbes allemands presents dans l'atelier, et les REMPLACENT dans defs
# ( comme dictionaries_pd.py pour it/pt ).
#  formats observes d entree de verbe :
#   Beginnen , begann , begunne ; begonnen : 1) tr. : anfangen ...
#   Arbeiten (-4<), 1) intr. (haben) : leibliche oder geistige Kraefte ...
#   Antworten, ir. : 1) Antwort geben, erwidern ...
# Variantes orthographiques 1876 : -ieren/-iren, f/ph, th/t, c/z.
# Usage : sanders_extract.py workshop.db ak.txt lr.txt sz.txt [--ecrire]
# SPDX-License-Identifier : MIT
import re, sqlite3, sys, time

SANDERS = 'Sanders 1876'
MAXDIST = 110
MAXSENS = 3

# Liste noire : gloses revues a la main dont la vedette est fausse
# ( tete d article perdue par l OCR Fraktur ) ou la glose polluee.
SKIP = {
    # --- partie 1 ( gloses 1-130 ) ---
    'beigen', 'beherzigen', 'bequemen', 'blecken', 'demaskieren',
    'eisen', 'einen', 'fällen', 'grillieren', 'grübeln', 'hassen',
    'herzen', 'himmeln', 'ketteln',
    # --- partie 2 ( gloses 130-267 ) ---
    'lachen', 'lesen', 'löschen', 'lösen', 'müssen', 'petzen',
    'pflanzen', 'quetschen', 'reden', 'reichen', 'räumen', 'rücken',
    'salben', 'sehnen', 'sein', 'stimmen', 'strecken', 'säbeln',
    'säen', 'sägen', 'verzoll', 'weben', 'wühlen', 'zählen',
    # --- echantillon final ---
    'leben', 'bringen', 'knirschen',
}

def normalise(t):
    t = t.replace('\r\n', '\n').replace('\ufeff', '')
    t = t.replace('ſ', 's')
    t = re.sub(r'-\n', '', t)
    t = t.replace('\n=== page', '\f=== page')
    t = re.sub(r'\n', ' ', t)
    t = t.replace('\f=== page', '\n=== page')
    return t

MARQ = re.compile(
    r'(?:^|[\s(;,.])'
    r'(?:\d?\d?\)?\s*)?'
    r'(?:inlr|infr|intr|ir|tr|ref|v)\.?\s?'
    r'(?:[.,;]\s*(?:ref\)?|intr|ir|haben|sein|tr)\.?)*\s*'
    r'(?:\([^)]{1,18}\)\s*)?'
    r'\s*[:]\s*')

MOT = re.compile(r'[A-ZÄÖÜ][a-zäöüß\-]{2,29}')
BRUITBAD = re.compile(r'[A-ZÄÖÜ“”„"«»?!]|--|==')
STOP = re.compile(r'\s--|\s==|\sS\s\.|\s1c\.|\s2c\.|\n|\sz\.\sB\.|\s=(?!=)|\sEtwas\s[a-z]{0,2}\.|:\s')

def variantes(v):
    return {v, v.replace('ß','ss'), v.replace('ß','s'),
            v.replace('ieren','iren'), v.replace('ieren','iren').replace('ss','s'),
            v.replace('phot','fot'), v.replace('th','t'), v.replace('th','t').replace('ieren','iren'),
            v.replace('c','z').replace('ieren','iren'), v.replace('y','i')}

def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dbp, f_ak, f_lr, f_sz = args[0], args[1], args[2], args[3]
    t0 = time.time()
    t = ''.join(normalise(open(f, encoding='utf-8').read())
                for f in (f_ak, f_lr, f_sz))
    print('texte : %.1f Mo' % (len(t)/1e6))

    db = sqlite3.connect(dbp)
    formes = {}
    for (v,) in db.execute("SELECT verbe FROM verbes WHERE langue='de' "
                           "GROUP BY verbe"):
        for x in variantes(v):
            formes.setdefault(x.lower(), v)
    inventaire = {v for v in formes.values()}

    trouve = {}
    for m in MARQ.finditer(t):
        deb = max(0, m.start()-MAXDIST)
        zone = t[deb:m.start()]
        best = None
        for mm in MOT.finditer(zone):
            v = formes.get(mm.group(0).lower())
            if not v:
                continue
            if BRUITBAD.search(zone[mm.end():]):
                continue
            if best is None or mm.end() > best[1]:
                best = (v, mm.end())
        if best is None:
            continue
        g = STOP.split(t[m.end():m.end()+380], 1)[0]
        g = re.sub(r'\s+', ' ', g).strip(' ,;:.').strip()
        if (len(g) >= 30 and not g[0].isupper()
                and not re.search(r'\bs\.\s?d', g[:22])):
            trouve.setdefault(best[0], []).append(g)
    # tri : garder la glose la plus longue si plusieurs ( proscrit
    # les fragments trop courts ), max 3 sens
    res = {}
    for v, gs in trouve.items():
        gs = sorted(set(gs), key=len, reverse=True)[:MAXSENS]
        res[v] = gs
    # ---- phase 2 : articles composites Prefix- + parent verbe ----
    # dans Sanders, les derives pre子上 abregent : 'Ein-: 1) intr. : ...'
    # sous l article du verbe parent ( Fahren, Kochen 2c. ).
    compose = {}
    direct = sorted(res.items())
    # positions des vedettes directes pour situer le parent
    COMP = re.compile(r'\b([A-ZÄÖÜ][a-zäöüß]{1,14})-\s*[:]?\s*\d?\)?\s*$')
    derniere = None   # (position, verbe) du parent le plus recent
    marques = sorted((m for m in MARQ.finditer(t)), key=lambda x: x.start())
    # reperer les tetes d articles reconnues en phase 1 : repasse
    tetes = []
    for m in MARQ.finditer(t):
        deb = max(0, m.start()-MAXDIST)
        zone = t[deb:m.start()]
        best = None
        for mm in MOT.finditer(zone):
            v = formes.get(mm.group(0).lower())
            if not v: continue
            if BRUITBAD.search(zone[mm.end():]): continue
            if best is None or mm.end() > best[1]: best = (v, mm.end())
        if best: tetes.append((m.start(), best[0]))
    pont = 6000   # le parent doit etre assez proche
    for m in marques:
        # parent le plus recent avant ce marqueur
        parent = None
        for pos, v in reversed(tetes):
            if pos < m.start():
                if m.start() - pos < pont: parent = v
                break
        if not parent: continue
        zone2 = t[max(0,m.start()-70):m.start()]
        mc = None
        for mm in COMP.finditer(zone2):
            mc = mm
        if not mc: continue
        pref = mc.group(1).lower()
        cand = formes.get(pref + parent)
        if not cand: continue
        g = STOP.split(t[m.end():m.end()+380], 1)[0]
        g = re.sub(r'\s+', ' ', g).strip(' ,;:.').strip()
        if (len(g) >= 30 and not g[0].isupper()
                and not re.search(r'\bs\.\s?d', g[:22])):
            compose.setdefault(cand, []).append(g)
    for v, gs in compose.items():
        if v not in res:
            res[v] = sorted(set(gs), key=len, reverse=True)[:MAXSENS]
    print('verbes ajoutes via composites Prefix- : %d' % len(compose))

    for v in (SKIP & set(res)):
        del res[v]
    bilans = len(res)
    print('verbes de l atelier      : %d' % len(inventaire))
    print('verbes trouves chez Sanders : %d (%.1fs)' % (bilans, time.time()-t0))
    import random
    random.seed(7)
    echant = random.sample(sorted(res), 18)
    for v in echant:
        print('   %-15s %s' % (v, res[v][0][:95]))

    if ecrire:
        db.execute("INSERT OR IGNORE INTO sources(nom,caract) VALUES(?,?)",
                   (SANDERS, 'Daniel Sanders, Woerterbuch der deutschen '
                             'Sprache ( 1876, 3 vol. ), domaine public ; '
                             'OCR maison Tesseract modele frk ( 2026-11-25 )'))
        id_s = dict((n, i) for i, n in db.execute('SELECT id, nom FROM sources'))
        n = 0
        for v, senss in res.items():
            db.execute("DELETE FROM defs WHERE langue='de' AND verbe=?", (v,))
            pos = db.execute("SELECT COALESCE(MAX(pos),-1)+1 FROM defs "
                             "WHERE langue='de'").fetchone()[0]
            for rg, sens in enumerate(senss):
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                           ('de', pos, rg, v, SANDERS, sens, id_s[SANDERS],
                            '2026-11-25'))
            n += 1
        db.commit()
        print('%d verbes de remplaces' % n)
        print('defs sans source : %d' % db.execute(
            "SELECT COUNT(*) FROM defs WHERE id_source IS NULL").fetchone()[0])
    db.close()
    print('mode : %s' % ('ECRITURE' if ecrire else 'lecture seule'))

if __name__ == '__main__':
    main()
