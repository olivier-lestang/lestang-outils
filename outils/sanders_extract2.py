# -*- coding: utf-8 -*-
# sanders_extract2.py v4 - extraction MULTI-SENS du Sanders 1876 ( lot 42 ).
# SPDX-License-Identifier : MIT
import json, os, re, sqlite3, sys, time

MAXSENS   = 6
LG_MIN    = 22
MAXPARENT = 120

SKIP = {
    'beigen', 'beherzigen', 'bequemen', 'blecken', 'demaskieren',
    'eisen', 'einen', 'fällen', 'grillieren', 'grübeln', 'hassen',
    'herzen', 'himmeln', 'ketteln',
    'lachen', 'lesen', 'löschen', 'lösen', 'müssen', 'petzen',
    'pflanzen', 'quetschen', 'reden', 'reichen', 'räumen', 'rücken',
    'salben', 'sehnen', 'sein', 'stimmen', 'strecken', 'säbeln',
    'säen', 'sägen', 'verzoll', 'weben', 'wühlen', 'zählen',
    'leben', 'bringen', 'knirschen',
}

FONCTIONS = {
    'also', 'bei', 'dabei', 'danach', 'dann', 'deshalb', 'durch',
    'eben', 'ebenso', 'eines', 'ferner', 'fur', 'für', 'hier', 'mit',
    'nach', 'namlich', 'namentlich', 'nichts', 'oft', 'ohne', 'so',
    'statt', 'uber', 'ueber', 'über', 'unter', 'vor', 'wegen', 'wohl',
    'zudem', 'zuletzt', 'zum', 'zur', 'zwar',
}

def normalise(t):
    t = t.replace('\ufeff', '').replace('\r\n', '\n').replace('\r', '\n')
    t = t.replace('ſ', 's')
    t = re.sub(r'([a-zäöüß])-\n', r'\1', t)
    return t

MARQ = re.compile(
    r'(?:^|[\s(;,.])'
    r'(?:\d?\d?\)?\s*)?'
    r'(?:inlr|infr|intr|ir|tr|ref|re[sß]|v|imp)\.?\s?'
    r'(?:[.,;]\s*(?:ref\)?|intr|ir|haben|sein|tr|ugs?|imp)\.?)*\s*'
    r'(?:\([^)]{1,18}\)\s*)?'
    r'\s*[:]\s*')
SOUS = re.compile(r'(?:^|[\s(;])([0-9]{1,2}|[a-z])\)\s')
STOP = re.compile(r'\s--|\s=-|\s==|\sS\s\.|\s1c\.|\s2c\.|\s\nc\.|\n|\sz\.\sB\.|\sEtwas\s[a-z]{0,2}\.|:\s'
                  r'|\s[A-ZÄÖÜ][a-zäöüß]+\s+[A-ZÄÖÜ][a-zäöüß]*\.\s+\d|\s[A-ZÄÖÜ][a-zäöüß]+\s+\d')
BRUIT = re.compile(r'["”“„«»]|--|==|\s=-')
# sous-entree composite ( "Ver-: 1) tr. :", "Ein- [2]:" ) : fin d article
COMPF = re.compile(r'\b[A-ZÄÖÜ][a-zäöüß]{1,14}-\s*(?::|!|\[\d)')
CITATION = re.compile(r'^[A-ZÄÖÜ][a-zäöüß]+\s+\d')

OUVERT = re.compile(r'^([A-ZÄÖÜ][a-zäöüß\-]{2,29})\s*(?:[,:]\s*|\(\s*|\s,[a-zäöü])')
NOMINAL = re.compile(r'^\s*[,:]\s*(?:m|f|n|pl)\.')
# vedette avec article allemand : "Machen, die Macherei" = nom, pas verbe
NOMINAL2 = re.compile(r'^\s*[,:]\s*(?:m|f|n|pl|der|die|das|ein|eine)\b')
GRAM = re.compile(r'^\s*[,:]\s*(?:m|f|n|pl|v|adj|adv|intr|infr|inlr|ir|tr|'
                  r'ref|refl|re[sß]|imp|ugs?|haben|sein|impers|pers|inpers)\b')
PAR = re.compile(r'^\s*\(\s*[-\d“„]')

def forte(m, l):
    rest = l[m.end(1):]
    if GRAM.match(rest) or PAR.match(rest):
        return True
    if MARQ.search(l[:150]):
        return True
    tete = rest[:120]
    if (';' in tete or tete.count(',') >= 2) and \
       (':' in tete or (tete.count('(') >= 1 and
                        tete.count('(') >= tete.count(')'))) and \
       '?' not in tete:
        return True
    return False

def variantes(v):
    return {v, v.replace('ß', 'ss'), v.replace('ß', 's'),
            v.replace('ieren', 'iren'),
            v.replace('ieren', 'iren').replace('ss', 's'),
            v.replace('phot', 'fot'), v.replace('th', 't'),
            v.replace('th', 't').replace('ieren', 'iren'),
            v.replace('c', 'z').replace('ieren', 'iren'),
            v.replace('y', 'i')}

def glose(seg):
    g = STOP.split(seg, 1)[0]
    g = re.sub(r'\s+', ' ', g).strip(' ,;:.)').strip()
    if not g:
        return None
    if BRUIT.search(g):
        return None
    if len(g) < LG_MIN:
        return None
    if g.startswith('[') or re.search(r'\[\d', g):
        return None
    if re.search(r'\d{2,}', g):     # references de citations ( 22,46 / 977 )
        return None
    if g[0].isupper() and CITATION.match(g):
        return None
    if len(g) > 400:
        return None
    if re.match(r'^(?:\d|[ivx])\)', g):
        return None
    return g

