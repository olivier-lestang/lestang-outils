# Filtre le lexique anglais par le Webster's Revised Unabridged Dictionary
# ( 1913, texte du domaine public ; numerisation lunixbochs/webster, code
#   MIT, cite dans le README ). Regle demandee : un verbe ne reste dans la
# base que si un dictionnaire du domaine public le definit ; sa definition
# vient alors de ce dictionnaire.
#   1. les verbes du generateur ( defs Webster du projet web ) restent ;
#   2. un verbe Wiktionary reste seulement si le Webster 1913 le definit
#      comme verbe, et son glossaire Wiktionary est remplace par la
#      definition du Webster ;
#   3. tout autre verbe Wiktionary, et sa definition, sont retires.
# Usage : python3 outils/filter_webster.py webster1913.json[.bz2]
# SPDX-License-Identifier: MIT
import base64
import bz2
import gzip
import html
import json
import os
import re
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
BALISE = re.compile(r'<[^>]+>')


def texte_propre(s):
    return re.sub(r'\s+', ' ', html.unescape(BALISE.sub(' ', s))).strip()


def supprimer_div(s, cls):
    """Retire un bloc <div class="cls"> ... </div> complet, meme imbrique."""
    out, i = [], 0
    tag = '<div class="%s"' % cls
    while i < len(s):
        j = s.find(tag, i)
        if j < 0:
            out.append(s[i:])
            break
        out.append(s[i:j])
        profondeur, k = 1, j
        while profondeur:
            m = re.search(r'<div\b|</div>', s[k + 1:])
            if not m:
                k = len(s)
                break
            k = k + 1 + m.start()
            profondeur += 1 if s[k:k + 4] == '<div' else -1
        i = k + 6
    return ''.join(out)


def sens_verbaux(entree):
    """Les sens verbaux d'une entree : articles dont la nature contient
    'v.' ; pour chaque definition, le numero de sens et la marque suivante."""
    sens = []
    for morceau in re.split(r'(?=<h2 class="hw">)', entree):
        mpos = re.search(r'<div class="pos">([^<]*)</div>', morceau)
        if not mpos or not re.search(r'\bv\.', mpos.group(1)):
            continue
        a = morceau
        for cls in ('ety', 'vmorph', 'syn', 'rj', 'pr'):
            a = supprimer_div(a, cls)
        for num, definition, marque in re.findall(
                r'(?:<div class="sn">([^<]*)</div>\s*)?'
                r'<div class="def">(.*?)</div>'
                r'(?:\s*<div class="mark">([^<]*)</div>)?', a, re.S):
            t = texte_propre(definition)
            if not t:
                continue
            if num:
                t = texte_propre(num) + ' ' + t
            if marque:
                t += ' ' + texte_propre(marque)
            sens.append(t)
    return sens


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        ICI, '..', 'webster1913.json.bz2')
    if source.endswith('.bz2'):
        webster = json.loads(bz2.open(source, 'rt', encoding='utf-8').read())
    else:
        with open(source, encoding='utf-8') as f:
            webster = json.load(f)
    canon = {}
    for k in webster:
        canon.setdefault(k.lower(), k)

    chemin = os.path.join(ICI, 'raw.json')
    with open(chemin, encoding='utf-8') as f:
        b = json.load(f)
    vsrc = set(x for x in b['EN_VSRC_STR'].split('\n') if x)

    lignes = b['EN_VERBS_STR'].split('\n')
    avant = sum(len([x for x in g.split(',') if x]) for g in lignes)
    gardees = []
    retires = 0
    for grp in lignes:
        gardes = [w for w in grp.split(',')
                  if w and (w not in vsrc or w in canon)]
        retires += len([w for w in grp.split(',') if w]) - len(gardes)
        gardees.append(','.join(gardes))

    # definitions : decodees du B64 existant
    txt = gzip.decompress(base64.b64decode(b['EN_DEFS_B64'])).decode('utf-8')
    defs = {}
    for p in txt.split('\x02'):
        if not p:
            continue
        k = p.split('\x01')
        if len(k) == 2 and k[0]:
            defs[k[0]] = k[1]

    # remplacer les glossaires Wiktionary par la definition Webster
    webster_defs, sans = {}, []
    for g in gardees:
        for w in g.split(','):
            if not w or w not in vsrc:
                continue
            sens = sens_verbaux(webster[canon[w]])
            if sens:
                webster_defs[w] = '\x03'.join(sens)
            else:
                sans.append(w)
    if sans:
        vus = set(sans)
        gardees = [','.join([w for w in g.split(',') if w not in vus])
                   for g in gardees]
        retires += len(sans)
        print('presences sans sens verbal extrait (retires) :', sans)
    verbes = [w for g in gardees for w in g.split(',') if w]
    for w, definition in webster_defs.items():
        defs[w] = definition

    # verbes conserves du generateur sans definition ( formes doubles
    # comme spoil/kneel ) : on prend la definition du Webster
    for w in verbes:
        if w in defs or w not in canon:
            continue
        sens = sens_verbaux(webster[canon[w]])
        if sens:
            webster_defs[w] = '\x03'.join(sens)
    for w, definition in webster_defs.items():
        defs[w] = definition

    restants = set(verbes)
    defs = {w: d for w, d in defs.items() if w in restants}
    b['EN_VSRC_STR'] = '\n'.join(sorted(vsrc & restants))
    b['EN_VERBS_STR'] = '\n'.join(gardees)
    corps = '\x02'.join(w + '\x01' + defs[w] for w in sorted(defs))
    b['EN_DEFS_B64'] = base64.b64encode(
        gzip.compress(corps.encode('utf-8'))).decode('ascii')

    with open(chemin, 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))
    print('verbes : %d -> %d ( -%d ), defs remplacees par le Webster : %d'
          % (avant, len(verbes), retires, len(webster_defs)))
    print('tous les verbes ont une definition :',
          all(w in defs for w in verbes))


if __name__ == '__main__':
    main()
