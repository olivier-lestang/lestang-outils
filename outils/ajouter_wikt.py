# Ajoute la definition angl. Wiktionary aux verbes it/pt/de qui n'en ont
# plus ( remplacees par la 1.3/1.4 par Petrocchi/Figueiredo/Sanders ),
# puis ordonne les sens : Wiktionary en premier, dictionnaire du
# domaine public ensuite.
#   1. restauration depuis la brute 1.2.2 ( glosses anglais Wikt )
#   2. fetch MediaWiki API en.wiktionary pour les verbes centraux
#      restants ( sont, kommen, entrare... ), cache durable.
# Usage : ajouter_wikt.py atelier.db brut122.json [--ecrire]
# SPDX-License-Identifier : MIT
import json, re, sqlite3, sys, time, urllib.parse, urllib.request

CACHE = '/home/user/artifacts/wikt_fetch.json'
WT = 'angl. Wiktionary'
LANGUES = {'it': 'Italian', 'pt': 'Portuguese', 'de': 'German'}
API = ('https://en.wiktionary.org/w/api.php?action=query&format=json'
       '&formatversion=2&prop=revisions&rvprop=content&rvslots=main'
       '&redirects=1&titles=')

def defs_old(path):
    b = json.load(open(path, encoding='utf-8'))
    out = {}
    for lg, cle in (('it', 'IT_DEFS_STR'), ('pt', 'PT_DEFS_STR'),
                    ('de', 'DE_DEFS_STR')):
        d = {}
        for rec in b[cle].split('\x02'):
            if not rec: continue
            v, reste = rec.split('\x01', 1)
            et, senss = reste.split('\x04', 1)
            senss = [s for s in senss.split('\x03') if s.strip()]
            if 'Wiktionary' in et and senss:
                d[v] = senss
        out[lg] = d
    return out

TPL = re.compile(r'\{\{[^{}]*\}\}', re.S)
def nettoyage(g):
    g = re.sub(r'<ref[^>]*/>', '', g)
    g = re.sub(r'\[\[[^\]|]*\|([^\]]*)\]\]', r'\1', g)
    g = re.sub(r'\[\[([^\]]*)\]\]', r'\1', g)
    for _ in range(6):
        g2 = TPL.sub('', g)
        if g2 == g: break
        g = g2
    g = re.sub(r"'''?", '', g)
    g = re.sub(r'\s+', ' ', g).strip(' ,;:')
    return g

def gloses_wikitext(t, langue):
    """gloses des sections Verb de la langue voulue"""
    i = t.find('==%s==' % LANGUES[langue])
    if i < 0: return []
    m2 = re.search(r'\n==[A-Z]', t[i + 4:])
    j = i + 4 + m2.start() if m2 else len(t)
    sec = t[i:j]
    out = []
    dans = False
    for ligne in sec.split('\n'):
        if re.match(r'={3,6}Verb[0-9 =(]*={3,6}\s*$', ligne):
            dans = True
            continue
        if dans and re.match(r'={2,6}[^=]', ligne):
            dans = False
            continue
        if dans and ligne.startswith('# ') and not ligne.startswith('#*'):
            g = nettoyage(ligne[2:])
            if g and len(g) > 1 and g not in out:
                out.append(g)
    return out[:4]

