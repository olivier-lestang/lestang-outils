# Extrait des dumps Wikimedia des Wiktionary natifs ( fr, es, it, pt, de )
# la definition VERBALE de chaque verbe de l'atelier : section de la
# langue, section Verbe uniquement ( pas d adjectifs ni de flexions ),
# jusqu a 4 sens. Ecrit le cache durable wikt_natif_fetch.json,
# une langue par appel. ScanByteBuffer : seuls les titres voulus
# sont decodes ( rapide ).
# Usage : python3 dump_native.py <lg> <dump.xml.bz2> [workshop.db] [cache.json]
# SPDX-License-Identifier : MIT
import bz2
import json
import os
import re
import sqlite3
import sys

CACHE_DEF = '/home/user/artifacts/wikt_natif_fetch.json'
TPL = re.compile(r'\{\{[^{}]*\}\}', re.S)

LANGUE = {
    'fr': re.compile(r'^=+\s*\{\{\s*langue\|fr\s*\}\}\s*=+\s*$'),
    'es': re.compile(r'^=+\s*\{\{\s*lengua\|es\s*\}\}\s*=+\s*$'),
    'it': re.compile(r'^=+\s*\{\{\s*-it-\s*\}\}\s*=+\s*$'),
    'pt': re.compile(r'^=+\s*\{\{\s*-pt-\s*\}\}\s*=+\s*$'),
    'de': re.compile(r'^=+\s*.*\{\{\s*Sprache\|Deutsch\s*\}\}'),
}
AUTRE_LANGUE = {
    'fr': re.compile(r'^=+\s*\{\{\s*langue\|[a-z-]+\s*\}\}'),
    'es': re.compile(r'^=+\s*\{\{\s*lengua\|[a-z-]+\s*\}\}'),
    'it': re.compile(r'^=+\s*\{\{\s*-[a-zà-ÿ]+-\s*(?:\|[^ }]*)?\}\}\s*=+\s*$'),
    'pt': re.compile(r'^=+\s*\{\{\s*-[a-zà-ÿ]+-\s*\}\}\s*=+\s*$'),
    'de': re.compile(r'^=+\s*.*\{\{\s*Sprache\|[A-Za-z]+\s*\}\}'),
}
VERBE = {
    'fr': re.compile(r'^=+\s*\{\{\s*S\s*\|verbe[^}]*\}\}\s*=+\s*$'),
    'es': re.compile(r'^=+\s*\{\{\s*verbo[^}]*\}\}\s*=+\s*$'),
    'pt': re.compile(r'^=+\s*Verbos?\b.*=+\s*$'),
    'de': re.compile(r'^=+\s*\{\{\s*Wortart\|Verb\|Deutsch[^}]*\}\}[^=]*=+\s*$'),
}
IT_VERBE = re.compile(r'^\s*\{\{-verb-\|?\s*(?:it)?\s*\}\}\s*$')
IT_PO = re.compile(r'^\s*\{\{-[a-zà-ÿ0-9 ]+-\|?\s*[a-z]*\}\}')
FLEXION = re.compile(r'flexion|Wortform|Forma\b')


def nettoyage(g):
    g = re.sub(r'<ref[^>]*/>', '', g)
    g = re.sub(r'<ref[^>]*>.*?</ref>', '', g, flags=re.S)
    g = re.sub(r'\[\[[^\]|]*\|([^\]]*)\]\]', r'\1', g)
    g = re.sub(r'\[\[([^\]]*)\]\]', r'\1', g)
    for _ in range(3):
        g = re.sub(r'\{\{(?:plm2?|ucf)\|([^{}|]*)\|?[^{}]*\}\}', r'\1, ', g)
    for _ in range(6):
        g2 = TPL.sub('', g)
        if g2 == g:
            break
        g = g2
    g = re.sub(r"'''?", '', g)
    g = re.sub(r'\s*,\s*,+', ', ', g)
    g = re.sub(r'\s+', ' ', g).strip(' ,;:.-')
    return g


