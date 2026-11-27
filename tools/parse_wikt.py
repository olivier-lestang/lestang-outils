# Extrait les definitions monolingues des dumps Wiktionary pl/cs/ro
# pour une liste de verbes. Sortie : {mot: {'g': gloss jusqu a 4 sens}}
# SPDX-License-Identifier: MIT
import bz2, json, re, sys

def nettoie(l):
    l = re.sub(r'<ref[^>]*/>', '', l)
    l = re.sub(r'<ref[^>]*>.*?</ref>', '', l, flags=re.S)
    l = re.sub(r'<[^>]+>', '', l)
    while re.search(r'\{\{[^{}]*\}\}', l):
        l = re.sub(r'\{\{[^{}]*\}\}', '', l)
    l = re.sub(r'\[\[(?:[^|\]]*\|)?([^\]]*)\]\]', r'\1', l)
    l = re.sub(r"''+", '', l)
    l = re.sub(r'\s+', ' ', l).strip()
    return re.sub(r'[;,.\s]+$', '', l).strip()

def section(texte, debut_re, fin_re):
    m = debut_re.search(texte)
    if not m:
        return ''
    f = fin_re.search(texte, m.end())
    return texte[m.start():f.start() if f else len(texte)]

def ro(texte):
    sec = section(texte, re.compile(r'^==\s*\{\{limba\|ron\}\}\s*==', re.M),
                  re.compile(r'^==[^=]', re.M))
    v = section(sec, re.compile(r'^\{\{-verb-\|ron\}\}', re.M),
                re.compile(r'^\{\{-|^==[^=]', re.M))
    defs = []
    for ligne in v.split('\n'):
        ls = ligne.strip()
        if ls.startswith('((') or ls.startswith('*'):
            continue
        if ls.startswith('#') and not ls.startswith(('#:', '#*')):
            t = nettoie(ls[1:])
            if len(t) >= 3 and t not in defs:
                defs.append(t)
        elif ls and not ls.startswith('#') and defs:
            break
        if len(defs) >= 4:
            break
    return defs

def pl(texte):
    sec = section(texte, re.compile(r'^==[^\n]*\(\{\{język polski\}\}\)', re.M),
                  re.compile(r'^==[^=]', re.M))
    zs = re.search(r'\{\{znaczenia\}\}', sec)
    if not zs:
        return []
    fin = re.search(r'\{\{odmiana\}\}|^==|\{\{wymowa\}\}', sec[zs.end():], re.M)
    bloc = sec[zs.end():zs.end() + fin.start()] if fin else sec[zs.end():]
    defs, pos = [], False
    for ligne in bloc.split('\n'):
        ls = ligne.strip()
        if re.search(r"''.*czasownik.*''", ls):
            pos = True
            continue
        if ls.startswith(': (') and pos:
            t = nettoie(re.sub(r'^:\s*\(\d+\.\d+\)\s*', '', ls))
            if len(t) >= 3 and t not in defs:
                defs.append(t)
        if len(defs) >= 4:
            break
    return defs

def cs(texte):
    sec = section(texte, re.compile(r'^==\s*čeština\s*==', re.M),
                  re.compile(r'^==[^=]', re.M))
    v = section(sec, re.compile(r'^===\s*sloveso\s*===', re.M),
                re.compile(r'^===[^=]', re.M))
    m = re.search(r'^=+\s*význam', v, re.M)
    if not m:
        return []
    fin = re.search(r'^=+[^=]', v[m.end():], re.M)
    bloc = v[m.end():m.end() + fin.start()] if fin else v[m.end():]
    defs = []
    for ligne in bloc.split('\n'):
        ls = ligne.strip()
        if ls.startswith('#') and not ls.startswith(('#:', '#*')):
            t = nettoie(ls[1:])
            if len(t) >= 3 and t not in defs:
                defs.append(t)
        elif ls and not ls.startswith(('#',)) and defs:
            break
        if len(defs) >= 4:
            break
    return defs

PARSE = {'ro': ro, 'pl': pl, 'cs': cs}

def main():
    lg, cible, sortie = sys.argv[1:4]
    dump = {'ro': 'rowiktionary-latest-pages-articles.xml.bz2',
            'pl': 'plwiktionary-latest-pages-articles.xml.bz2',
            'cs': 'cswiktionary-latest-pages-articles.xml.bz2'}[lg]
    mots = {l.strip() for l in open(cible, encoding='utf-8') if l.strip()}
    extraire = PARSE[lg]
    out = {}
    titre_re = re.compile(r'<title>([^<]+)</title>')
    texte_re = re.compile(r'xml:space="preserve">(.*?)</text>', re.S)
    flux = bz2.open(dump, 'rt', encoding='utf-8', errors='replace')
    page, titre, dans = [], '', False
    for ligne in flux:
        if '<title>' in ligne:
            m = titre_re.search(ligne)
            if m:
                titre = m.group(1)
                dans = titre in mots
        elif dans and '</page>' in ligne:
            page.append(ligne)
            m = texte_re.search(''.join(page))
            if m:
                d = extraire(m.group(1))
                if d:
                    out[titre] = ' ; '.join(d[:4])
            page, dans = [], False
        elif dans:
            page.append(ligne)
    with open(sortie, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1, sort_keys=True)
    print('%s : %d verbes avec definition monolingue sur %d (%.0f%%)'
          % (lg, len(out), len(mots), 100.0 * len(out) / len(mots)))

if __name__ == '__main__':
    main()
