# Nettoie la conjugaison anglaise de raw.json :
#   1. dedoublonne les verbes (premiere occurrence conservee) ;
#   2. retire les verbes composés a trait d union ;
#   3. retire les verbes tres specialises : un verbe Wiktionary n est
#      conserve que si lui-meme ou l une de ses formes flechies usuelles
#      figure dans la liste de frequence OpenSubtitles
#      ( hermitdave/FrequencyWords, en_full.txt, utilisee uniquement
#      pour ce tri : aucune donnee n est embarquee ) ;
#   4. ajoute les doubles formes -ed/-t ( burnt, dreamt, learnt... )
#      pour burn, dream, dwell, kneel, leap, lean, learn, spoil,
#      retires de leur ancien groupe et places dans un template
#      commun a double terminaison.
# SPDX-License-Identifier: MIT
import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
FREQUENCE = '/home/user/work/kaikki/en_full.txt'

DOUBLES = ['burn', 'dream', 'leap', 'lean', 'learn', 'spoil']
# radicaux particuliers : dwelt = dwel+lt ( pas dwell+t ),
# knelt = kn+elt, kneeled = kn+eeled
SPECIAUX = ['dwell', 'kneel']


def formes_de(w):
    fs = {w, w + 's', w + 'es', w + 'ed', w + 'ing'}
    if w.endswith('e'):
        fs |= {w + 'd', w[:-1] + 'ing'}
    if w.endswith('y'):
        fs |= {w[:-1] + 'ied', w[:-1] + 'ies'}
    return fs


def main():
    with open(FREQUENCE, encoding='utf-8') as f:
        freq = set(l.split()[0] for l in f if l.strip())

    with open(os.path.join(ICI, 'raw.json'), encoding='utf-8') as f:
        b = json.load(f)
    vsrc = set(x for x in b['EN_VSRC_STR'].split('\n') if x)
    tpls = b['EN_TPL_STR'].split('\n')
    groupes = b['EN_VERBS_STR'].split('\n')
    assert len(tpls) == len(groupes), 'tpl/verbes desynchronises'

    vus = set()
    nouveaux_t, nouveaux_g = [], []
    retires = 0
    for tpl, grp in zip(tpls, groupes):
        gardes = []
        for w in grp.split(','):
            if not w:
                continue
            if w in vus:
                retires += 1
                continue
            if '-' in w or w in DOUBLES or w in SPECIAUX:
                retires += 1
                continue
            if w in vsrc and not (formes_de(w) & freq):
                retires += 1
                continue
            vus.add(w)
            gardes.append(w)
        if gardes:
            nouveaux_t.append(tpl)
            nouveaux_g.append(','.join(gardes))

    # le template des doubles formes -ed/-t : radical = le verbe entier
    nouveaux_t.append('dblt:;,,s,,,;ed,t,ed,t,ed,t;ed/t;ing;')
    nouveaux_g.append(','.join(sorted(DOUBLES)))
    # dwell : rad dwel ( suffixe l )→ dwelled ( dwel+led ) / dwelt ( dwel+t )
    nouveaux_t.append('dwel:l;l,l,ls,l,l,l;led,t,led,t,led,t;led/t;ling;')
    nouveaux_g.append('dwell')
    # kneel : rad kne ( suffixe el )→ kneeled ( kne+eled ) / knelt ( kne+lt )
    nouveaux_t.append('kneel:el;el,el,els,el,el,el;'
                      'eled,lt,eled,lt,eled,lt;eled/lt;eling;')
    nouveaux_g.append('kneel')
    for w in DOUBLES + SPECIAUX:
        vus.add(w)

    b['EN_TPL_STR'] = '\n'.join(nouveaux_t)
    b['EN_VERBS_STR'] = '\n'.join(nouveaux_g)
    b['EN_VSRC_STR'] = '\n'.join(sorted(x for x in vsrc if x in vus))

    with open(os.path.join(ICI, 'raw.json'), 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))

    print('verbes conserves : %d (dont %d du Wiktionary), %d retires'
          % (len(vus), len(b['EN_VSRC_STR'].split('\n')) - 1, retires))


if __name__ == '__main__':
    main()