def gloses(tx, lg, verbe):
    m_lang = LANGUE[lg]
    m_autre = AUTRE_LANGUE[lg]
    m_verbe = VERBE.get(lg)
    dans_lang = dans_verbe = False
    out = []
    for l in tx.split('\n'):
        if m_lang.match(l):
            dans_lang, dans_verbe = True, False
            continue
        if not dans_lang:
            continue
        if lg == 'it' and (l.startswith('=') or m_autre.match(l)):
            if m_autre.match(l):
                dans_lang = dans_verbe = False
            else:
                dans_verbe = False
            continue
        if lg != 'it' and (l.startswith('=') or m_autre.match(l)):
            if m_autre.match(l):
                dans_lang = dans_verbe = False
                continue
            if m_verbe is not None and re.match(r'^={2,6}\s*[^=]', l):
                dans_verbe = bool(m_verbe.match(l)) and \
                    not FLEXION.search(l)
            else:
                dans_verbe = False
            continue
        # ligne de glose potentielle
        if lg == 'it':
            if IT_VERBE.match(l):
                dans_verbe = True
                continue
            if IT_PO.match(l):
                dans_verbe = False
                continue
            g = l[2:] if re.match(r'^#[^#:*]', l) else None
        elif lg == 'de':
            m = re.match(r'^:\[?\d+\]?\s*(.*)$', l)
            g = m.group(1) if m else None
        elif lg == 'es':
            m = re.match(r'^;\d+:\s*(.*)$', l)
            if m:
                g = m.group(1)
            elif l.startswith('# ') and not l.startswith('#*'):
                g = l[2:]
            else:
                g = None
        else:
            if l.startswith('#') and not l.startswith(('#*', '#:', '##')):
                g = l[1:].strip()
            else:
                g = None
        if g is None or not dans_verbe:
            continue
        g = nettoyage(g)
        if g and len(g) > 1 and g.lower() != verbe.lower() and g not in out:
            out.append(g)
    return out[:4]


def main():
    lg = sys.argv[1]
    dump = sys.argv[2]
    atelier = sys.argv[3] if len(sys.argv) > 3 else 'workshop.db'
    cache_p = sys.argv[4] if len(sys.argv) > 4 else CACHE_DEF
    db = sqlite3.connect(atelier)
    verbes = [v for (v,) in db.execute(
        'SELECT verbe FROM verbes WHERE langue=?', (lg,))]
    casse = {}
    for v in verbes:
        casse.setdefault(v[0].lower() + v[1:], []).append(v)
    cache = {}
    if os.path.exists(cache_p):
        try:
            cache = json.load(open(cache_p, encoding='utf-8'))
        except Exception:
            cache = {}
    cache.setdefault(lg, {})
    TR = b'<title>'
    PAT_X = re.compile(r'<text[^>]*>(.*?)</text>', re.S)
    n_gardees = 0
    redirects = {}
    with bz2.open(dump, 'rb') as f:
        buf = b''
        while True:
            ch = f.read(40_000_000)
            if not ch:
                break
            buf += ch
            pos = 0
            while True:
                i = buf.find(TR, pos)
                if i < 0:
                    pos = len(buf)
                    break
                j = buf.find(b'</title>', i)
                if j < 0:
                    pos = i
                    break
                titre = buf[i + len(TR):j].decode('utf-8', 'replace')[:80]
                clef = titre[0].lower() + titre[1:] if titre else ''
                garde = (clef in casse) or (titre in casse.get(titre, []))
                if not garde:
                    pos = j
                    continue
                k = buf.find(b'</page>', j)
                if k < 0:
                    pos = i
                    break
                bloc = buf[i:k].decode('utf-8', 'replace')
                mx = PAT_X.search(bloc)
                if mx:
                    tx = mx.group(1).replace('&lt;', '<'). \
                        replace('&gt;', '>').replace('&quot;', '"') \
                        .replace('&amp;', '&')
                    mred = re.match(r'\s*#REDIRECT\s*\[\[([^\]|#]+)', tx,
                                    re.I)
                    if mred:
                        for v in casse.get(clef, []):
                            redirects[v] = mred.group(1).strip()
                    else:
                        gs = gloses(tx, lg, titre)
                        for v in casse.get(clef, []):
                            if v == titre:
                                cache[lg][v] = gs      # exact : priorite
                            elif v not in cache[lg] or \
                                    not cache[lg][v]:
                                cache[lg][v] = gs      # variante de casse
                        n_gardees += 1
                pos = k + 8
            if pos < len(buf):
                buf = buf[pos:]
            else:
                buf = b''
    for v, cible in redirects.items():
        c0 = cible[0].lower() + cible[1:]
        cache[lg][v] = cache[lg].get(cible, cache[lg].get(c0, ''))
    json.dump(cache, open(cache_p, 'w', encoding='utf-8'),
              ensure_ascii=False)
    avec = sum(1 for g in cache[lg].values() if g)
    print('%s : %d pages gardees ; %d verbes en cache ; %d avec gloses ;'
          ' %d redirects' % (lg, n_gardees, len(cache[lg]), avec,
                             len(redirects)), flush=True)


if __name__ == '__main__':
    main()