def sens_article(txt):
    if len(txt) > 6000:
        txt = txt[:6000]
    mc = COMPF.search(txt)
    if mc:
        txt = txt[:mc.start()]   # les composites ne sont pas ses sens
    marques = []
    for mm in MARQ.finditer(txt):
        marques.append((mm.start(), mm.end()))
    for mm in SOUS.finditer(txt):
        marques.append((mm.start() + mm.group(0).index(mm.group(1)) + len(mm.group(1)) + 1,
                        mm.end()))
    marques.sort(key=lambda x: (x[0], -(x[1] - x[0])))
    propres = []
    for d, f in marques:
        if propres and d < propres[-1][1]:
            continue
        propres.append((d, f))
    gs = []
    for i, (d, f) in enumerate(propres):
        fin = propres[i + 1][0] if i + 1 < len(propres) else f + 420
        g = glose(txt[f:min(fin, f + 420)])
        if g:
            gs.append(g)
    vus, pur = set(), []
    for g in gs:
        if g not in vus:
            vus.add(g)
            pur.append(g)
    return pur

def main():
    ici = os.path.dirname(os.path.abspath(__file__))
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dbp = args[0]
    fichiers = args[1:4]
    t0 = time.time()

    db = sqlite3.connect('file:%s?mode=ro' % dbp, uri=True)
    formes = {}
    for (v,) in db.execute("SELECT verbe FROM verbes WHERE langue='de' "
                           "GROUP BY verbe"):
        for x in variantes(v):
            formes.setdefault(x.lower(), v)
    db.close()
    print('verbes allemands de l atelier : %d' % len(set(formes.values())))

    res, composites = {}, {}

    def cloture():
        if cour[0] in res:
            res[cour[0]] = (res[cour[0]] +
                            [g for g in pur if g not in res[cour[0]]])[:MAXSENS]
        elif pur:
            res[cour[0]] = pur[:MAXSENS]

    n_blocs = 0
    for f in fichiers:
        t = normalise(open(f, encoding='utf-8').read())
        fusion = []
        for l in t.split('\n'):
            if fusion and fusion[-1].endswith('-') and \
               re.search(r'[a-zäöüß]-$', fusion[-1]):
                fusion[-1] = fusion[-1][:-1] + l.lstrip()
            else:
                fusion.append(l)
        cour = None
        for l in fusion:
            l = l.strip()
            if not l:
                continue
            if l.startswith('=== page'):
                if cour:
                    pur = sens_article(' '.join(cour[1]))
                    cloture()
                    cour = None
                continue
            m = OUVERT.match(l)
            mot = m.group(1).lower() if m else None
            if m and mot not in FONCTIONS and forte(m, l):
                if cour:
                    pur = sens_article(' '.join(cour[1]))
                    cloture()
                    cour = None
                n_blocs += 1
                v = formes.get(mot)
                # article de verbe : ni vedette nominale ( m. f. n. )
                # ni nom avec article ( der die das ein eine )
                if v and not NOMINAL2.match(l[m.end(1):].lstrip()):
                    cour = (v, [l])
            elif cour is not None:
                if l.lower() == cour[0]:
                    continue
                if mot and formes.get(mot) == cour[0]:
                    continue
                cour[1].append(l)
        if cour:
            pur = sens_article(' '.join(cour[1]))
            cloture()
    print('blocs ( vedettes quelconques ) : %d (%.1fs)' % (n_blocs, time.time() - t0))

    for f in fichiers:
        t = normalise(open(f, encoding='utf-8').read())
        for mm in re.finditer(r'\b([A-ZÄÖÜ][a-zäöüß]{1,14})-\s*[: ]?\s*'
                              r'(?=\d?\)?\s*(?:inlr|infr|intr|ir|tr|ref|'
                              r're[sß]|v)\b|\d\)\s)', t):
            zone = t[max(0, mm.start() - MAXPARENT):mm.start()]
            parent = None
            for mm2 in re.finditer(r'[A-ZÄÖÜ][a-zäöüß]{2,29}', zone):
                if mm2.group(0).lower() in formes:
                    parent = mm2.group(0).lower()
            if not parent:
                continue
            cand = formes.get(mm.group(1).lower() + parent)
            if not cand:
                continue
            g = glose(t[mm.end():mm.end() + 420])
            if g and g not in composites.get(cand, []):
                composites.setdefault(cand, []).append(g)

    for v, gs in composites.items():
        if v not in res and gs:
            res[v] = gs[:MAXSENS]
    for v in (SKIP & set(res)):
        del res[v]

    print('verbes avec sens : %d (%.1fs)' % (len(res), time.time() - t0))
    n_sens = sum(len(g) for g in res.values())
    print('sens au total : %d ( moyenne %.2f )' % (n_sens, n_sens / max(1, len(res))))

    for v in ('stammen', 'beginnen', 'antworten', 'arbeiten', 'reihen', 'wachsen', 'machen', 'folgen'):
        print('--- %s' % v)
        for i, g in enumerate(res.get(v, [])):
            print('   %d) %s' % (i + 1, g[:105]))

    out = os.path.join(ici, 'sanders_sens2.json')
    with open(out, 'w', encoding='utf-8') as fo:
        json.dump({'source': 'Sanders 1876', 'verbes': res},
                  fo, ensure_ascii=False, separators=(',', ':'))
    print('ecrit : %s (%.1f Ko)' % (out, os.path.getsize(out) / 1e3))

if __name__ == '__main__':
    main()