def fetch(verbes, langue):
    try:
        cache = json.load(open(CACHE, encoding='utf-8'))
    except Exception:
        cache = {}
    cle = 'wikt_' + langue
    cache.setdefault(cle, {})
    restants = [v for v in verbes if v not in cache[cle]]
    UA = {'User-Agent': 'LestangOutils/1.4.3'}
    for bi in range(0, len(restants), 50):
        lot = restants[bi:bi + 50]
        url = API + urllib.parse.quote('|'.join(lot))
        for essai in range(4):
            try:
                req = urllib.request.Request(url, headers=UA)
                r = json.load(urllib.request.urlopen(req, timeout=90))
                break
            except Exception as e:
                err = '%s: %s' % (type(e).__name__, e)
                time.sleep(3 + essai * 5)
        else:
            print('   ECHEC batch %d : %s' % (bi, err))
            continue
        pages = r.get('query', {}).get('pages', [])
        for p in pages:
            rev = p.get('revisions')
            if not rev:
                cache[cle][p.get('title', '?')] = ''   # absent
                continue
            tx = rev[0]['slots']['main']['content']
            cache[cle][p['title']] = gloses_wikitext(tx, langue)
        if 'missing' in p or True: pass
        for m in r.get('query', {}).get('normalized', []) + \
                 r.get('query', {}).get('redirects', []):
            src = m.get('from'); dst = m.get('to')
            if src in lot and dst in cache[cle]:
                cache[cle][src] = cache[cle][dst]
        if bi % 100 == 0:
            json.dump(cache, open(CACHE, 'w', encoding='utf-8'),
                      ensure_ascii=False)
        time.sleep(0.4)
    json.dump(cache, open(CACHE, 'w', encoding='utf-8'),
              ensure_ascii=False)
    return cache[cle]

def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dbp, brut122 = args[0], args[1]
    db = sqlite3.connect(dbp)
    old = defs_old(brut122)
    total_wikt = 0
    rapport = {}
    for lg in ('it', 'pt', 'de'):
        avec = {v for (v,) in db.execute(
            "SELECT DISTINCT verbe FROM defs WHERE langue=? AND etiquette LIKE 'angl. Wiktionary%'", (lg,))}
        tous = {v for (v,) in db.execute(
            "SELECT DISTINCT verbe FROM defs WHERE langue=?", (lg,))}
        sans = tous - avec
        rest = {v: old[lg][v] for v in sans if v in old[lg]}
        api_voulus = sorted(sans - set(rest))
        print('%s : %d sans Wikt | %d restaurables 1.2.2 | %d via API'
              % (lg, len(sans), len(rest), len(api_voulus)))
        fetched = fetch(api_voulus, lg) if api_voulus else {}
        api_gloses = {v: [g for g in fetched.get(v, []) if len(g) >= 2]
                      for v in api_voulus}
        n_wikt = {**{v: list(gs) for v, gs in rest.items()},
                  **{v: gs for v, gs in api_gloses.items() if gs}}
        rapport[lg] = {'restaures': len(rest), 'api_ok': sum(
            1 for v in api_voulus if api_gloses.get(v)),
            'api_absents': sum(1 for v in api_voulus if not api_gloses.get(v))}
        if not ecrire: continue
        src_id = dict(db.execute('SELECT nom, id FROM sources'))
        idw = src_id.get(WT)
        for v, gs in n_wikt.items():
            cur = list(db.execute(
                'SELECT pos, rang, verbe, etiquette, texte, id_source, '
                'date_ajout FROM defs WHERE langue=? AND verbe=? '
                'ORDER BY rang', (lg, v)))
            if not cur: continue
            pos = cur[0][0]
            date = cur[0][6] or '2026-11-25'
            db.execute('DELETE FROM defs WHERE langue=? AND verbe=?',
                       (lg, v))
            rg = 0
            for g in gs:
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                           (lg, pos, rg, v, WT, g, idw, '2026-11-25'))
                rg += 1
                total_wikt += 1
            for c in cur:
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                           (lg, pos, rg, v, c[3], c[4], c[5], date))
                rg += 1
        db.commit()
        print('   ecrit : %d verbes augmentes' % len(n_wikt))
    print('rapport :', json.dumps(rapport))
    print('sens Wikt ajoutes :', total_wikt if ecrire else '( lecture seule )')
    print('sens sans source :', db.execute(
        'SELECT COUNT(*) FROM defs WHERE id_source IS NULL').fetchone()[0])
    db.close()

if __name__ == '__main__':
    main()
